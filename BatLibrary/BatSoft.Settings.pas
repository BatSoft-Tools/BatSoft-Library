unit BatSoft.Settings;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.SysUtils, System.TypInfo, System.RTTI, System.Classes, Generics.Collections,
  BatSoft.Common;

{$region 'Settings attributes'}

type
  /// Indicates that objects in this TStrings property should be saved too.
  SettingsDeep = class(TCustomAttribute);

{$region 'Ignore'}

type
  /// Indicates that BatSoft.Settings should ignore this property.
  SettingsIgnore = class(TCustomAttribute);

function HasSettingsIgnore(const Prop: TRttiProperty): Boolean;

{$endregion}

{$region 'Settings Load/Save Order'}

type
  /// Base class.  Don't use this.  Use SettingsLoadOrder or SettingsSaveOrder.
  SettingsOrderBase = class abstract(TCustomAttribute)
  private
    fOrder: integer;
  public
    constructor Create(const AOrder: integer);
    property  Order : integer read fOrder;
  end;

  /// Used for specifying load order.  Default is 0.
  SettingsLoadOrder = class(SettingsOrderBase);
  /// Used for specifying save order.  Default is 0.
  SettingsSaveOrder = class(SettingsOrderBase);

function GetSettingsOrder(const Prop: TRttiProperty; const Save: Boolean): integer;
function SortAndFilter(const Props: TArray<TRttiProperty>; const Save: Boolean): TArray<TRttiProperty>;

{$endregion}

{$region 'SettingName'}

type
  ///  Store the setting with a different name.
  ///  Don't use 'Class', because that's already used by BatSoft.Settings.
  SettingsName = class(TCustomAttribute)
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
  /// <summary>Used for holding on to a settings store.</summary>
  ISettingsStore<T: class> = interface
    ['{3692006F-AEAC-4A20-A719-30A5FF9F936F}']
    procedure Load(var Obj: T);
    procedure Save(const Obj: T);
  end;

  ISettingsStoreReader = interface;
  ISettingsStoreWriter = interface;

  TSettingsStore<T: class> = class abstract(TInterfacedObject, ISettingsStore<T>)
  protected
    function CreateSettingsStoreReader: ISettingsStoreReader; virtual; abstract;
    function CreateSettingsStoreWriter: ISettingsStoreWriter; virtual; abstract;
  public
    //  ISettings<T: class> interface
    procedure Load(var Obj: T);
    procedure Save(const Obj: T);
  end;

  //  The only class of interest below this point is SettingsTypes
  //  From here onwards is just implementation, and can be ignored by most developers.

  ///  Implement ISettingsStoreReader to load settings from different store types.
  ///  Use TSettingsStore as the base class.
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

  ///  Implement ISettingsStoreWriter to save settings to different store types.
  ///  Use TSettingsStore as the base class.
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

  ///  This contains the smarts for loading.  It uses implementations of ISettingsStoreReader to read from specific stores types.
  TSettingsReader = class
  private
    fStore: ISettingsStoreReader;
    procedure CorrectObjectClass(var Obj: TObject; const PropertyClass: TRttiInstanceType);
    function  GetObjClass: TRttiInstanceType;
    procedure LoadProperties(const Obj: TObject);
    procedure LoadProperty(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadObject(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadObjList(const Obj: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
    procedure LoadListComplex(const Obj: TObject; const ElemType: TRttiType; const RTTIProp: TRttiProperty);
    procedure LoadListSimple(const Obj: TObject; const ElemType: TRttiType; const RTTIProp: TRttiProperty);
    function  LoadString(const Name: string): string;
    procedure LoadStrings(const Obj: TObject; const RTTIProp: TRttiProperty);
    procedure LoadStringsDeep(const Obj: TObject; const RTTIProp: TRttiProperty);
    function  LoadComplexType(const Obj: TObject; const RTTIProp: TRttiProperty): Boolean;
  public
    constructor Create(ASettingsReader: ISettingsStoreReader); overload;
    procedure Load(var Obj: TObject; const ObjClass: TClass);
  end;

  ///  This contains the smarts for saving.  It uses implementations of ISettingsStoreWriter to write to specific stores types.
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

  ///  Register conversion functions here, that convert values between what's in memory and what's in storage.
  ///  This works for both simple types (ex. TDateTime is a float in memory but may be a string in files) and also complex types (such as records).
  ///  For examples, look in BatSoft.Settings.Types unit.
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
  public
    class constructor Create;
    class destructor  Destroy;
    class procedure Register(const PropInfo, StoreInfo: PTypeInfo; const ToProperty, ToStore: TSimpleTypeConverter); overload;
    class procedure Register(const PropInfo: PTypeInfo; const ToStore: TComplexSaver; const ToProperty: TComplexLoader); overload;
    class function  ConvertToProperty(const PropInfo: PTypeInfo; const StoreValue: TValue): TValue;
    class function  ConvertToStore(const PropInfo: PTypeInfo; const PropValue: TValue): TValue;
  end;

  ESettings = class(EBatSoft);

const
  SClass  = 'Class';
  SNil    = 'Null';

resourcestring
  SESettingsNotNil      = 'Settings must not be nil.';
  SENotSettingsList     = 'List is not a settings list.';
  SENotByteArray        = 'Property %s cannot be loaded because it is a dynamic array, but not TArray<Byte>.';
  SEUnsupportedType     = 'Property %s cannot be loaded because it is of type %s.';
  SENotImplements       = 'Does not implement %s.';
  SENotRegisteredClass  = 'Class %s is not registered.';
  SEPropertyIsNil       = 'Property %s is nil';
  SEPropertyIsWrongType = 'Object in property %s is of type %s but %s is expected.';
  SEFailedToEnterElem   = 'Failed to enter list element.';

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
begin
  Result  := Prop.GetAttributes.Has<SettingsIgnore>()
end;

{ SettingsOrderBase }

constructor SettingsOrderBase.Create(const AOrder: integer);
begin
  inherited Create;
  fOrder  := AOrder;
end;

function GetSettingsOrder(const Prop: TRttiProperty; const Save: Boolean): integer;
var
  Attr: SettingsOrderBase;
begin
  Result  := 0;
  if  Save  then
    begin
      if  Prop.GetAttributes.Has<SettingsSaveOrder>(Attr) then
        Result  := Attr.Order
    end
  else
    begin
      if  Prop.GetAttributes.Has<SettingsLoadOrder>(Attr) then
        Result  := Attr.Order
    end;
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

constructor SettingsName.Create(const ASettingName: string);
begin
  inherited Create;
  fStoreName  := ASettingName;
end;

class function SettingsName.StoreNameOf(const Prop: TRttiProperty): string;
var
  Attr: SettingsName;
begin
  if  Prop.GetAttributes.Has<SettingsName>(Attr) then
    Result  := Attr.StoreName
  else
    Result  := Prop.Name;
end;

{ TSettingsStore<T> }

procedure TSettingsStore<T>.Load(var Obj: T);
var
  Reader  : TSettingsReader;
begin
  Reader  := TSettingsReader.Create(CreateSettingsStoreReader);
  try
    Reader.Load(TObject(Obj), T);
  finally
    Reader.Free;
  end;
end;

procedure TSettingsStore<T>.Save(const Obj: T);
var
  Writer  : TSettingsWriter;
begin
  Writer  := TSettingsWriter.Create(CreateSettingsStoreWriter);
  try
    Writer.Save(Obj, T);
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
    raise ESettings.Create(SENotRegisteredClass, [ClassName]);
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

procedure TSettingsReader.LoadListComplex(const Obj: TObject; const ElemType: TRttiType; const RTTIProp: TRttiProperty);
var
  ComplexConverter: SettingsTypes.TComplexConverters;
  Value: TValue;
begin
  if  not SettingsTypes._ComplexTypes.TryGetValue(ElemType.Handle, ComplexConverter) then
    raise ESettings.Create(SENotImplements, [ElemType.Name]);
  fStore.ListBegin(RTTIProp.Name);
  try
    while fStore.ElemNext do
      if  not fStore.ElemEnter  then
        raise ESettings.Create(SEFailedToEnterElem)
      else
        try
          //  Populate element
          Value := ComplexConverter.ToProperty(
            function (const Name: string; const TypeInfo: PTypeInfo): TValue
            begin
              Result  := SettingsTypes.ConvertToProperty(TypeInfo, fStore.LoadValue(Name, TypeInfo))
            end);
          RTTIProp.SetValue(Obj, Value);
        finally
          fStore.ElemLeave;
        end;
  finally
    fStore.ListEnd;
  end;
end;

procedure TSettingsReader.LoadListSimple(const Obj: TObject; const ElemType: TRttiType; const RTTIProp: TRttiProperty);
var
  SimpleConverter: SettingsTypes.TSimpleConverters;
  Value: TValue;
begin
  if  not SettingsTypes._SimpleTypes.TryGetValue(ElemType.Handle, SimpleConverter) then
    raise ESettings.Create(SENotImplements, [ElemType.Name]);
  fStore.ListBegin(RTTIProp.Name);
  try
    while fStore.ElemNext do
      if  not fStore.ElemEnter  then
        raise ESettings.Create(SEFailedToEnterElem)
      else
        try
          //  Determine what to load
          Value := fStore.LoadValue('_', SettingsTypes.StoreTypeInfoOf(ElemType.Handle));
          //  Apply simple converter
          Value := SettingsTypes.ConvertToProperty(RTTIProp.PropertyType.Handle, Value);
          //  Set the value
          RTTIProp.SetValue(Obj, Value);
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
      if  RTTIProp.IsWritable then
        begin
          CorrectObjectClass(Child, RTTIProp.PropertyType.AsInstance);
          RTTIProp.SetValue(Obj, Child);
        end
      else
        if  not Assigned(Child) then
          raise ESettings.Create(SEPropertyIsNil, [RTTIProp.Name])
        else if not (Child is ChildClass) then
          raise ESettings.Create(SEPropertyIsWrongType, [RTTIProp.Name, Child.ClassName, ChildClass.ClassName]);
      LoadProperties(Child);
    finally
      fStore.NodeLeave;
    end;
end;

procedure TSettingsReader.LoadObjList(const Obj: TObject; const ElemClass: TClass; const RTTIProp: TRttiProperty);
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
  ElemRTTI: TRttiType;
begin
  //  Get the correct settings name
  SettName  := SettingsName.StoreNameOf(RTTIProp);
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
        if  RTTIProp.GetAttributes.Has(SettingsDeep) then
          LoadStringsDeep(Obj, RTTIProp)
        //  Read "shallow" TStrings as a single delimited string
        else
          LoadStrings(Obj, RTTIProp)
      //  Load object lists
      else if RegisteredLists.IsRegistered(ChildClass, ElemClass) then
        LoadObjList(RTTIProp.GetValue(Obj).AsObject, ElemClass, RTTIProp)
      //  Load non-object lists
      else if RegisteredLists.IsRegistered(ChildClass, ElemRTTI) then
        if  ElemRTTI.TypeKind = tkRecord  then
          LoadListComplex(RTTIProp.GetValue(Obj).AsObject, ElemRTTI, RTTIProp)
        else
          LoadListSimple(RTTIProp.GetValue(Obj).AsObject, ElemRTTI, RTTIProp)
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
    raise ESettings.Create(SEPropertyIsNil, [RTTIProp.Name]);
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
  SettName  := SettingsName.StoreNameOf(RTTIProp);
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
        if  RTTIProp.GetAttributes.Has(SettingsDeep)  then
          SaveStringsDeep(Child, Child, RTTIProp)
        //  Write "shallow" TStrings as a single delimited string
        else
          SaveStrings(SettName, Child)
      //  Save settings list elements as objects
      else if RegisteredLists.IsRegistered(Child.ClassType, ElemClass) then
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

initialization
  RTTI  := TRttiContext.Create;
  ReadComparer  := TSettingsOrderComparer.Create(False);
  WriteComparer := TSettingsOrderComparer.Create(True);

finalization
  RTTI.Free;

end.
