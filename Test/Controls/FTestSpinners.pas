unit FTestSpinners;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, Bat.Spinners, FMX.Edit, FMX.Menus, FMX.EditBox,
  FMX.SpinBox, FMX.Objects;

type
  TfrmTestSpinners = class(TForm)
    ListSpinner1: TListSpinner;
    PopupMenu1: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    edItemCount: TSpinBox;
    Label1: TLabel;
    edItemHeight: TSpinBox;
    Label2: TLabel;
    edItemIndex: TSpinBox;
    Label3: TLabel;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    ListSpinner2: TListSpinner;
    butShowListControls: TButton;
    butCompare1: TButton;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    butCompare2: TButton;
    butCopy: TButton;
    butRestore: TButton;
    butChangeClass: TButton;
    function ListSpinner1ObtainItem(Sender: TListSpinner; Index: Integer): TControl;
    function ListSpinner1ItemIndexChange(Sender: TListSpinner; Index: Integer): TControl;
    procedure edItemCountChange(Sender: TObject);
    procedure edItemHeightChange(Sender: TObject);
    procedure edItemIndexChange(Sender: TObject);
    function ListSpinner2ObtainItem(Sender: TListSpinner; Index: Integer): TControl;
    procedure butShowListControlsClick(Sender: TObject);
    procedure butCompare1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure butCompare2Click(Sender: TObject);
    procedure butCopyClick(Sender: TObject);
    procedure butRestoreClick(Sender: TObject);
    procedure butChangeClassClick(Sender: TObject);
  private
    fCopy: TObject;
    function  CloneObject(const Obj: TObject; const Path: string): TObject;
  end;

var
  frmTestSpinners: TfrmTestSpinners;

implementation

{$R *.fmx}

uses
  RTTI, FListControls, BatSoft.Mementos, Delphi.Mocks.Helpers, FMX.Text;

var
  Ctx: TRttiContext;

type
  TInsideEdit = class(TPresentedControl)
  protected
    FButtonsContent: TContentEdit;
  end;

  TDudEdit = class(TEdit)
  protected
    procedure Paint; override;
  end;

{ TDudEdit }

procedure TDudEdit.Paint;
begin
end;

{ TfrmTestSpinners }

procedure TfrmTestSpinners.butChangeClassClick(Sender: TObject);
begin
  Pointer(Pointer(Edit1)^)  := Pointer(TDudEdit);
end;

procedure TfrmTestSpinners.butCompare1Click(Sender: TObject);
var
  Changes: TChanges;
  Msg: string;
  i: Integer;
begin
  Changes := TChanges.Create;
  try
    ListFieldChanges('', Edit1, frmListControls.Edit1, Changes);
    for i := 0 to Changes.Count - 1 do
      Msg := Msg + sLineBreak + Changes[i].Name;
    ShowMessage(Msg);
  finally
    Changes.Free;
  end;
end;

procedure TfrmTestSpinners.butCompare2Click(Sender: TObject);
var
  Changes: TStrings;

  function LooksLikeRecursion(const Prefix: string): Boolean;
  var
    Strs: TStringList;
    Str1, Str2: string;
    i: Integer;
  begin
    Result  := False;
    Strs  := TStringList.Create;
    try
      Strs.Delimiter  := '.';
      Strs.DelimitedText  := Prefix;
      if  Strs.Count < 4  then
        Exit;
      Str1  := Strs[Strs.Count - 2];
      Str2  := Strs[Strs.Count - 1];
      if  SameText(Str2, 'fInfo') then
        begin
          for i := Strs.Count - 2 downto 1 do
            if  (Strs[i] = Str2) then
              Exit(True)
        end
      else
        begin
          for i := Strs.Count - 2 downto 1 do
            if  (Strs[i] = Str2) and (Strs[i - 1] = Str1) then
              Exit(True);
        end;
    finally
      Strs.Free;
    end;
  end;

  procedure CompareObject(const Obj1, Obj2: TObject; const Prefix: string);
  var
    Fields: TArray<TRttiField>;
    Field: TRttiField;
    SubObj1, SubObj2: TObject;
  begin
    if  LooksLikeRecursion(Prefix)  then
      Exit;
    Fields  := (Ctx.GetType(Obj1.ClassType) as TRttiInstanceType).GetFields;
    for Field in Fields do
      try
        if  not Assigned(Field.FieldType) then
          Continue;
        if Field.FieldType.TypeKind = tkClass  then
          begin
            if  SameText(Field.Name, 'fOwner') or
                SameText(Field.Name, 'fParent') or
                SameText(Field.Name, 'fParentControl') or
                SameText(Field.Name, 'fControl') or
                SameText(Field.Name, 'fModel') or
                SameText(Field.Name, 'fDefault') or
                SameText(Copy(Field.Name, 0, 8), 'fDefault')
            then
              Continue;
            SubObj1 := Field.GetValue(Obj1).AsObject;
            SubObj2 := Field.GetValue(Obj2).AsObject;
            if  Assigned(SubObj1) or Assigned(SubObj2) then
              CompareObject(SubObj1, SubObj2, Prefix + '.' + Field.Name);
          end
        else if Field.FieldType.TypeKind = tkRecord then
//          if  SameText(Field.Name, 'fDefaultValue') then
            Continue
//          else
//            Changes.Add(Prefix + '.' + Field.Name + ': ???')
        else
          if not SameValue(Field.GetValue(Obj1), Field.GetValue(Obj2)) then
            Changes.Add(Prefix + '.' + Field.Name + ': ' + VarToStr(Field.GetValue(Obj1).AsVariant) + ' -> ' + VarToStr(Field.GetValue(Obj2).AsVariant));
      except
        ShowMessage(Prefix + '-' + Field.Name);
      end;
  end;

begin
  Changes := TStringList.Create;
  try
    CompareObject(fCopy, Edit1, '');
    if  Changes.Count > 0 then
      ShowMessage(Changes.Text);
  finally
    Changes.Free;
  end;
end;

procedure TfrmTestSpinners.butShowListControlsClick(Sender: TObject);
begin
  frmListControls.Show
end;

procedure TfrmTestSpinners.Button1Click(Sender: TObject);
begin
  Edit1.Visible := not Edit1.Visible
end;

procedure TfrmTestSpinners.Button2Click(Sender: TObject);
begin
  Edit1.Repaint;
//  Edit1.AncestorVisibleChanged(True);
  Edit1.RecalcUpdateRect;
end;

procedure TfrmTestSpinners.butCopyClick(Sender: TObject);
begin
  fCopy := CloneObject(Edit1, '');
end;

procedure TfrmTestSpinners.butRestoreClick(Sender: TObject);

  procedure CopyData(const Backup, Obj: TObject);
  var
    Fields: TArray<TRttiField>;
    Field: TRttiField;
  begin
    Fields  := (Ctx.GetType(Obj.ClassType) as TRttiInstanceType).GetFields;
    for Field in Fields do
      try
        if  not Assigned(Field.FieldType) then
          Continue;
        if  (Field.FieldType.TypeKind = tkClass)  then
          Continue;
        if  (Field.FieldType.TypeKind = tkRecord)  then
          Continue;
        Field.SetValue(Obj, Field.GetValue(Backup));
      finally

      end;
  end;

begin
  CopyData(fCopy, Edit1);
  CopyData(TInsideEdit(fCopy).fButtonsContent, TInsideEdit(Edit1).fButtonsContent);
end;

function TfrmTestSpinners.CloneObject(const Obj: TObject; const Path: string): TObject;
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  SrcObj: TObject;
begin
  //  Create instance
  try
    Result  := AllocMem(Obj.ClassType.InstanceSize);
    Obj.ClassType.InitInstance(Result);
  except
    ShowMessage(Path);
  end;
  //  Copy data
  Fields  := (Ctx.GetType(Obj.ClassType) as TRttiInstanceType).GetFields;
  for Field in Fields do
    try
      if  not Assigned(Field.FieldType) then
        Continue;
      if  (Field.FieldType.TypeKind = tkClass)
          and not SameText(Field.Name, 'fOwner')
          and not SameText(Field.Name, 'fParent')
          and not SameText(Field.Name, 'fParentControl')
          and not SameText(Field.Name, 'fDelayedEvents')
          and not SameText(Field.Name, 'fCaret')
          and not SameText(Field.Name, 'fEditModel')
          and not SameText(Field.Name, 'fInfo')
          and not SameText(Field.Name, 'fTextSettings')
          and not SameText(Field.Name, 'fReceiver')
          and not SameText(Field.Name, 'fControl')
      then
        begin
          SrcObj  := Field.GetValue(Obj).AsPointer;
          if  Assigned(SrcObj) then
            Field.SetValue(Result, CloneObject(Field.GetValue(Obj).AsObject, Path + '.' + Field.Name))
          else
            Field.SetValue(Result, nil);
        end
      else
        Field.SetValue(Result, Field.GetValue(Obj));
    except
      ShowMessage(Path + '-' + Field.Name);
    end;
end;

procedure TfrmTestSpinners.edItemCountChange(Sender: TObject);
begin
  ListSpinner1.ItemCount  := Trunc(edItemCount.Value);
  edItemCount.Value       := ListSpinner1.ItemCount;
end;

procedure TfrmTestSpinners.edItemHeightChange(Sender: TObject);
begin
  ListSpinner1.ItemHeight := Trunc(edItemHeight.Value);
  edItemHeight.Value      := ListSpinner1.ItemHeight;
end;

procedure TfrmTestSpinners.edItemIndexChange(Sender: TObject);
begin
  ListSpinner1.ItemIndex  := Trunc(edItemIndex.Value);
end;

function TfrmTestSpinners.ListSpinner1ItemIndexChange(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := frmListControls.CheckBox1;
  frmListControls.CheckBox1.Text          := 'Item ' + IntToStr(Index);
  edItemIndex.Value       := ListSpinner1.ItemIndex;
end;

function TfrmTestSpinners.ListSpinner1ObtainItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  if Index < 0 then
    Result  := nil
  else if Index < 4 then
    begin
      Result  := frmListControls.Label1;
      frmListControls.Label1.Text  := 'Item ' + IntToStr(Index);
    end
  else if Odd(Index) then
    begin
      Result  := frmListControls.Button1;
      frmListControls.Button1.Text  := 'Item ' + IntToStr(Index);
    end
  else
    begin
      Result  := Edit1;
      Edit1.Text  := 'Item ' + IntToStr(Index);
    end;
//    begin
//      Result  := frmListControls.Edit1;
//      frmListControls.Edit1.Text  := 'Item ' + IntToStr(Index);
//    end;
end;

function TfrmTestSpinners.ListSpinner2ObtainItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  Result  := frmListControls.frameComplexListItem1;
  frmListControls.frameComplexListItem1.Value := Index;
end;

initialization
  Ctx := TRttiContext.Create;

finalization
  Ctx.Free;

end.
