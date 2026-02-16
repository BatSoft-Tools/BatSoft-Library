unit FMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListBox, FMX.Controls.Presentation, FMX.Layouts;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    cmbNewShape: TComboBox;
    butNewShape: TButton;
    loDrawing: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure loDrawingClick(Sender: TObject);
    procedure loDrawingMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    fWhere: TPointF;
    function GetNewShapeName: string;
  public
    property NewShapeName: string read GetNewShapeName;
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
  ShapeFactory.List(cmbNewShape.Items);
end;

function TfrmMain.GetNewShapeName: string;
begin
  if  cmbNewShape.ItemIndex < 0 then
    Result  := string.Empty
  else
    Result  := cmbNewShape.Items[cmbNewShape.ItemIndex]
end;

procedure TfrmMain.loDrawingClick(Sender: TObject);
begin
  if  not NewShapeName.IsEmpty  then
    ShapeFactory.CreateShape(NewShapeName, loDrawing, fWhere);
end;

procedure TfrmMain.loDrawingMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fWhere  := PointF(X, Y);
end;

end.
