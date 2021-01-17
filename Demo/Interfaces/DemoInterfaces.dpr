program DemoInterfaces;

uses
  System.StartUpCopy,
  FMX.Forms,
  FInterfaces in 'FInterfaces.pas' {frmInterfaces},
  uModuleCoupling in 'uModuleCoupling.pas',
  uModuleAlpha in 'uModuleAlpha.pas',
  uModuleBeta in 'uModuleBeta.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmInterfaces, frmInterfaces);
  Application.Run;
end.
