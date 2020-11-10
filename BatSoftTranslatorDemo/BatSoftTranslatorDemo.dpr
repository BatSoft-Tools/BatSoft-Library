program BatSoftTranslatorDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  FDemoMain in 'FDemoMain.pas' {frmDemoMain},
  FrDemoFrame in 'FrDemoFrame.pas' {frameDemo: TFrame},
  FDemoFormA in 'FDemoFormA.pas' {frmDemoA},
  FDemoFormB in 'FDemoFormB.pas' {frmDemoB};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoMain, frmDemoMain);
  Application.CreateForm(TfrmDemoA, frmDemoA);
  Application.CreateForm(TfrmDemoB, frmDemoB);
  Application.Run;
end.
