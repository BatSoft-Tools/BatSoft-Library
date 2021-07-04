program DemoVectorArt;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMain in 'FMain.pas' {frmMain},
  uShapes in 'uShapes.pas',
  uShapes.Simple in 'uShapes.Simple.pas',
  uShapes.Controls in 'uShapes.Controls.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
