program DemoMementos;

uses
  System.StartUpCopy,
  FMX.Forms,
  uRefCounter in 'uRefCounter.pas',
  FChangeTest in 'FChangeTest.pas' {frmChangeTest},
  BatSoft.Mementos in '..\..\BatLibrary\BatSoft.Mementos.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmChangeTest, frmChangeTest);
  Application.Run;
end.
