program DemoEditors;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoEditors in 'FDemoEditors.pas' {frmDemoEditors};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoEditors, frmDemoEditors);
  Application.Run;
end.
