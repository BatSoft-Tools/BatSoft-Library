unit uShapes.Controls;

interface

procedure RegisterSimpleControls;

implementation

uses
  FMX.Controls, FMX.StdCtrls, uShapes;

procedure RegisterSimpleControls;
begin
  ShapeFactory.Register('Button',
    function (AOwner: TControl): TControl
    begin
      Result  := TButton.Create(AOwner);
    end);

  ShapeFactory.Register('Group',
    function (AOwner: TControl): TControl
    begin
      Result  := TGroupBox.Create(AOwner);
    end);
end;

initialization
  RegisterSimpleControls;

end.
