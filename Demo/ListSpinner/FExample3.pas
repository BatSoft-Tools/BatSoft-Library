unit FExample3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.Layouts, BatSoft.Spinners, uEmployment;

const
  NumberOfItemsInList = 100;

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
    memDescription: TMemo;
    labComment1: TLabel;
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
    procedure SetLabelText(const Parent: TComponent; const Text: string);
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
  lstDifferent.JumpTo(Round(edDifferentItemIndex.Value), TTextAlign.Center);
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
  memDescription.Lines.Append('This list has ' + NumberOfItemsInList.ToString + ' items.');
  labComment1.Visible     := False;
  //  Create some demo data
  fEmployments  := TEmploymentList.Create;
  fEmployments.Populate(NumberOfItemsInList);
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
  //  (Disclaimer: In production code I *never* write unmaintainable code like this.)
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
  SetLabelText(Result, Index.ToString);
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
  //  (Disclaimer: In production code I *never* write unmaintainable code like this.)
  Result  := nil;
  if  Emp is TContract  then
    begin
      Result  := frmItemControls.frameEmpContractShow;
      frmItemControls.frameEmpContractShow.Contract       := Emp as TContract;
    end;
  if  Emp is TFullTime  then
    begin
      Result  := frmItemControls.frameEmpFullTimeShow;
      frmItemControls.frameEmpFullTimeShow.FullTime       := Emp as TFullTime;
    end;
  if  Emp is TPartTime  then
    begin
      Result  := frmItemControls.frameEmpPartTimeShow;
      frmItemControls.frameEmpPartTimeShow.PartTime       := Emp as TPartTime;
    end;
  //  Never mind this.  This is only for the demo.
  SetLabelText(Result, Index.ToString);
end;

procedure TfrmExample3.SetLabelText(const Parent: TComponent; const Text: string);
var
  i: Integer;
begin
  if  Assigned(Parent)  then
    for i := 0 to Parent.ComponentCount - 1 do
      if SameText('labIndex', Parent.Components[i].Name) then
        begin
          (Parent.Components[i] as TLabel).Text := Text;
          break;
        end;
end;

end.
