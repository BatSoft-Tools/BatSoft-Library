unit FrPerson;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, uPerson, BatSoft.Observer.Managed;

type
  TframePerson = class(TFrame)
    labPerID: TLabel;
    labPerName: TLabel;
    labFamName: TLabel;
    edPerID: TEdit;
    edPerName: TEdit;
    edFamName: TEdit;
    butLoad: TButton;
    butSave: TButton;
    procedure butLoadClick(Sender: TObject);
    procedure butSaveClick(Sender: TObject);
    procedure edFamNameTyping(Sender: TObject);
    procedure edPerNameTyping(Sender: TObject);
  private
    fPerson: TPerson;
    fSubscription: ISubscription;
    procedure SetPerson(const Value: TPerson);
    procedure PopulateFrame;
    procedure PersonChanged(Sender: TObject; Person: TPerson);
  public
    destructor  Destroy; override;
    property  Person: TPerson read fPerson write SetPerson;
  end;

implementation

{$R *.fmx}

{ TframePerson }

procedure TframePerson.butLoadClick(Sender: TObject);
begin
  PersonFactory.Load(fPerson);
  PopulateFrame;
end;

procedure TframePerson.butSaveClick(Sender: TObject);
begin
  fPerson.PerName := edPerName.Text;
  fPerson.FamName := edFamName.Text;
  PersonFactory.Save(fPerson);
end;

destructor TframePerson.Destroy;
begin
  Person  := nil;
  inherited;
end;

procedure TframePerson.edFamNameTyping(Sender: TObject);
begin
  fPerson.FamName := edFamName.Text
end;

procedure TframePerson.edPerNameTyping(Sender: TObject);
begin
  fPerson.PerName := edPerName.Text
end;

procedure TframePerson.PersonChanged(Sender: TObject; Person: TPerson);
begin
  PopulateFrame;
end;

procedure TframePerson.PopulateFrame;
begin
  if  Assigned(fPerson) then
    begin
      edPerID.Text    := fPerson.PerID.ToString;
      edPerName.Text  := fPerson.PerName;
      edFamName.Text  := fPerson.FamName;
    end
  else
    begin
      edPerID.Text    := '';
      edPerName.Text  := '';
      edFamName.Text  := '';
    end;
end;

procedure TframePerson.SetPerson(const Value: TPerson);
begin
  //  Change person object
  if  Assigned(fPerson) then
    fPerson.Release;
  fPerson := Value;
  if  Assigned(fPerson) then
    fPerson.Obtain;
  //  Subscribe to events (unsubscribing is automatic)
  if  Assigned(fPerson) then
    fSubscription := fPerson.OnChanged.Subscribe(PersonChanged);
  //  Update UI
  PopulateFrame;
end;

end.
