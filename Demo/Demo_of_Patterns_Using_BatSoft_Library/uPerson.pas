unit uPerson;

interface

//  This is an example of a "concrete factory".
//  That is because TPersonFactory is the factory that creates TPerson objects.

//  TPersonFactory is an example of a "singleton",
//  because PersonFactory is the one and only instance of TPersonFactory.

//  Try with and without multiton:
{$DEFINE MULTITON}
{$IFDEF MULTITON}
//  TPerson is an example of "multiton".
//  Every TPerson object is unique - there will never be multiple TPerson
//  objects that represent the same person.
//  But because many people exist, there will be *multiple instances* of
//  TPerson, hence TPerson is not a singleton class, but a multiton class.
{$ENDIF}

uses
  System.SysUtils,
  Classes, Generics.Collections, BatSoft.Observer.Managed;

type
  TPerID = integer;
const
  NoPerson  : TPerID = 0;

type
  TPerIDs = class(TList<TPerID>);

  TPerson = class;

  TPersonEvents = class(TEvent1Param<TPerson>);

  TPerson = class
  private
{$IFDEF MULTITON}
    fRefCount: integer;
{$ENDIF}
    fPerID: TPerID;
    fPerName: string;
    fFamName: string;
    fOnChanged: TPersonEvents;
    procedure SetPerName(const Value: string);
    procedure SetFamName(const Value: string);
  private
    //  Lifetime
    constructor Create(const APerID: TPerID);
  public
    destructor  Destroy; override;
    //  TPerson object lifetime management
    procedure Obtain;
    procedure Release;
    //  Values
    property  PerID       : TPerID        read fPerID;
    property  PerName     : string        read fPerName write SetPerName;
    property  FamName     : string        read fFamName write SetFamName;
    function  FullName    : string;
    property  OnChanged   : TPersonEvents read fOnChanged;
  end;

  //  Collection of TPerson objects
  TPeople = class(TObjectList<TPerson>)
  protected
    procedure Notify(const Value: TPerson; Action: TCollectionNotification); override;
    procedure AddPeople(const APerIDs: TPerIDs);
  public
    constructor Create(const APerIDs: TPerIDs); overload;
    constructor CreateAll;
    procedure AsStrings(const Strs: TStrings);
  end;

  IPersonStore = interface
    ['{13497910-AF88-4827-B5CB-8A47B3E3C528}']
    procedure LoadPersonIDs(const PerIDs: TPerIDs);
    procedure LoadPerson(const Person: TPerson);
    procedure SavePerson(const Person: TPerson);
    function  NewID: TPerID;
  end;

  TPersonFactory = class
  private
    //  Interface to database
    fStore: IPersonStore;
{$IFDEF MULTITON}
    //  TPerson object lifetimes
    fAllPeopleInMemory: TDictionary<TPerID, TPerson>;
{$ENDIF}
    //  Notification of data changes
    fOnChanged: TPersonEvents;
    //  Internal functionality
    procedure PersonObtain(const Person: TPerson);
    procedure PersonRelease(const Person: TPerson);
  public
    constructor Create(AStore: IPersonStore);
    destructor  Destroy; override;
    //  TPerson object lifetime management
    function  ObtainNew: TPerson;
    function  Obtain(const PerID: TPerID): TPerson;
    //  TPerson persistance (ie. loading and saving)
    procedure ListAll(const PerIDs: TPerIDs); overload;
    procedure ListAll(const People: TPeople); overload;
    procedure Load(const Person: TPerson);
    procedure Save(const Person: TPerson);
    //  Changes
    property  OnChanged : TPersonEvents read fOnChanged;
  end;

  EPerson = class(Exception);

var
  PersonFactory: TPersonFactory;

implementation

{ TPerson }

constructor TPerson.Create(const APerID: TPerID);
begin
  inherited Create;
  fPerID      := APerID;
  fOnChanged  := TPersonEvents.Create(Self);
end;

destructor TPerson.Destroy;
begin
  fOnChanged.Free;
  inherited;
end;

function TPerson.FullName: string;
begin
  Result  := PerName + ', ' + FamName
end;

procedure TPerson.Obtain;
begin
  //  Let the factory handle this, in case it wants to anything special.
  PersonFactory.PersonObtain(Self);
end;

procedure TPerson.Release;
begin
  //  Let the factory handle this, because it's possible that this TPerson
  //  object is no longer used.  If so, then the factory can free it.
  PersonFactory.PersonRelease(Self);
end;

procedure TPerson.SetFamName(const Value: string);
begin
  fFamName := Value;
  fOnChanged.Call(Self);
end;

procedure TPerson.SetPerName(const Value: string);
begin
  fPerName := Value;
  fOnChanged.Call(Self);
end;

{ TPeople }

procedure TPeople.AddPeople(const APerIDs: TPerIDs);
var
  PerID: TPerID;
  Person: TPerson;
begin
  for PerID in APerIDs  do
    begin
      Person  := PersonFactory.Obtain(PerID);
      Self.Add(Person);
      Person.Release;
    end;
end;

procedure TPeople.AsStrings(const Strs: TStrings);
var
  Person: TPerson;
begin
  Strs.BeginUpdate;
  try
    Strs.Clear;
    for Person in Self  do
      Strs.AddObject(Person.PerName+' '+Person.FamName, Person);
  finally
    Strs.EndUpdate;
  end;
end;

constructor TPeople.Create(const APerIDs: TPerIDs);
begin
  inherited Create();
  AddPeople(APerIDs)
end;

constructor TPeople.CreateAll;
var
  PerIDs: TPerIDs;
begin
  PerIDs  := TPerIDs.Create;
  try
    PersonFactory.ListAll(PerIDs);
    Create(PerIDs);
  finally
    PerIDs.Free;
  end;
end;

procedure TPeople.Notify(const Value: TPerson; Action: TCollectionNotification);
begin
  inherited;
  if  OwnsObjects then
    case Action of
      cnAdded :     Value.Obtain;
      cnRemoved :   Value.Release;
      cnExtracted : Value.Release;
    end;
end;

{ TPersonFactory }

constructor TPersonFactory.Create(AStore: IPersonStore);
var
  PerIDs: TPerIDs;
  PerID: TPerID;
begin
  inherited Create;
  fStore  := AStore;
{$IFDEF MULTITON}
  //  Load person ID's (uses less memory than loading into memory)
  PerIDs := TPerIDs.Create;
  try
    fStore.LoadPersonIDs(PerIDs);
    fAllPeopleInMemory := TDictionary<TPerID, TPerson>.Create();
    for PerID in PerIDs  do
      fAllPeopleInMemory.Add(PerID, nil);
  finally
    PerIDs.Free;
  end;
{$ENDIF}
  fOnChanged  := TPersonEvents.Create(Self);
end;

destructor TPersonFactory.Destroy;
begin
  fOnChanged.Free;
{$IFDEF MULTITON}
  fAllPeopleInMemory.Free;
{$ENDIF}
  inherited;
end;

procedure TPersonFactory.ListAll(const PerIDs: TPerIDs);
begin
  fStore.LoadPersonIDs(PerIDs);
end;

procedure TPersonFactory.ListAll(const People: TPeople);
begin

end;

procedure TPersonFactory.Load(const Person: TPerson);
begin
  fStore.LoadPerson(Person);
end;

function TPersonFactory.Obtain(const PerID: TPerID): TPerson;
begin
{$IFDEF MULTITON}
  //  If the TPerson object already exists in memory, then use that.
  if  not fAllPeopleInMemory.TryGetValue(PerID, Result) then
    raise EPerson.Create('PersonID does not exist');
  if  not Assigned(Result)  then
    try
{$ENDIF}
      //  Person is not currently in memory, so...
      //  - Create new TPerson object
      Result  := TPerson.Create(PerID);
      //  - Load properties from database
      fStore.LoadPerson(Result);
{$IFDEF MULTITON}
      //  - Keep track of it
      fAllPeopleInMemory.Add(PerID, Result);
    except
      //  Load failed, so tidy up and continue the exception.
      Result.Free;
      raise;
    end;
  //  Now that we have it, increment the RefCount
  inc(Result.fRefCount);
{$ENDIF}
end;

function TPersonFactory.ObtainNew: TPerson;
begin
  //  Create new TPerson object
  Result  := TPerson.Create(fStore.NewID);
{$IFDEF MULTITON}
  //  Keep track of it
  fAllPeopleInMemory.Add(Result.PerID, Result);
  //  Now that we have it, increment the RefCount
  inc(Result.fRefCount);
{$ENDIF}
  //  Notify that there is a new person
  fOnChanged.Call(Result);
end;

procedure TPersonFactory.PersonObtain(const Person: TPerson);
begin
{$IFDEF MULTITON}
  //  Simply increment the RefCount
  inc(Person.fRefCount);
{$ENDIF}
end;

procedure TPersonFactory.PersonRelease(const Person: TPerson);
begin
{$IFDEF MULTITON}
  //  Decrement the reference count
  dec(Person.fRefCount);
  //  If this object is no longer used, then...
  if  Person.fRefCount = 0  then
    begin
      //  - Stop keeping track of it
      fAllPeopleInMemory.Remove(Person.PerID);
      //  - Free the object
      Person.Free;
    end;
{$ENDIF}
end;

procedure TPersonFactory.Save(const Person: TPerson);
begin
  fStore.SavePerson(Person);
  fOnChanged.Call(Person);
end;

end.
