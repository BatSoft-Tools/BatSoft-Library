unit uPersonStore;

interface

//  WARNING: Please don't study this unit.  It contains some bad code.
//  It contains a pretend database implementation to support the factory demo.

uses
  Generics.Collections, BatSoft.Factories, BatSoft.Observer.Managed, uPerson;

type
  TPersonStore_Random = class(TInterfacedObject, TPerson.IStore)
  private type

    TPersonRecord = record
      PerName: string;
      FamName: string;
    end;

  private
    fNewID: TPerID;
    fPeople: TList<TPersonRecord>;
    function  PerIDToIndex(const PerID: TPerID): integer; inline;
    procedure Populate;
    procedure SavePerson(const PerID: TPerID; const PerName, FamName: string); overload;
  public
    constructor Create;
    destructor  Destroy; override;
    //  TPerson.IStore interface
    procedure LoadIDs(const PerIDs: TList<TPerID>);
    procedure Load(const Person: TMultiton<TPerID>);
    procedure Save(const Person: TMultiton<TPerID>); overload;
    function  NewID: TPerID;
  end;

implementation

uses
  Classes;

{ TPersonStore_Random }

constructor TPersonStore_Random.Create;
begin
  inherited;
  fPeople := TList<TPersonRecord>.Create;
  Populate;
end;

destructor TPersonStore_Random.Destroy;
begin
  fPeople.Free;
  inherited;
end;

procedure TPersonStore_Random.Load(const Person: TMultiton<TPerID>);
var
  nx: integer;
begin
  nx  := PerIDToIndex(Person.ID);
  TPerson(Person).PerName  := fPeople[nx].PerName;
  TPerson(Person).FamName  := fPeople[nx].FamName;
end;

procedure TPersonStore_Random.LoadIDs(const PerIDs: TList<TPerID>);
var
  PerID: integer;
begin
  PerIDs.Clear;
  for PerID := 1 to fPeople.Count do
    PerIDs.Add(PerID);
end;

function TPersonStore_Random.NewID: TPerID;
begin
  inc(fNewID);
  Result  := fNewID;
  SavePerson(fNewID, '', '');
end;

function TPersonStore_Random.PerIDToIndex(const PerID: TPerID): integer;
begin
  if  fPeople.Count < PerID then
    fPeople.Count  := PerID;
  Result  := PerID - 1;
end;

procedure TPersonStore_Random.Populate;
const
  NrPeople  = 200;
  incPer    = 3;
  incFam    = 5;

  function RandomName(const Names: TStrings; var nx: integer; const incNx: integer): string;
  begin
    nx  := (nx + incNx) mod Names.Count;
    Result  := Names[nx];
  end;

var
  PerNames  : TStringList;
  FamNames  : TStringList;
  nxPer, nxFam: integer;
  PerID: Integer;
begin
  PerNames  := TStringList.Create;
  FamNames  := TStringList.Create;
  try
    PerNames.AddStrings(['Kristofer', 'Christina', 'Pearlene', 'Merideth',
      'Ardell', 'Clement', 'Divina', 'Tamisha', 'Preston', 'Ming', 'Lavina',
      'Sharika', 'Mayola', 'Charlotte', 'Bebe', 'Moises', 'Theda', 'Aisha',
      'Russel', 'Mark', 'Odell', 'Sha', 'Karl', 'Jasper', 'Nicolas', 'Kylie',
      'Amanda', 'Rhoda', 'Elnora']);
    FamNames.AddStrings(['Latham', 'Henneman', 'Hickson', 'Greenwalt',
      'Abdulla', 'Pimentel', 'Borgmeyer', 'Mosbey', 'Durrell', 'Start', 'Rusin',
      'Austell', 'Agostini', 'Bowland', 'Mucci', 'Arant', 'Deere', 'Kristensen',
      'Salmi', 'Costanza', 'Noto', 'Lightcap', 'Ridenhour', 'Archer', 'Jenson',
      'Sebesta', 'Zoeller', 'Rommel', 'Pawlowski']);
    for PerID := 1 to NrPeople do
      SavePerson(NewID,
        RandomName(PerNames, nxPer, incPer),
        RandomName(FamNames, nxFam, incFam));
  finally
    PerNames.Free;
    FamNames.Free;
  end;
end;

procedure TPersonStore_Random.SavePerson(const PerID: TPerID; const PerName, FamName: string);
var
  PerRec: TPersonRecord;
  nx: integer;
begin
  PerRec.PerName  := PerName;
  PerRec.FamName  := FamName;
  nx  := PerIDToIndex(PerID);
  fPeople[nx] := PerRec;
end;

procedure TPersonStore_Random.Save(const Person: TMultiton<TPerID>);
begin
  SavePerson(Person.ID, TPerson(Person).PerName, TPerson(Person).FamName);
end;

end.
