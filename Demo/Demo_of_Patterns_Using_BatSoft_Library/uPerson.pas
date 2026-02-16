unit uPerson;

interface

uses
  BatSoft.Factories, BatSoft.Mementos, BatSoft.Observer.Managed;

type
  TPersonID = integer;

  TPerson = class;

  //  Change updates
  TOnChanged = TEvent1Param<TPerson>;

  TPerson = class(TMultiton<TPersonID>)
  private
    //  Notification of data changes
    fOnChanged: TOnChanged;
    //  Backup to help with undo's
    fBackup: TBackupFields;
    //  Person properties
    fFamName: string;
    fPerName: string;
    procedure SetFamName(const Value: string);
    procedure SetPerName(const Value: string);
  public
    constructor Create(const AID: TPersonID);
    destructor  Destroy; override;
    //  Persistance
    procedure Load; override;
    procedure Save; override;
    //  Changes
    property  OnChanged : TOnChanged  read fOnChanged;
    //  Person properties
    property  FamName     : string  read fFamName write SetFamName;
    property  PerName     : string  read fPerName write SetPerName;
    function  FullName    : string;
  end;

implementation

{ TPersonMultiton }

constructor TPerson.Create(const AID: TPersonID);
begin
  inherited Create(AID);
  fOnChanged  := TOnChanged.Create(Self);
  fBackup     := TBackupFields.Create(Self);
end;

destructor TPerson.Destroy;
begin
  fBackup.Free;
  fOnChanged.Free;
  inherited;
end;

function TPerson.FullName: string;
begin
  Result  := FamName + ', ' + PerName
end;

procedure TPerson.Load;
begin
  inherited;
  fBackup.Backup;
end;

procedure TPerson.Save;
begin
  inherited;
  fBackup.Backup;
end;

procedure TPerson.SetFamName(const Value: string);
begin
  fFamName := Value;
  OnChanged.Call(Self);
end;

procedure TPerson.SetPerName(const Value: string);
begin
  fPerName := Value;
  OnChanged.Call(Self);
end;

end.
