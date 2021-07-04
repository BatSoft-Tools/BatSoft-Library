unit uShapes;

interface

uses
  System.Types, System.Classes, FMX.Controls, Generics.Collections;

type
  TControlClass = class of TControl;

  TShapeFactory = class
  private
    fShapeTypes: TDictionary<string, TControlClass>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure RegisterShape(const ShapeName: string; const ControlClass: TControlClass);
    procedure List(const ShapeNames: TStrings);
    function  CreateShape(const ShapeName: string; const Owner: TControl; const Where: TPointF): TControl;
  end;

var
  ShapeFactory: TShapeFactory;

implementation

{ TShapeFactory }

constructor TShapeFactory.Create;
begin
  inherited;
  fShapeTypes := TDictionary<string, TControlClass>.Create;
end;

function TShapeFactory.CreateShape(const ShapeName: string;
  const Owner: TControl; const Where: TPointF): TControl;
var
  ControlClass: TControlClass;
begin
  if  fShapeTypes.TryGetValue(ShapeName, ControlClass)  then
    begin
      Result  := ControlClass.Create(Owner);
      Result.Parent := Owner;
      Result.Position.Point := Where;
    end;
end;

destructor TShapeFactory.Destroy;
begin
  fShapeTypes.Free;
  inherited;
end;

procedure TShapeFactory.List(const ShapeNames: TStrings);
var
  ShapeName: string;
begin
  ShapeNames.Clear;
  for ShapeName in fShapeTypes.Keys do
    ShapeNames.Add(ShapeName)
end;

procedure TShapeFactory.RegisterShape(const ShapeName: string; const ControlClass: TControlClass);
begin
  fShapeTypes.Add(ShapeName, ControlClass);
end;

initialization
  ShapeFactory  := TShapeFactory.Create

finalization
  ShapeFactory.Free;

end.
