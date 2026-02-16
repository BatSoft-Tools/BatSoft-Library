unit uShapes;

interface

uses
  System.Types, System.Classes, FMX.Controls, Generics.Collections;

type
  TControlCreator = reference to function (AOwner: TControl): TControl;

  TShapeFactory = class
  private
    fShapeTypes: TDictionary<string, TControlCreator>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(const ShapeName: string; Creator: TControlCreator);
    procedure List(const ShapeNames: TStrings);
    function  CreateShape(const ShapeName: string; const Owner: TControl; const Where: TPointF): TControl;
  end;

var
  ShapeFactory: TShapeFactory;

implementation

uses
  System.SysUtils;

{ TShapeFactory }

constructor TShapeFactory.Create;
begin
  inherited;
  fShapeTypes := TDictionary<string, TControlCreator>.Create;
end;

function TShapeFactory.CreateShape(const ShapeName: string; const Owner: TControl; const Where: TPointF): TControl;
var
  Creator: TControlCreator;
begin
  if  not fShapeTypes.TryGetValue(ShapeName, Creator) then
    raise Exception.Create('Shape type ' + ShapeName + ' found');
  //  Create and initialise shape
  Result  := Creator(Owner);
  Result.Parent         := Owner;
  Result.Position.Point := Where;
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
  for ShapeName in fShapeTypes.Keys  do
    ShapeNames.Add(ShapeName);
end;

procedure TShapeFactory.Register(const ShapeName: string; Creator: TControlCreator);
begin
  fShapeTypes.Add(ShapeName, Creator);
end;

initialization
  ShapeFactory  := TShapeFactory.Create;

finalization
  ShapeFactory.Free;

end.
