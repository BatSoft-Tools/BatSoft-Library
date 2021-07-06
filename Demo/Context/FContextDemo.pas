unit FContextDemo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, BatSoft.Context,
  FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Layouts;

type
  TfrmContextDemo = class(TForm)
    butGetValue: TButton;
    memMacro: TMemo;
    butRunMacro: TButton;
    lstMacros: TListBox;
    panMacros: TGroupBox;
    Layout1: TLayout;
    panNameValues: TGroupBox;
    lstNameValues: TListBox;
    Splitter1: TSplitter;
    panMacro: TGroupBox;
    FlowLayout1: TFlowLayout;
    chkSystemValues: TCheckBox;
    chkForm: TCheckBox;
    procedure butGetValueClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure butRunMacroClick(Sender: TObject);
    procedure lstMacrosDblClick(Sender: TObject);
    procedure lstNameValuesDblClick(Sender: TObject);
    procedure ContextChange(Sender: TObject);
  private
    fContextValues: TContextValues;
    fContext: IContext;
    procedure ShowContextNames;
  end;

var
  frmContextDemo: TfrmContextDemo;

implementation

{$R *.fmx}

uses
  System.Rtti, System.TypInfo, System.Generics.Collections,
  uContextObject, uContextSystem, uMacro, uMacroCommands;

{ TfrmContextDemo }

procedure TfrmContextDemo.butGetValueClick(Sender: TObject);
var
  Name: string;
  Value: TValue;
  ValueAsStr: string;
begin
  if  lstNameValues.ItemIndex < 0 then
    Exit;
  Name  := lstNameValues.Items[lstNameValues.ItemIndex];
  Value := fContext.GetValue(Name);
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
    tkEnumeration :
      ValueAsStr  := GetEnumName(Value.TypeInfo, Value.AsOrdinal);
    tkSet :
      ValueAsStr  := GetSetElementName(Value.TypeInfo, Value.AsOrdinal);
  else
      ValueAsStr  := 'Unhandled type';
  //  tkUnknown, tkClass, tkMethod, tkArray, tkRecord,
  //  tkInterface, tkDynArray, tkPointer, tkProcedure, tkMRecord
  end;
  ShowMessage(ValueAsStr);
end;

procedure TfrmContextDemo.butRunMacroClick(Sender: TObject);
begin
  Macros.Run(memMacro.Lines, fContext);
  ShowContextNames;
end;

procedure TfrmContextDemo.ContextChange(Sender: TObject);
var
  List: TList<IContext>;
begin
  //  Create a new selection of contexts
  List  := TList<IContext>.Create;
  try
    List.Add(fContextValues);
    if  chkSystemValues.IsChecked then
      List.Add(TContextSystem.Create);
    if  chkForm.IsChecked then
      List.Add(TContextObject.Create(Self, 'frm_'));
    fContext  := TContexts.Create(List.ToArray);
  finally
    List.Free;
  end;
  //  Show the available names
  ShowContextNames;
end;

procedure TfrmContextDemo.FormCreate(Sender: TObject);
begin
  //  Macros
  RegisterCommands;
  Macros.ListCommands(lstMacros.Items);
  //  Context
  fContextValues  := TContextValues.Create;
  ContextChange(nil);
end;

procedure TfrmContextDemo.lstMacrosDblClick(Sender: TObject);
begin
  if  lstMacros.ItemIndex >= 0  then
    begin
      memMacro.Lines.Insert(memMacro.CaretPosition.Line + 1, lstMacros.Items[lstMacros.ItemIndex] + ' ');
      memMacro.CaretPosition.IncrementLine;
      memMacro.GoToLineEnd;
    end;
end;

procedure TfrmContextDemo.lstNameValuesDblClick(Sender: TObject);
var
  Line: string;
begin
  if  lstNameValues.ItemIndex >= 0  then
    begin
      Line  := memMacro.Lines[memMacro.CaretPosition.Line];
      Line  := Line.Insert(memMacro.CaretPosition.Pos, '<' + lstNameValues.Items[lstNameValues.ItemIndex] + '>');
      memMacro.Lines[memMacro.CaretPosition.Line] := Line;
    end;
end;

procedure TfrmContextDemo.ShowContextNames;
begin
  lstNameValues.Items.Clear;
  fContext.GetNames(lstNameValues.Items);
end;

end.
