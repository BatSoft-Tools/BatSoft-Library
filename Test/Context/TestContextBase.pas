unit TestContextBase;

interface

uses
  DUnitX.TestFramework, BatSoft.Context;

type
  [TestFixture]
  TTestContextPartial = class
  private
    fContext: IContext;
  public
    [Setup]
    procedure Setup();
    [Test]
    procedure TestMethods;
  end;

implementation

uses
  System.Rtti;

{ TTestContextPartial }

procedure TTestContextPartial.Setup;
begin
  fContext  := TContextPartial.Create;
end;

procedure TTestContextPartial.TestMethods;
begin
  Assert.WillRaise(
    procedure
    begin
      fContext.HasValue('A');
    end, EContext);

  Assert.WillRaise(
    procedure
    begin
      fContext.DelValue('A');
    end, EContext);

  Assert.WillRaise(
    procedure
    begin
      fContext.GetValue('A');
    end, EContext);

  Assert.WillRaise(
    procedure
    begin
      fContext.GetValueKind('A');
    end, EContext);

  Assert.WillRaise(
    procedure
    begin
      fContext.SetValue('A', TValue.Empty);
    end, EContext);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContextPartial);

end.
