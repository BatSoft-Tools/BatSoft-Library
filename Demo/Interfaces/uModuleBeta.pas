unit uModuleBeta;

interface

uses
  uModule;

type
  //  This module makes use of module Alpha, but because it has no access to
  //  Alpha's implementation, the only coupling it has to the Alpha module is
  //  the IAlpha interface.  Beta knows nothing about Alpha's implementation.
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
  //  Here we obtain IAlpha's implementation, and can use Alpha.
  Alpha := Modules.Obtain<IAlpha>();
  for i := 1 to 3 do
    Alpha.DoSomething('from beta (' + i.ToString + ')')
end;

initialization
  //  The important part!
  //  Module Beta is registered as IBeta.
  Modules.Register(IBeta, TModuleBeta.Create);

end.
