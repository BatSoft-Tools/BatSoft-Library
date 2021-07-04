unit uModuleAlpha;

interface

uses
  uModule;

type
  //  This module is self contained but, by registering it, we make it available to other modules.
  TModuleAlpha = class(TInterfacedObject, IAlpha)
  public
    //  IModuleAplha interface
    procedure DoSomething(const Str: string);
  end;

implementation

uses
  FMX.Dialogs;

{ TModuleAlpha }

procedure TModuleAlpha.DoSomething(const Str: string);
begin
  ShowMessage('Module Alpha does something with: ' + Str)
end;

initialization
  Modules.Register(IAlpha, TModuleAlpha.Create);

end.
