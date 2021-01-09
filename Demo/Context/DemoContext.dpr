program DemoContext;

uses
  System.StartUpCopy,
  FMX.Forms,
  FContextDemo in 'FContextDemo.pas' {frmContextDemo},
  uContextSystem in 'uContextSystem.pas',
  uContextObject in 'uContextObject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmContextDemo, frmContextDemo);
  Application.Run;
end.
