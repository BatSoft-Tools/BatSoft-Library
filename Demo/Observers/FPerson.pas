unit FPerson;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, BatSoft.Observer.Managed, uPeople,
  FMX.Layouts, FMX.StdCtrls, FMX.ListBox, uCourses;

type
  TfrmPerson = class(TForm)
    edName: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edNameTyping(Sender: TObject);
  private
    fPerson: TPerson;
    fSubcsription: ISubscription<TPerson>;
    procedure SetPerson(const Value: TPerson);
    procedure ShowName(Person: TPerson);
    procedure OnEnded(const EventHandler: TManagedEventHandler<TPerson>);
  public
    property  Person: TPerson read fPerson  write SetPerson;
  end;

procedure ShowPerson(const Person: TPerson);

implementation

{$R *.fmx}

procedure ShowPerson(const Person: TPerson);
var
  NewForm: TfrmPerson;
begin
  NewForm := TfrmPerson.Create(Application);
  NewForm.Person  := Person;
  NewForm.Show;
end;

{ TfrmPerson }

procedure TfrmPerson.edNameTyping(Sender: TObject);
begin
  Person.Name := edName.Text;
end;

procedure TfrmPerson.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action  := TCloseAction.caFree
end;

procedure TfrmPerson.OnEnded(const EventHandler: TManagedEventHandler<TPerson>);
begin
  Close;
end;

procedure TfrmPerson.SetPerson(const Value: TPerson);
begin
  fPerson := Value;
  edName.Text	:= fPerson.Name;
  fSubcsription := fPerson.OnChanged.Subscribe(ShowName);
  fSubcsription.OnEnd := OnEnded;
end;

procedure TfrmPerson.ShowName(Person: TPerson);
begin
  edName.Text := Person.Name
end;

end.
