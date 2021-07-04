program DemoInterfaces;

uses
  System.StartUpCopy,
  FMX.Forms,
  FInterfaces in 'FInterfaces.pas' {frmInterfaces},
  uModule in 'uModule.pas',
  uModuleAlpha in 'uModuleAlpha.pas',
  uModuleBeta in 'uModuleBeta.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmInterfaces, frmInterfaces);
  Application.Run;
end.
