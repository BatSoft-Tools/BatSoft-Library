unit BatSoft.Observer.Base;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, Generics.Collections;

type
  TCallCallback = reference to procedure(const Callback: TMethod);

  EObserver = class(Exception);

  TFlowingEnumerators<T> = class
  private type

    TEnumeratorObject = class(TInterfacedObject, IEnumerator)
    private
      fFlowing: TFlowingEnumerators<T>;
      fIndex: integer;
    public
      procedure Expire; inline;
      //  IEnumerator interface
      function GetCurrent: TObject;
      function MoveNext: Boolean;
      procedure Reset; inline;
    end;

    TEnumeratorGeneric = class(TEnumeratorObject, IEnumerator<T>)
    private
      procedure Removing(const Index: integer);
      constructor Create(const AFlowing: TFlowingEnumerators<T>);
    public
      destructor  Destroy; override;
      //  IEnumerator<T> interface
      function GetCurrent: T; inline;
    end;

  private
    fList: TList<T>;
    fEnumerators: TList<TEnumeratorGeneric>;
  public
    constructor Create(const AList: TList<T>);
    destructor  Destroy; override;
    function  GetEnumerator: IEnumerator<T>; inline;
    //  Either call this for every item removed...
    procedure ListItemRemoved(const Index: integer);
    //  ... or call one these directly instead of calling the list directly
    procedure DeleteListItem(const Index: integer);
    function  RemoveListItem(const Value: T): Integer;
  end;

implementation

{ TFlowingEnumerators<T>.TEnumeratorObject }

procedure TFlowingEnumerators<T>.TEnumeratorObject.Expire;
begin
  fIndex  := MaxInt;
end;

function TFlowingEnumerators<T>.TEnumeratorObject.GetCurrent: TObject;
begin
  raise EObserver.Create(ClassName + ' does not return objects.');
end;

function TFlowingEnumerators<T>.TEnumeratorObject.MoveNext: Boolean;
begin
  Result  := fIndex < fFlowing.fList.Count - 1;
  if  Result  then
    inc(fIndex);
end;

procedure TFlowingEnumerators<T>.TEnumeratorObject.Reset;
begin
  fIndex  := -1;
end;

{ TFlowingEnumerators<T>.TEnumeratorGeneric }

constructor TFlowingEnumerators<T>.TEnumeratorGeneric.Create(const AFlowing: TFlowingEnumerators<T>);
begin
  inherited Create;
  fFlowing  := AFlowing;
  fFlowing.fEnumerators.Add(Self);
  Reset;
end;

destructor TFlowingEnumerators<T>.TEnumeratorGeneric.Destroy;
begin
  fFlowing.fEnumerators.Remove(Self);
  inherited;
end;

function TFlowingEnumerators<T>.TEnumeratorGeneric.GetCurrent: T;
begin
  Result  := fFlowing.fList[fIndex]
end;

procedure TFlowingEnumerators<T>.TEnumeratorGeneric.Removing(const Index: integer);
begin
  if  Index <= fIndex then
    dec(fIndex);
end;

{ TFlowingEnumerators<T> }

constructor TFlowingEnumerators<T>.Create(const AList: TList<T>);
begin
  inherited Create;
  fList         := AList;
  fEnumerators  := TList<TEnumeratorGeneric>.Create;
end;

procedure TFlowingEnumerators<T>.DeleteListItem(const Index: integer);
begin
  fList.Delete(Index);
  ListItemRemoved(Index);
end;

destructor TFlowingEnumerators<T>.Destroy;
var
  i: integer;
begin
  fList.OnNotify  := nil;
  for i := 0 to fEnumerators.Count - 1 do
    fEnumerators[i].Expire;
  fEnumerators.Free;
  inherited;
end;

function TFlowingEnumerators<T>.GetEnumerator: IEnumerator<T>;
begin
  Result  := TEnumeratorGeneric.Create(Self);
end;

procedure TFlowingEnumerators<T>.ListItemRemoved(const Index: integer);
var
  i: integer;
begin
  for i := fEnumerators.Count - 1 downto 0  do
    fEnumerators[i].Removing(Index);
end;

function TFlowingEnumerators<T>.RemoveListItem(const Value: T): Integer;
begin
  Result  := fList.Remove(Value);
  ListItemRemoved(Result);
end;

end.
