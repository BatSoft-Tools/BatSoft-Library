unit BatSoft.Settings.Base;

interface

uses
  System.SysUtils, System.TypInfo, System.RTTI, System.Classes, Generics.Collections;

type
  SettingsDeepField = class(TCustomAttribute);

{$region 'Settings attributes'}

{$region 'Ignore'}

type
  SettingIgnoreAttribute = class(TCustomAttribute);

function HasSettingIgnore(const Prop: TRttiProperty): Boolean;

{$endregion}

{$region 'Preferred constructor'}

//type
//  PreferredConstructorAttribute = class(TCustomAttribute);

{$endregion}

{$region 'Don''t clear'}

//type
//  SettingClearAttribute = class(TCustomAttribute)
//  private
//    fClear: Boolean;
//  public
//    constructor Create(const AClear: Boolean);
//    property  Clear: Boolean  read fClear;
//    class function ShouldClear(const Prop: TRttiProperty; const Default: Boolean): Boolean;
//  end;

{$endregion}

{$region 'SettingsOrder'}

type
  SettingsOrderAttribute = class(TCustomAttribute)
  private
    fReadOrder: integer;
    fWriteOrder: integer;
  public
    constructor Create(const AReadOrder, AWriteOrder: integer);
    property  ReadOrder   : integer read fReadOrder;
    property  WriteOrder  : integer read fWriteOrder;
  end;

function GetSettingsOrder(const Prop: TRttiProperty; const Write: Boolean): integer;
function SortAndFilter(const Props: TArray<TRttiProperty>; const Write: Boolean): TArray<TRttiProperty>;

{$endregion}

{$region 'SettingName'}

type
  SettingNameAttribute = class(TCustomAttribute)
  private
    fSettingName: string;
  public
    constructor Create(const ASettingName: string);
    property  SettingName: string read fSettingName;
    class function SettingNameOf(const Prop: TRttiProperty): string;
  end;

{$endregion}

{$endregion}
type
  ISettingsStoreReader = interface
    ['{42508E64-EC8C-44C9-A2F6-9C666BE84230}']
    //  Storage
    procedure LoadBegin;
    procedure LoadEnd;
    //  Navigation
    procedure NodeChildren(const Names: TStrings);
    function  NodeEnter(const Name: string): Boolean;
    procedure NodeLeave;
    //  Arrays
//    function  ListBegin(const Name: string): Boolean;
//    procedure ListEnd;
//    //  Array elements
//    function  ElemEnter(const Index: integer): Boolean;
//    procedure ElemLeave;
    //  Simple values
    function  LoadValue(const Name: string; const TypeInfo: PTypeInfo): TValue;
  end;

  ISettingsStoreWriter = interface
    ['{DE922225-D7A5-40DF-BAB4-CE84F522328D}']
    //  Storage
    procedure SaveBegin;
    procedure SaveEnd;
    //  Navigation
    procedure NodeClear(const Name: string);
    procedure NodeEnter(const Name: string; const IsNil: Boolean);
    procedure NodeLeave;
    //  Arrays
    procedure ListClear(const Name: string);
    procedure ListBegin(const Name: string; const IsNil: Boolean);
    procedure ListEnd;
    //  Array elements
    procedure ElemEnter(const Index: integer; const IsNil: Boolean);
    procedure ElemLeave;
    //  Simple values
    procedure SaveValue(const Name: string; const Value: TValue);
  end;

  TSettingsStore = class(TInterfacedObject)
  protected
    fFileName: string;
    fEnumsAsStrings: Boolean;
  public
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True); virtual;
    class procedure Load(var Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean = True; const DefaultClass: TClass = nil); overload;
    class procedure Load<T: class>(var Obj: T; const AFileName: string; const AEnumsAsStrings: Boolean = True); overload;
    class procedure Save(const Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean = True);
  end;
  TSettingsStoreClass = class of TSettingsStore;

  TSettingsReader = class
  private
    fStore: ISettingsStoreReader;
    procedure CorrectObjectClass(var Obj: TObject; const PropertyClass: TRttiInstanceType);
    function  GetObjClass: TRttiInstanceType;
    procedure LoadProperties(const Obj: TObject);
    function  LoadString(const Name: string): string;
    procedure LoadStringsDeep(var Obj: TObject; const RTTIProp: TRttiProperty);
  public
    constructor Create(ASettingsReader: ISettingsStoreReader); overload;
    procedure Load(var Obj: TObject; const ObjClass: TClass);
  end;

  TSettingsWriter = class
  private
    fStore: ISettingsStoreWriter;
    procedure SaveProperties(const Obj: TObject; const PropClass: TClass);
    procedure SaveList(const Obj: TObject; const ElemClass: TClass);
    procedure SaveStrings(const Name: string; const Obj: TObject);
    procedure SaveStringsDeep(const Obj: TObject);
  public
    constructor Create(const ASettingsWriter: ISettingsStoreWriter);
    procedure Save(const Obj: TObject; ObjClass: TClass = nil);
  end;

  ObjectLists = class
  private
    class var _Types: TDictionary<TClass, TClass>;
  public
    class constructor Create;
    class destructor  Destroy;
    class procedure Register(const ListClass, ElemClass: TClass);
    class function  IsRegistered(const ListClass: TClass; out ElemClass: TClass): Boolean; overload;
  end;

  ESettings = class(Exception)
  public
    constructor Create(const AMessage: string); overload;
    constructor Create(const AMessage: string; const Args: array of const); overload;
  end;

function  EnumToStr(const Value: TValue): string;
function  EnumSetToStr(const Value: TValue): string;

function  StrToEnum(const Value: string; const Info: PTypeInfo): integer;
function  StrToEnumSet(Value: string; const Info: PTypeInfo): Int64;

function  Enum_StringToValue(const Value: string; const Info: PTypeInfo): TValue;
function  EnumSet_StringToValue(const Value: string; const Info: PTypeInfo): TValue;

const
  SClass  = 'Class';
  SNil    = 'Null';

resourcestring
  SESettingsNotNil    = 'Settings must not be nil.';
  SENotSettingsList   = 'List is not a settings list.';
  SENotByteArray      = 'Property %s cannot be loaded because it is a dynamic array, but not TArray<Byte>.';
  SEUnsupportedType   = 'Property %s cannot be loaded because it is of type %s.';
  SNotImplemented     = 'Not implemented.';
  SNotRegisteredClass = 'Class %s is not registered.';

implementation

uses
  System.Generics.Defaults, BatSoft.Classes;

var
  RTTI: TRttiContext;

const
  SupportedSimpleTypes = [tkInteger, tkInt64, tkFloat, tkEnumeration, tkSet,
        tkChar, tkWChar, tkString, tkLString, tkWString, tkUString, tkVariant];

type
  TSettingsOrderComparer = class(TInterfacedObject, IComparer<TRttiProperty>)
  private
    fWriteOrder: Boolean;
  public
    constructor Create(const AWriteOrder: Boolean);
    //  IComparer<T> interface
    function Compare(const Left, Right: TRttiProperty): Integer;
  end;

var
  ReadComparer: IComparer<TRttiProperty>;
  WriteComparer: IComparer<TRttiProperty>;

function FindAttribute(const Prop: TRttiProperty; const AttributeClass: TClass; out Attribute: TCustomAttribute): Boolean;
var
  Attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
begin
  Attrs   := Prop.GetAttributes;
  for Attr in Attrs do
    if  Attr is AttributeClass  then
      begin
        Attribute := Attr;
        Exit(True);
      end;
  Result  := False;
end;

{ TSettingsOrderComparer }

function TSettingsOrderComparer.Compare(const Left, Right: TRttiProperty): Integer;
begin
  Result  := GetSettingsOrder(Left, fWriteOrder) - GetSettingsOrder(Right, fWriteOrder)
end;

constructor TSettingsOrderComparer.Create(const AWriteOrder: Boolean);
begin
  inherited Create;
  fWriteOrder := AWriteOrder;
end;

{ IgnoreSettingAttribute }

function HasSettingIgnore(const Prop: TRttiProperty): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := FindAttribute(Prop, SettingIgnoreAttribute, Attr)
end;

{ SettingsOrderAttribute }

constructor SettingsOrderAttribute.Create(const AReadOrder, AWriteOrder: integer);
begin
  inherited Create;
  fReadOrder  := AReadOrder;
  fWriteOrder := AWriteOrder;
end;

function GetSettingsOrder(const Prop: TRttiProperty; const Write: Boolean): integer;
var
  Attr: TCustomAttribute;
begin
  if  not FindAttribute(Prop, SettingsOrderAttribute, Attr) then
    Result  := 0
  else if Write then
    Result  := SettingsOrderAttribute(Attr).WriteOrder
  else
    Result  := SettingsOrderAttribute(Attr).ReadOrder;
end;

function SortAndFilter(const Props: TArray<TRttiProperty>; const Write: Boolean): TArray<TRttiProperty>;
var
  List: TList<TRttiProperty>;
  Prop: TRttiProperty;
begin
  List  := TList<TRttiProperty>.Create;
  try
    //  Sort properties
    for Prop in Props do
      if  Prop.Visibility = TMemberVisibility.mvPublished then
        if  not HasSettingIgnore(Prop)  then
          List.Add(Prop);
    if  Write then
      List.Sort(WriteComparer)
    else
      List.Sort(ReadComparer);
    //  Done
    Result  := List.ToArray;
  finally
    List.Free;
  end;
end;

{ SettingNameAttribute }

constructor SettingNameAttribute.Create(const ASettingName: string);
begin
  inherited Create;
  fSettingName  := ASettingName;
end;

class function SettingNameAttribute.SettingNameOf(const Prop: TRttiProperty): string;
var
  Attr: TCustomAttribute;
begin
  if  FindAttribute(Prop, SettingNameAttribute, Attr) then
    Result  := SettingNameAttribute(Attr).SettingName
  else
    Result  := Prop.Name;
end;

//  Enumeration strings

function EnumToStr(const Value: TValue): string;
var
  Int: integer;
begin
  Value.ExtractRawDataNoCopy(@Int);
  Result  := GetEnumName(Value.TypeInfo, Int)
end;

function EnumSetToStr(const Value: TValue): string;
var
  Int: integer;
begin
  Value.ExtractRawDataNoCopy(@Int);
  Result  := SetToString(Value.TypeInfo, Int)
end;

function  StrToEnum(const Value: string; const Info: PTypeInfo): integer;
begin
  Result  := GetEnumValue(Info, Value)
end;

function  StrToEnumSet( Value: string; const Info: PTypeInfo): Int64;
begin
  Result  := StringToSet(Info, Value)
end;

function  Enum_StringToValue(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := StrToEnum(Value, Info);
  Result  := TValue.FromOrdinal(Info, Val)
end;

function  EnumSet_StringToValue(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := StrToEnumSet(Value, Info);
  TValue.Make(@Val, Info, Result);
end;

{ TSettingsStore }

constructor TSettingsStore.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  inherited Create();
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
end;

class procedure TSettingsStore.Load(var Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean; const DefaultClass: TClass);
var
  Reader: TSettingsReader;
begin
  if  Self = TSettingsStore then
    raise ESettings.Create(SNotImplemented);
  Reader  := TSettingsReader.Create(Self.Create(AFileName, AEnumsAsStrings) as ISettingsStoreReader);
  try
    Reader.Load(TObject(Obj), DefaultClass);
  finally
    Reader.Free;
  end;
end;

class procedure TSettingsStore.Load<T>(var Obj: T; const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  Load(TObject(Obj), AFileName, AEnumsAsStrings, T);
end;

class procedure TSettingsStore.Save(const Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean);
var
  Writer: TSettingsWriter;
begin
  if  Self = TSettingsStore then
    raise ESettings.Create(SNotImplemented);
  Writer  := TSettingsWriter.Create(Self.Create(AFileName, AEnumsAsStrings) as ISettingsStoreWriter);
  try
    Writer.Save(Obj);
  finally
    Writer.Free;
  end;
end;

{ TSettingsReader }

procedure TSettingsReader.CorrectObjectClass(var Obj: TObject; const PropertyClass: TRttiInstanceType);
var
  ObjClass: TRttiInstanceType;
  Methods: TArray<TRttiMethod>;
  Method: TRttiMethod;
begin
  //  Determine the type Obj should be
  ObjClass  := GetObjClass;
  if  not Assigned(ObjClass)  then
    ObjClass  := PropertyClass;
  //  Might be that
  if  not Assigned(ObjClass) or (Obj is ObjClass.MetaclassType) then
    Exit;
  FreeAndNil(Obj);
  //  Find preferred constructor
  Methods := ObjClass.GetMethods;
  for Method in Methods do
    if Method.IsConstructor and (Length(Method.GetParameters) = 0) then
      begin
        //  Found a usable constructor
        Obj := Method.Invoke(ObjClass.MetaclassType, []).AsObject;
        Exit;
      end;
  //  Ah, well. Create an un-initialised object
  Obj.Free;
  Obj := ObjClass.MetaclassType.Create;
end;

constructor TSettingsReader.Create(ASettingsReader: ISettingsStoreReader);
begin
  inherited Create;
  fStore  := ASettingsReader;
end;

function TSettingsReader.GetObjClass: TRttiInstanceType;
var
  ClassName: string;
  RTTIType: TRttiType;
begin
  ClassName := LoadString(SClass);
  if  ClassName.IsEmpty then
    Exit(nil);
  RTTIType  := RTTI.FindType(ClassName);
  if not Assigned(RTTIType) then
    raise ESettings.Create(SNotRegisteredClass, [ClassName]);
  Result  := RTTIType.AsInstance;
end;

procedure TSettingsReader.Load(var Obj: TObject; const ObjClass: TClass);
var
  RTTIInst: TRttiInstanceType;
begin
  if  Assigned(ObjClass)  then
    RTTIInst  := RTTI.GetType(ObjClass).AsInstance
  else
    RTTIInst  := nil;
  fStore.LoadBegin;
  try
    CorrectObjectClass(Obj, RTTIInst);
    LoadProperties(Obj);
  finally
    fStore.LoadEnd;
  end;
end;

procedure TSettingsReader.LoadProperties(const Obj: TObject);
var
  RTTIType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
  Kind: TTypeKind;
  SettName: string;
  Child: TObject;
  ChildClass: TClass;
begin
  if  not Assigned(Obj) then
    Exit;
  RTTIType  := RTTI.GetType(Obj.ClassType);
  RTTIProps := RTTIType.GetProperties;
  RTTIProps := SortAndFilter(RTTIProps, False);
  for RTTIProp in RTTIProps do
    begin
      //  Get the correct settings name
      SettName  := SettingNameAttribute.SettingNameOf(RTTIProp);
      //  Examine type kind
      Kind  := RTTIProp.PropertyType.TypeKind;
      //  Save simple type
      if Kind in SupportedSimpleTypes then
        RTTIProp.SetValue(Obj, fStore.LoadValue(SettName, RTTIProp.PropertyType.Handle))
      //  Save sub-object
      else if Kind = tkClass then
        begin
          ChildClass  := RTTIProp.PropertyType.AsInstance.MetaclassType;
          //  TStrings are special
          if  ChildClass.InheritsFrom(TStrings) then
            //  Read "deep" TStrings elements as separate named children
            if  TCustomAttribute.HasAttribute(RTTIProp.GetAttributes, SettingsDeepField)  then
              begin
                Child := RTTIProp.GetValue(Obj).AsObject;
                LoadStringsDeep(Child, RTTIProp);
                if  RTTIProp.IsWritable then
                  RTTIProp.SetValue(Obj, Child);
              end
            else
              //  Read "shallow" TStrings as a single delimited string
              (Child as TStrings).DelimitedText := LoadString(SettName)

//          //  Save settings list elements as objects
//          else if ObjectLists.IsRegistered(Child.ClassType, ElemClass) then
//            begin
//              fStore.ListClear(SettName);
//              fStore.ListBegin(SettName, not Assigned(Child));
//              try
//                SaveList(Child, ElemClass);
//              finally
//                fStore.ListEnd;
//              end;
//            end
//          //  Not a list
//          else
//            begin
//              fStore.NodeEnter(SettName, not Assigned(Child));
//              try
//                SaveProperties(Child, RTTIProp.PropertyType.AsInstance.MetaclassType);
//              finally
//                fStore.NodeLeave;
//              end;
//            end
//              raise ESettings.Create(SEUnsupportedType, [SettName, Child.ClassName]);
        end
      //  - Unhandled
      else
        raise ESettings.Create(SEUnsupportedType, [SettName, EnumToStr(TValue.From(Kind))]);
    end;

end;

function TSettingsReader.LoadString(const Name: string): string;
begin
  Result  := fStore.LoadValue(Name, TypeInfo(string)).AsString
end;

procedure TSettingsReader.LoadStringsDeep(var Obj: TObject; const RTTIProp: TRttiProperty);
var
  Strs: TStrings absolute Obj;
  ElemNames: TStrings;
  ElemName: string;
  Elem: TObject;
  i: integer;
begin
  if  fStore.NodeEnter(RTTIProp.Name) then
    try
      if  RTTIProp.IsWritable then
        CorrectObjectClass(Obj, RTTIProp.PropertyType.AsInstance);
      ElemNames := TStringList.Create;
      try
        fStore.NodeChildren(ElemNames);
        for ElemName in ElemNames do
          begin
            //  Ensure we have the element
            i := Strs.IndexOf(ElemName);
            if  i < 0 then
              i := Strs.Add(ElemName);
            //  Load the element object
            Elem  := Strs.Objects[i];
            if  fStore.NodeEnter(ElemName)  then
              try
                CorrectObjectClass(Elem, nil);
                Strs.Objects[i] := Elem;
                LoadProperties(Elem);
              finally
                fStore.NodeLeave;
              end;
          end;
      finally
        ElemNames.Free;
      end;
    finally
      fStore.NodeLeave;
    end;
end;

{ TSettingsWriter }

constructor TSettingsWriter.Create(const ASettingsWriter: ISettingsStoreWriter);
begin
  inherited Create();
  fStore  := ASettingsWriter;
end;

procedure TSettingsWriter.Save(const Obj: TObject; ObjClass: TClass);
begin
  //  Determine object class
  if  not Assigned(ObjClass)  then
    ObjClass  := Obj.ClassType;
  //  Save
  fStore.SaveBegin;
  try
    SaveProperties(Obj, ObjClass);
  finally
    fStore.SaveEnd;
  end;
end;

procedure TSettingsWriter.SaveList(const Obj: TObject; const ElemClass: TClass);
var
  List: TObjectList<TObject> absolute Obj;
  i: integer;
begin
  for i := 0 to List.Count - 1 do
    begin
      fStore.ElemEnter(i, not Assigned(List[i]));
      try
        SaveProperties(List[i], ElemClass)
      finally
        fStore.ElemLeave;
      end;
    end;
end;

procedure TSettingsWriter.SaveProperties(const Obj: TObject; const PropClass: TClass);
var
  RTTIType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
  Kind: TTypeKind;
  SettName: string;
  Child: TObject;
  ElemClass: TClass;
begin
  if  not Assigned(Obj) then
    Exit;
  RTTIType  := RTTI.GetType(Obj.ClassType);
  if  RTTIType.AsInstance.MetaclassType <> PropClass  then
    fStore.SaveValue(SClass, Obj.QualifiedClassName);
  RTTIProps := RTTIType.GetProperties;
  RTTIProps := SortAndFilter(RTTIProps, True);
  for RTTIProp in RTTIProps do
    begin
      //  Get the correct settings name
      SettName  := SettingNameAttribute.SettingNameOf(RTTIProp);
      //  Examine type kind
      Kind  := RTTIProp.PropertyType.TypeKind;
      //  Save simple type
      if Kind in SupportedSimpleTypes then
        fStore.SaveValue(SettName, RTTIProp.GetValue(Obj))
      //  Save sub-object
      else if Kind = tkClass then
        begin
          Child := RTTIProp.GetValue(Obj).AsObject;
          //  Handle nil objects
          if  not Assigned(Child) then
            Continue;
          //  TStrings are special
          if  Child is TStrings then
            //  Write "deep" TStrings elements as separate named children
            if  TCustomAttribute.HasAttribute(RTTIProp.GetAttributes, SettingsDeepField)  then
              begin
                fStore.NodeClear(SettName);
                fStore.NodeEnter(SettName, not Assigned(Child));
                try
                  SaveStringsDeep(Child);
                finally
                  fStore.NodeLeave;
                end;
              end
            else
              //  Write "shallow" TStrings as a single delimited string
              SaveStrings(SettName, Child)
          //  Save settings list elements as objects
          else if ObjectLists.IsRegistered(Child.ClassType, ElemClass) then
            begin
              fStore.ListClear(SettName);
              fStore.ListBegin(SettName, not Assigned(Child));
              try
                SaveList(Child, ElemClass);
              finally
                fStore.ListEnd;
              end;
            end
          //  Not a list
          else
            begin
              fStore.NodeEnter(SettName, not Assigned(Child));
              try
                SaveProperties(Child, RTTIProp.PropertyType.AsInstance.MetaclassType);
              finally
                fStore.NodeLeave;
              end;
            end
//            raise ESettings.Create(SEUnsupportedType, [SettName, Child.ClassName]);
        end
      //  - Unhandled
      else
        raise ESettings.Create(SEUnsupportedType, [SettName, EnumToStr(TValue.From(Kind))]);
    end;
end;

procedure TSettingsWriter.SaveStrings(const Name: string; const Obj: TObject);
var
  Strs: TStrings absolute Obj;
begin
  fStore.SaveValue(Name, Strs.DelimitedText);
end;

procedure TSettingsWriter.SaveStringsDeep(const Obj: TObject);
var
  Strs: TStrings absolute Obj;
  i: integer;
begin
  for i := 0 to Strs.Count - 1 do
    begin
      fStore.NodeEnter(Strs[i], not Assigned(Strs.Objects[i]));
      try
        SaveProperties(Strs.Objects[i], TObject);
      finally
        fStore.NodeLeave;
      end;
    end;
end;

{ ObjectLists }

class constructor ObjectLists.Create;
begin
  _Types  := TDictionary<TClass, TClass>.Create;
end;

class destructor ObjectLists.Destroy;
begin
  _Types.Free;
end;

class function ObjectLists.IsRegistered(const ListClass: TClass; out ElemClass: TClass): Boolean;
begin
  Result  := _Types.TryGetValue(ListClass, ElemClass)
end;

class procedure ObjectLists.Register(const ListClass, ElemClass: TClass);
begin
  _Types.Add(ListClass, ElemClass);
end;

{ ESettings }

constructor ESettings.Create(const AMessage: string; const Args: array of const);
begin
  inherited Create(Format(AMessage, Args));
end;

constructor ESettings.Create(const AMessage: string);
begin
  inherited;
end;

initialization
  RTTI  := TRttiContext.Create;
  ReadComparer  := TSettingsOrderComparer.Create(False);
  WriteComparer := TSettingsOrderComparer.Create(True);

finalization
  RTTI.Free;

end.
