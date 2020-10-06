program DemoSettings;

uses
  System.StartUpCopy,
  FMX.Forms,
  BatSoft.Settings in '..\..\BatLibrary\BatSoft.Settings.pas',
  BatSoft.Settings.Ini in '..\..\BatLibrary\BatSoft.Settings.Ini.pas',
  BatSoft.Classes in '..\..\BatLibrary\BatSoft.Classes.pas',
  BatSoft.Settings.JSON in '..\..\BatLibrary\BatSoft.Settings.JSON.pas',
  uDemoSettings in 'uDemoSettings.pas',
  FDemoSettings in 'FDemoSettings.pas' {frmDemoSettings},
  BatSoft.Settings.Types in '..\..\BatLibrary\BatSoft.Settings.Types.pas',
  FEditUser in 'FEditUser.pas' {frmEditUser};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoSettings, frmDemoSettings);
  Application.Run;
end.
