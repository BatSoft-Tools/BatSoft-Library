program Demo_of_Patterns_Using_BatSoft_Library;



uses
  System.StartUpCopy,
  FMX.Forms,
  FMain in 'FMain.pas' {frmMain},
  uPersonStore in 'uPersonStore.pas',
  FrPerson in 'FrPerson.pas' {framePerson: TFrame},
  FPerson in 'FPerson.pas' {frmPerson},
  FPersonListItems in 'FPersonListItems.pas' {frmPersonListItems},
  FrPeople in 'FrPeople.pas' {framePeople: TFrame},
  BatSoft.Factories in '..\..\BatLibrary\BatSoft.Factories.pas',
  uPerson in 'uPerson.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPerson, frmPerson);
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPersonListItems, frmPersonListItems);
  Application.Run;
end.
