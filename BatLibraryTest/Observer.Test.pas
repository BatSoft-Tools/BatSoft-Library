unit Observer.Test;

interface

uses
  DUnitX.TestFramework, SysUtils, Generics.Collections, BatSoft.Observer;

type
  [TestFixture]
  TObserverTest = class(TObject)
  private type

    EObserver = Exception;

    TObserver = class
    private
      fOwner: TObserverTest;
      fAmount: Integer;
      fFail: Boolean;
      fDead: Boolean;
    public
      constructor Create(const AOwner: TObserverTest; const AAmount: Integer; const AFail: Boolean);
      destructor  Destroy; override;
      procedure React(Sender: TObject);
    end;

    TObservers = TObjectList<TObserver>;

    TSubject = class
      fOnEvents: TNotifyEvents;
      constructor Create;
      destructor  Destroy; override;
      property  OnEvents  : TNotifyEvents read fOnEvents;
    end;

  private
    fTotal: integer;
    fObservers: TObservers;
    fSubject: TSubject;
    function  NewObserverAmount(const Amount: integer): TObserver;
    function  NewObserverFail: TObserver;
    procedure ExpectTotal(const ExpectedTotal: integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1_AllGood;
    [Test]
    procedure Test2_Fail;
    [Test]
    procedure Test3_RemoveSubject;
    [Test]
    procedure Test4_RemoveObserver;
//    // Test with TestCase Attribute to supply parameters.
//    [Test]
//    [TestCase('TestA','1,2')]
//    [TestCase('TestB','3,4')]
//    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

{ TObserverTest.TObserver }

constructor TObserverTest.TObserver.Create(const AOwner: TObserverTest;
  const AAmount: Integer; const AFail: Boolean);
begin
  inherited Create;
  fOwner  := AOwner;
  fAmount := AAmount;
  fFail   := AFail;
end;

destructor TObserverTest.TObserver.Destroy;
begin
  fDead := True;
  inherited;
end;

procedure TObserverTest.TObserver.React(Sender: TObject);
begin
  if  fDead then
    raise EObserver.Create('Already dead: '+fAmount.ToHexString);
  if  fFail then
    raise EObserver.Create('Failed: '+fAmount.ToHexString);
  inc(fOwner.fTotal, fAmount)
end;

{ TObserverTest.TSubject }

constructor TObserverTest.TSubject.Create;
begin
  inherited;
  fOnEvents := TNotifyEvents.Create(Self);
end;

destructor TObserverTest.TSubject.Destroy;
begin
  fOnEvents.Free;
  inherited;
end;

{ TObserverTest }

procedure TObserverTest.ExpectTotal(const ExpectedTotal: integer);
begin
  if  fTotal <> ExpectedTotal then
    raise Exception.Create('Expected '+ExpectedTotal.ToHexString+' but got '+fTotal.ToHexString);
end;

function TObserverTest.NewObserverAmount(const Amount: integer): TObserver;
begin
  Result  := TObserver.Create(Self, Amount, False);
  fObservers.Add(Result);
  fSubject.OnEvents.Subscribe(Result.React);
end;

function TObserverTest.NewObserverFail: TObserver;
begin
  Result  := TObserver.Create(Self, 0, True);
  fObservers.Add(Result);
  fSubject.OnEvents.Subscribe(Result.React);
end;

procedure TObserverTest.Setup;
begin
  fTotal      := 0;
  fObservers  := TObservers.Create(True);
  fSubject    := TSubject.Create;
end;

procedure TObserverTest.TearDown;
begin
  FreeAndNil(fSubject);
  FreeAndNil(fObservers);
end;

procedure TObserverTest.Test1_AllGood;
begin
  NewObserverAmount($1);
  NewObserverAmount($10);
  fSubject.OnEvents.Call;
  fSubject.OnEvents.Call;
  fSubject.OnEvents.Call;
  ExpectTotal($33);
end;

procedure TObserverTest.Test2_Fail;
begin
  NewObserverAmount($1);
  NewObserverFail;
  NewObserverAmount($10);
  try
    fSubject.OnEvents.Call;
    fSubject.OnEvents.Call;
    fSubject.OnEvents.Call;
  except on X: EObserver do
    ExpectTotal($1);
  end;
end;

procedure TObserverTest.Test3_RemoveSubject;
begin
  FreeAndNil(fSubject);
  FreeAndNil(fObservers);
end;

procedure TObserverTest.Test4_RemoveObserver;
begin
  NewObserverAmount($1);
  NewObserverAmount($10);
  NewObserverAmount($100);
  fObservers.Delete(1);
  fSubject.OnEvents.Call;
  ExpectTotal($101);
end;

initialization
  TDUnitX.RegisterTestFixture(TObserverTest);
end.
