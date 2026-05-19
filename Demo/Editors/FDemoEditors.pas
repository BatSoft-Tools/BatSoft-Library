unit FDemoEditors;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  BatSoft.Editors, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListBox,
  FMX.ExtCtrls, BatSoft.Editors.Enum, BatSoft.ObjectTreeView, FMX.TreeView;

type
{$M+}
  TSomeThing = class
  private
    fStr: string;
    fInt: integer;
    fEnum: TAlignment;
    fEnumSet: TAnchors;
  published
    property  Str: string       read fStr     write fStr;
    property  Int: integer      read fInt     write fInt;
    property  Enum: TAlignment  read fEnum    write fEnum;
    property  EnumSet: TAnchors read fEnumSet write fEnumSet;
  end;
{$M-}

  TfrmDemoEditors = class(TForm)
    Editors1: TEditors;
    Popup1: TPopup;
    ObjectTreeView1: TObjectTreeView;
    grpTree: TGroupBox;
    grpEditors: TGroupBox;
    Splitter1: TSplitter;
    Layout1: TLayout;
    Button0: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    Splitter2: TSplitter;
    TreeProperties: TEditors;
    grpTreeProperties: TGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button0Click(Sender: TObject);
    procedure ObjectTreeView1Changed(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    fThing: TSomeThing;
  end;

var
  frmDemoEditors: TfrmDemoEditors;

implementation

{$R *.fmx}

uses
  System.Rtti;

{ TfrmDemoEditors }

procedure TfrmDemoEditors.Button0Click(Sender: TObject);
begin
  Editors1.EditObject   := nil;
end;

procedure TfrmDemoEditors.Button1Click(Sender: TObject);
begin
  Editors1.EditObject   := fThing;
end;

procedure TfrmDemoEditors.Button2Click(Sender: TObject);
begin
  Editors1.EditObject   := GroupBox1;
end;

procedure TfrmDemoEditors.Button3Click(Sender: TObject);
begin
  ObjectTreeView1.Root  := nil;
end;

procedure TfrmDemoEditors.Button4Click(Sender: TObject);
begin
  ObjectTreeView1.Root  := fThing;
end;

procedure TfrmDemoEditors.Button5Click(Sender: TObject);
begin
  ObjectTreeView1.Root  := GroupBox1;
end;

procedure TfrmDemoEditors.FormCreate(Sender: TObject);
begin
  fThing  := TSomeThing.Create;
  fThing.Str  := 'xyz';
  fThing.Int  := 3;
  TreeProperties.EditObject := ObjectTreeView1
end;

procedure TfrmDemoEditors.FormDestroy(Sender: TObject);
begin
  fThing.Free;
end;

procedure TfrmDemoEditors.ObjectTreeView1Changed(Sender: TObject);
begin
  Editors1.EditObject   := ObjectTreeView1.Selected;
end;

end.
