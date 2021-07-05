unit TestInterfaces;

interface

uses
  DUnitX.TestFramework, System.SysUtils, BatSoft.Classes;

type
  IIntfOne = interface
    ['{7FDA1271-F73F-4D8D-9B63-D75DB513EC43}']
    function GetOne: string;
  end;

  IIntfTwo = interface
    ['{CA625822-620F-44AE-BF49-6847EE517FE1}']
    function GetTwo: string;
  end;

  TOneTwo = class(TObject, IIntfOne, IIntfTwo)
  private
    fRefCounter: IInterface;
    fDestroyProc: TProc;
  public
    constructor Create(const ADestroyProc: TProc);
    destructor  Destroy; override;
    //  IInterface interface
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    //  IIntfOne interface
    function GetOne: string;
    //  IIntfTwo interface
    function GetTwo: string;
  end;

  [TestFixture]
  TTestInterfaces = class
  public
    [Test]
    procedure TestNoRefCountObject;
    [Test]
    procedure TestRefCountMyOwner_IInterface;
    [Test]
    procedure TestRefCountMyOwner_OneTwo;
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
  DUnitX.Assert.Ex;

type
  TTestNoRef = class(TInterfacedObjectNoRefCount)
  private
    fCallback: TProc;
  public
    constructor Create(const ACallback: TProc);
    destructor  Destroy; override;
  end;

  TTestRefCountOwner = class(TRefCountMyOwner)
  private
    fCallback: TProc;
  public
    constructor Create(const AOwner: TObject; const ACallback: TProc);
    destructor  Destroy; override;
  end;

  TTestOwner = class(TObject, IInterface)
  private
    fCallback: TProc;
    fIntf: IInterface;
  public
    constructor Create(const ACallback: TProc);
    destructor  Destroy; override;
    property  Intf: IInterface  read fIntf  implements IInterface;
  end;

{ TTestNoRef }

constructor TTestNoRef.Create(const ACallback: TProc);
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

constructor TTestRefCountOwner.Create(const AOwner: TObject; const ACallback: TProc);
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

constructor TTestOwner.Create(const ACallback: TProc);
begin
  inherited Create;
  fCallback := ACallback;
end;

destructor TTestOwner.Destroy;
begin
  fCallback();
  inherited;
end;

{ TOneTwo }

constructor TOneTwo.Create(const ADestroyProc: TProc);
begin
  inherited Create();
  fRefCounter   := TRefCountMyOwner.Create(Self);
  fDestroyProc  := ADestroyProc;
end;

destructor TOneTwo.Destroy;
begin
  fDestroyProc();
  inherited;
end;

function TOneTwo.GetOne: string;
begin
  Result  := 'One'
end;

function TOneTwo.GetTwo: string;
begin
  Result  := 'Two'
end;

function TOneTwo.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TOneTwo._AddRef: Integer;
begin
  Result  := fRefCounter._AddRef
end;

function TOneTwo._Release: Integer;
begin
  Result  := fRefCounter._Release
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

procedure TTestInterfaces.TestRefCountMyOwner_IInterface;
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

procedure TTestInterfaces.TestRefCountMyOwner_OneTwo;
var
  OneTwo: TOneTwo;
  One: IIntfOne;
  Two: IIntfTwo;
  IsDestroyed: Boolean;
begin
  IsDestroyed := False;
  OneTwo  := TOneTwo.Create(
      procedure
      begin
        IsDestroyed := True;
      end);
      
  One := OneTwo;
  Assert.AreEqual('One', One.GetOne);
  Assert.IsFalse(IsDestroyed);

  Assert.IsTrue(Supports(One, IIntfTwo, Two));
  Assert.AreEqual('One', One.GetOne);
  Assert.AreEqual('Two', Two.GetTwo);
  Assert.IsFalse(IsDestroyed);
  
  Two := nil;
  Assert.AreEqual('One', One.GetOne);
  Assert.IsFalse(IsDestroyed);

  One := nil;
  Assert.IsTrue(IsDestroyed);
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
