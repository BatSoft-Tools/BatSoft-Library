program Spinner;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  FSpinner in 'FSpinner.pas' {frmSpinner},
  uSpinner in 'uSpinner.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmSpinner, frmSpinner);
  Application.Run;
end.
