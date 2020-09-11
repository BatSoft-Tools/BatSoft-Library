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
    function State: string;
    //  Storage
    procedure BeginLoad;
    procedure EndLoad;
    //  Navigation
    procedure NodeEnter(const Name: string);
    procedure NodeLeave;
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
    class procedure Load(const Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean = True);
    class procedure Save(const Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean = True);
  end;
  TSettingsStoreClass = class of TSettingsStore;

  TSettingsReader = class
  public
    constructor Create(AReader: ISettingsStoreReader; AWriter: ISettingsStoreWriter); overload;
    constructor Create(AReaderWriter: IInterface); overload;
    procedure Load(const Obj: TObject);
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

const
  SClass  = 'Class';

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

function EnumSetToStr(const Value: TValue): string;
var
  Int: integer;
begin
  Value.ExtractRawDataNoCopy(@Int);
  Result  := SetToString(Value.TypeInfo, Int)
end;

function EnumToStr(const Value: TValue): string;
var
  Int: integer;
begin
  Value.ExtractRawDataNoCopy(@Int);
  Result  := GetEnumName(Value.TypeInfo, Int)
end;

{ TSettingsStore }

constructor TSettingsStore.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  inherited Create();
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
end;

class procedure TSettingsStore.Load(const Obj: TObject; const AFileName: string; const AEnumsAsStrings: Boolean);
var
  Reader: TSettingsReader;
begin
  if  Self = TSettingsStore then
    raise ESettings.Create(SNotImplemented);
  Reader  := TSettingsReader.Create(Self.Create(AFileName, AEnumsAsStrings) as ISettingsStoreReader);
  try
    Reader.Load(Obj);
  finally
    Reader.Free;
  end;
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

constructor TSettingsReader.Create(AReader: ISettingsStoreReader; AWriter: ISettingsStoreWriter);
begin
  inherited Create();
end;

constructor TSettingsReader.Create(AReaderWriter: IInterface);
begin
  Create(AReaderWriter as ISettingsStoreReader, AReaderWriter as ISettingsStoreWriter)
end;

procedure TSettingsReader.Load(const Obj: TObject);
begin

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
