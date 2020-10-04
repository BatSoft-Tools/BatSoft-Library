program DemoSettings;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoSettings in 'FDemoSettings.pas' {frmDemoSettings},
  uDemoSettings in 'uDemoSettings.pas',
  BatSoft.Settings in '..\..\BatLibrary\BatSoft.Settings.pas',
  BatSoft.Settings.Ini in '..\..\BatLibrary\BatSoft.Settings.Ini.pas',
  BatSoft.Classes in '..\..\BatLibrary\BatSoft.Classes.pas',
  BatSoft.Settings.JSON in '..\..\BatLibrary\BatSoft.Settings.JSON.pas',
  BatSoft.Settings.Types in '..\..\BatLibrary\BatSoft.Settings.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoSettings, frmDemoSettings);
  Application.Run;
end.
