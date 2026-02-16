unit FPeople;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.Layouts, FMX.ListBox, BatSoft.Observer.Managed, uPeople,
  FMX.Controls.Presentation, FMX.StdCtrls, System.Generics.Collections;

type
  TfrmPeople = class(TForm)
    lstPeople: TListBox;
    butDelete: TButton;
    butNewPerson: TButton;
    procedure FormCreate(Sender: TObject);
    procedure lstPeopleDblClick(Sender: TObject);
    procedure butDeleteClick(Sender: TObject);
    procedure butNewPersonClick(Sender: TObject);
  private
    fPersonSubscriptions: TList<ISubscription<TPerson>>;
    fPeopleSubscription: ISubscription<TPeople>;
    procedure PeopleUpdate(People: TPeople);
    procedure PersonUpdate(Person: TPerson);
    function  SelectedPerson: TPerson;
  end;

var
  frmPeople: TfrmPeople;

implementation

{$R *.fmx}

uses
  uNameGenerator, FPerson;

{ TfrmPeople }

procedure TfrmPeople.butDeleteClick(Sender: TObject);
begin
  People.Remove(SelectedPerson);
end;

procedure TfrmPeople.butNewPersonClick(Sender: TObject);
begin
  People.Add(TPerson.Create(NewName));
end;

procedure TfrmPeople.FormCreate(Sender: TObject);
begin
  fPeopleSubscription := People.OnChanged.Subscribe(PeopleUpdate);
  fPersonSubscriptions:= TList<ISubscription<TPerson>>.Create;
end;

procedure TfrmPeople.lstPeopleDblClick(Sender: TObject);
begin
  if lstPeople.ItemIndex >= 0 then
    ShowPerson(SelectedPerson);
end;

procedure TfrmPeople.PeopleUpdate(People: TPeople);
begin
  People.AssignTo(lstPeople.Items);
  fPersonSubscriptions.Clear;
  for var Person in People.Expose do
    fPersonSubscriptions.Add(Person.OnChanged.Subscribe(PersonUpdate));
end;

procedure TfrmPeople.PersonUpdate(Person: TPerson);
var
  i: integer;
begin
  i := lstPeople.Items.IndexOfObject(Person);
  lstPeople.Items[i]  := Person.Name;
end;

function TfrmPeople.SelectedPerson: TPerson;
begin
  if lstPeople.ItemIndex < 0 then
    Result  := nil
  else
    Result  := lstPeople.Items.Objects[lstPeople.ItemIndex] as TPerson
end;

end.
