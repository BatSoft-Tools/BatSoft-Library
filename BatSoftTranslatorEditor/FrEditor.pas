unit FrEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Controls.Presentation, FMX.TreeView, System.JSON;

type
  TframeEditor = class(TFrame)
    panFile: TGroupBox;
    edFile: TEdit;
    Layout1: TLayout;
    panStruc: TGroupBox;
    panValue: TGroupBox;
    treStruc: TTreeView;
    labValue: TLabel;
    edValue: TEdit;
    butSave: TButton;
    butCopy: TButton;
    OpenDialog: TOpenDialog;
    Layout2: TLayout;
    panNode: TGroupBox;
    butDelete: TButton;
    procedure treStrucChange(Sender: TObject);
    procedure edValueChange(Sender: TObject);
    procedure butSaveClick(Sender: TObject);
    procedure butCopyClick(Sender: TObject);
    procedure butDeleteClick(Sender: TObject);
  private
    fFileFull: string;
    fTranslation: TJSONObject;
    procedure SetFileFull(const Value: string);
    procedure PopulateEditor;
    procedure PopulateValItem(const ValItem: TTreeViewItem);
    procedure PopulateValEditor;
  public
    destructor  Destroy; override;
    property  FileFull  : string  read fFileFull  write SetFileFull;
    function  GetValItem: TTreeViewItem;
    function  GetValJSON: TJSONString;
    procedure Load;
  end;

implementation

{$R *.fmx}

uses
  System.IOUtils, Generics.Collections, FMX.DialogService;

const
  CNoValue  : Char  = #$00;

{ TframeEditor }

procedure TframeEditor.butCopyClick(Sender: TObject);

  procedure CopyNode(const Orig, Dest: TJSONObject; Name: string);
  var
    DestPair: TJSONPair;
    ChildName: string;
    ChildOrig, ChildDest: TJSONValue;
  begin
    for DestPair in Dest  do
      begin
        ChildName := DestPair.JsonString.Value;
        ChildDest := DestPair.JsonValue;
        ChildOrig := Orig.GetValue(ChildName);
        //  Need to actually have an original to copy from
        if  not Assigned(ChildOrig) then
          Continue;
        //  If value is an object, then recurse
        if  (DestPair.JsonValue is TJSONObject) then
          begin
            if  (ChildOrig is TJSONObject)  then
              CopyNode(ChildOrig as TJSONObject, ChildDest as TJSONObject, ChildName);
            Continue;
          end;
        //  Value is a "proper value", so copy that
        if  SameText(ChildOrig.Value, ChildDest.Value)  then
          Continue;
        Dest.RemovePair(ChildName);
        Dest.AddPair(ChildName, ChildOrig.Clone as TJSONValue);
      end;
  end;

var
  Original: TJSONObject;
begin
  if  OpenDialog.Execute  then
    begin
      Original  := TJSONObject.ParseJSONValue(TFile.ReadAllText(OpenDialog.FileName)) as TJSONObject;
      try
        CopyNode(Original, fTranslation, 'Root');
      finally
        Original.Free;
      end;
      PopulateEditor;
    end;
end;

procedure TframeEditor.butDeleteClick(Sender: TObject);
var
  ParentItem: TTreeViewItem;
  ParentNode: TJSONObject;
  Comp: TComponent;
begin
  ParentItem  := treStruc.Selected.ParentItem;
  if  Assigned(ParentItem)  then
    ParentNode  := ParentItem.TagObject as TJSONObject
  else
    ParentNode  := fTranslation;
  //  Remove node
  ParentNode.RemovePair(treStruc.Selected.TagString);
  //  Rebuild tree
  PopulateEditor;
  //  Select parent
  for Comp in treStruc  do
    if  Comp is TTreeViewItem then
      if  TTreeViewItem(Comp).TagObject = ParentNode  then
        begin
          treStruc.Selected := TTreeViewItem(Comp);
          break;
        end;
end;

procedure TframeEditor.butSaveClick(Sender: TObject);
begin
  TFile.WriteAllText(fFileFull, fTranslation.ToJSON);
end;

destructor TframeEditor.Destroy;
begin
  fTranslation.Free;
  inherited;
end;

procedure TframeEditor.edValueChange(Sender: TObject);
var
  ValItem: TTreeViewItem;
  ValJSON: TJSONString;
  ObjItem: TTreeViewItem;
  ObjJSON: TJSONObject;
begin
  if  GetValJSON <> nil then
    begin
      ValItem := GetValItem;
      ObjItem := GetValItem.ParentItem;
      ObjJSON := ObjItem.TagObject as TJSONObject;
      //  Remove old ValJSON
      ObjJSON.RemovePair(ValItem.TagString);
      //  Replace with new ValJSON
      if  edValue.Text.IsEmpty  then
        ValJSON := TJSONString.Create(CNoValue)
      else
        ValJSON := TJSONString.Create(edValue.Text);
      ObjJSON.AddPair(ValItem.TagString, ValJSON);
      ValItem.TagObject := ValJSON;
      //  Show the change
      PopulateValItem(ValItem);
    end;
end;

function TframeEditor.GetValItem: TTreeViewItem;
begin
  Result  := nil;
  if  Assigned(treStruc.Selected) then
    if  treStruc.Selected.TagObject is TJSONString  then
      Result  := treStruc.Selected
end;

function TframeEditor.GetValJSON: TJSONString;
var
  ValItem: TTreeViewItem;
begin
  ValItem := GetValItem;
  if  Assigned(ValItem) then
    Result  := treStruc.Selected.TagObject as TJSONString
  else
    Result  := nil
end;

procedure TframeEditor.Load;
begin
  fTranslation.Free;
  try
    fTranslation  := TJSONObject.ParseJSONValue(TFile.ReadAllText(fFileFull)) as TJSONObject;
  finally
    PopulateEditor;
  end;
end;

procedure TframeEditor.PopulateEditor;

  function  NewItem(const Parent: TFmxObject; const Pair: TJSONPair): TTreeViewItem;
  begin
    Result  := TTreeViewItem.Create(treStruc);
    Result.Text       := Pair.JsonString.Value;
    Result.TagString  := Pair.JsonString.Value;
    Result.TagObject  := Pair.JsonValue;
    Parent.AddObject(Result);
  end;

  procedure AddVal(const ObjItem: TTreeViewItem; const ValPair: TJSONPair);
  var
    ValItem: TTreeViewItem;
  begin
    ValItem := NewItem(ObjItem, ValPair);
    ValItem.TagString := ValPair.JsonString.Value;
    PopulateValItem(ValItem);
  end;

  procedure AddObj(const SecItem: TTreeViewItem; const ObjPair: TJSONPair);
  var
    ObjItem: TTreeViewItem;
    ObjJSON: TJSONObject;
    Pair: TJSONPair;
  begin
    ObjItem := NewItem(SecItem, ObjPair);
    ObjJSON := ObjPair.JsonValue as TJSONObject;
    //  Add values
    for Pair in ObjJSON do
      AddVal(ObjItem, Pair);
  end;

  procedure AddSec(const SecPair: TJSONPair);
  var
    SecItem: TTreeViewItem;
    SecJSON: TJSONObject;
    Pair: TJSONPair;
  begin
    SecItem := NewItem(treStruc, SecPair);
    SecJSON := SecPair.JsonValue as TJSONObject;
    //  Add objects
    for Pair in SecJSON do
      AddObj(SecItem, Pair);
  end;

var
  Pair: TJSONPair;
begin
  //  File
  edFile.Text := fFileFull;
  //  Tree
  treStruc.Clear;
  for Pair in fTranslation  do
    AddSec(Pair);
  treStruc.ExpandAll;
end;

procedure TframeEditor.PopulateValEditor;
var
  ValJSON: TJSONString;
begin
  //  Populare value editor
  ValJSON := GetValJSON;
  panValue.Enabled  := Assigned(ValJSON);
  if  panValue.Enabled  then
    begin
      labValue.Text := treStruc.Selected.TagString;
      edValue.Text  := ValJSON.Value;
    end
  else
    begin
      labValue.Text := '';
      edValue.Text  := '';
    end;
  //  Populate node editor
  panNode.Enabled := Assigned(treStruc.Selected);
end;

procedure TframeEditor.PopulateValItem(const ValItem: TTreeViewItem);
var
  ValJSON: TJSONString;
begin
  ValJSON := ValItem.TagObject as TJSONString;
  ValItem.Text  := ValItem.TagString + ' = ' + ValJSON.Value;
end;

procedure TframeEditor.SetFileFull(const Value: string);
begin
  fFileFull := Value;
  Load;
  treStrucChange(treStruc);
end;

procedure TframeEditor.treStrucChange(Sender: TObject);
begin
  PopulateValEditor;
end;

end.
