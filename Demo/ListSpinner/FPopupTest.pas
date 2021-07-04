unit FPopupTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, BatSoft.Popup, FMX.ListBox, BatSoft.Spinners;

type
  TfrmPopupTest = class(TForm)
    butShow: TButton;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    butCreate: TButton;
    ComboBox1: TComboBox;
    Popup1: TPopup;
    ImageControl1: TImageControl;
    butPopup: TButton;
    Label1: TLabel;
    procedure butPopupClick(Sender: TObject);
    procedure butCreateClick(Sender: TObject);
    function GetShowItem(Sender: TListSpinner; Index: Integer): TControl;
  end;

var
  frmPopupTest: TfrmPopupTest;

implementation

{$R *.fmx}

{ TfrmPopupTest }

procedure TfrmPopupTest.butCreateClick(Sender: TObject);
var
  Combo: TComboSpinner;
begin
  Combo := TComboSpinner.Create(Self);
  Combo.Parent  := Self;
  Combo.ItemCount := 5;
  Combo.ItemIndex := 1;
  Combo.OnGetShowItem := GetShowItem;
end;

procedure TfrmPopupTest.butPopupClick(Sender: TObject);
begin
  ImageControl1.Parent  := Popup1;
  ImageControl1.Align   := TAlignLayout.Client;
  Popup1.Placement      := TPlacement.Bottom;
  Popup1.Popup()
end;

function TfrmPopupTest.GetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := Label1;
  Label1.Text  := 'Item ' + Index.ToString;
end;

end.
