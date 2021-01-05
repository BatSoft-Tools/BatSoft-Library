unit TestContextSimple;

interface

uses
  DUnitX.TestFramework, BatSoft.Context;

type
  [TestFixture]
  TTestContextSimple = class
  private
    fContext: IContext;
  public
    [Setup]
    procedure Setup();
    [Test]
    procedure TestBeforeSet;
    [Test]
    procedure TestAfterSet;
    [Test]
    procedure TestMethods;
  end;

implementation

{ TTestContextSimple }

procedure TTestContextSimple.Setup;
begin
  fContext  := TContext.Create;
end;

procedure TTestContextSimple.TestAfterSet;
const
  Name              = 'Name';
  Value1  : string  = 'Value';
  Value2  : integer = 23;
begin
  Assert.IsFalse(fContext.HasValue(Name));
  Assert.IsTrue(fContext.SetValue(Name, Value1));

  Assert.IsTrue(fContext.HasValue(Name));
  Assert.AreEqual(fContext.GetValue(Name).AsString, Value1);
  Assert.AreEqual(fContext.GetValueKind(Name), TTypeKind.tkUString);

  Assert.IsTrue(fContext.SetValue(Name, Value2));

  Assert.IsTrue(fContext.HasValue(Name));
  Assert.AreEqual(fContext.GetValue(Name).AsInteger, Value2);
  Assert.AreEqual(fContext.GetValueKind(Name), TTypeKind.tkInteger);

  Assert.IsTrue(fContext.DelValue(Name));
  Assert.IsFalse(fContext.HasValue(Name));
end;

procedure TTestContextSimple.TestBeforeSet;
const
  Name  = 'Name';
begin
  Assert.IsFalse(fContext.HasValue(Name));
  Assert.IsFalse(fContext.DelValue(Name));

  Assert.WillRaise(
    procedure
    begin
      fContext.GetValue(Name);
    end, EContext);

  Assert.WillRaise(
    procedure
    begin
      fContext.GetValueKind(Name);
    end, EContext);
end;

procedure TTestContextSimple.TestMethods;
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContextSimple);

end.
