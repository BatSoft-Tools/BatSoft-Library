unit FContextDemo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, BatSoft.Context,
  FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit;

type
  TfrmContextDemo = class(TForm)
    butUpdateNames: TButton;
    cmbNames: TComboBox;
    butGetValue: TButton;
    edName: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure butUpdateNamesClick(Sender: TObject);
    procedure butGetValueClick(Sender: TObject);
    procedure cmbNamesChange(Sender: TObject);
    procedure edNameChange(Sender: TObject);
  private
    fContext: IContext;
  end;

var
  frmContextDemo: TfrmContextDemo;

implementation

{$R *.fmx}

uses
  System.Rtti, uContextObject, uContextSystem;

{ TfrmContextDemo }

procedure TfrmContextDemo.butGetValueClick(Sender: TObject);
var
  Value: TValue;
  ValueAsStr: string;
begin
  Value := fContext.GetValue(edName.Text);
  case Value.Kind of
    tkInteger :
      ValueAsStr  := Value.AsInteger.ToString;
    tkInt64 :
      ValueAsStr  := Value.AsInt64.ToString;
    tkFloat :
      ValueAsStr  := Value.AsExtended.ToString;
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString :
      ValueAsStr  := Value.AsString;
    tkVariant :
      ValueAsStr  := VarToStr(Value.AsVariant);
    tkClassRef :
      ValueAsStr  := Value.AsClass.ClassName;
  else
      ValueAsStr  := 'Unhandled type';
  //  tkUnknown, tkEnumeration, tkSet, tkClass, tkMethod, tkArray, tkRecord,
  //  tkInterface, tkDynArray, tkPointer, tkProcedure, tkMRecord
  end;
  ShowMessage(ValueAsStr);
end;

procedure TfrmContextDemo.butUpdateNamesClick(Sender: TObject);
var
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Names.Duplicates  := dupIgnore;
    Names.Sorted      := True;
    fContext.GetNames(Names);
    cmbNames.Items.Assign(Names);
  finally
    Names.Free;
  end;
end;

procedure TfrmContextDemo.cmbNamesChange(Sender: TObject);
begin
  if  cmbNames.ItemIndex >= 0 then
    edName.Text := cmbNames.Items[cmbNames.ItemIndex]
end;

procedure TfrmContextDemo.edNameChange(Sender: TObject);
begin
  cmbNames.ItemIndex  := cmbNames.Items.IndexOf(edName.Text)
end;

procedure TfrmContextDemo.FormCreate(Sender: TObject);
begin
  fContext  := TContexts.Create([TContextValues.Create, TContextSystem.Create])
end;

end.
