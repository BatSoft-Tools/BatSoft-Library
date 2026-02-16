unit uPeople;

interface

uses
  System.Classes, System.Generics.Collections, BatSoft.Observer.Managed;

type
  TPerson = class
  private
    fName: string;
    fOnChanged: TNotifyEvents<TPerson>;
    procedure SetName(const Value: string);
  public
    constructor Create(const AName: string);
    destructor  Destroy; override;
    property  Name  : string read fName write SetName;
    property  OnChanged : TNotifyEvents<TPerson>  read fOnChanged;
  end;

  TPeople = class
  private
    fPeople: TObjectList<TPerson>;
    fOnChanged: TNotifyEvents<TPeople>;
  public
    constructor Create(AOwnsObjects: Boolean);
    destructor  Destroy; override;
    procedure Add(Person: TPerson);
    procedure Remove(Person: TPerson);
    function  Contains(Person: TPerson): Boolean;
    procedure AssignTo(const Strs: TStrings);
    property  Expose: TObjectList<TPerson> read fPeople;
    property  OnChanged : TNotifyEvents<TPeople>  read fOnChanged;
  end;

var
  People  : TPeople;

implementation

uses
  SysUtils;

{ TPerson }

constructor TPerson.Create(const AName: string);
begin
  inherited Create;
  fName := AName;
  fOnChanged  := TNotifyEvents<TPerson>.Create(Self);
end;

destructor TPerson.Destroy;
begin
  fOnChanged.Free;
  inherited;
end;

procedure TPerson.SetName(const Value: string);
begin
  fName := Value;
  fOnChanged.Call;
end;

{ TPeople }

procedure TPeople.Add(Person: TPerson);
begin
  fPeople.Add(Person);
  fOnChanged.Call;
end;

procedure TPeople.AssignTo(const Strs: TStrings);
begin
  Strs.Clear;
  for var Person in fPeople do
    Strs.AddObject(Person.Name, Person);
end;

function TPeople.Contains(Person: TPerson): Boolean;
begin
  Result  := fPeople.Contains(Person);
end;

constructor TPeople.Create(AOwnsObjects: Boolean);
begin
  inherited Create;
  fPeople     := TObjectList<TPerson>.Create(AOwnsObjects);
  fOnChanged  := TNotifyEvents<TPeople>.Create(Self, True);
end;

destructor TPeople.Destroy;
begin
  fPeople.Free;
  fOnChanged.Free;
  inherited;
end;

procedure TPeople.Remove(Person: TPerson);
begin
  if Assigned(Person) then
    begin
      fPeople.Remove(Person);
      fOnChanged.Call;
    end;
end;

initialization
  People  := TPeople.Create(True);

finalization
  People.Free;

end.
