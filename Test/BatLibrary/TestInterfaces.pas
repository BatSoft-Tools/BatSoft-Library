unit TestInterfaces;

interface

uses
  DUnitX.TestFramework, BatSoft.Classes;

type
  [TestFixture]
  TTestInterfaces = class
  public
    [Test]
    procedure TestNoRefCountObject;
    [Test]
    procedure TestRefCountMyOwner;
  end;

  [TestFixture]
  TTestInterfaceRegistry = class
  private type

    IAlpha = interface
      ['{AC7EA6A6-43F2-44ED-8784-DEEFC69D94B7}']
      function GetString: string;
    end;

    IBeta = interface(IAlpha)
      ['{BC97DB7F-F8B8-4437-9D80-277FA75D8B15}']
      function GetString: string;
    end;

    IGamma = interface
      ['{67433553-3554-4685-B628-F9D10FA401CA}']
      function GetString: string;
    end;

    TImpl = class(TInterfacedObject)
    private
      fString: string;
    public
      constructor Create(const AString: string);
      function GetString: string;
    end;

    TAlpha = class(TImpl, IAlpha);
    TBeta = class(TImpl, IBeta);
    TGamma = class(TImpl, IGamma);

  private const
    SAlpha  = 'Alpha';
    SBeta1  = 'Beta1';
    SBeta2  = 'Beta2';
    SGamma  = 'Gamma';
  private
    fRegistry: TInterfaceRegistry;
    procedure RegisterBeta2;
    procedure RegisterFaulty;
  public
    [Setup]
    procedure Setup();
    [TearDown]
    procedure Teardown();
    [Test]
    procedure TestRegisterFaulty;
    [Test]
    procedure TestRegister;
  end;

implementation

uses
  SysUtils, DUnitX.Assert.Ex;

type
  TCallback = reference to procedure;

  TTestNoRef = class(TInterfacedObjectNoRefCount)
  private
    fCallback: TCallback;
  public
    constructor Create(const ACallback: TCallback);
    destructor  Destroy; override;
  end;

  TTestRefCountOwner = class(TRefCountMyOwner)
  private
    fCallback: TCallback;
  public
    constructor Create(const AOwner: TObject; const ACallback: TCallback);
    destructor  Destroy; override;
  end;

  TTestOwner = class(TObject, IInterface)
  private
    fCallback: TCallback;
    fIntf: IInterface;
  public
    constructor Create(const ACallback: TCallback);
    destructor  Destroy; override;
    property  Intf: IInterface  read fIntf  implements IInterface;
  end;

{ TTestNoRef }

constructor TTestNoRef.Create(const ACallback: TCallback);
begin
  inherited Create;
  fCallback := ACallback;
end;

destructor TTestNoRef.Destroy;
begin
  fCallback();
  inherited;
end;

{ TTestRefCountOwner }

constructor TTestRefCountOwner.Create(const AOwner: TObject; const ACallback: TCallback);
begin
  inherited Create(AOwner);
  fCallback := ACallback;
end;

destructor TTestRefCountOwner.Destroy;
begin
  fCallback();
  inherited;
end;

{ TTestOwner }

constructor TTestOwner.Create(const ACallback: TCallback);
begin
  inherited Create;
  fCallback := ACallback;
end;

destructor TTestOwner.Destroy;
begin
  fCallback();
  inherited;
end;

{ TTestInterfaces }

procedure TTestInterfaces.TestNoRefCountObject;
var
  Test: TTestNoRef;
  Intf: IInterface;
  IsDestroyed: Boolean;
begin
  IsDestroyed := False;
  Test  := TTestNoRef.Create(
    procedure()
    begin
      IsDestroyed := True;
    end);

  Assert.IsFalse(IsDestroyed);
  Intf  := Test;
  Assert.IsFalse(IsDestroyed);
  Intf  := nil;
  Assert.IsFalse(IsDestroyed);
  Test.Free;
  Assert.IsTrue(IsDestroyed);
end;

procedure TTestInterfaces.TestRefCountMyOwner;
var
  Owner: TTestOwner;
  OwnerI: IInterface;
  IsOwnerDestroyed, IsChildDestroyed: Boolean;
begin
  IsOwnerDestroyed  := False;
  IsChildDestroyed  := False;

  Owner := TTestOwner.Create(
    procedure()
    begin
      IsOwnerDestroyed  := True;
    end);

  Owner.fIntf := TTestRefCountOwner.Create(Owner,
    procedure()
    begin
      IsChildDestroyed  := True;
    end);

  Assert.IsFalse(IsOwnerDestroyed);
  Assert.IsFalse(IsChildDestroyed);

  OwnerI  := Owner;

  Assert.IsFalse(IsOwnerDestroyed);
  Assert.IsFalse(IsChildDestroyed);

  OwnerI  := nil;

  Assert.IsTrue(IsOwnerDestroyed);
  Assert.IsTrue(IsChildDestroyed);
end;

{ TTestInterfaceRegistry.TImpl }

constructor TTestInterfaceRegistry.TImpl.Create(const AString: string);
begin
  inherited Create;
  fString := AString;
end;

function TTestInterfaceRegistry.TImpl.GetString: string;
begin
  Result  := fString;
end;

{ TTestInterfaceRegistry }

procedure TTestInterfaceRegistry.RegisterBeta2;
begin
  fRegistry.Register(IBeta, TBeta.Create(SBeta2));
end;

procedure TTestInterfaceRegistry.RegisterFaulty;
begin
  fRegistry.Register(IBeta, TGamma.Create(SBeta2));
end;

procedure TTestInterfaceRegistry.Setup;
begin
  fRegistry := TInterfaceRegistry.Create;
end;

procedure TTestInterfaceRegistry.Teardown;
begin
  fRegistry.Free;
end;

procedure TTestInterfaceRegistry.TestRegister;
var
  Alpha: IAlpha;
  Beta: IBeta;
  Gamma: IGamma;
begin
  //  Register and Obtain
  Assert.IsFalse(fRegistry.TryObtain<IAlpha>(Alpha));
  Assert.IsFalse(fRegistry.TryObtain<IBeta>(Beta));
  Assert.IsFalse(fRegistry.TryObtain<IGamma>(Gamma));

  fRegistry.Register(IAlpha, TAlpha.Create(SAlpha));
  fRegistry.Register(IBeta, TBeta.Create(SBeta1));
  fRegistry.Register(IGamma, TGamma.Create(SGamma));

  Assert.IsTrue(fRegistry.TryObtain<IAlpha>(Alpha));
  Assert.IsTrue(fRegistry.TryObtain<IBeta>(Beta));
  Assert.IsTrue(fRegistry.TryObtain<IGamma>(Gamma));

  Assert.AreEqual(Alpha.GetString, SAlpha);
  Assert.AreEqual(Beta.GetString, SBeta1);
  Assert.AreEqual(Gamma.GetString, SGamma);

  //  Register on top of already registered
  //  - Exception
  Assert.WillRaise(RegisterBeta2, EListError);
  Assert.IsTrue(fRegistry.TryObtain<IBeta>(Beta));
  Assert.AreEqual(Beta.GetString, SBeta1);
  //  - Replace
  fRegistry.Register(IBeta, TBeta.Create(SBeta2), True);
  Assert.IsTrue(fRegistry.TryObtain<IBeta>(Beta));
  Assert.AreEqual(Beta.GetString, SBeta2);
end;

procedure TTestInterfaceRegistry.TestRegisterFaulty;
const
  SEDoesNotImplement  = 'SEDoesNotImplement';
begin
  Assert.WillRaise(RegisterFaulty, EBatSoft, SEDoesNotImplement)
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInterfaces);

end.
