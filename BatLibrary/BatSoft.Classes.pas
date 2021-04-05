unit BatSoft.Classes;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.SysUtils, System.Types, System.Generics.Defaults, Generics.Collections, System.TypInfo, System.Rtti;

type
{$region 'Interfaces'}

  ///  Like TInterfacedObject but without reference counting.
  TInterfacedObjectNoRefCount = System.Generics.Defaults.TSingletonImplementation;

  //  Sometimes I want interfaced objects to free when the RefCount is something
  //  other than 0, such as when writing factories that keep track of multitons.
  /// TInterfacedObject that free's with a specified reference count.
  TMinRefCountObject = class(TInterfacedObject, IInterface)
  public
    constructor Create(const AMinRefCount: integer = 0);
  end;

  //  Did you ever have a class that you want to add an interface to, but can't
  //  change the root class to TInterfacedObject?  Well, here is your solution.
  //
  //  Add the following to your class declaration:
  //    private
  //      fIntf: IInterface;
  //    public
  //      property  Intf: IInterface  read fIntf  implements IInterface;
  //
  //  In the constructor add:
  //    fIntf := TRefCountMyOwner.Create(Self);

  /// Add interfaces to a class that is not a TInterfacedObject.
  TRefCountMyOwner = class(TMinRefCountObject, IInterface)
  private
    fOwner: TObject;
  public
    constructor Create(const AOwner: TObject);
    destructor  Destroy; override;
  end;

  ///  Used for registering interface implementations.
  ///  The intention is for modules to register their interface implementations
  ///  centrally (typically this would be a singleton), then the rest of the
  ///  application can obtain them knowing only the interface. The only coupling
  ///  will be the global instance of this object and the interface declarations,
  ///  but not their implementations.
  TInterfaceRegistry = class
  private
    fRegistry: TDictionary<TGUID, IInterface>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(const IID: TGUID; IntfObj: IInterface; const Replace: Boolean = False);
    function  Obtain<I: IInterface>(): I;
    function  TryObtain<I: IInterface>(out IntfObj: I): Boolean;
  end;

{$endregion}

{$region 'Generic lists'}

  ///  Register TObjectList<> classes here. No further conversion routines are necessary.
  ///  This does not take TList<> classes.
  RegisteredLists = class
  private
    class var _Types: TDictionary<TClass, TRttiType>;
  public
    class constructor Create;
    class destructor  Destroy;
    class procedure Register(const ListClass, ElemClass: TClass); overload;
    class procedure Register(const ListClass: TClass; const TypeInfo: PTypeInfo); overload;
    class function  IsRegistered(const ListClass: TClass; out ElemClass: TClass): Boolean; overload;
    class function  IsRegistered(const ListClass: TClass; out RTTIType: TRttiType): Boolean; overload;
    class function  IsRegistered(const ListClass: TClass; out TypeInfo: PTypeInfo): Boolean; overload;
  end;

{$endregion}

{$region 'Binary sorted list'}

  //  This is a container that stores items in proper order using binary search.
  TBinaryList<T> = class
  private
    fComparer: IComparer<T>;
    fList: TList<T>;
    fDuplicates: TDuplicates;
    function GetCount: integer; inline;
    function GetItems(const Index: integer): T; inline;
    function GetOnNotify: TCollectionNotifyEvent<T>; inline;
    procedure SetOnNotify(const Value: TCollectionNotifyEvent<T>); inline;
    function  NextBase2: integer;
    function  InternalIndexOf(const Value: T): integer;
  public
    constructor Create; overload;
    constructor Create(const AComparer: IComparer<T>); overload;
    destructor  Destroy; override;

    function  Add(const Value: T): integer;

    procedure AddRange(const Values: array of T); overload;
    procedure AddRange(const Collection: IEnumerable<T>); overload;
    procedure AddRange(const Collection: TEnumerable<T>); overload; inline;

    function  IndexOf(const Value: T): integer;

    procedure Delete(const Index: integer); inline;
    procedure DeleteRange(const Index, Count: integer); inline;
    function  Remove(const Value: T): integer; inline;

    procedure Clear; inline;

    property  Items[const Index: integer]: T  read GetItems; default;
    property  Count: integer read GetCount;
    property  Duplicates: TDuplicates read fDuplicates write fDuplicates;

    property  Comparer: IComparer<T> read FComparer;

    property OnNotify: TCollectionNotifyEvent<T> read GetOnNotify write SetOnNotify;
    function GetEnumerator: TList<T>.TEnumerator; reintroduce; inline;
  end;

{$endregion}

{$region 'Attributes'}

  TAttributeArrayHelper = record helper for TArray<TCustomAttribute>
  public
    class function Has(const AttributeClass: TClass): Boolean; overload;
    class function Has<T: TCustomAttribute>(): Boolean; overload; inline;
    class function Has<T: TCustomAttribute>(const [ref] FoundAttribute: TCustomAttribute): Boolean; overload;
  end;

{$endregion}

  EBatSoft = class(Exception)
  public
    constructor Create(AMessage: string; const Params: array of const); overload;
  end;

/// <summary>Change the class of an object. Certain rules apply to reduce the risk of bugs.<br>
/// Please be very careful with this.  Make certain you know what you're doing.</summary>
procedure ChangeClass(const Obj: TObject; const ToClass: TClass);

//  Convenience section that contains things I often re-write.

function GetExeDir: string;

var
  /// Instead of re-writing instancing/tidy ups of TRttiContext all over the place, here is it, in one place.
  RTTI: TRttiContext;

resourcestring
  SEBatSoftBug          = 'BatSoft bug that should never happen. Please notify at: peter@batsoft.com.au';
  SEIncompatibleClasses = 'Incompatible classes.';
  SEIntfNotRegistered   = 'Tried to obtain an interface that is not registered.';

implementation

uses
  System.RTLConsts;

procedure ChangeClass(const Obj: TObject; const ToClass: TClass);
var
  FromClass: TClass;
begin
  FromClass := Obj.ClassType;
  if  (FromClass.InstanceSize = ToClass.InstanceSize) and
      (ToClass.InheritsFrom(FromClass) or FromClass.InheritsFrom(ToClass))
  then
    Pointer(Pointer(Obj)^)  := Pointer(ToClass)
  else
    raise EBatSoft.Create(SEIncompatibleClasses);
end;

function GetExeDir: string;
begin
  Result  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))
end;

{ TMinRefCountObject }

constructor TMinRefCountObject.Create(const AMinRefCount: integer);
begin
  inherited Create();
  dec(FRefCount, AMinRefCount)
end;

{ TRefCountMyOwner }

constructor TRefCountMyOwner.Create(const AOwner: TObject);
begin
  inherited Create(1);  //  The 1 is for the fOwner's reference to this object
  fOwner  := AOwner;
end;

destructor TRefCountMyOwner.Destroy;
begin
  fOwner.Free;
  inherited;
end;

{ TInterfaceRegistry }

constructor TInterfaceRegistry.Create;
begin
  inherited;
  fRegistry := TDictionary<TGUID, IInterface>.Create();
end;

destructor TInterfaceRegistry.Destroy;
begin
  fRegistry.Free;
  inherited;
end;

function  TInterfaceRegistry.Obtain<I>(): I;
begin
  if  not TryObtain<I>(Result)  then
    raise EBatSoft.Create(SEIntfNotRegistered);
end;

procedure TInterfaceRegistry.Register(const IID: TGUID; IntfObj: IInterface; const Replace: Boolean);
begin
  if  not Assigned(IntfObj) or not Supports(IntfObj, IID) then
    raise EBatSoft.Create(SEIntfNotRegistered);
  if  Replace then
    fRegistry.AddOrSetValue(IID, IntfObj)
  else
    fRegistry.Add(IID, IntfObj)
end;

function TInterfaceRegistry.TryObtain<I>(out IntfObj: I): Boolean;
var
  IID: TGUID;
  Found: IInterface;
begin
  IID     := GetTypeData(TypeInfo(I)).GUID;
  Result  := fRegistry.TryGetValue(IID, Found);
  if  Result  then
    if  not Supports(Found, IID, IntfObj) then
      raise EBatSoft.Create(SEBatSoftBug);
end;

{ RegisteredLists }

class constructor RegisteredLists.Create;
begin
  _Types  := TDictionary<TClass, TRttiType>.Create;
end;

class destructor RegisteredLists.Destroy;
begin
  _Types.Free;
end;

class function RegisteredLists.IsRegistered(const ListClass: TClass; out ElemClass: TClass): Boolean;
var
  RTTIType: TRttiType;
begin
  Result  := IsRegistered(ListClass, RTTIType);
  if  Result and (RTTIType is TRttiInstanceType)  then
    ElemClass := (RTTIType as TRttiInstanceType).MetaclassType
  else
    Result    := False;
end;

class function  RegisteredLists.IsRegistered(const ListClass: TClass; out RTTIType: TRttiType): Boolean;
begin
  Result  := _Types.TryGetValue(ListClass, RTTIType);
end;

class function RegisteredLists.IsRegistered(const ListClass: TClass; out TypeInfo: PTypeInfo): Boolean;
var
  RTTIType: TRttiType;
begin
  Result  := IsRegistered(ListClass, RTTIType);
  if  Result  then
    TypeInfo  := RTTIType.Handle
end;

class procedure RegisteredLists.Register(const ListClass, ElemClass: TClass);
begin
  _Types.Add(ListClass, RTTI.GetType(ElemClass));
end;

class procedure RegisteredLists.Register(const ListClass: TClass; const TypeInfo: PTypeInfo);
begin
  _Types.Add(ListClass, RTTI.GetType(TypeInfo));
end;

{ TBinaryList<T> }

function TBinaryList<T>.Add(const Value: T): integer;
begin
  if Count = 0 then
    Result  := fList.Add(Value)
  else
    begin
      Result  := InternalIndexOf(Value);
      if  Result < 0  then
        begin
          Result  := - Result - 1;
          fList.Insert(Result, Value);
        end
      else if (fDuplicates = dupAccept) then
        fList.Insert(Result, Value)
      else if fDuplicates = dupError  then
        raise EArgumentException.CreateRes(@SGenericDuplicateItem);
    end;
end;

constructor TBinaryList<T>.Create;
begin
  inherited;
  fList     := TList<T>.Create;
  fComparer := fList.Comparer
end;

procedure TBinaryList<T>.AddRange(const Values: array of T);
var
  Item: T;
begin
  for Item in Values do
    Add(Item)
end;

procedure TBinaryList<T>.AddRange(const Collection: IEnumerable<T>);
var
  Item: T;
begin
  for Item in Collection do
    Add(Item)
end;

procedure TBinaryList<T>.AddRange(const Collection: TEnumerable<T>);
begin
  AddRange(Collection.ToArray)
end;

procedure TBinaryList<T>.Clear;
begin
  fList.Clear;
end;

constructor TBinaryList<T>.Create(const AComparer: IComparer<T>);
begin
  inherited Create;
  fList     := TList<T>.Create(AComparer);
  fComparer := fList.Comparer;
end;

procedure TBinaryList<T>.Delete(const Index: integer);
begin
  fList.Delete(Index);
end;

procedure TBinaryList<T>.DeleteRange(const Index, Count: integer);
begin
  fList.DeleteRange(Index, Count)
end;

destructor TBinaryList<T>.Destroy;
begin
  fList.Free;
  inherited;
end;

function TBinaryList<T>.GetCount: integer;
begin
  Result  := fList.Count;
end;

function TBinaryList<T>.GetEnumerator: TList<T>.TEnumerator;
begin
  Result  := fList.GetEnumerator
end;

function TBinaryList<T>.GetItems(const Index: integer): T;
begin
  Result  := fList[Index]
end;

function TBinaryList<T>.GetOnNotify: TCollectionNotifyEvent<T>;
begin
  Result  := fList.OnNotify
end;

function TBinaryList<T>.IndexOf(const Value: T): integer;
begin
  Result  := InternalIndexOf(Value);
  if Result < 0 then
    Result  := -1;
end;

function TBinaryList<T>.InternalIndexOf(const Value: T): integer;
var
  Index: integer absolute Result;
  Jump, Comparison: integer;
begin
  Index := NextBase2 shr 1;
  Jump  := Index shr 1;
  dec(Index);
  while Jump > 0 do
    begin
      if  Count <= Index  then
        dec(Index, Jump)
      else
        begin
          Comparison  := fComparer.Compare(Value, Items[Index]);
          if  Comparison = 0  then
            Exit;
          if  Comparison < 0  then
            dec(Index, Jump)
          else
            inc(Index, Jump);
        end;
      Jump  := Jump shr 1;
    end;
  if  Count <= Index  then
    Exit(-Index - 1);
  Comparison  := fComparer.Compare(Value, Items[Index]);
  if  Comparison = 0  then
    Exit;
  if  Comparison < 0  then
    Result  := - Index
  else
    Result  := -(Index + 1);
  dec(Index);
end;

function TBinaryList<T>.NextBase2: integer;
var
  b: integer absolute Result;
  c: integer;
begin
  b := 1;
  c := Count;
  while c > 0 do
    begin
      b := b shl 1;
      c := c shr 1;
    end;
end;

function TBinaryList<T>.Remove(const Value: T): integer;
begin
  Result  := fList.Remove(Value)
end;

procedure TBinaryList<T>.SetOnNotify(const Value: TCollectionNotifyEvent<T>);
begin
  fList.OnNotify  := Value
end;

{ TAttributeArrayHelper }

class function TAttributeArrayHelper.Has(const AttributeClass: TClass): Boolean;
var
  Attribute: TCustomAttribute;
begin
  Result := True;
  for Attribute in Self do
    if Attribute is AttributeClass then
      Exit;
  Result := False;
end;

class function TAttributeArrayHelper.Has<T>(const [ref] FoundAttribute: TCustomAttribute): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := True;
  for Attr in Self do
    if Attr is T then
      begin
        TObject(Pointer(@FoundAttribute)^) := Attr;
        Exit;
      end;
  Result  := False;
  TObject(Pointer(@FoundAttribute)^) := nil;
end;

class function TAttributeArrayHelper.Has<T>(): Boolean;
begin
  Result  := Has(T);
end;

{ EBatSoft }

constructor EBatSoft.Create(AMessage: string; const Params: array of const);
begin
  inherited Create(Format(AMessage, Params))
end;

initialization
  RTTI  := TRttiContext.Create;

finalization
  RTTI.Free;

end.
