unit BatSoft.Classes;

interface

uses
  System.Types, System.Generics.Defaults, Generics.Collections;

type
  TNoRefInterfacedObject = class(TObject, IInterface)
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  //  This is a reference counted TList<T> that can be used to implement interfaces
  //  It is a combination of TInterfacedObject and TList<>
  TInterfacedList<T: class> = class(TList<T>, IInterface)
{$IFNDEF AUTOREFCOUNT}
  private const
    objDestroyingFlag = Integer($80000000);
    function GetRefCount: Integer; inline;
{$ENDIF}
  protected
{$IFNDEF AUTOREFCOUNT}
    [Volatile] FRefCount: Integer;
    class procedure __MarkDestroying(const Obj); static; inline;
{$ENDIF}
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
{$IFNDEF AUTOREFCOUNT}
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: Integer read GetRefCount;
{$ENDIF}
  end;

  //  This is a reference counted TObjectList<T> that can be used to implement interfaces
  //  It is a combination of TInterfacedObject and TObjectList<>
  TInterfacedObjectList<T: class> = class(TObjectList<T>, IInterface)
{$IFNDEF AUTOREFCOUNT}
  private const
    objDestroyingFlag = Integer($80000000);
    function GetRefCount: Integer; inline;
{$ENDIF}
  protected
{$IFNDEF AUTOREFCOUNT}
    [Volatile] FRefCount: Integer;
    class procedure __MarkDestroying(const Obj); static; inline;
{$ENDIF}
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
{$IFNDEF AUTOREFCOUNT}
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: Integer read GetRefCount;
{$ENDIF}
  end;

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
//    procedure Prepopulate(const Value: T);

    property OnNotify: TCollectionNotifyEvent<T> read GetOnNotify write SetOnNotify;
    function GetEnumerator: TList<T>.TEnumerator; reintroduce; inline;
  end;

  TAttributeHelper = class helper for TCustomAttribute
  public
    class function HasAttribute(const Attributes: TArray<TCustomAttribute>; const AttributeClass: TClass): Boolean; overload;
    class function HasAttribute<T: TCustomAttribute>(const Attributes: TArray<TCustomAttribute>): Boolean; overload;
    class function HasAttribute<T: TCustomAttribute>(const Attributes: TArray<TCustomAttribute>; out Attribute: T): Boolean; overload;
  end;

implementation

uses
  System.SysUtils, System.RTLConsts;

{ TNoRefInterfacedObject }

function TNoRefInterfacedObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TNoRefInterfacedObject._AddRef: Integer;
begin
  //  Do nothing
  Result  := 0;
end;

function TNoRefInterfacedObject._Release: Integer;
begin
  //  Do nothing
  Result  := 0;
end;

{ TInterfacedList<T> }

{$IFNDEF AUTOREFCOUNT}

procedure TInterfacedList<T>.AfterConstruction;
begin
// Release the constructor's implicit refcount
  AtomicDecrement(FRefCount);
end;

procedure TInterfacedList<T>.BeforeDestruction;
begin
  if RefCount <> 0 then
    System.Error(reInvalidPtr);
end;

function TInterfacedList<T>.GetRefCount: Integer;
begin
  Result := FRefCount and not objDestroyingFlag;
end;

// Set an implicit refcount so that refcounting during construction won't destroy the object.
class function TInterfacedList<T>.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TInterfacedList<T>(Result).FRefCount := 1;
end;

{$ENDIF AUTOREFCOUNT}

function TInterfacedList<T>.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TInterfacedList<T>._AddRef: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicIncrement(FRefCount);
{$ELSE}
  Result := __ObjAddRef;
{$ENDIF}
end;

function TInterfacedList<T>._Release: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
  begin
    // Mark the refcount field so that any refcounting during destruction doesn't infinitely recurse.
    __MarkDestroying(Self);
    Destroy;
  end;
{$ELSE}
  Result := __ObjRelease;
{$ENDIF}
end;

{$IFNDEF AUTOREFCOUNT}

class procedure TInterfacedList<T>.__MarkDestroying(const Obj);
var
  LRef: Integer;
begin
  repeat
    LRef := TInterfacedList<T>(Obj).FRefCount;
  until AtomicCmpExchange(TInterfacedList<T>(Obj).FRefCount, LRef or objDestroyingFlag, LRef) = LRef;
end;

{$ENDIF AUTOREFCOUNT}

{ TInterfacedObjectList<T> }

{$IFNDEF AUTOREFCOUNT}

procedure TInterfacedObjectList<T>.AfterConstruction;
begin
// Release the constructor's implicit refcount
  AtomicDecrement(FRefCount);
end;

procedure TInterfacedObjectList<T>.BeforeDestruction;
begin
  if RefCount <> 0 then
    System.Error(reInvalidPtr);
end;

function TInterfacedObjectList<T>.GetRefCount: Integer;
begin
  Result := FRefCount and not objDestroyingFlag;
end;

// Set an implicit refcount so that refcounting during construction won't destroy the object.
class function TInterfacedObjectList<T>.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TInterfacedObjectList<T>(Result).FRefCount := 1;
end;

{$ENDIF AUTOREFCOUNT}

function TInterfacedObjectList<T>.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TInterfacedObjectList<T>._AddRef: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicIncrement(FRefCount);
{$ELSE}
  Result := __ObjAddRef;
{$ENDIF}
end;

function TInterfacedObjectList<T>._Release: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
  begin
    // Mark the refcount field so that any refcounting during destruction doesn't infinitely recurse.
    __MarkDestroying(Self);
    Destroy;
  end;
{$ELSE}
  Result := __ObjRelease;
{$ENDIF}
end;

{$IFNDEF AUTOREFCOUNT}

class procedure TInterfacedObjectList<T>.__MarkDestroying(const Obj);
var
  LRef: Integer;
begin
  repeat
    LRef := TInterfacedObjectList<T>(Obj).FRefCount;
  until AtomicCmpExchange(TInterfacedObjectList<T>(Obj).FRefCount, LRef or objDestroyingFlag, LRef) = LRef;
end;

{$ENDIF AUTOREFCOUNT}

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

//procedure TBinaryList<T>.Prepopulate(const Value: T);
//begin
//  fList.Add(Value);
//end;

function TBinaryList<T>.Remove(const Value: T): integer;
begin
  Result  := fList.Remove(Value)
end;

procedure TBinaryList<T>.SetOnNotify(const Value: TCollectionNotifyEvent<T>);
begin
  fList.OnNotify  := Value
end;

{ TAttributeHelper }

class function TAttributeHelper.HasAttribute(const Attributes: TArray<TCustomAttribute>;
  const AttributeClass: TClass): Boolean;
var
  Attribute: TCustomAttribute;
begin
  Result := True;
  for Attribute in Attributes do
    if Attribute is AttributeClass then
      Exit;
  Result := False;
end;

class function TAttributeHelper.HasAttribute<T>(const Attributes: TArray<TCustomAttribute>;
  out Attribute: T): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := True;
  for Attr in Attributes do
    if Attr is T then
      begin
        Attribute := Attr as T;
        Exit;
      end;
  Result  := False;
end;

class function TAttributeHelper.HasAttribute<T>(const Attributes: TArray<TCustomAttribute>): Boolean;
var
  Attribute: T;
begin
  Result  := HasAttribute<T>(Attributes, Attribute)
end;

end.
