unit FExample3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.Layouts, BatSoft.Spinners, uEmployment;

type
  TfrmExample3 = class(TForm)
    loDifferent: TLayout;
    Layout4: TLayout;
    edDifferentHeight: TSpinBox;
    Label6: TLabel;
    edDifferentItemIndex: TSpinBox;
    Label8: TLabel;
    butJumpTo: TButton;
    chkScrollbar: TCheckBox;
    lstDifferent: TListSpinner;
    Memo3: TMemo;
    procedure edDifferentHeightChange(Sender: TObject);
    procedure edDifferentItemIndexChange(Sender: TObject);
    procedure butJumpToClick(Sender: TObject);
    procedure chkScrollbarChange(Sender: TObject);
    function lstDifferentGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstDifferentGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fEmployments: TEmploymentList;
  end;

var
  frmExample3: TfrmExample3;

implementation

{$R *.fmx}

uses
  FItemControls;

{ TfrmExample3 }

procedure TfrmExample3.butJumpToClick(Sender: TObject);
begin
  lstDifferent.JumpTo(lstDifferent.ItemIndex, TTextAlign.Center);
end;

procedure TfrmExample3.chkScrollbarChange(Sender: TObject);
begin
  lstDifferent.ShowScrollbar := chkScrollbar.IsChecked
end;

procedure TfrmExample3.edDifferentHeightChange(Sender: TObject);
begin
  lstDifferent.ItemHeight := Trunc(edDifferentHeight.Value);
end;

procedure TfrmExample3.edDifferentItemIndexChange(Sender: TObject);
begin
  lstDifferent.ItemIndex  := Trunc(edDifferentItemIndex.Value);
end;

procedure TfrmExample3.FormCreate(Sender: TObject);
begin
  //  Create some demo data
  fEmployments  := TEmploymentList.Create;
  fEmployments.Populate(100);
  lstDifferent.ItemCount  := fEmployments.Count;
end;

procedure TfrmExample3.FormDestroy(Sender: TObject);
begin
  fEmployments.Free;
end;

function TfrmExample3.lstDifferentGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
var
  Emp: TEmployment;
begin
  if  (Index < 0) or (fEmployments.Count <= Index)  then
    Exit(nil);
  //  Obtain the object
  Emp := fEmployments[Index] as TEmployment;
  //  Show the correct frame, and populate it
  Result  := nil;
  if  Emp is TContract  then
    begin
      Result  := frmItemControls.frameEmpContractEdit;
      frmItemControls.frameEmpContractEdit.Contract   := Emp as TContract;
    end;
  if  Emp is TFullTime  then
    begin
      Result  := frmItemControls.frameEmpFullTimeEdit;
      frmItemControls.frameEmpFullTimeEdit.FullTime   := Emp as TFullTime;
    end;
  if  Emp is TPartTime  then
    begin
      Result  := frmItemControls.frameEmpPartTimeEdit;
      frmItemControls.frameEmpPartTimeEdit.PartTime   := Emp as TPartTime;
    end;
  //  Never mind this.  This is only for the demo.
  edDifferentItemIndex.Value  := Index;
end;

function TfrmExample3.lstDifferentGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
var
  Emp: TEmployment;
begin
  if  (Index < 0) or (fEmployments.Count <= Index)  then
    Exit(nil);
  //  Obtain the object
  Emp := fEmployments[Index] as TEmployment;
  //  Show the correct frame, and populate it
  Result  := nil;
  if  Emp is TContract  then
    begin
      Result  := frmItemControls.frameEmpContractShow;
      frmItemControls.frameEmpContractShow.Contract   := Emp as TContract;
    end;
  if  Emp is TFullTime  then
    begin
      Result  := frmItemControls.frameEmpFullTimeShow;
      frmItemControls.frameEmpFullTimeShow.FullTime   := Emp as TFullTime;
    end;
  if  Emp is TPartTime  then
    begin
      Result  := frmItemControls.frameEmpPartTimeShow;
      frmItemControls.frameEmpPartTimeShow.PartTime   := Emp as TPartTime;
    end;
end;

end.
