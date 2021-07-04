unit uShapes.Controls;

interface

implementation

uses
  FMX.StdCtrls, uShapes;

procedure RegisterControls;
begin
  ShapeFactory.RegisterShape('Button', TButton);
  ShapeFactory.RegisterShape('Group Box', TGroupBox);
end;

initialization
  RegisterControls;

end.
