unit BatSoft.Settings;

interface

uses
  System.SysUtils, System.TypInfo, System.RTTI, System.Classes, Generics.Collections;

{$region 'Settings attributes'}
type

  SettingsDeepField = class(TCustomAttribute);

{$region 'Ignore'}

type
  SettingsIgnore = class(TCustomAttribute);

function HasSettingsIgnore(const Prop: TRttiProperty): Boolean;

{$endregion}

{$region 'Settings Load/Save Order'}

type
  SettingsOrderBase = class abstract(TCustomAttribute)
  private
    fOrder: integer;
  public
    constructor Create(const AOrder: integer);
    property  Order : integer read fOrder;
  end;

  SettingsLoadOrder = class(SettingsOrderBase);
  SettingsSaveOrder = class(SettingsOrderBase);

function GetSettingsOrder(const Prop: TRttiProperty; const Save: Boolean): integer;
function SortAndFilter(const Props: TArray<TRttiProperty>; const Save: Boolean): TArray<TRttiProperty>;

{$endregion}

{$region 'SettingName'}

type
  SettingsStoreName = class(TCustomAttribute)
  private
    fStoreName: string;
  public
    constructor Create(const ASettingName: string);
    property  StoreName: string read fStoreName;
    class function StoreNameOf(const Prop: TRttiProperty): string;
  end;

{$endregion}

{$endregion}
type
  ISettingsStoreReader = interface
    ['{42508E64-EC8C-44C9-A2F6-9C666BE84230}']
    //  Storage
    procedure LoadBegin;
    procedure LoadEnd;
    //  Navigate objects and complex values
    procedure NodeChildren(const Names: TStrings);
    function  NodeEnter(const Name: string): Boolean;
    procedure NodeLeave;
    //  Navigate arrays
    function  ListBegin(const Name: string): Boolean;
    procedure ListEnd;
    //  Navigate array elements
    function  ElemEnter: Boolean;
    procedure ElemLeave;
    function  ElemNext: Boolean;
    //  Simple values
    function  LoadValue(const Name: string; const TypeInfo: PTypeInfo): TValue;
  end;

  ISettingsStoreWriter = interface
    ['{DE922225-D7A5-40DF-BAB4-CE84F522328D}']
    //  Storage
    procedure SaveBegin;
    procedure SaveEnd;
    //  Navigate objects and complex values
    procedure NodeClear(const Name: string);
    procedure NodeEnter(const Name: string; const IsNil: Boolean);
    procedure NodeLeave;
    //  Navigate arrays
    procedure ListClear(const Name: string);
    procedure ListBegin(const Name: string; const IsNil: Boolean);
    procedure ListEnd;
    //  Navigate array elements
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
    procedure LoadProperty(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadObject(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadList(const Obj: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
    function  LoadString(const Name: string): string;
    procedure LoadStrings(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadStringsDeep(const Obj: TObject; const RTTIProp: TRttiProperty);
    function  LoadComplexType(const Obj: TObject; const RTTIProp: TRttiProperty): Boolean;
  public
    constructor Create(ASettingsReader: ISettingsStoreReader); overload;
    procedure Load(var Obj: TObject; const ObjClass: TClass);
  end;

  TSettingsWriter = class
  private
    fStore: ISettingsStoreWriter;
    procedure SaveProperties(const Obj: TObject; const PropClass: TClass);
    procedure SaveProperty(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure SaveObject(const Obj, Child: TObject; const RTTIProp: TRttiProperty);
    procedure SaveList(const Child: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
    procedure SaveStrings(const Name: string; const Obj: TObject);
    procedure SaveStringsDeep(const Obj, Child: TObject; const RTTIProp: TRttiProperty);
    function  SaveComplexType(const Obj: TObject; const RTTIProp: TRttiProperty): Boolean;
  public
    constructor Create(const ASettingsWriter: ISettingsStoreWriter);
    procedure Save(const Obj: TObject; ObjClass: TClass = nil);
  end;

  TSimpleTypeConverter = reference to function(const Value: TValue; const Info: PTypeInfo): TValue;

  TSimpleLoader   = reference to function (const Name: string; const TypeInfo: PTypeInfo): TValue;
  TSimpleSaver    = reference to procedure (const Name: string; const Value: TValue);

  TComplexLoader  = reference to function (const LoadValue: TSimpleLoader): TValue;
  TComplexSaver   = reference to procedure (const Value: TValue; const SaveValue: TSimpleSaver);

  SettingsTypes = class
  private type
    TSimpleConverters = record
      StoreInfo: PTypeInfo;
      ToStore, ToProperty: TSimpleTypeConverter;
    end;
    TComplexConverters = record
      PropInfo: PTypeInfo;
      ToStore: TComplexSaver;
      ToProperty: TComplexLoader;
    end;
  private
    class var _SimpleTypes: TDictionary<PTypeInfo, TSimpleConverters>;
    class var _ComplexTypes: TDictionary<PTypeInfo, TComplexConverters>;
    class function  StoreTypeInfoOf(const PropInfo: PTypeInfo): PTypeInfo;
    class function  ConvertToProperty(const PropInfo: PTypeInfo; const StoreValue: TValue): TValue;
    class function  ConvertToStore(const PropInfo: PTypeInfo; const PropValue: TValue): TValue;
  public
    class constructor Create;
    class destructor  Destroy;
    class procedure Register(const PropInfo, StoreInfo: PTypeInfo; const ToProperty, ToStore: TSimpleTypeConverter); overload;
    class procedure Register(const PropInfo: PTypeInfo; const ToStore: TComplexSaver; const ToProperty: TComplexLoader); overload;
  end;

  SettingsLists = class
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
function  StrToEnum(const Value: string; const Info: PTypeInfo): TValue;

function  EnumToOrd(const Value: TValue): integer;
function  OrdToEnum(const Value: Int64; const Info: PTypeInfo): TValue;

function  EnumSetToStr(const Value: TValue): string;
function  StrToEnumSet(const Value: string; const Info: PTypeInfo): TValue;

function  EnumSetToOrd(const Value: TValue): Int64;
function  OrdToEnumSet(const Value: Int64; const Info: PTypeInfo): TValue;

const
  SClass  = 'Class';
  SNil    = 'Null';

resourcestring
  SESettingsNotNil    = 'Settings must not be nil.';
  SENotSettingsList   = 'List is not a settings list.';
  SENotByteArray      = 'Property %s cannot be loaded because it is a dynamic array, but not TArray<Byte>.';
  SEUnsupportedType   = 'Property %s cannot be loaded because it is of type %s.';
  SNotImplements      = 'Does not implement %s.';
  SNotRegisteredClass = 'Class %s is not registered.';
  SPropertyIsNil      = 'Property %s is nil';
  SPropertyIsWrongType= 'Object in property %s is of type %s but %s is expected.';

implementation

uses
  System.Generics.Defaults, BatSoft.Classes;

var
  RTTI: TRttiContext;

const
  SupportedTypes = [tkInteger, tkInt64, tkFloat, tkEnumeration, tkSet, tkRecord,
        tkChar, tkWChar, tkString, tkLString, tkWString, tkUString, tkVariant];

type
  TSettingsOrderComparer = class(TInterfacedObject, IComparer<TRttiProperty>)
  private
    fSaveOrder: Boolean;
  public
    constructor Create(const ASaveOrder: Boolean);
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
  Result  := GetSettingsOrder(Left, fSaveOrder) - GetSettingsOrder(Right, fSaveOrder)
end;

constructor TSettingsOrderComparer.Create(const ASaveOrder: Boolean);
begin
  inherited Create;
  fSaveOrder  := ASaveOrder;
end;

{ SettingsIgnore }

function HasSettingsIgnore(const Prop: TRttiProperty): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := FindAttribute(Prop, SettingsIgnore, Attr)
end;

//{ SettingsOrder }
//
//constructor SettingsOrder.Create(const AReadOrder, AWriteOrder: integer);
//begin
//  inherited Create;
//  fReadOrder  := AReadOrder;
//  fWriteOrder := AWriteOrder;
//end;
//
//function GetSettingsOrder(const Prop: TRttiProperty; const Write: Boolean): integer;
//var
//  Attr: TCustomAttribute;
//begin
//  if  not FindAttribute(Prop, SettingsOrder, Attr) then
//    Result  := 0
//  else if Write then
//    Result  := SettingsOrder(Attr).WriteOrder
//  else
//    Result  := SettingsOrder(Attr).ReadOrder;
//end;

//function SortAndFilter(const Props: TArray<TRttiProperty>; const Write: Boolean): TArray<TRttiProperty>;
//var
//  List: TList<TRttiProperty>;
//  Prop: TRttiProperty;
//begin
//  List  := TList<TRttiProperty>.Create;
//  try
//    //  Sort properties
//    for Prop in Props do
//      if  Prop.Visibility = TMemberVisibility.mvPublished then
//        if  not HasSettingsIgnore(Prop)  then
//          List.Add(Prop);
//    if  Write then
//      List.Sort(WriteComparer)
//    else
//      List.Sort(ReadComparer);
//    //  Done
//    Result  := List.ToArray;
//  finally
//    List.Free;
//  end;
//end;
//
{ SettingsOrderBase }

constructor SettingsOrderBase.Create(const AOrder: integer);
begin
  inherited Create;
  fOrder  := AOrder;
end;

function GetSettingsOrder(const Prop: TRttiProperty; const Save: Boolean): integer;
var
  Attr: TCustomAttribute;
begin
  if  not FindAttribute(Prop, SettingsOrderBase, Attr) then
    Result  := 0
  else if Save  then
    Result  := SettingsSaveOrder(Attr).Order
  else
    Result  := SettingsLoadOrder(Attr).Order;
end;

function SortAndFilter(const Props: TArray<TRttiProperty>; const Save: Boolean): TArray<TRttiProperty>;
var
  List: TList<TRttiProperty>;
  Prop: TRttiProperty;
begin
  List  := TList<TRttiProperty>.Create;
  try
    //  Sort properties
    for Prop in Props do
      if  Prop.Visibility = TMemberVisibility.mvPublished then
        if  not HasSettingsIgnore(Prop)  then
          List.Add(Prop);
    if  Save  then
      List.Sort(WriteComparer)
    else
      List.Sort(ReadComparer);
    //  Done
    Result  := List.ToArray;
  finally
    List.Free;
  end;
end;

{ SettingsStoreName }

constructor SettingsStoreName.Create(const ASettingName: string);
begin
  inherited Create;
  fStoreName  := ASettingName;
end;

class function SettingsStoreName.StoreNameOf(const Prop: TRttiProperty): string;
var
  Attr: TCustomAttribute;
begin
  if  FindAttribute(Prop, SettingsStoreName, Attr) then
    Result  := SettingsStoreName(Attr).StoreName
  else
    Result  := Prop.Name;
end;

//  Enumeration strings

function EnumToStr(const Value: TValue): string;
begin
  Result  := GetEnumName(Value.TypeInfo, EnumToOrd(Value))
end;

function  StrToEnum(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := GetEnumValue(Info, Value);
  Result  := TValue.FromOrdinal(Info, Val)
end;

function  EnumToOrd(const Value: TValue): integer;
begin
  Result  := 0;
  Value.ExtractRawDataNoCopy(@Result);
end;

function  OrdToEnum(const Value: Int64; const Info: PTypeInfo): TValue;
begin
  TValue.Make(Value, Info, Result)
end;

function EnumSetToStr(const Value: TValue): string;
begin
  Result  := SetToString(Value.TypeInfo, EnumSetToOrd(Value))
end;

function  StrToEnumSet(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := StringToSet(Info, Value);
  TValue.Make(@Val, Info, Result);
end;

function  EnumSetToOrd(const Value: TValue): Int64;
begin
  Result  := 0;
  Value.ExtractRawDataNoCopy(@Result);
end;

function  OrdToEnumSet(const Value: Int64; const Info: PTypeInfo): TValue;
begin
  TValue.Make(Value, Info, Result)
end;

{ TSettingsStoreBase }

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
  if  not Supports(Self, ISettingsStoreReader)  then
    raise ESettings.Create(SNotImplements, ['ISettingsStoreReader']);
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
  if  not Supports(Self, ISettingsStoreWriter)  then
    raise ESettings.Create(SNotImplements, ['ISettingsStoreWriter']);
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

function TSettingsReader.LoadComplexType(const Obj: TObject; const RTTIProp: TRttiProperty): Boolean;
var
  ComplexConverter: SettingsTypes.TComplexConverters;
  Value: TValue;
begin
  Result  := SettingsTypes._ComplexTypes.TryGetValue(RTTIProp.PropertyType.Handle, ComplexConverter);
  if  Result  then
    begin
      fStore.NodeEnter(RTTIProp.Name);
      try
        Value := ComplexConverter.ToProperty(
          function (const Name: string; const TypeInfo: PTypeInfo): TValue
          begin
            Result  := SettingsTypes.ConvertToProperty(TypeInfo, fStore.LoadValue(Name, TypeInfo))
          end);
        RTTIProp.SetValue(Obj, Value);
      finally
        fStore.NodeLeave;
      end;
    end;
end;

procedure TSettingsReader.LoadList(const Obj: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
var
  RTTIElemClass: TRttiInstanceType;
  List: TObjectList<TObject> absolute Obj;
  Elem: TObject;
begin
  fStore.ListBegin(RTTIProp.Name);
  try
    RTTIElemClass := RTTI.GetType(ElemClass).AsInstance;
    while fStore.ElemNext do
      if  not fStore.ElemEnter  then
        List.Add(nil)
      else
        try
          Elem  := nil;
          CorrectObjectClass(Elem, RTTIElemClass);
          List.Add(Elem);
          LoadProperties(Elem);
        finally
          fStore.ElemLeave;
        end;
  finally
    fStore.ListEnd;
  end;
end;

procedure TSettingsReader.LoadObject(const Obj: TObject; const RTTIProp: TRttiProperty);
var
  ChildClass: TClass;
  Child: TObject;
begin
  if  RTTIProp.IsReadable then
    try
      ChildClass  := RTTIProp.PropertyType.AsInstance.MetaclassType;
      Child       := RTTIProp.GetValue(Obj).AsObject;
      if  not RTTIProp.IsWritable then
        if  not Assigned(Child) then
          raise ESettings.Create(SPropertyIsNil, [RTTIProp.Name])
        else if not (Child is ChildClass) then
          raise ESettings.Create(SPropertyIsWrongType, [RTTIProp.Name, Child.ClassName, ChildClass.ClassName]);
      CorrectObjectClass(Child, RTTIProp.PropertyType.AsInstance);
      RTTIProp.SetValue(Obj, Child);
      LoadProperties(Child);
    finally
      fStore.NodeLeave;
    end;
end;

procedure TSettingsReader.LoadProperties(const Obj: TObject);
var
  RTTIType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
begin
  if  not Assigned(Obj) then
    Exit;
  RTTIType  := RTTI.GetType(Obj.ClassType);
  RTTIProps := RTTIType.GetProperties;
  RTTIProps := SortAndFilter(RTTIProps, False);
  for RTTIProp in RTTIProps do
    LoadProperty(Obj, RTTIProp)
end;

procedure TSettingsReader.LoadProperty(const Obj: TObject; const RTTIProp: TRttiProperty);
var
  Kind: TTypeKind;
  SettName, ClassName: string;
  ChildClass: TClass;
  ElemClass: TClass;
  Value: TValue;
begin
  //  Get the correct settings name
  SettName  := SettingsStoreName.StoreNameOf(RTTIProp);
  //  Manage complex types separately
  if  LoadComplexType(Obj, RTTIProp)  then
    Exit;
  //  Examine type kind
  Kind  := RTTIProp.PropertyType.TypeKind;
  //  Load simple type
  if Kind in SupportedTypes then
    begin
      if  not RTTIProp.IsWritable then
        Exit;
      //  Determine what to load
      Value := fStore.LoadValue(SettName, SettingsTypes.StoreTypeInfoOf(RTTIProp.PropertyType.Handle));
      //  Apply simple converter
      Value := SettingsTypes.ConvertToProperty(RTTIProp.PropertyType.Handle, Value);
      //  Set the value
      RTTIProp.SetValue(Obj, Value);
    end
  //  Load TClass
  else if Kind = tkClassRef then
    begin
      ClassName := LoadString(SettName);
      if  ClassName.IsEmpty then
        RTTIProp.SetValue(Obj, nil)
      else
        RTTIProp.SetValue(Obj, RTTI.FindType(ClassName).AsInstance.MetaclassType)
    end
  //  Save sub-object
  else if Kind = tkClass then
    begin
      ChildClass  := RTTIProp.PropertyType.AsInstance.MetaclassType;
      //  TStrings are special
      if  ChildClass.InheritsFrom(TStrings) then
        //  Read "deep" TStrings elements as separate named children
        if  TCustomAttribute.HasAttribute(RTTIProp.GetAttributes, SettingsDeepField)  then
          LoadStringsDeep(Obj, RTTIProp)
        //  Read "shallow" TStrings as a single delimited string
        else
          LoadStrings(Obj, RTTIProp)
      //  Load settings list elements as objects
      else if SettingsLists.IsRegistered(ChildClass, ElemClass) then
        LoadList(RTTIProp.GetValue(Obj).AsObject, ElemClass, RTTIProp)
      //  Child object
      else if fStore.NodeEnter(SettName)  then
        LoadObject(Obj, RTTIProp)
    end
  //  - Unhandled
  else
    raise ESettings.Create(SEUnsupportedType, [SettName, EnumToStr(TValue.From(Kind))]);
end;

function TSettingsReader.LoadString(const Name: string): string;
begin
  Result  := fStore.LoadValue(Name, TypeInfo(string)).AsString
end;

procedure TSettingsReader.LoadStrings(const Obj: TObject; const RTTIProp: TRttiProperty);
var
  Child: TObject;
begin
  Child := RTTIProp.GetValue(Obj).AsObject;
  if  not Assigned(Child) then
    raise ESettings.Create(SPropertyIsNil, [RTTIProp.Name]);
  (Child as TStrings).DelimitedText := LoadString(RTTIProp.Name)
end;

procedure TSettingsReader.LoadStringsDeep(const Obj: TObject; const RTTIProp: TRttiProperty);
var
  Strs: TStrings;
  ElemNames: TStringList;
  ElemName: string;
  Elem: TObject;
  i: integer;
begin
  Strs  := RTTIProp.GetValue(Obj).AsObject as TStrings;

  if  fStore.NodeEnter(RTTIProp.Name) then
    try
      //  Correct strings type
      if  not Assigned(Strs) and RTTIProp.IsWritable  then
        begin
          CorrectObjectClass(TObject(Strs), RTTIProp.PropertyType.AsInstance);
          RTTIProp.SetValue(Obj, Strs);
        end;
      //
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
        //  Tidy up
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

function TSettingsWriter.SaveComplexType(const Obj: TObject; const RTTIProp: TRttiProperty): Boolean;
var
  ComplexConverter: SettingsTypes.TComplexConverters;
  Child: TValue;
begin
  Result  := SettingsTypes._ComplexTypes.TryGetValue(RTTIProp.PropertyType.Handle, ComplexConverter);
  if  Result  then
    begin
      Child := RTTIProp.GetValue(Obj);
      fStore.NodeEnter(RTTIProp.Name, False);
      try
        ComplexConverter.ToStore(Child,
          procedure (const Name: string; const Value: TValue)
          begin
            fStore.SaveValue(Name, SettingsTypes.ConvertToStore(Value.TypeInfo, Value))
          end);
      finally
        fStore.NodeLeave;
      end;
    end;
end;

procedure TSettingsWriter.SaveList(const Child: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
var
  List: TObjectList<TObject> absolute Child;
  i: integer;
begin
  fStore.ListClear(RTTIProp.Name);
  fStore.ListBegin(RTTIProp.Name, not Assigned(Child));
  try
    for i := 0 to List.Count - 1 do
      begin
        fStore.ElemEnter(i, not Assigned(List[i]));
        try
          SaveProperties(List[i], ElemClass)
        finally
          fStore.ElemLeave;
        end;
      end;
  finally
    fStore.ListEnd;
  end;
end;

procedure TSettingsWriter.SaveObject(const Obj, Child: TObject; const RTTIProp: TRttiProperty);
begin
  fStore.NodeEnter(RTTIProp.Name, not Assigned(Child));
  try
    SaveProperties(Child, RTTIProp.PropertyType.AsInstance.MetaclassType);
  finally
    fStore.NodeLeave;
  end;
end;

procedure TSettingsWriter.SaveProperties(const Obj: TObject; const PropClass: TClass);
var
  RTTIType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
begin
  if  not Assigned(Obj) then
    Exit;
  RTTIType  := RTTI.GetType(Obj.ClassType);
  if  RTTIType.AsInstance.MetaclassType <> PropClass  then
    fStore.SaveValue(SClass, Obj.QualifiedClassName);
  RTTIProps := RTTIType.GetProperties;
  RTTIProps := SortAndFilter(RTTIProps, True);
  for RTTIProp in RTTIProps do
    SaveProperty(Obj, RTTIProp)
end;

procedure TSettingsWriter.SaveProperty(const Obj: TObject; const RTTIProp: TRttiProperty);
var
  Kind: TTypeKind;
  SettName: string;
  Child: TObject;
  ElemClass: TClass;
  Value: TValue;
begin
  if  not RTTIProp.IsReadable then
    Exit;
  //  Get the correct settings name
  SettName  := SettingsStoreName.StoreNameOf(RTTIProp);
  //  Manage complex types separately
  if  SaveComplexType(Obj, RTTIProp)  then
    Exit;
  //  Determine what to save
  Value := RTTIProp.GetValue(Obj);
  //  Apply simple converter
  Value := SettingsTypes.ConvertToStore(RTTIProp.PropertyType.Handle, Value);
  //  Examine type kind
  Kind  := Value.Kind;
  //  Save simple type
  if Kind in SupportedTypes then
    fStore.SaveValue(SettName, Value)
  //  Save TClass
  else if Kind = tkClassRef then
    fStore.SaveValue(SettName, Value.AsClass.QualifiedClassName)
  //  Save sub-object
  else if Kind = tkClass then
    begin
      Child := RTTIProp.GetValue(Obj).AsObject;
      //  Handle nil objects
      if  not Assigned(Child) then
        begin
          fStore.NodeEnter(SettName, not Assigned(Child));
          fStore.NodeLeave;
        end
      //  TStrings are special
      else if  Child is TStrings then
        //  Write "deep" TStrings elements as separate named children
        if  TCustomAttribute.HasAttribute(RTTIProp.GetAttributes, SettingsDeepField)  then
          SaveStringsDeep(Child, Child, RTTIProp)
        //  Write "shallow" TStrings as a single delimited string
        else
          SaveStrings(SettName, Child)
      //  Save settings list elements as objects
      else if SettingsLists.IsRegistered(Child.ClassType, ElemClass) then
        SaveList(Child, ElemClass, RTTIProp)
      //  Child object
      else
        SaveObject(Obj, Child, RTTIProp)
    end
  //  - Unhandled
  else
    raise ESettings.Create(SEUnsupportedType, [SettName, EnumToStr(TValue.From(Kind))]);
end;

procedure TSettingsWriter.SaveStrings(const Name: string; const Obj: TObject);
var
  Strs: TStrings absolute Obj;
begin
  fStore.SaveValue(Name, Strs.DelimitedText);
end;

procedure TSettingsWriter.SaveStringsDeep(const Obj, Child: TObject; const RTTIProp: TRttiProperty);
var
  Strs: TStrings absolute Obj;
  i: integer;
begin
  fStore.NodeClear(RTTIProp.Name);
  fStore.NodeEnter(RTTIProp.Name, not Assigned(Child));
  try
    for i := 0 to Strs.Count - 1 do
      begin
        fStore.NodeEnter(Strs[i], not Assigned(Strs.Objects[i]));
        try
          SaveProperties(Strs.Objects[i], TObject);
        finally
          fStore.NodeLeave;
        end;
      end;
  finally
    fStore.NodeLeave;
  end;
end;

{ SettingsTypes }

class function SettingsTypes.ConvertToProperty(const PropInfo: PTypeInfo; const StoreValue: TValue): TValue;
var
  Converters: TSimpleConverters;
begin
  if  _SimpleTypes.TryGetValue(PropInfo, Converters)  then
    Result  := Converters.ToProperty(StoreValue, PropInfo)
  else
    Result  := StoreValue;
end;

class function SettingsTypes.ConvertToStore(const PropInfo: PTypeInfo; const PropValue: TValue): TValue;
var
  Converters: TSimpleConverters;
begin
  if  _SimpleTypes.TryGetValue(PropInfo, Converters)  then
    Result  := Converters.ToStore(PropValue, PropInfo)
  else
    Result  := PropValue;
end;

class constructor SettingsTypes.Create;
begin
  _SimpleTypes  := TDictionary<PTypeInfo, TSimpleConverters>.Create;
  _ComplexTypes := TDictionary<PTypeInfo, TComplexConverters>.Create;
end;

class destructor SettingsTypes.Destroy;
begin
  _SimpleTypes.Free;
  _ComplexTypes.Free;
end;

class procedure SettingsTypes.Register(const PropInfo: PTypeInfo; const ToStore: TComplexSaver; const ToProperty: TComplexLoader);
var
  ValueConverters: TComplexConverters;
begin
  ValueConverters.PropInfo    := PropInfo;
  ValueConverters.ToStore     := ToStore;
  ValueConverters.ToProperty  := ToProperty;
  _ComplexTypes.AddOrSetValue(PropInfo, ValueConverters);
end;

class procedure SettingsTypes.Register(const PropInfo, StoreInfo: PTypeInfo; const ToProperty, ToStore: TSimpleTypeConverter);
var
  ValueConverters: TSimpleConverters;
begin
  ValueConverters.StoreInfo   := StoreInfo;
  ValueConverters.ToStore     := ToStore;
  ValueConverters.ToProperty  := ToProperty;
  _SimpleTypes.AddOrSetValue(PropInfo, ValueConverters);
end;

class function SettingsTypes.StoreTypeInfoOf(const PropInfo: PTypeInfo): PTypeInfo;
var
  Converters: TSimpleConverters;
begin
  if  _SimpleTypes.TryGetValue(PropInfo, Converters)  then
    Result  := Converters.StoreInfo
  else
    Result  := PropInfo
end;

{ ObjectLists }

class constructor SettingsLists.Create;
begin
  _Types  := TDictionary<TClass, TClass>.Create;
end;

class destructor SettingsLists.Destroy;
begin
  _Types.Free;
end;

class function SettingsLists.IsRegistered(const ListClass: TClass; out ElemClass: TClass): Boolean;
begin
  Result  := _Types.TryGetValue(ListClass, ElemClass)
end;

class procedure SettingsLists.Register(const ListClass, ElemClass: TClass);
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
