unit TestContextBase;

interface

uses
  DUnitX.TestFramework, BatSoft.Context;

type
  [TestFixture]
  TTestContextBase = class
  private
    fContext: TContextBase;
  public
    [Setup]
    procedure Setup();
    [Test]
    procedure TestContext;
    [Test]
    procedure TestContextNames;
  end;

implementation

uses
  System.Rtti, System.Classes;

{ TTestContextBase }

procedure TTestContextBase.Setup;
begin
  fContext  := TContextBase.Create;
end;

procedure TTestContextBase.TestContext;
begin
  Assert.IsFalse(fContext.HasValue('A'));

  Assert.IsFalse(fContext.DelValue('A'));

  Assert.WillRaise(
    procedure
    begin
      fContext.GetValue('A');
    end, EContext);

  Assert.IsFalse(fContext.SetValue('A', 123));
end;

procedure TTestContextBase.TestContextNames;
var
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Assert.IsFalse(fContext.GetNames(Names));
  finally
    Names.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContextBase);

end.
