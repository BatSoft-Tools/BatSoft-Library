program BatSoftTranslatorEditor;

uses
  System.StartUpCopy,
  FMX.Forms,
  FTranslator in 'FTranslator.pas' {frmTranslator},
  FrEditor in 'FrEditor.pas' {frameEditor: TFrame},
  FEditor in 'FEditor.pas' {frmEditor};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTranslator, frmTranslator);
  Application.Run;
end.
