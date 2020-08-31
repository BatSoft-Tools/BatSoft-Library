unit FChangeTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Controls.Presentation, uRefCounter,
  FMX.ScrollBox, FMX.Memo, BatSoft.Mementos, FMX.Memo.Types;

type
  TAddress = class
  private
    fStreet: string;
    fSuburb: string;
  public
    property  Street  : string  read fStreet  write fStreet;
    property  Suburb  : string  read fSuburb  write fSuburb;
  end;

  TPerson = class
  private
    fAge: integer;
    fFamName: string;
    fPerName: string;
    fCounter: IRefCounter;
    fNotes: TStrings;
    [MementoDeepField]
    fAddress: TAddress;
  public
    constructor Create;
    destructor  Destroy; override;
    property  Age     : integer     read fAge     write fAge;
    property  FamName : string      read fFamName write fFamName;
    property  PerName : string      read fPerName write fPerName;
    property  Counter : IRefCounter read fCounter write fCounter;
    property  Notes   : TStrings    read fNotes;
    property  Address : TAddress    read fAddress write fAddress;
  end;

  TfrmChangeTest = class(TForm)
    labAge: TLabel;
    labPerName: TLabel;
    edAge: TSpinBox;
    edPerName: TEdit;
    labFamName: TLabel;
    edFamName: TEdit;
    labVersion: TLabel;
    edVersion: TLabel;
    butCreate: TButton;
    butFree: TButton;
    butPopulate: TButton;
    butBackup: TButton;
    butHasChanged: TButton;
    butListChanges: TButton;
    butUndo: TButton;
    butRedo: TButton;
    labRefCounter: TLabel;
    edRefCounter: TEdit;
    labCounter: TLabel;
    chkCounter: TCheckBox;
    butRestore: TButton;
    Street: TLabel;
    edStreet: TEdit;
    Suburb: TLabel;
    edSuburb: TEdit;
    labNotes: TLabel;
    edNotes: TMemo;
    grpTPerson: TGroupBox;
    grpTAddress: TGroupBox;
    panButtons: TPanel;
    butToggle: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edPerNameExit(Sender: TObject);
    procedure edFamNameExit(Sender: TObject);
    procedure butPopulateClick(Sender: TObject);
    procedure butBackupClick(Sender: TObject);
    procedure butUndoClick(Sender: TObject);
    procedure butHasChangedClick(Sender: TObject);
    procedure butListChangesClick(Sender: TObject);
    procedure butCreateClick(Sender: TObject);
    procedure butFreeClick(Sender: TObject);
    procedure butRedoClick(Sender: TObject);
    procedure chkCounterChange(Sender: TObject);
    procedure butRestoreClick(Sender: TObject);
    procedure edAgeExit(Sender: TObject);
    procedure edStreetExit(Sender: TObject);
    procedure edSuburbExit(Sender: TObject);
    procedure edNotesExit(Sender: TObject);
    procedure butToggleClick(Sender: TObject);
  private
    fRefCounter: IRefCounter;
    fPerson: TPerson;
    fMemento: TMemento;
    function  IsVersions: Boolean;
    procedure EnableControls;
    procedure ShowPerson;
  end;

var
  frmChangeTest: TfrmChangeTest;

implementation

{$R *.fmx}

{ TPerson }

constructor TPerson.Create;
begin
  inherited;
  fNotes    := TStringList.Create;
  fAddress  := TAddress.Create;
end;

destructor TPerson.Destroy;
begin
  fAddress.Free;
  fNotes.Free;
  inherited;
end;

{ TfrmChangeTest2 }

procedure TfrmChangeTest.butCreateClick(Sender: TObject);
begin
  if  IsVersions  then
    fMemento := TVersionsFields.Create(fPerson)
  else
    fMemento := TBackupFields.Create(fPerson);
  EnableControls;
  ShowPerson;
end;

procedure TfrmChangeTest.butFreeClick(Sender: TObject);
begin
  FreeAndNil(fMemento);
  EnableControls;
  ShowPerson;
end;

procedure TfrmChangeTest.butHasChangedClick(Sender: TObject);
begin
  if  fMemento.HasChanges then
    ShowMessage('Changed')
  else
    ShowMessage('Unchanged');
end;

procedure TfrmChangeTest.butBackupClick(Sender: TObject);
begin
  fMemento.Backup;
  ShowPerson;
end;

procedure TfrmChangeTest.butListChangesClick(Sender: TObject);
var
  Changes: TChanges;
  Change: TChange;
  Strs: TStringList;
begin
  //  Obtain list of changes
  Changes := TChanges.Create;
  try
    fMemento.ListChanges(Changes);
    //  Show changes to user
    Strs    := TStringList.Create;
    try
      Strs.Add('Changes:');
      for Change in Changes do
        Strs.Add(Change.Name+': '+Change.Backup.ToString+' -> '+Change.Original.ToString);
      ShowMessage(Strs.Text);
    finally
      Strs.Free;
    end;
  finally
    Changes.Free;
  end;
end;

procedure TfrmChangeTest.butPopulateClick(Sender: TObject);
begin
  fPerson.Age       := 29;
  fPerson.FamName   := 'Doe';
  fPerson.PerName   := 'John';
  fPerson.fCounter  := fRefCounter;
  fPerson.Notes.Text:= 'Some notes about this person.';
  fPerson.Address.Street  := '1 Main Road';
  fPerson.Address.Suburb  := 'Suburbia';
  ShowPerson;
end;

procedure TfrmChangeTest.butRedoClick(Sender: TObject);
begin
  if IsVersions then
    TMementoVersions(fMemento).Redo;
  ShowPerson;
end;

procedure TfrmChangeTest.butRestoreClick(Sender: TObject);
begin
  fMemento.Restore;
  ShowPerson;
end;

procedure TfrmChangeTest.butToggleClick(Sender: TObject);
begin
  //  Choose between TVersionsFields and TBackupFields
  butToggle.Tag := integer(not Boolean(butToggle.Tag));
  EnableControls;
end;

procedure TfrmChangeTest.butUndoClick(Sender: TObject);
begin
  if IsVersions then
    TMementoVersions(fMemento).Undo;
  ShowPerson;
end;

procedure TfrmChangeTest.chkCounterChange(Sender: TObject);
begin
  if chkCounter.IsChecked then
    fPerson.Counter := fRefCounter
  else
    fPerson.Counter := nil;
  ShowPerson;
end;

procedure TfrmChangeTest.edAgeExit(Sender: TObject);
begin
  if Assigned(fPerson) then
    fPerson.Age := Trunc(edAge.Value);
end;

procedure TfrmChangeTest.edFamNameExit(Sender: TObject);
begin
  if Assigned(fPerson) then
    fPerson.FamName := edFamName.Text;
end;

procedure TfrmChangeTest.edNotesExit(Sender: TObject);
begin
  fPerson.Notes.Assign(edNotes.Lines);
end;

procedure TfrmChangeTest.edPerNameExit(Sender: TObject);
begin
  if Assigned(fPerson) then
    fPerson.PerName := edPerName.Text;
end;

procedure TfrmChangeTest.edStreetExit(Sender: TObject);
begin
  fPerson.Address.Street  := edStreet.Text;
end;

procedure TfrmChangeTest.edSuburbExit(Sender: TObject);
begin
  fPerson.Address.Suburb  := edSuburb.Text;
end;

procedure TfrmChangeTest.EnableControls;
var
  i: integer;
begin
  //  Optionally visible
  labVersion.Visible  := IsVersions;
  edVersion.Visible   := IsVersions;
  butUndo.Visible     := IsVersions;
  butRedo.Visible     := IsVersions;
  //  Disable unavailable
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TButton then
      TControl(Components[i]).Enabled := Assigned(fMemento);
  panButtons.Enabled  := True;
  butToggle.Enabled   := not Assigned(fMemento);
  butCreate.Enabled   := not Assigned(fMemento);
  //  Other
  if  IsVersions  then
    butToggle.Text    := 'Versions'
  else
    butToggle.Text    := 'Backup'
end;

procedure TfrmChangeTest.FormCreate(Sender: TObject);
begin
  fRefCounter   := TRefCounter.Create;
  fPerson       := TPerson.Create;
  EnableControls;
  ShowPerson;
end;

procedure TfrmChangeTest.FormDestroy(Sender: TObject);
begin
  fPerson.Free;
end;

function TfrmChangeTest.IsVersions: Boolean;
begin
  Result  := Boolean(butToggle.Tag)
end;

procedure TfrmChangeTest.ShowPerson;
var
  Versioned: TMementoVersions;
begin
  edVersion.Enabled   := Assigned(fPerson);
  edAge.Enabled       := Assigned(fPerson);
  edFamName.Enabled   := Assigned(fPerson);
  edPerName.Enabled   := Assigned(fPerson);
  chkCounter.Enabled  := Assigned(fPerson);
  if Assigned(fPerson) then
    begin
      if IsVersions then
        if not Assigned(fMemento) then
          edVersion.Text := ''
        else
          begin
            Versioned := TMementoVersions(fMemento);
            edVersion.Text := Versioned.VersionNow.ToString + '/' + Versioned.VersionMax.ToString;
          end;
      edAge.Text            := fPerson.Age.ToString;
      edFamName.Text        := fPerson.FamName;
      edPerName.Text        := fPerson.PerName;
      chkCounter.IsChecked  := Assigned(fPerson.Counter);
      edNotes.Lines.Text    := fPerson.Notes.Text;
      edStreet.Text         := fPerson.Address.Street;
      edSuburb.Text         := fPerson.Address.Suburb;
    end
  else
    begin
      edVersion.Text        := '';
      edAge.Text            := '';
      edFamName.Text        := '';
      edPerName.Text        := '';
      chkCounter.IsChecked  := False;
      edNotes.Lines.Text    := '';
      edStreet.Text         := '';
      edSuburb.Text         := '';
    end;
  edRefCounter.Text := fRefCounter.Count.ToString
end;

end.
