unit FDemoMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TfrmDemoMain = class(TForm)
    butSave: TButton;
    butLoad: TButton;
    butOpenForms: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure butSaveClick(Sender: TObject);
    procedure butLoadClick(Sender: TObject);
    procedure butOpenFormsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDemoMain: TfrmDemoMain;

implementation

{$R *.fmx}

uses
  BatSoft.Translator, FDemoFormA, FDemoFormB;

{ TfrmDemoMain }

procedure TfrmDemoMain.butLoadClick(Sender: TObject);
begin
  if  OpenDialog.Execute  then
    begin
      //  Load translation library
      Translation.Load(OpenDialog.FileName);
      //  Apply to forms
      Translation.ApplyTo(frmDemoMain);
      Translation.ApplyTo(frmDemoA);
      Translation.ApplyTo(frmDemoB);
    end;
end;

procedure TfrmDemoMain.butOpenFormsClick(Sender: TObject);
begin
  frmDemoA.Show;
  frmDemoB.Show;
end;

procedure TfrmDemoMain.butSaveClick(Sender: TObject);
const
  PropertyNames = 'Text,Caption,Items';
begin
  if  SaveDialog.Execute  then
    begin
      //  Build translation library.  (Don't worry about frames.)
      Translation.AddWords(frmDemoMain, PropertyNames);
      Translation.AddWords(frmDemoA,    PropertyNames);
      Translation.AddWords(frmDemoB,    PropertyNames);
      //  Save the library to file
      Translation.Save(SaveDialog.FileName);
    end;
end;

end.
