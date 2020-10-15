program TestControls;

uses
  System.StartUpCopy,
  FMX.Forms,
  FTestSpinners in 'FTestSpinners.pas' {frmTestSpinners},
  Bat.Spinners in '..\..\BatControls\Bat.Spinners.pas',
  FListControls in 'FListControls.pas' {frmListControls},
  FrComplexListItem in 'FrComplexListItem.pas' {frameComplexListItem: TFrame},
  BatSoft.Mementos in '..\..\BatLibrary\BatSoft.Mementos.pas',
  FTestPaint in 'FTestPaint.pas' {frmTestPaint},
  FTestPaintControls in 'FTestPaintControls.pas' {frmTestPaintControls};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTestSpinners, frmTestSpinners);
  Application.CreateForm(TfrmTestPaint, frmTestPaint);
  Application.CreateForm(TfrmListControls, frmListControls);
  Application.CreateForm(TfrmTestPaintControls, frmTestPaintControls);
  Application.Run;
end.
