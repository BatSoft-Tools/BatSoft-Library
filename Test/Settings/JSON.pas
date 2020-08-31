unit JSON;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestJSON = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

uses
  TestObjects;

{ TTestJSON }

procedure TTestJSON.Setup;
begin

end;

procedure TTestJSON.TearDown;
begin

end;

procedure TTestJSON.Test1;
begin

end;

procedure TTestJSON.Test2(const AValue1, AValue2: Integer);
begin

end;

initialization
  TDUnitX.RegisterTestFixture(TTestJSON);

end.
