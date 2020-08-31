unit FTestBinaryList;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, BatSoft.Classes, FMX.EditBox, FMX.SpinBox;

type
  TfrmTestBinaryList = class(TForm)
    butAdd: TButton;
    grpDuplicates: TGroupBox;
    chkIgnore: TRadioButton;
    chkAccept: TRadioButton;
    chkError: TRadioButton;
    edValue: TEdit;
    memValues: TMemo;
    butDelete: TButton;
    butIndexOf: TButton;
    butRemove: TButton;
    edIndex: TSpinBox;
    butClear: TButton;
    butPopulate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure butAddClick(Sender: TObject);
    procedure butRemoveClick(Sender: TObject);
    procedure butDeleteClick(Sender: TObject);
    procedure butIndexOfClick(Sender: TObject);
    procedure butClearClick(Sender: TObject);
    procedure butPopulateClick(Sender: TObject);
    procedure chkChange(Sender: TObject);
  private
    fList: TBinaryList<string>;
    procedure PopulateForm;
  end;

var
  frmTestBinaryList: TfrmTestBinaryList;

implementation

{$R *.fmx}

{ TfrmTestBinaryList }

procedure TfrmTestBinaryList.butAddClick(Sender: TObject);
begin
  fList.Add(edValue.Text);
  PopulateForm;
end;

procedure TfrmTestBinaryList.butClearClick(Sender: TObject);
begin
  fList.Clear;
  PopulateForm;
end;

procedure TfrmTestBinaryList.butDeleteClick(Sender: TObject);
begin
  fList.Delete(Trunc(edIndex.Value));
  PopulateForm;
end;

procedure TfrmTestBinaryList.butIndexOfClick(Sender: TObject);
begin
  edIndex.Value := fList.IndexOf(edValue.Text);
  PopulateForm;
end;

procedure TfrmTestBinaryList.butPopulateClick(Sender: TObject);
begin
  fList.Prepopulate('100');
  fList.Prepopulate('200');
  fList.Prepopulate('300');
  fList.Prepopulate('400');
  fList.Prepopulate('500');
  fList.Prepopulate('600');
  fList.Prepopulate('700');
  PopulateForm;
end;

procedure TfrmTestBinaryList.butRemoveClick(Sender: TObject);
begin
  fList.Remove(edValue.Text);
  PopulateForm;
end;

procedure TfrmTestBinaryList.chkChange(Sender: TObject);
var
  Radio: TRadioButton absolute Sender;
begin
  if Radio.IsChecked then
    fList.Duplicates  := TDuplicates(Radio.Tag);
end;

procedure TfrmTestBinaryList.FormCreate(Sender: TObject);
begin
  fList := TBinaryList<string>.Create;
  PopulateForm;
end;

procedure TfrmTestBinaryList.FormDestroy(Sender: TObject);
begin
  fList.Free;
end;

procedure TfrmTestBinaryList.PopulateForm;
var
  Value: string;
begin
  //  Duplicates
  case fList.Duplicates of
    dupIgnore : chkIgnore.IsChecked := True;
    dupAccept : chkAccept.IsChecked := True;
    dupError :  chkError.IsChecked  := True;
  end;
  //  Data
  memValues.BeginUpdate;
  try
    memValues.Lines.Clear;
    for Value in fList do
      memValues.Lines.Add(Value);
  finally
    memValues.EndUpdate;
  end;
end;

end.
