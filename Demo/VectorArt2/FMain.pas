unit FMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TfrmMain = class(TForm)
    Panel1: TPanel;
    cmbShapes: TComboBox;
    Layout1: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure Layout1Click(Sender: TObject);
    procedure Layout1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    fWhere: TPointF;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  uShapes;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ShapeFactory.List(cmbShapes.Items)
end;

procedure TfrmMain.Layout1Click(Sender: TObject);
var
  ShapeName: string;
begin
  ShapeName := cmbShapes.Items[cmbShapes.ItemIndex];
  ShapeFactory.CreateShape( ShapeName, Layout1, fWhere );
end;

procedure TfrmMain.Layout1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fWhere  := PointF(X, Y)
end;

end.
