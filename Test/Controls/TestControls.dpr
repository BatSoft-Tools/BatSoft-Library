program TestControls;

uses
  System.StartUpCopy,
  FMX.Forms,
  FTestSpinners in 'FTestSpinners.pas' {frmTestSpinners},
  Bat.Spinners in '..\..\BatControls\Bat.Spinners.pas',
  FListControls in 'FListControls.pas' {frmListControls},
  FrComplexListItem in 'FrComplexListItem.pas' {frameComplexListItem: TFrame},
  BatSoft.Mementos in '..\..\BatLibrary\BatSoft.Mementos.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTestSpinners, frmTestSpinners);
  Application.CreateForm(TfrmListControls, frmListControls);
  Application.Run;
end.
