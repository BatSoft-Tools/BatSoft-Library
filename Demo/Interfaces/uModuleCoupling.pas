unit uModuleCoupling;

interface

uses
  BatSoft.Classes;

  //  For demo purposes (and depending on your app, this might be appropriate)
  //  we decalare different modules only as interfaces, thereby minimising coupling.
type
  IAlpha = interface
    ['{F19CBBC3-4D30-4508-B6A6-A651BB9B3B65}']
    procedure DoSomething(const Str: string);
  end;

  IBeta = interface
    ['{ED7DDC42-6A37-4FBA-B2D5-4273AC83F41E}']
    procedure SomeBetaFunctionality;
  end;

  //  Here we create a central repository of module interfaces.
  //  Each module register its own interface implementation.
  //  After that, the application can access modules by asking for interfaces,
  //  while the actual implementations can be hidden.
var
  Modules: TInterfaceRegistry;

implementation

initialization
  Modules := TInterfaceRegistry.Create;

finalization
  Modules.Free;

end.
