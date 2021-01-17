unit uModuleBeta;

interface

uses
  uModuleCoupling;

type
  //  This module makes use of module Aplha, but because it has no access to
  //  Aplha's implementation, it can't depend on Alpha nor interfere with it.
  TModuleBeta = class(TInterfacedObject, IBeta)
  public
    //  IModuleBeta interface
    procedure SomeBetaFunctionality;
  end;

implementation

uses
  System.SysUtils;

{ TModuleBeta }

procedure TModuleBeta.SomeBetaFunctionality;
var
  Alpha: IAlpha;
  i: Integer;
begin
  Alpha := Modules.Obtain<IAlpha>();
  for i := 1 to 3 do
    Alpha.DoSomething('from beta (' + i.ToString + ')')
end;

initialization
  Modules.Register(IBeta, TModuleBeta.Create);

end.
