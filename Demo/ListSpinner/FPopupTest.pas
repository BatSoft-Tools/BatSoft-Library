unit FPopupTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, BatSoft.Popup, FMX.ListBox;

type
  TfrmPopupTest = class(TForm)
    butShow: TButton;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    butHide: TButton;
    ComboBox1: TComboBox;
    Popup1: TPopup;
    ImageControl1: TImageControl;
    butPopup: TButton;
    procedure butPopupClick(Sender: TObject);
  end;

var
  frmPopupTest: TfrmPopupTest;

implementation

{$R *.fmx}

{ TfrmPopupTest }

procedure TfrmPopupTest.butPopupClick(Sender: TObject);
begin
  ImageControl1.Parent  := Popup1;
  ImageControl1.Align   := TAlignLayout.Client;
  Popup1.Placement      := TPlacement.Bottom;
  Popup1.Popup()
end;

end.
