unit FDemoListSpinner;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, Bat.Spinners, FMX.Edit, FMX.EditBox,
  FMX.SpinBox, FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, uEmployment;

type
  TfrmDemoListSpinner = class(TForm)
    lstROEditors: TListSpinner;
    loROEditors: TLayout;
    loEditorsControls: TLayout;
    edROEditorsCount: TSpinBox;
    Label1: TLabel;
    edROEditorsHeight: TSpinBox;
    Label2: TLabel;
    Memo1: TMemo;
    Splitter1: TSplitter;
    loWritable: TLayout;
    Layout2: TLayout;
    edWritableCount: TSpinBox;
    Label3: TLabel;
    edWritableHeight: TSpinBox;
    Label4: TLabel;
    lstWritable: TListSpinner;
    Memo2: TMemo;
    loDifferent: TLayout;
    Layout4: TLayout;
    edDifferentHeight: TSpinBox;
    Label6: TLabel;
    lstDifferent: TListSpinner;
    Memo3: TMemo;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    edWritableItemIndex: TSpinBox;
    Label7: TLabel;
    edDifferentItemIndex: TSpinBox;
    Label8: TLabel;
    butJumpTo: TButton;
    chkScrollbar: TCheckBox;
    CheckBox1: TCheckBox;
    procedure edCountChange(Sender: TObject);
    procedure edHeightChange(Sender: TObject);
    procedure edItemIndexChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    function lstDifferentGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstROEditorsGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstWritableGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstWritableGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
    function lstDifferentGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
    procedure butJumpToClick(Sender: TObject);
    procedure chkScrollbarChange(Sender: TObject);
  private
    fEmployments: TEmploymentList;
    function AssociatedListSpinner(Sender: TObject): TListSpinner;
  end;

var
  frmDemoListSpinner: TfrmDemoListSpinner;

implementation

{$R *.fmx}

uses
  FItemControls;

{ TfrmDemoListSpinner }

function TfrmDemoListSpinner.AssociatedListSpinner(Sender: TObject): TListSpinner;
var
  Layout: TLayout;
  i: integer;
begin
  Layout  := TControl(Sender).Parent.Parent as TLayout;
  for i := 0 to Layout.ChildrenCount - 1 do
    if  Layout.Children[i] is TListSpinner  then
      Exit(Layout.Children[i] as TListSpinner);
  raise Exception.Create('Didn''t find the list spinner.');
end;

procedure TfrmDemoListSpinner.butJumpToClick(Sender: TObject);
var
  Spinner: TListSpinner;
begin
  Spinner := AssociatedListSpinner(Sender);
  Spinner.JumpTo(Spinner.ItemIndex);
end;

procedure TfrmDemoListSpinner.chkScrollbarChange(Sender: TObject);
begin
  AssociatedListSpinner(Sender).ShowScrollbar := TCheckBox(Sender).IsChecked
end;

procedure TfrmDemoListSpinner.edCountChange(Sender: TObject);
begin
  AssociatedListSpinner(Sender).ItemCount   := Trunc(TSpinBox(Sender).Value);
end;

procedure TfrmDemoListSpinner.edHeightChange(Sender: TObject);
begin
  AssociatedListSpinner(Sender).ItemHeight  := Trunc(TSpinBox(Sender).Value);
end;

procedure TfrmDemoListSpinner.edItemIndexChange(Sender: TObject);
begin
  AssociatedListSpinner(Sender).ItemIndex   := Trunc(TSpinBox(Sender).Value);
end;

procedure TfrmDemoListSpinner.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  //  The WordWrap property really ought to be published
  for i := 0 to ComponentCount - 1 do
    if  Components[i] is TMemo then
      (Components[i] as TMemo).WordWrap := True;
  //  Create some demo data
  fEmployments  := TEmploymentList.Create;
  fEmployments.Populate(100);
  lstDifferent.ItemCount  := fEmployments.Count;
end;

procedure TfrmDemoListSpinner.FormDestroy(Sender: TObject);
begin
  fEmployments.Free;
end;

function TfrmDemoListSpinner.lstDifferentGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
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

function TfrmDemoListSpinner.lstDifferentGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
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

function TfrmDemoListSpinner.lstROEditorsGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := frmItemControls.edDisplayOnly;
  frmItemControls.edDisplayOnly.Text  := 'Display ' + Index.ToString;
end;

function TfrmDemoListSpinner.lstWritableGetEditItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := frmItemControls.edEditable;
  frmItemControls.edEditable.Text  := 'Editable ' + Index.ToString;
  //  Never mind this.  This is only for the demo.
  edWritableItemIndex.Value := Index;
end;

function TfrmDemoListSpinner.lstWritableGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := frmItemControls.labDisplayOnly;
  frmItemControls.labDisplayOnly.Text := 'Display ' + Index.ToString;
end;

end.
