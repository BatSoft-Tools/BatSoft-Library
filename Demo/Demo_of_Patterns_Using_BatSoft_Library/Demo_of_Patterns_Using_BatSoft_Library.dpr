program Demo_of_Patterns_Using_BatSoft_Library;



uses
  System.StartUpCopy,
  FMX.Forms,
  FMain in 'FMain.pas' {frmMain},
  uPersonStore in 'uPersonStore.pas',
  uPerson in 'uPerson.pas',
  FrPerson in 'FrPerson.pas' {framePerson: TFrame},
  FPerson in 'FPerson.pas' {frmPerson},
  FPersonListItems in 'FPersonListItems.pas' {frmPersonListItems},
  FrPeople in 'FrPeople.pas' {framePeople: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPerson, frmPerson);
  Application.CreateForm(TfrmPersonListItems, frmPersonListItems);
  Application.Run;
end.
