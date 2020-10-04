unit uRefCounter;

interface

type
  IRefCounter = interface
    ['{A97C23B6-A03E-4365-8077-42A9CC2E7260}']
    function Count: Integer;
  end;

  TRefCounter = class(TInterfacedObject, IRefCounter)
  public
    //  IRefCounter interface
    function Count: Integer;
  end;

implementation

{ TRefCounter }

function TRefCounter.Count: Integer;
begin
  Result := Self.RefCount
end;

end.
