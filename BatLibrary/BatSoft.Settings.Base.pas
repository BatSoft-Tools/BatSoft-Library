unit BatSoft.Settings.Base;

interface

{$DEFINE DEVELOPING}

uses
  System.RTTI, Classes, BatSoft.Settings;

{$IFDEF DEVELOPING}
type
  ISettingsStoreReader = interface
    ['{42508E64-EC8C-44C9-A2F6-9C666BE84230}']
    function State: string;
    //  Storage
    procedure BeginLoad;
    procedure EndLoad;
    //  Navigation
    procedure MoveToChild(const Name: string);
    procedure MoveToParent;
    //  Arrays
    function  ListBegin: Boolean;
    function  ListNext: Boolean;
    procedure ListEnd;
    function  ListValue: string;
    procedure LoadStrings(const Strs: TStrings);
    //  Property values
    //  - Iterators
    function  ValueBegin: Boolean;
    function  ValueNext: Boolean;
    procedure ValueEnd;
//    //  - Accessors
//    function  GetNameValue(out Name: string; out Value: TValue): Boolean;
    function  GetValue(const Name: string; const TypeKind: TTypeKind; out Value: TValue): Boolean;
  end;

  ISettingsStoreWriter = interface
    ['{DE922225-D7A5-40DF-BAB4-CE84F522328D}']
    //  Storage
    procedure BeginSave;
    procedure EndSave;
    //  Navigation
    procedure MoveToChild(const Name: string);
    procedure MoveToParent;
    //  Arrays
    //  - Iterators
    function  IsList: Boolean;
    function  ListBegin: Boolean;
    function  ListNext: Boolean;
    procedure ListEnd;
    procedure SaveStrings(const Strs: TStrings);
    //  - Modifiers
    procedure ListClear;
    procedure ListAdd;
    //  Property values
    procedure SetValue(const Name: string; const Value: TValue);
  end;

  TSettingsReader = class
  private
    function  CreateObject(const DefaultClass: TRttiType): TObject;
  protected
    fReader: ISettingsStoreReader;
    fWriter: ISettingsStoreWriter;
    fClearValues: Boolean;
    //  Loading
    procedure LoadThing(const Obj: TObject);
    procedure LoadList(const Obj: TObject);
    procedure LoadObj(const Obj: TObject);
    procedure LoadStrings(const Obj: TObject);
  public
    constructor Create(AReader: ISettingsStoreReader; AWriter: ISettingsStoreWriter); overload;
    constructor Create(AReaderWriter: IInterface); overload;
    //  ISettingsStore interface
    procedure LoadFile(const Settings: TObject; const ClearValues: Boolean);
    procedure SaveFile(const Settings: TObject);
  end;

  TSettingsWriter = class

  end;

resourcestring
  SESettingsNotNil  = 'Settings must not be nil.';
  SENotSettingsList = 'List is not a settings list.';
  SENotByteArray    = 'Property %s cannot be loaded because it is a dynamic array, but not TArray<Byte>.';
  SEUnsupportedType = 'Property %s cannot be loaded because it is of type %s.';
{$ENDIF}

implementation

{$IFDEF DEVELOPING}
uses
  SysUtils, TypInfo, Generics.Collections, BatSoft.Classes;

var
  RTTI: TRttiContext;
  TypeBool: TRttiType;
  STBytes: string;

const
  SClass  = 'Class';
  SCreate = 'Create';
  SupportedSimpleTypes = [tkInteger, tkInt64, tkFloat, tkEnumeration, tkSet,
              tkChar, tkWChar, tkString, tkLString, tkWString, tkUString, tkVariant];

{ TSettingsReader }

constructor TSettingsReader.Create(AReader: ISettingsStoreReader; AWriter: ISettingsStoreWriter);
begin
  inherited Create();
  fReader := AReader;
  fWriter := AWriter;
end;

constructor TSettingsReader.Create(AReaderWriter: IInterface);
begin
  Create(AReaderWriter as ISettingsStoreReader, AReaderWriter as ISettingsStoreWriter)
end;

function TSettingsReader.CreateObject(const DefaultClass: TRttiType): TObject;

  function CreateOfClass(ChildClass: TRttiType): TObject;
  var
    Methods: TArray<TRttiMethod>;
    Method: TRttiMethod;
    i: integer;
  begin
    Methods := ChildClass.GetMethods;
    for i := 0 to Length(Methods) - 1 do
      begin
        Method  := Methods[i];
        if  Method.IsConstructor and (Length(Method.GetParameters) = 0) and SameText(Method.Name, SCreate) or
            TCustomAttribute.HasAttribute<PreferredConstructorAttribute>(Method.GetAttributes)
        then
          Exit(Method.Invoke(ChildClass.AsInstance.MetaclassType, []).AsObject);
      end;
    Result  := ChildClass.AsInstance.MetaclassType.Create;
  end;

var
  ClassValue: TValue;
  ChildClassName: string;
  ChildClass: TRttiType;
begin
  //  Determine class
  if  fReader.GetValue(SClass, tkString, ClassValue) and not ClassValue.IsEmpty then
    begin
      ChildClassName  := ClassValue.AsString;
      ChildClass      := RTTI.FindType(ChildClassName);
    end
  else
    ChildClass  := DefaultClass;
  //  Create object
  if  not Assigned(ChildClass)  then
    Result  := nil
  else
    Result  := CreateOfClass(ChildClass)
end;

procedure TSettingsReader.LoadFile(const Settings: TObject; const ClearValues: Boolean);
begin
  fClearValues  := ClearValues;
  if  not Assigned(Settings)  then
    raise ESettings.Create(SESettingsNotNil);
  fReader.BeginLoad;
  try
    LoadThing(Settings);
  finally
    fReader.EndLoad;
  end;
end;

procedure TSettingsReader.LoadList(const Obj: TObject);
var
  ListObj: TObjectList<TObject>;
  ElemType: TClass;
  RTTIType: TRttiType;
  ElemObj: TObject;
begin
  if  not RegisteredSettingsLists.Find(Obj, ListObj, ElemType) then
    raise ESettings.Create(SENotSettingsList);
  RTTIType  := RTTI.GetType(ElemType);
  //  Might clear the list
  if  fClearValues  then
    ListObj.Clear;
  //  Load the list
  if  fReader.ListBegin then
    try
      repeat
        ElemObj := CreateObject(RTTIType);
        ListObj.Add(ElemObj);
        LoadThing(ElemObj);
      until not fReader.ListNext;
    finally
      fReader.ListEnd;
    end;
end;

procedure TSettingsReader.LoadObj(const Obj: TObject);
var
  RTTIType, RTTIClassType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
  SettName: string;
  Value: TValue;
  ChildObj: TObject;
begin
//  if  not Assigned(Obj) then
//    Exit;
  RTTIType  := RTTI.GetType(Obj.ClassType);
  RTTIProps := RTTIType.GetProperties;
  RTTIProps := SortAndFilter(RTTIProps, False);
  for RTTIProp in RTTIProps do
    begin
      //  Get the correct settings name
      SettName  := SettingNameAttribute.SettingNameOf(RTTIProp);
      //  Obtain value
      if  not fReader.GetValue(SettName, RTTIProp.PropertyType.TypeKind, Value) then
        if  fClearValues  then
          Value := TValue.Empty
        else
          Continue;
      //  Might clear property
      if  Value.IsEmpty and SettingClearAttribute.ShouldClear(RTTIProp, fClearValues) then
        begin
          if  RTTIProp.PropertyType.TypeKind = tkClass  then
            begin
              RTTIProp.GetValue(Obj).AsObject.Free;
              RTTIProp.SetValue(Obj, nil);
            end
          else
            RTTIProp.SetValue(Obj, TValue.Empty);
          Continue;
        end;
      //  Set property
      if  RTTIProp.IsWritable or (RTTIProp.PropertyType.TypeKind = tkClass) then
        case RTTIProp.PropertyType.TypeKind of
          tkClassRef :
            begin
              RTTIClassType  := RTTI.FindType(Value.AsString);
              if  not Assigned(RTTIClassType)  then
                raise ESettings.Create('Class ' + Value.AsString + ' not found.');
              if  RTTIClassType.TypeKind <> tkClass then
                raise ESettings.Create('Type ' + Value.AsString + ' is not a class.');
              RTTIProp.SetValue(Obj, TClass((RTTIClassType as TRttiInstanceType).MetaclassType));
            end;
          tkClass :
            begin
              //  Get current object
              ChildObj := RTTIProp.GetValue(Obj).AsObject;
              //  Get hold of a child object
              if  not Assigned(ChildObj) and not Value.IsEmpty and RTTIProp.IsWritable  then
                begin
                  ChildObj  := CreateObject(RTTI.GetType((RTTIProp.PropertyType as TRttiInstanceType).MetaclassType));
                  RTTIProp.SetValue(Obj, ChildObj);
                end;
              //
//            if  Assigned(ChildObj) and not Value.IsEmpty and (Should-be-ClassType <> ChildObj.ClassType) then
//              ...
              //  Load its settings
              if  Assigned(ChildObj) then
                try
                  fReader.MoveToChild(SettName);
                  LoadThing(ChildObj);
                finally
                  fReader.MoveToParent;
                end;
            end;
          tkDynArray :
            if  not Value.IsEmpty then
              begin
                if  not SameText(RTTIProp.PropertyType.Name, STBytes) then
                  raise ESettings.Create(SENotByteArray, [SettName]);
                if  not SameText(Value.TypeInfo.Name, STBytes)  then
                  raise ESettings.Create(SENotByteArray, [SettName]);
                RTTIProp.SetValue(Obj, Value);
              end;
          tkEnumeration :
            SetEnumProp(Obj, SettName, Value.ToString);
          tkSet :
            SetSetProp(Obj, SettName, Value.ToString);
        else
            RTTIProp.SetValue(Obj, Value);
        end;
    end;
end;

procedure TSettingsReader.LoadStrings(const Obj: TObject);
var
  Strs: TStrings absolute Obj;
  Str: string;
begin
  //  Might clear the list
  if  fClearValues  then
    Strs.Clear;
  //  Load the list
  fReader.LoadStrings(Strs);
  if  fReader.ListBegin then
    try
      repeat
        Str := fReader.ListValue;
        Strs.Add(Str);
      until not fReader.ListNext;
    finally
      fReader.ListEnd;
    end;
end;

procedure TSettingsReader.LoadThing(const Obj: TObject);
begin
  if  RegisteredSettingsLists.IsSettingsList(Obj.ClassType) then
    LoadList(Obj)
  else if Obj is TStrings then
    LoadStrings(Obj)
  else
    LoadObj(Obj)
end;

procedure TSettingsReader.SaveFile(const Settings: TObject);

  procedure SaveObj(const Obj: TObject);
  begin

  end;

begin
//  if  not Assigned(Settings)  then
//    raise ESettings.Create(SESettingsNotNil);
//  fImplementation.BeginSave;
//  try
//    SaveObj(Settings);
//  finally
//    fImplementation.EndSave;
//  end;
end;

initialization
  RTTI    := TRttiContext.Create;
  STBytes := 'TArray<System.Byte>';

finalization
  RTTI.Free;

{$ENDIF}
end.
