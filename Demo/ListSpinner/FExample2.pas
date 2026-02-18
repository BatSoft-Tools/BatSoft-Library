unit FExample2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, BatSoft.Spinners, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Layouts;

type
  TfrmExample2 = class(TForm)
    loWritable: TLayout;
    Layout2: TLayout;
    edWritableCount: TSpinBox;
    Label3: TLabel;
    edWritableHeight: TSpinBox;
    Label4: TLabel;
    edWritableItemIndex: TSpinBox;
    Label7: TLabel;
    lstWritable: TListSpinner;
    memDescription: TMemo;
    labDisplayOnly: TLabel;
    edEditable: TEdit;
    labComment1: TLabel;
    labComment2: TLabel;
    procedure edWritableCountChange(Sender: TObject);
    procedure edWritableHeightChange(Sender: TObject);
    procedure edWritableItemIndexChange(Sender: TObject);
    function lstWritableGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstWritableGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    procedure FormCreate(Sender: TObject);
  end;

var
  frmExample2: TfrmExample2;

implementation

{$R *.fmx}

{ TfrmExample2 }

procedure TfrmExample2.edWritableCountChange(Sender: TObject);
begin
  lstWritable.ItemCount   := Trunc(edWritableCount.Value);
end;

procedure TfrmExample2.edWritableHeightChange(Sender: TObject);
begin
  lstWritable.ItemHeight  := Trunc(edWritableHeight.Value);
end;

procedure TfrmExample2.edWritableItemIndexChange(Sender: TObject);
begin
  lstWritable.ItemIndex   := Trunc(edWritableItemIndex.Value);
end;

procedure TfrmExample2.FormCreate(Sender: TObject);
begin
  labComment1.Visible     := False;
  labComment2.Visible     := False;
  labDisplayOnly.Visible  := False;
  edEditable.Visible      := False;
end;

function TfrmExample2.lstWritableGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  //  This is what we will use to edit
  Result  := edEditable;
  //  Populate it
  edEditable.Text  := 'Editable ' + Index.ToString;
  //  Never mind this.  This is only for the demo.
  edWritableItemIndex.Value := Index;
end;

function TfrmExample2.lstWritableGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  //  This is what we will use to display
  Result  := labDisplayOnly;
  //  Populate it
  labDisplayOnly.Text := 'Display ' + Index.ToString;
end;

end.
