unit uShapes.Geometric;

interface

implementation

uses
  FMX.Objects, uShapes;

procedure RegisterGeometric;
begin
  ShapeFactory.RegisterShape('Circle', TCircle);
  ShapeFactory.RegisterShape('Rectangle', TRectangle);
  ShapeFactory.RegisterShape('Arc', TArc);
  ShapeFactory.RegisterShape('Line', TLine);
end;

initialization
  RegisterGeometric;

end.
