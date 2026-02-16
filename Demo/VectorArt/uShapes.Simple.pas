unit uShapes.Simple;

interface

procedure RegisterSimpleShapes;

implementation

uses
  FMX.Controls, FMX.Objects, uShapes;

procedure RegisterSimpleShapes;
begin
  ShapeFactory.Register('Line',
    function (AOwner: TControl): TControl
    begin
      Result  := TLine.Create(AOwner);
    end);

  ShapeFactory.Register('Rectangle',
    function (AOwner: TControl): TControl
    begin
      Result  := TRectangle.Create(AOwner);
    end);

  ShapeFactory.Register('Circle',
    function (AOwner: TControl): TControl
    begin
      Result  := TCircle.Create(AOwner);
    end);
end;

initialization
  RegisterSimpleShapes;

end.
