unit BatSoft.Settings;

interface

uses
  System.SysUtils, System.RTTI, Generics.Collections;

type
  ISettingsReader = interface
    ['{11B3303D-3467-43B2-89B9-5CD4A3E24487}']
  end;

  ISettingsWriter = interface
    ['{4923075C-0B58-4363-83B7-E3D53DF41CEE}']
  end;

  ISettingsStore = interface
    ['{70D9554A-76DC-4F16-BAC3-ABBAA937B42C}']
    procedure LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
    procedure SaveFile(const Settings: TObject; const FileName: string);
  end;

{$region 'Settings attributes'}

{$region 'Ignore'}

type
  SettingIgnoreAttribute = class(TCustomAttribute);

function HasSettingIgnore(const Prop: TRttiProperty): Boolean;

{$endregion}

{$region 'Preferred constructor'}

type
  PreferredConstructorAttribute = class(TCustomAttribute);

{$endregion}

{$region 'Don''t clear'}

type
  SettingClearAttribute = class(TCustomAttribute)
  private
    fClear: Boolean;
  public
    constructor Create(const AClear: Boolean);
    property  Clear: Boolean  read fClear;
    class function ShouldClear(const Prop: TRttiProperty; const Default: Boolean): Boolean;
  end;

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

{$region 'TSettingsList<>'}

type
  TSettingsList<T: class> = class
  private
    fItems: TObjectList<TObject>;
    function GetCount: Integer;
    function GetItem(Index: Integer): T;
    function GetItems: TObjectList<TObject>;
    function GetOwnsObjects: Boolean;
    procedure SetItem(Index: Integer; const Value: T);
    procedure SetOwnsObjects(const Value: Boolean);
  public
    class constructor Create;
    constructor Create(AOwnsObjects: Boolean = True); overload;
    destructor  Destroy; override;
    property  OwnsObjects: Boolean read GetOwnsObjects write SetOwnsObjects;
    function  Add(const Value: T): Integer; inline;
    procedure Insert(Index: Integer; const Value: T); inline;
    function  Remove(const Value: T): Integer; inline;
    procedure Delete(Index: Integer); inline;
    procedure Clear; inline;
    property  Count: Integer read GetCount;
    property  Items[Index: Integer]: T read GetItem write SetItem; default;
    function  ItemType: TClass;

    type
      TEnumerator = class(TEnumerator<T>)
      private
        FList: TSettingsList<T>;
        FIndex: Integer;
        function GetCurrent: T;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const AList: TSettingsList<T>);
        property Current: T read GetCurrent;
        function MoveNext: Boolean;
      end;

    function GetEnumerator: TEnumerator; reintroduce; inline;
  end;

  ESettings = class(Exception)
  public
    constructor Create(const AMessage: string; const Args: array of const); overload;
  end;

{$region 'Internal TSettingsList<> registrations'}
//  Note: Although this is declared in the interface section, it should be
//  considered to be internal.
type
  TGetObjectList = reference to function(const SettingsList: TObject): TObjectList<TObject>;

  RegisteredSettingsLists = class
  private type

    TClassInfo = record
      ElemType: TClass;
      GetObjectList: TGetObjectList;
    end;

  private
    class var fDictionary: TDictionary<TClass, TClassInfo>;
    class procedure Register(const ListType, ElemType: TClass; const GetObjectList: TGetObjectList);
    class function  FindClassInfo(ListType: TClass; out ClassInfo: TClassInfo): Boolean;
  public
    class constructor Create;
    class destructor  Destroy;
    //  Tools
    class function  IsSettingsList(ClassType: TClass): Boolean;
    class function  Find(const SettingsList: TObject; out ObjectList: TObjectList<TObject>; out ElemType: TClass): Boolean;
    //  General information
    class procedure List(const ListTypes, ElemTypes: TList<TClass>);
  end;

{$endregion}

{$endregion}

function FullFileName(const Obj: TObject): string;

implementation

uses
  TypInfo, Generics.Defaults;

function FullFileName(const Obj: TObject): string;
begin
  Result  := ParamStr(0);
  Result  := ExtractFileName(Result);
//  Result  := TPath.ChangeExtension(Result, '');
  Result  := Copy(Result, 0, Length(Result) - 1);
//  Result  := TPath.Combine(TPath.GetDocumentsPath, Result);
//  Result  := TPath.Combine(Result, Copy(Obj.ClassName, 2, MaxInt)) + '.json'
end;

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

{ IgnoreSettingAttribute }

function HasSettingIgnore(const Prop: TRttiProperty): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := FindAttribute(Prop, SettingIgnoreAttribute, Attr)
end;

{ SettingClearAttribute }

constructor SettingClearAttribute.Create(const AClear: Boolean);
begin
  inherited Create;
  fClear  := AClear;
end;

class function SettingClearAttribute.ShouldClear(const Prop: TRttiProperty; const Default: Boolean): Boolean;
var
  Attr: TCustomAttribute;
begin
  if  FindAttribute(Prop, SettingClearAttribute, Attr)  then
    Result  := SettingClearAttribute(Attr).Clear
  else
    Result  := Default
end;

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

{ SettingsOrderAttribute }

constructor SettingsOrderAttribute.Create(const AReadOrder, AWriteOrder: integer);
begin
  inherited Create;
  fReadOrder  := AReadOrder;
  fWriteOrder := AWriteOrder;
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

{ TSettingsList<T> }

function TSettingsList<T>.Add(const Value: T): Integer;
begin
  Result  := GetItems.Add(Value)
end;

procedure TSettingsList<T>.Clear;
begin
  GetItems.Clear
end;

class constructor TSettingsList<T>.Create;
var
  ElemType: TClass;
  ObjectList: TSettingsList<T>;
  GetObjectList : TGetObjectList;
begin
  //  Determine data type of items
  ObjectList  := TSettingsList<T>(NewInstance);
  try
    ElemType  := ObjectList.ItemType;
  finally
    ObjectList.Free;
  end;
  //  Generate code obtaining list of items
  GetObjectList :=
    function(const SettingsList: TObject): TObjectList<TObject>
    begin
      Result  := TSettingsList<T>(SettingsList).GetItems;
    end;
  //  Register the generic
  RegisteredSettingsLists.Register(TSettingsList<T>, ElemType, GetObjectList);
end;

constructor TSettingsList<T>.Create(AOwnsObjects: Boolean);
begin
  inherited Create;
  GetItems.OwnsObjects  := AOwnsObjects;
end;

procedure TSettingsList<T>.Delete(Index: Integer);
begin
  GetItems.Delete(Index);
end;

destructor TSettingsList<T>.Destroy;
begin
  fItems.Free;
  inherited;
end;

function TSettingsList<T>.GetCount: Integer;
begin
  Result  := GetItems.Count
end;

function TSettingsList<T>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TSettingsList<T>.GetItem(Index: Integer): T;
begin
  Result  := T(GetItems[Index])
end;

function TSettingsList<T>.GetItems: TObjectList<TObject>;
begin
  if  not Assigned(fItems)  then
    fItems  := TObjectList<TObject>.Create();
  Result  := fItems;
end;

function TSettingsList<T>.GetOwnsObjects: Boolean;
begin
  Result  := GetItems.OwnsObjects
end;

procedure TSettingsList<T>.Insert(Index: Integer; const Value: T);
begin
  GetItems.Insert(Index, Value);
end;

function TSettingsList<T>.ItemType: TClass;
begin
  Result  := T
end;

function TSettingsList<T>.Remove(const Value: T): Integer;
begin
  Result  := GetItems.Remove(Value)
end;

procedure TSettingsList<T>.SetItem(Index: Integer; const Value: T);
begin
  GetItems[Index] := Value;
end;

procedure TSettingsList<T>.SetOwnsObjects(const Value: Boolean);
begin
  GetItems.OwnsObjects  := Value
end;

{ TSettingsList<T>.TEnumerator }

constructor TSettingsList<T>.TEnumerator.Create(const AList: TSettingsList<T>);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TSettingsList<T>.TEnumerator.DoGetCurrent: T;
begin
  Result := GetCurrent;
end;

function TSettingsList<T>.TEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TSettingsList<T>.TEnumerator.GetCurrent: T;
begin
  Result := FList[FIndex];
end;

function TSettingsList<T>.TEnumerator.MoveNext: Boolean;
begin
  if FIndex >= FList.Count then
    Exit(False);
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

{ ESettings }

constructor ESettings.Create(const AMessage: string; const Args: array of const);
begin
  inherited Create(Format(AMessage, Args));
end;

{ RegisteredSettingsLists }

class constructor RegisteredSettingsLists.Create;
begin
  fDictionary := TDictionary<TClass, TClassInfo>.Create();
end;

class destructor RegisteredSettingsLists.Destroy;
begin
  fDictionary.Free;
end;

class function RegisteredSettingsLists.Find(const SettingsList: TObject;
  out ObjectList: TObjectList<TObject>; out ElemType: TClass): Boolean;
var
  ClassInfo: TClassInfo;
begin
  Result  := FindClassInfo(SettingsList.ClassType, ClassInfo);
  if  Result  then
    begin
      ElemType    := ClassInfo.ElemType;
      ObjectList  := ClassInfo.GetObjectList(SettingsList);
    end;
end;

class function RegisteredSettingsLists.FindClassInfo(ListType: TClass; out ClassInfo: TClassInfo): Boolean;
begin
  Result  := False;
  while Assigned(ListType) and not Result do
    begin
      Result    := fDictionary.TryGetValue(ListType, ClassInfo);
      ListType  := ListType.ClassParent;
    end;
end;

class function RegisteredSettingsLists.IsSettingsList(ClassType: TClass): Boolean;
begin
  Result    := False;
  while Assigned(ClassType) and not Result do
    begin
      Result    := fDictionary.ContainsKey(ClassType);
      ClassType := ClassType.ClassParent;
    end;
end;

class procedure RegisteredSettingsLists.List(const ListTypes, ElemTypes: TList<TClass>);
var
  Pair: TPair<TClass, TClassInfo>;
begin
  ListTypes.Clear;
  ElemTypes.Clear;
  for Pair in fDictionary do
    begin
      ListTypes.Add(Pair.Key);
      ElemTypes.Add(Pair.Value.ElemType);
    end;
end;

class procedure RegisteredSettingsLists.Register(const ListType, ElemType: TClass;
  const GetObjectList: TGetObjectList);
var
  ClassInfo: TClassInfo;
begin
  if  not fDictionary.ContainsKey(ListType) then
    begin
      ClassInfo.ElemType      := ElemType;
      ClassInfo.GetObjectList := GetObjectList;
      fDictionary.Add(ListType, ClassInfo);
    end;
end;

initialization
  ReadComparer  := TSettingsOrderComparer.Create(False);
  WriteComparer := TSettingsOrderComparer.Create(True);

end.
