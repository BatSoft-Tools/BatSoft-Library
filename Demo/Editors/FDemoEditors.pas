unit FDemoEditors;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  BatSoft.Editors, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
{$M+}
  TSomeThing = class
  private
    fStr: string;
    fInt: integer;
    fEnum: TAlignment;
  published
    property  Str: string       read fStr   write fStr;
    property  Int: integer      read fInt   write fInt;
    property  Enum: TAlignment  read fEnum  write fEnum;
  end;
{$M-}

  TfrmDemoEditors = class(TForm)
    Editors1: TEditors;
    Button1: TButton;
    Button2: TButton;
    VertScrollBox1: TVertScrollBox;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    fThing: TSomeThing;
  end;

var
  frmDemoEditors: TfrmDemoEditors;

implementation

{$R *.fmx}

{ TfrmDemoEditors }

procedure TfrmDemoEditors.Button1Click(Sender: TObject);
begin
  Editors1.EditObject := nil;
  Editors1.EditObject := fThing;
end;

procedure TfrmDemoEditors.Button2Click(Sender: TObject);
begin
  Editors1.EditObject := GroupBox1;
end;

procedure TfrmDemoEditors.FormCreate(Sender: TObject);
begin
  fThing  := TSomeThing.Create;
  fThing.Str  := 'xyz';
  fThing.Int  := 3;
//  Editors1.EditObject := fThing;
end;

procedure TfrmDemoEditors.FormDestroy(Sender: TObject);
begin
  fThing.Free;
end;

end.
