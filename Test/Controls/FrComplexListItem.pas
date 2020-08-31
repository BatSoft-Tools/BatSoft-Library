unit FrComplexListItem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts;

type
  TframeComplexListItem = class(TFrame)
    Layout1: TLayout;
    Label1: TLabel;
    Edit1: TEdit;
    Layout2: TLayout;
    Image1: TImage;
  private
    fValue: integer;
    procedure SetValue(const Value: integer);
  public
    property  Value : integer read fValue write SetValue;
  end;

implementation

{$R *.fmx}

{ TframeComplexListItem }

procedure TframeComplexListItem.SetValue(const Value: integer);
begin
  fValue := Value;
  Label1.Text   := IntToStr(fValue);
  Edit1.Text    := IntToHex(fValue, 2);
end;

end.
