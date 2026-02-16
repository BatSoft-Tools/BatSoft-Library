program DemoEditors;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoEditors in 'FDemoEditors.pas' {frmDemoEditors},
  BatSoft.Editors in '..\..\BatControlsFMX\BatSoft.Editors.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoEditors, frmDemoEditors);
  Application.Run;
end.
