unit BatSoft.ObjectTreeView;

interface

uses
  System.Classes, FMX.Controls, FMX.TreeView;

type
  TTreeOpenState = (Closed, RootOpen, AllOpen);

{$M+}
  TObjectTreeView = class(TControl)
  private
    fTreeView: TTreeView;
    fRoot: TObject;
    fIncludeRoot: Boolean;
    procedure SetIncludeRoot(const Value: Boolean);
    procedure SetRoot(const Value: TObject);
    function GetSelected: TObject;
    function GetStyleLookup: string;
    function GetStyleName: string;
    procedure SetStyleLookup(const Value: string);
    procedure SetStyleName(const Value: string);
  private
    fOnChanged: TNotifyEvent;
    fOpenState: TTreeOpenState;
    procedure BuildTree;
    procedure Changed(Sender: TObject);
    procedure DoChanged;
    procedure SetOpenState(const Value: TTreeOpenState);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property  Root        : TObject read fRoot        write SetRoot;
    property  IncludeRoot : Boolean read fIncludeRoot write SetIncludeRoot default True;
    property  Selected    : TObject read GetSelected;
    property  OpenState   : TTreeOpenState  read fOpenState write SetOpenState;
    property  Align;
    property  Anchors;
    property  CanFocus;
    property  Enabled;
    property  Position;
    property  Height;
    property  Width;
    property  StyleLookup : string  read GetStyleLookup write SetStyleLookup;
    property  StyleName   : string  read GetStyleName   write SetStyleName;
    property  TabOrder;
    property  Tag;
    property  Visible;
    property  OnChanged   : TNotifyEvent  read fOnChanged write fOnChanged;
  end;
{$M-}

procedure Register;

implementation

uses
  System.TypInfo, System.Rtti, FMX.Types, BatSoft.Common;

procedure Register;
begin
  RegisterComponents('BatSoft', [TObjectTreeView]);
end;

{ TObjectTreeView }

procedure TObjectTreeView.BuildTree;
var
  RootNode: TTreeViewItem;

  function CreateNode(const Parent: TTreeViewItem; const Text: string; const Obj: TObject): TTreeViewItem;
  begin
    if  not Assigned(Obj)  then
      Exit(nil);
    Result  := TTreeViewItem.Create(fTreeView);
    Result.Parent     := Parent;
    Result.Text       := Text;
    Result.TagObject  := Obj;
    if  Assigned(Parent)  then
      Parent.AddObject(Result)
    else
      fTreeView.AddObject(Result)
  end;

  procedure AddChildren(const Parent: TTreeViewItem; const Obj: TObject);
  var
    Props: TArray<TRttiProperty>;
    ChildObj: TObject;
    ChildNode: TTreeViewItem;
  begin
    if  not Assigned(Obj) then
      Exit;
    Props := RTTI.GetType(Obj.ClassType).GetProperties;
    for var Prop in Props do
      if  (Prop.PropertyType.TypeKind = TTypeKind.tkClass) and (Prop.Visibility = mvPublished) and Prop.IsReadable then
        begin
          ChildObj  := Prop.GetValue(Obj).AsObject;
          ChildNode := CreateNode(Parent, Prop.Name, ChildObj);
          AddChildren(ChildNode, ChildObj);
        end;
  end;
  
begin
  fTreeView.BeginUpdate;
  try
    fTreeView.Clear;
    if  IncludeRoot then
      RootNode  := CreateNode(nil, 'Root', fRoot)
    else
      RootNode  := nil;
    AddChildren(RootNode, fRoot);
  finally
    fTreeView.EndUpdate;
  end;
  case fOpenState of
    Closed : ;
    RootOpen :
      if  fTreeView.Count > 0 then
        fTreeView.Items[0].Expand;
    AllOpen:
      fTreeView.ExpandAll;
  end;
end;

procedure TObjectTreeView.Changed(Sender: TObject);
begin
  DoChanged;
end;

constructor TObjectTreeView.Create(AOwner: TComponent);
begin
  inherited;
  fTreeView := TTreeView.Create(Self);
  fTreeView.Parent    := Self;
  fTreeView.Stored    := False;
  fTreeView.Align     := TAlignLayout.Client;
  fTreeView.OnChange  := Changed;
  fIncludeRoot        := True;
end;

procedure TObjectTreeView.DoChanged;
begin
  if  Assigned(fOnChanged)  then
    fOnChanged(Self);
end;

function TObjectTreeView.GetSelected: TObject;
var
  Node: TTreeViewItem;
begin
  Node  := fTreeView.Selected;
  if  Assigned(Node)  then
    Result  := Node.TagObject
  else if (fTreeView.Count = 0) and Assigned(fRoot) then
    Result  := fRoot
  else
    Result  := nil
end;

function TObjectTreeView.GetStyleLookup: string;
begin
  Result  := fTreeView.StyleLookup
end;

function TObjectTreeView.GetStyleName: string;
begin
  Result  := fTreeView.StyleName
end;

procedure TObjectTreeView.SetIncludeRoot(const Value: Boolean);
begin
  if  fIncludeRoot <> Value then
    begin
      fIncludeRoot := Value;
      BuildTree;
    end;
end;

procedure TObjectTreeView.SetOpenState(const Value: TTreeOpenState);
begin
  fOpenState := Value;
end;

procedure TObjectTreeView.SetRoot(const Value: TObject);
begin
  if  fRoot = Value then
    exit;
  fRoot := Value;
  BuildTree;
  if  fTreeView.Count > 0 then
    fTreeView.Selected  := fTreeView.Items[0]
  else
    DoChanged;
end;

procedure TObjectTreeView.SetStyleLookup(const Value: string);
begin
  fTreeView.StyleLookup := Value
end;

procedure TObjectTreeView.SetStyleName(const Value: string);
begin
  fTreeView.StyleName := Value
end;

end.
