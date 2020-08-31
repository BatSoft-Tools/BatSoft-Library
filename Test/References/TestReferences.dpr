program TestReferences;

uses
  System.StartUpCopy,
  FMX.Forms,
  FTestReferences in 'FTestReferences.pas' {frmTestReferences},
  BatSoft.References in '..\..\BatLibrary\BatSoft.References.pas',
  FTestBinaryList in 'FTestBinaryList.pas' {frmTestBinaryList},
  BatSoft.Classes in '..\..\BatLibrary\BatSoft.Classes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTestBinaryList, frmTestBinaryList);
  Application.CreateForm(TfrmTestReferences, frmTestReferences);
  Application.Run;
end.
