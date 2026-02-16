unit uCourses;

interface

uses
  System.Classes, System.Generics.Collections, BatSoft.Observer.Managed, uPeople;

type
  TEnrolmentAction = (Enrol, Leave);

  TCourse = class
  private type
    TEnrolmentEvent = TEvent2Param<TCourse, TPerson, TEnrolmentAction>;
  private
    fName: string;
    fPeopleInRoom: TPeople;
    fOnChange: TEnrolmentEvent;
  public
    constructor Create(const AName: string);
    destructor  Destroy; override;
    property  Name      : string read fName;
    function  Enrol(const Person: TPerson): Boolean;
    procedure Leave(const Person: TPerson);
    procedure PeopleInRoom(const Strs: TStrings);
    property  OnChange  : TEnrolmentEvent  read fOnChange;
  end;

  TCourses = class
  private
    fCourses: TObjectList<TCourse>;
    fOnChanged: TNotifyEvents<TCourses>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Add(Course: TCourse);
    procedure Remove(Course: TCourse);
    procedure AssignTo(const Strs: TStrings);
    property  OnChanged : TNotifyEvents<TCourses> read fOnChanged;
  end;

var
  Courses   : TCourses;

implementation

{ TCourse }

constructor TCourse.Create(const AName: string);
begin
  inherited Create;
  fName         := AName;
  fPeopleInRoom := TPeople.Create(False);
  fOnChange     := TEnrolmentEvent.Create(Self, True);
end;

destructor TCourse.Destroy;
begin
  fPeopleInRoom.Free;
  fOnChange.Free;
  inherited;
end;

function TCourse.Enrol(const Person: TPerson): Boolean;
begin
  Result  := not fPeopleInRoom.Contains(Person);
  if Result then
    begin
      fPeopleInRoom.Add(Person);
      fOnChange.Call(Person, TEnrolmentAction.Enrol);
    end;
end;

procedure TCourse.Leave(const Person: TPerson);
begin
  if fPeopleInRoom.Contains(Person) then
    begin
      fPeopleInRoom.Remove(Person);
      fOnChange.Call(Person, TEnrolmentAction.Leave);
    end;
end;

procedure TCourse.PeopleInRoom(const Strs: TStrings);
begin
  fPeopleInRoom.AssignTo(Strs);
end;

{ TCourses }

procedure TCourses.Add(Course: TCourse);
begin
  fCourses.Add(Course);
  fOnChanged.Call;
end;

procedure TCourses.AssignTo(const Strs: TStrings);
begin
  Strs.Clear;
  for var Room in fCourses do
    Strs.AddObject(Room.Name, Room);
end;

constructor TCourses.Create;
begin
  inherited;
  fCourses    := TObjectList<TCourse>.Create;
  fOnChanged  := TNotifyEvents<TCourses>.Create(Self, True);
end;

destructor TCourses.Destroy;
begin
  fCourses.Free;
  fOnChanged.Free;
  inherited;
end;

procedure TCourses.Remove(Course: TCourse);
begin
  fCourses.Remove(Course);
  fOnChanged.Call;
end;

initialization
  Courses := TCourses.Create;

finalization
  Courses.Free;

end.
