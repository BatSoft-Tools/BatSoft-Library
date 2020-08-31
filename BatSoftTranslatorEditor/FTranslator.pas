unit FTranslator;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FEditor,
  FrEditor, FMX.Menus, FMX.Layouts;

type
  TfrmTranslator = class(TForm)
    layEditors: TLayout;
    MainMenu: TMainMenu;
    miOpen: TMenuItem;
    OpenDialog: TOpenDialog;
    procedure miOpenClick(Sender: TObject);
  end;

var
  frmTranslator: TfrmTranslator;

implementation

{$R *.fmx}

{ TfrmTranslator }

procedure TfrmTranslator.miOpenClick(Sender: TObject);
var
  Form: TfrmEditor;
begin
  if  OpenDialog.Execute  then
    begin
      Form  := TfrmEditor.Create(Self);
      Form.Parent := Self;
      Form.frameEditor.FileFull := OpenDialog.FileName;
      Form.Show;
    end;
end;

end.
