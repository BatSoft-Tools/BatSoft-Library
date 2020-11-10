program DemoSettings;

uses
  System.StartUpCopy,
  FMX.Forms,
  uDemoSettings in 'uDemoSettings.pas',
  FDemoSettings in 'FDemoSettings.pas' {frmDemoSettings},
  FEditUser in 'FEditUser.pas' {frmEditUser};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoSettings, frmDemoSettings);
  Application.Run;
end.
