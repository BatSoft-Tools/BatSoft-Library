program DemoListSpinner;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoListSpinner in 'FDemoListSpinner.pas' {frmDemoListSpinner},
  FItemControls in 'FItemControls.pas' {frmItemControls},
  FrEmpContract in 'FrEmpContract.pas' {frameEmpContract: TFrame},
  uEmployment in 'uEmployment.pas',
  FrEmpPartTime in 'FrEmpPartTime.pas' {frameEmpPartTime: TFrame},
  FrEmpFullTime in 'FrEmpFullTime.pas' {frameEmpFullTime: TFrame},
  FExample1 in 'FExample1.pas' {frmExample1},
  FExample2 in 'FExample2.pas' {frmExample2},
  FExample3 in 'FExample3.pas' {frmExample3};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoListSpinner, frmDemoListSpinner);
  Application.CreateForm(TfrmItemControls, frmItemControls);
  Application.CreateForm(TfrmExample1, frmExample1);
  Application.CreateForm(TfrmExample2, frmExample2);
  Application.CreateForm(TfrmExample3, frmExample3);
  Application.Run;
end.
