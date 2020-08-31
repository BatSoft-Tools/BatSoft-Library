unit TestObserverManual;

interface

uses
  DUnitX.TestFramework, Generics.Collections, BatSoft.Observer.Manual;

type
  TIntegerEvents = class(TEvent1Param<integer>);

  TSubject = class
  strict private
    fIntValue: integer;
    fOnEvents: TIntegerEvents;
    procedure SetIntValue(const Value: integer);
  public
    constructor Create;
    destructor  Destroy; override;
    property  IntValue: integer         read fIntValue  write SetIntValue;
    property  OnEvents: TIntegerEvents  read fOnEvents;
  end;

  TObserver = class
  private
    fSubject: TSubject;
    fCopiedSubject: TObject;
    fCopiedInt: integer;
    procedure SetSubject(const Value: TSubject);
    procedure IntEvent(ASubject: TObject; AParam: integer);
  public
    destructor  Destroy; override;
    property  Subject       : TSubject  read fSubject       write SetSubject;
    property  CopiedSubject : TObject   read fCopiedSubject;
    property  CopiedInt     : integer   read fCopiedInt;
  end;

  [TestFixture]
  TTestObserverManualSingle = class
  private
    fSubject: TSubject;
    fObserver: TObserver;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestObserver_Functions;
    [Test]
    procedure TestObserver_Enable;
    [Test]
    procedure TestObserver_ObserverDiesFirst;
    [Test]
    procedure TestObserver_SubjectDiesFirst;
  end;

  TObserverSum = class
  strict private
    fSum: integer;
    procedure IntEvent(ASubject: TObject; AParam: integer);
  public
    procedure Subscribe(const Subject: TSubject);
    procedure Unsubscribe(const Subject: TSubject);
    property  Sum     : integer   read fSum;
  end;

  [TestFixture]
  TTestObserverManualMultiple = class
  private
    fSubject1, fSubject2, fSubject3: TSubject;
    fObserver1, fObserver2, fObserver3: TObserverSum;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestObserver_MultipleObservers;
    [Test]
    procedure TestObserver_MultipleSubjects;
    [Test]
    procedure TestObserver_RepeatedSubscriptions;
  end;

  TTestObserverManualFlow = class;

  TSubjectPlain = class
  private
    fOnEvents: TNotifyEvents;
  public
    constructor Create;
    destructor  Destroy; override;
    property  OnEvents: TNotifyEvents read fOnEvents;
  end;

  TObserverFunctionality = class;

  TFunctionality = reference to procedure(Observer: TObserverFunctionality);

  TObserverFunctionality = class
  public
    fSubject: TSubjectPlain;
    fInt: integer;
    fFunctionality: TFunctionality;
    procedure Event(Sender: TObject);
  public
    constructor Create(const ASubject: TSubjectPlain; const AInt: integer; AFunctionality: TFunctionality);
    destructor  Destroy; override;
    property  Int : integer read fInt;
  end;

  [TestFixture]
  TTestObserverManualFlow = class
  private
    fSubject: TSubjectPlain;
    fObservers: TObjectList<TObserverFunctionality>;
    fCounter, fResult: integer;
    function  CreateObserver(const AInt: integer; AFunctionality: TFunctionality): TObserverFunctionality;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestObserver_FlowAdd;
    [Test]
    procedure TestObserver_FlowRemove;
  end;

implementation

uses
  SysUtils;

{ TSubject }

constructor TSubject.Create;
begin
  inherited;
  fOnEvents := TIntegerEvents.Create(Self);
end;

destructor TSubject.Destroy;
begin
  fOnEvents.Free;
  inherited;
end;

procedure TSubject.SetIntValue(const Value: integer);
begin
  fIntValue := Value;
  OnEvents.Call(fIntValue);
end;

{ TObserver }

destructor TObserver.Destroy;
begin
  Subject := nil;
  inherited;
end;

procedure TObserver.IntEvent(ASubject: TObject; AParam: integer);
begin
  fCopiedSubject := ASubject;
  fCopiedInt    := AParam;
end;

procedure TObserver.SetSubject(const Value: TSubject);
begin
  //  Unsubscribe
  if Assigned(fSubject) then
    fSubject.OnEvents.Unsubscribe(IntEvent);
  //  Set value
  fSubject := Value;
  //  Subscribe to new subject
  if Assigned(fSubject) then
    fSubject.OnEvents.Subscribe(IntEvent);
end;

{ TTestObserverManualSingle }

procedure TTestObserverManualSingle.Setup;
begin
  fSubject  := TSubject.Create;
  fObserver := TObserver.Create;
end;

procedure TTestObserverManualSingle.TearDown;
begin
  fObserver.Free;
  fSubject.Free;
end;

procedure TTestObserverManualSingle.TestObserver_Enable;
begin
  fSubject.IntValue := 3;
  fObserver.Subject := fSubject;
  fSubject.IntValue := 5;

  Assert.AreEqual(fObserver.CopiedInt, 5, 'Wrong value (A)');

  fSubject.OnEvents.Enabled := False;
  fSubject.IntValue := 7;

  Assert.AreEqual(fObserver.CopiedInt, 5, 'Wrong value (B)');

  fSubject.OnEvents.Enabled := True;
  fSubject.IntValue := 9;

  Assert.AreEqual(fObserver.CopiedInt, 9, 'Wrong value (C)');
end;

procedure TTestObserverManualSingle.TestObserver_Functions;
begin
  fSubject.IntValue := 3;
  fObserver.Subject := fSubject;
  fSubject.IntValue := 5;
  //  Validations
  Assert.AreSame(fObserver.CopiedSubject, fSubject, 'Wrong subject');
  Assert.AreEqual(fObserver.CopiedInt, 5, 'Wrong value');
end;

procedure TTestObserverManualSingle.TestObserver_ObserverDiesFirst;
begin
  fSubject.IntValue := 3;
  fObserver.Subject := fSubject;
  fSubject.IntValue := 5;

  Assert.AreEqual(fObserver.CopiedInt, 5, 'Wrong value');

  FreeAndNil(fObserver);

  Assert.IsFalse(fSubject.OnEvents.HasSubscriptions, 'Subject should have no subscriptions');

  FreeAndNil(fSubject);
end;

procedure TTestObserverManualSingle.TestObserver_SubjectDiesFirst;
begin
  fSubject.IntValue := 3;
  fObserver.Subject := fSubject;

  fSubject.IntValue := 5;
  try
    fSubject.Free;
  finally
    fSubject  := nil;
  end;

  Assert.AreEqual(fObserver.CopiedInt, 5, 'Wrong value');

  FreeAndNil(fObserver);
end;

{ TObserverSum }

procedure TObserverSum.IntEvent(ASubject: TObject; AParam: integer);
begin
  inc(fSum, AParam);
end;

procedure TObserverSum.Subscribe(const Subject: TSubject);
begin
  Subject.OnEvents.Subscribe(IntEvent)
end;

procedure TObserverSum.Unsubscribe(const Subject: TSubject);
begin
  Subject.OnEvents.Unsubscribe(IntEvent)
end;

{ TTestObserverManualMultiple }

procedure TTestObserverManualMultiple.Setup;
begin
  fSubject1   := TSubject.Create;
  fSubject2   := TSubject.Create;
  fSubject3   := TSubject.Create;
  fObserver1  := TObserverSum.Create;
  fObserver2  := TObserverSum.Create;
  fObserver3  := TObserverSum.Create;
end;

procedure TTestObserverManualMultiple.TearDown;
begin
  fSubject1.Free;
  fSubject2.Free;
  fSubject3.Free;
  fObserver1.Free;
  fObserver2.Free;
  fObserver3.Free;
end;

procedure TTestObserverManualMultiple.TestObserver_MultipleObservers;
begin
  fObserver1.Subscribe(fSubject1);
  fObserver2.Subscribe(fSubject1);

  fSubject1.IntValue  := 3;

  Assert.AreEqual(fObserver1.Sum, 3, 'Wrong value (A1)');
  Assert.AreEqual(fObserver2.Sum, 3, 'Wrong value (A2)');
  Assert.AreEqual(fObserver3.Sum, 0, 'Wrong value (A3)');

  fObserver3.Subscribe(fSubject1);
  fSubject1.IntValue  := 5;

  Assert.AreEqual(fObserver1.Sum, 8, 'Wrong value (B1)');
  Assert.AreEqual(fObserver2.Sum, 8, 'Wrong value (B2)');
  Assert.AreEqual(fObserver3.Sum, 5, 'Wrong value (B3)');
end;

procedure TTestObserverManualMultiple.TestObserver_MultipleSubjects;
begin
  fObserver1.Subscribe(fSubject1);
  fObserver1.Subscribe(fSubject2);

  Assert.AreEqual(fObserver1.Sum, 0, 'Wrong value (A1)');

  fSubject1.IntValue  := 3;

  Assert.AreEqual(fObserver1.Sum, 3, 'Wrong value (B1)');

  fSubject2.IntValue  := 5;

  Assert.AreEqual(fObserver1.Sum, 8, 'Wrong value (C1)');
end;

procedure TTestObserverManualMultiple.TestObserver_RepeatedSubscriptions;
begin
  fObserver1.Subscribe(fSubject1);

  fSubject1.IntValue  := 3;
  Assert.AreEqual(fObserver1.Sum, 3, 'Wrong value (A1)');

  fObserver1.Subscribe(fSubject1);

  fSubject1.IntValue  := 5;
  Assert.AreEqual(fObserver1.Sum, 8, 'Wrong value (B1)');
end;

{ TSubjectPlain }

constructor TSubjectPlain.Create;
begin
  inherited;
  fOnEvents := TNotifyEvents.Create(Self);
end;

destructor TSubjectPlain.Destroy;
begin
  fOnEvents.Free;
  inherited;
end;

{ TObserverFunctionality }

constructor TObserverFunctionality.Create(const ASubject: TSubjectPlain; const AInt: integer; AFunctionality: TFunctionality);
begin
  inherited Create;
  fSubject        := ASubject;
  fInt            := AInt;
  fFunctionality  := AFunctionality;
  fSubject.OnEvents.Subscribe(Event);
end;

destructor TObserverFunctionality.Destroy;
begin
  fSubject.OnEvents.Unsubscribe(Event);
  inherited;
end;

procedure TObserverFunctionality.Event(Sender: TObject);
begin
  fFunctionality(Self)
end;

{ TTestObserverManualFlow }

function TTestObserverManualFlow.CreateObserver(const AInt: integer; AFunctionality: TFunctionality): TObserverFunctionality;
begin
  Result  := TObserverFunctionality.Create(fSubject, AInt, AFunctionality);
  fObservers.Add(Result);
end;

procedure TTestObserverManualFlow.Setup;
begin
  fSubject    := TSubjectPlain.Create;
  fObservers  := TObjectList<TObserverFunctionality>.Create;
  fCounter  := 0;
  fResult   := 0;
end;

procedure TTestObserverManualFlow.TearDown;
begin
  fObservers.Free;
  fSubject.Free;
end;

procedure TTestObserverManualFlow.TestObserver_FlowAdd;
var
  Func: TFunctionality;
begin
  Func  := procedure (Observer: TObserverFunctionality)
    begin
      inc(fCounter);
      if  Observer.Int > 0  then
        CreateObserver(Observer.Int - 1, Func);
    end;

  CreateObserver(3, Func);
  fSubject.OnEvents.Call;

  Assert.AreEqual(fCounter, 4, 'Observers not added correctly')
end;

procedure TTestObserverManualFlow.TestObserver_FlowRemove;
var
  DeleteAt: integer;
var
  Func: TFunctionality;

  procedure TestFlowRemove(const NrObservers, ADeleteAt, Expect: integer);
  var
    i: integer;
  begin
    fObservers.Clear;
    Assert.IsFalse(fSubject.OnEvents.HasSubscriptions, 'Should be no subscriptions');
    for i := 1 to 10 do
      CreateObserver(i, Func);
    fCounter  := 0;
    DeleteAt  := ADeleteAt;
    fSubject.OnEvents.Call;
    Assert.AreEqual(fCounter, Expect, 'Delete around failed: ' + fCounter.ToString + '/' + DeleteAt.ToString);
  end;

begin
  Func  := procedure (Observer: TObserverFunctionality)
    var
      i: integer;
    begin
      inc(fCounter);
      if  fCounter = DeleteAt then
        for i := fObservers.Count - 1 downto 0 do
          if  (i mod 2) = 0  then
            fObservers.Delete(i);
    end;

  TestFlowRemove(10, 4, 7);
  TestFlowRemove(10, 5, 8);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestObserverManualSingle);
  TDUnitX.RegisterTestFixture(TTestObserverManualMultiple);

end.
