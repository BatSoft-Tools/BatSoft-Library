unit BatSoft.Classes;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.SysUtils, System.Types, System.TypInfo, System.Rtti, System.Generics.Defaults, Generics.Collections;

type
{$region 'Interfaces'}

  ///  Like TInterfacedObject but without reference counting.
  TInterfacedObjectNoRefCount = System.TNoRefCountObject deprecated 'Use System.TNoRefCountObject';

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
  //      fRefCounter: TRefCountMyOwner;
  //    public
  //      property  RefCounter: TRefCountMyOwner read fRefCounter implements IMyInterface;
  //
  //  In the constructor add:
  //    fRefCounter   := TRefCountMyOwner.Create(Self);
  //
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
    procedure Register(const InterfaceType: TGUID; InterfaceInstance: IInterface; const Replace: Boolean = False);
    function  Obtain<I: IInterface>(): I;
    function  TryObtain<I: IInterface>(out InterfaceInstance: I): Boolean;
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
  protected
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

/// <summary>Change the class of an object. Certain rules apply to reduce the risk of bugs.<br>
/// Please be very careful with this.  Make certain you know what you're doing.</summary>
procedure ChangeClass(const Obj: TObject; const ToClass: TClass);

//  Convenience section that contains things I often re-write.

implementation

uses
  System.RTLConsts, BatSoft.Common;

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

procedure TInterfaceRegistry.Register(const InterfaceType: TGUID; InterfaceInstance: IInterface; const Replace: Boolean);
begin
  if  not Assigned(InterfaceInstance) or not Supports(InterfaceInstance, InterfaceType) then
    raise EBatSoft.Create(SEIntfNotRegistered);
  if  Replace then
    fRegistry.AddOrSetValue(InterfaceType, InterfaceInstance)
  else
    fRegistry.Add(InterfaceType, InterfaceInstance)
end;

function TInterfaceRegistry.TryObtain<I>(out InterfaceInstance: I): Boolean;
var
  IID: TGUID;
  Found: IInterface;
begin
  IID     := GetTypeData(TypeInfo(I)).GUID;
  Result  := fRegistry.TryGetValue(IID, Found);
  if  Result  then
    if  not Supports(Found, IID, InterfaceInstance) then
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

end.
