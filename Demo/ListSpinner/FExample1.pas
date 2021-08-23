unit FExample1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, BatSoft.Spinners, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Layouts;

type
  TfrmExample1 = class(TForm)
    loROEditors: TLayout;
    loEditorsControls: TLayout;
    edROEditorsCount: TSpinBox;
    Label1: TLabel;
    edROEditorsHeight: TSpinBox;
    Label2: TLabel;
    chkScrollbar: TCheckBox;
    lstROEditors: TListSpinner;
    Memo1: TMemo;
    edDisplayOnly: TEdit;
    labComment: TLabel;
    procedure edROEditorsCountChange(Sender: TObject);
    procedure edROEditorsHeightChange(Sender: TObject);
    procedure chkScrollbarChange(Sender: TObject);
    function lstROEditorsGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    procedure FormCreate(Sender: TObject);
  end;

var
  frmExample1: TfrmExample1;

implementation

{$R *.fmx}

{ TfrmExample1 }

procedure TfrmExample1.chkScrollbarChange(Sender: TObject);
begin
  lstROEditors.ShowScrollbar  := chkScrollbar.IsChecked
end;

procedure TfrmExample1.edROEditorsCountChange(Sender: TObject);
begin
  lstROEditors.ItemCount      := Trunc(edROEditorsCount.Value);
end;

procedure TfrmExample1.edROEditorsHeightChange(Sender: TObject);
begin
  lstROEditors.ItemHeight     := Trunc(edROEditorsHeight.Value);
end;

procedure TfrmExample1.FormCreate(Sender: TObject);
begin
  labComment.Visible    := False;
  edDisplayOnly.Visible := False;
end;

function TfrmExample1.lstROEditorsGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  //  This is what we will use to display
  Result  := edDisplayOnly;
  //  Populate it
  edDisplayOnly.Text  := 'Display ' + Index.ToString;
end;

end.
