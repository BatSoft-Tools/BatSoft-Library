unit TestInterfaces;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestInterfaces = class
  public
    [Test]
    procedure TestNoRefCountObject;
    [Test]
    procedure TestRefCountMyOwner;
  end;

implementation

uses
  SysUtils, DUnitX.Assert.Ex, BatSoft.Classes;

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

initialization
  TDUnitX.RegisterTestFixture(TTestInterfaces);

end.
