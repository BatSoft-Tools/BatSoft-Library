program DemoListSpinner;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoListSpinner in 'FDemoListSpinner.pas' {frmDemoListSpinner},
  FItemControls in 'FItemControls.pas' {frmItemControls},
  FrEmpContract in 'FrEmpContract.pas' {frameEmpContract: TFrame},
  uEmployment in 'uEmployment.pas',
  FrEmpPartTime in 'FrEmpPartTime.pas' {frameEmpPartTime: TFrame},
  FrEmpFullTime in 'FrEmpFullTime.pas' {frameEmpFullTime: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoListSpinner, frmDemoListSpinner);
  Application.CreateForm(TfrmItemControls, frmItemControls);
  Application.Run;
end.
