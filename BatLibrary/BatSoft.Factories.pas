unit BatSoft.Factories;

interface

uses
  System.SysUtils, System.Classes, Generics.Collections, BatSoft.Observer.Managed;

{$DEFINE MULTITON}

type
  TMultiton<TID> = class
  public type
    TFactory = class;

    //  Container types

    TIDs = TList<TID>;

    TContainer = class(TObjectList<TMultiton<TID>>)
    protected
      procedure Notify(const Value: TMultiton<TID>; Action: TCollectionNotification); override;
      procedure AddIDs(const AIDs: TList<TID>);
    public
      constructor Create(const AIDs: TList<TID>); overload;
      constructor CreateAll;
    end;

    //  Lifetime management

    TCreator = reference to function (ID: TID): TMultiton<TID>;

    IStore = interface
      procedure LoadIDs(const IDs: TList<TID>);
      procedure Load(const Obj: TMultiton<TID>);
      procedure Save(const Obj: TMultiton<TID>);
      function  NewID: TID;
    end;

    TFactory = class
    private
{$IFDEF MULTITON}
      //  TPerson object lifetimes
      fAllMultitonsInMemory: TDictionary<TID, TMultiton<TID>>;
{$ENDIF}
      fCreator: TCreator;
      //  Notification of data changes
      fOnChanged: TNotifyEvents;
      //  Internal functionality
      procedure MultitonObtain(const Multiton: TMultiton<TID>);
      procedure MultitonRelease(const Multiton: TMultiton<TID>);
    public
      constructor Create;
      destructor  Destroy; override;
      //  TObj object lifetime management
      property  Creator : TCreator  read fCreator write fCreator;
      function  ObtainNew: TMultiton<TID>;
      function  Obtain(const ID: TID): TMultiton<TID>;
      //  TObj persistance (ie. loading and saving)
      procedure ListAll(const IDs: TList<TID>); overload;
      procedure ListAll(const Multitons: TContainer); overload;
      procedure Load(const Multiton: TMultiton<TID>);
      procedure Save(const Multiton: TMultiton<TID>);
      //  Changes
      property  OnChanged : TNotifyEvents read fOnChanged;
    end;

  private
      //  Interface to database
    class var _Store: IStore;
    class var _Factory: TFactory;
    class constructor Create;
    class destructor  Destroy;
  public
    class function Store: IStore;
    class function Factory: TFactory; inline;
  private
{$IFDEF MULTITON}
    fRefCount: integer;
{$ENDIF}
    fID: TID;
  protected
    //  Lifetime
    constructor Create(const AID: TID);
  public
    //  TPerson object lifetime management
    procedure Obtain;
    procedure Release;
    //  Persistance
    procedure Load; virtual;
    procedure Save; virtual;
    //  Values
    property  ID        : TID         read fID;
  end;

  EMultiton = class(Exception);

resourcestring
  SENoStore = 'Factory has no IStore.';

implementation

{ TMultiton<TID>.TContainer }

procedure TMultiton<TID>.TContainer.AddIDs(const AIDs: TList<TID>);
var
  ID: TID;
  Multiton: TMultiton<TID>;
begin
  for ID in AIDs  do
    begin
      Multiton  := _Factory.Obtain(ID);
      Self.Add(Multiton);
      Multiton.Release;
    end;
end;

constructor TMultiton<TID>.TContainer.Create(const AIDs: TList<TID>);
begin
  inherited Create();
  AddIDs(AIDs)
end;

constructor TMultiton<TID>.TContainer.CreateAll;
var
  IDs: TIDs;
begin
  IDs  := TIDs.Create;
  try
    _Factory.ListAll(IDs);
    Create(IDs);
  finally
    IDs.Free;
  end;
end;

procedure TMultiton<TID>.TContainer.Notify(const Value: TMultiton<TID>;
  Action: TCollectionNotification);
begin
  inherited;
  if  OwnsObjects then
    case Action of
      cnAdded :     Value.Obtain;
      cnRemoved :   Value.Release;
      cnExtracted : Value.Release;
    end;
end;

{ TMultiton<TID>.TFactory }

constructor TMultiton<TID>.TFactory.Create;
var
  IDs: TIDs;
  ID: TID;
begin
  inherited Create;
{$IFDEF MULTITON}
  //  Load Multiton ID's (uses less memory than loading into memory)
  IDs := TIDs.Create;
  try
    _Store.LoadIDs(IDs);
    fAllMultitonsInMemory := TDictionary<TID, TMultiton<TID>>.Create();
    for ID in IDs  do
      fAllMultitonsInMemory.Add(ID, nil);
  finally
    IDs.Free;
  end;
{$ENDIF}
  fOnChanged  := TNotifyEvents.Create(Self);
  //  Default multiton creator
  fCreator    := function (ID: TID): TMultiton<TID>
    begin
      Result  := TMultiton<TID>.Create(_Store.NewID);
    end;
end;

destructor TMultiton<TID>.TFactory.Destroy;
begin
  fOnChanged.Free;
{$IFDEF MULTITON}
  fAllMultitonsInMemory.Free;
{$ENDIF}
  inherited;
end;

procedure TMultiton<TID>.TFactory.ListAll(const IDs: TList<TID>);
begin
  _Store.LoadIDs(IDs);
end;

procedure TMultiton<TID>.TFactory.ListAll(const Multitons: TContainer);
begin

end;

procedure TMultiton<TID>.TFactory.Load(const Multiton: TMultiton<TID>);
begin
  Multiton.Load;
end;

function TMultiton<TID>.TFactory.Obtain(const ID: TID): TMultiton<TID>;
begin
{$IFDEF MULTITON}
  //  If the TMultiton<TID> object already exists in memory, then use that.
  if  not fAllMultitonsInMemory.TryGetValue(ID, Result) then
    raise EMultiton.Create('MultitonID does not exist');
  if  not Assigned(Result)  then
    try
{$ENDIF}
      //  Multiton is not currently in memory, so...
      //  - Create new TMultiton<TID> object
      Result  := fCreator(ID);
      //  - Load properties from database
      _Store.Load(Result);
{$IFDEF MULTITON}
      //  - Keep track of it
      fAllMultitonsInMemory.Add(ID, Result);
    except
      //  Load failed, so tidy up and continue the exception.
      Result.Free;
      raise;
    end;
  //  Now that we have it, increment the RefCount
  inc(Result.fRefCount);
{$ENDIF}
end;

function TMultiton<TID>.TFactory.ObtainNew: TMultiton<TID>;
begin
  //  Create new TMultiton<TID> object
  Result  := fCreator(_Store.NewID);
{$IFDEF MULTITON}
  //  Keep track of it
  fAllMultitonsInMemory.Add(Result.ID, Result);
  //  Now that we have it, increment the RefCount
  inc(Result.fRefCount);
{$ENDIF}
  //  Notify that there is a new Multiton
//  fOnChanged.Call(Result);
end;

procedure TMultiton<TID>.TFactory.MultitonObtain(const Multiton: TMultiton<TID>);
begin
{$IFDEF MULTITON}
  //  Simply increment the RefCount
  inc(Multiton.fRefCount);
{$ENDIF}
end;

procedure TMultiton<TID>.TFactory.MultitonRelease(const Multiton: TMultiton<TID>);
begin
{$IFDEF MULTITON}
  //  Decrement the reference count
  dec(Multiton.fRefCount);
  //  If this object is no longer used, then...
  if  Multiton.fRefCount = 0  then
    begin
      //  - Stop keeping track of it
      fAllMultitonsInMemory.Remove(Multiton.ID);
      //  - Free the object
      Multiton.Free;
    end;
{$ENDIF}
end;

procedure TMultiton<TID>.TFactory.Save(const Multiton: TMultiton<TID>);
begin
  Multiton.Save;
end;

{ TMultiton<TID> }

constructor TMultiton<TID>.Create(const AID: TID);
begin
  inherited Create;
  fID      := AID;
end;

class constructor TMultiton<TID>.Create;
begin
  _Factory  := TFactory.Create;
end;

class function TMultiton<TID>.Factory: TFactory;
begin
  Result  := _Factory;
end;

procedure TMultiton<TID>.Load;
begin
  _Store.Load(Self)
end;

class destructor TMultiton<TID>.Destroy;
begin
  _Factory.Free;
end;

procedure TMultiton<TID>.Obtain;
begin
  //  Let the factory handle this, in case it wants to anything special.
  _Factory.MultitonObtain(Self);
end;

procedure TMultiton<TID>.Release;
begin
  //  Let the factory handle this, because it's possible that this TMultiton<TID>
  //  object is no longer used.  If so, then the factory can free it.
  _Factory.MultitonRelease(Self);
end;

procedure TMultiton<TID>.Save;
begin
  _Store.Save(Self);
end;

class function TMultiton<TID>.Store: IStore;
begin
  if  not Assigned(_Store)  then
    raise EMultiton.Create('Error Message');
  Result  := _Store;
end;

end.
