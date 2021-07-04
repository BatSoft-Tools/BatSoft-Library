unit TestContexts;

interface

uses
  DUnitX.TestFramework, System.Rtti, BatSoft.Context;

type
  [TestFixture]
  TTestContexts = class
  private
    fContexts, fContext1, fContext2: IContext;
  private const
    NameAlpha = 'Alpha';
    NameBeta  = 'Beta';
    NameGamma = 'Gamma';
    NameTheta = 'Theta';
    //  Set up
    ValueAlpha1 = 'A1';
    ValueBeta1a = 10;
    ValueBeta1b = 'B2';
    ValueGamma1 = 100;

    ValueAlpha2 = 2;
    ValueBeta2  = 20;
    ValueGamma2 = 200;
  private
    procedure SetValues(Context: IContext; const ValueAlpha, ValueBeta, ValueGamma: TValue);
    procedure GetValues(Context: IContext; const ValueAlpha, ValueBeta, ValueGamma: TValue);
    procedure ShowNameValues(Context: IContext);
  public
    [Setup]
    procedure Setup();
    [Test]
    procedure TestGetValue;
    [Test]
    procedure TestSetValue;
    [Test]
    procedure TestDelValue;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TTestContexts }

procedure TTestContexts.GetValues(Context: IContext; const ValueAlpha, ValueBeta, ValueGamma: TValue);

  procedure TestValue(const Name: string; const Value: TValue);
  begin
    if  Value.IsEmpty then
      Assert.IsFalse(Context.HasValue(Name))
    else
      begin
        //  Compare TTypeKind
        Assert.AreEqual(Context.GetValue(Name).Kind, Value.Kind);
        //  Compare actual values
        case Value.Kind of
          tkInteger :
            Assert.AreEqual(Context.GetValue(Name).AsInteger, Value.AsInteger);
          tkChar, tkWChar, tkString, tkUString, tkLString, tkWString :
            Assert.AreEqual(Context.GetValue(Name).AsString, Value.AsString);
        else
          raise Exception.Create('Broken test');
        end;
      end;
  end;

begin
  TestValue(NameAlpha, ValueAlpha);
  TestValue(NameBeta,  ValueBeta );
  TestValue(NameGamma, ValueGamma);
end;

procedure TTestContexts.Setup;
begin
  //  Create contexts
  fContext1 := TContextValues.Create();
  fContext2 := TContextValues.Create();
  fContexts := TContexts.Create([fContext1, fContext2]);
  //  Add test values
  SetValues(fContext1, ValueAlpha1,  ValueBeta1a, TValue.Empty);
  SetValues(fContext2, TValue.Empty, ValueBeta1b, ValueGamma1);
end;

procedure TTestContexts.SetValues(Context: IContext; const ValueAlpha, ValueBeta, ValueGamma: TValue);

  procedure SetValue(const Name: string; const Value: TValue);
  begin
    if  not Value.IsEmpty then
      Assert.IsTrue(Context.SetValue(Name, Value));
  end;

begin
  SetValue(NameAlpha, ValueAlpha);
  SetValue(NameBeta,  ValueBeta );
  SetValue(NameGamma, ValueGamma);
end;

procedure TTestContexts.ShowNameValues(Context: IContext);
var
  Strs: TStringList;
  i: integer;
  ContextName: string;
begin
  Strs  := TStringList.Create;
  try
    //  Get names
    Context.GetNames(Strs);
    //  Add values
    for i := 0 to Strs.Count - 1 do
      if  Context.HasValue(Strs[i]) then
        if  Context.GetValue(Strs[i]).Kind = tkInteger then
          Strs[i] := Strs[i] + '=' + Context.GetValue(Strs[i]).AsInteger.ToString
        else
          Strs[i] := Strs[i] + '=' + Context.GetValue(Strs[i]).AsString;
    //  Output
    if  (fContext1 as IContext) = Context then  ContextName := 'fContext1' else
    if  (fContext2 as IContext) = Context then  ContextName := 'fContext2' else
                                                ContextName := 'fContexts';
    Log(TLogLevel.Information, ContextName + ': ' + Strs.CommaText);
  finally
    Strs.Free;
  end;
end;

procedure TTestContexts.TestDelValue;
begin
  ShowNameValues(fContext1);
  ShowNameValues(fContext2);
  GetValues(fContext1, ValueAlpha1,   ValueBeta1a,  TValue.Empty);
  GetValues(fContext2, TValue.Empty,  ValueBeta1b,  ValueGamma1);
  GetValues(fContexts, ValueAlpha1,   ValueBeta1b,  ValueGamma1);

  Log(TLogLevel.Information, 'DelValues()');
  Assert.IsTrue(fContexts.DelValue(NameAlpha));
  Assert.IsTrue(fContexts.DelValue(NameBeta));
  Assert.IsTrue(fContexts.DelValue(NameGamma));
  Assert.IsFalse(fContexts.DelValue(NameTheta));

  ShowNameValues(fContext1);
  ShowNameValues(fContext2);
  GetValues(fContext1, TValue.Empty,  ValueBeta1a,  TValue.Empty);
  GetValues(fContext2, TValue.Empty,  TValue.Empty, TValue.Empty);
  GetValues(fContexts, TValue.Empty,  ValueBeta1a,  TValue.Empty);
end;

procedure TTestContexts.TestGetValue;
begin
  GetValues(fContexts, ValueAlpha1, ValueBeta1b, ValueGamma1);
end;

procedure TTestContexts.TestSetValue;
begin
  ShowNameValues(fContext1);
  ShowNameValues(fContext2);
  GetValues(fContext1, ValueAlpha1,   ValueBeta1a,  TValue.Empty);
  GetValues(fContext2, TValue.Empty,  ValueBeta1b,  ValueGamma1);
  GetValues(fContexts, ValueAlpha1,   ValueBeta1b,  ValueGamma1);

  Log(TLogLevel.Information, 'SetValues()');
  SetValues(fContexts, ValueAlpha2,   ValueBeta2,   ValueGamma2);

  ShowNameValues(fContext1);
  ShowNameValues(fContext2);
  GetValues(fContext1, ValueAlpha1,   ValueBeta1a,  TValue.Empty);
  GetValues(fContext2, ValueAlpha2,   ValueBeta2,   ValueGamma2);
  GetValues(fContexts, ValueAlpha2,   ValueBeta2,   ValueGamma2);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContexts);

end.
