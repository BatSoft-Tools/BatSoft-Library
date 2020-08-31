unit TestMementos;

interface

uses
  DUnitX.TestFramework, System.Classes, BatSoft.Mementos;

type
  IIntfValue = interface
    ['{A97C23B6-A03E-4365-8077-42A9CC2E7260}']
    function Value: Integer;
  end;

  TIntfValue = class(TInterfacedObject, IIntfValue)
  private
    fValue: integer;
  public
    constructor Create(const AValue: integer);
    //  IRefCounter interface
    function Value: Integer;
  end;

  TTestBase = class
  private
    fInt: integer;
    fStrs: TStrings;
    fStr: string;
    fIntf: IIntfValue;
    fWhen: TDateTime;
    fFloat: double;
    fChild: TTestBase;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Populate;
    property  Str   : string      read fStr   write fStr;
    property  Int   : integer     read fInt   write fInt;
    property  Float : double      read fFloat write fFloat;
    property  When  : TDateTime   read fWhen  write fWhen;
    property  Intf  : IIntfValue  read fIntf  write fIntf;
    property  Strs  : TStrings    read fStrs  write fStrs;
    [MementoDeepField]
    property  Child : TTestBase   read fChild write fChild;
  end;

  TTestBranch = class(TTestBase)
  public
    constructor Create;
  end;

  TTestRoot = class(TTestBase)
  public
    constructor Create;
  end;

  [TestFixture]
  TTestMementos = class
  private
    function  GetChanges(const Memento: TMemento): string;
    procedure TestBackup(const MementoClass: TMementoClass);
    procedure TestVersions(const MementoClass: TMementoVersionsClass);
  public
    [Test]
    procedure TestBackupField;
    [Test]
    procedure TestBackupProperty;
    [Test]
    procedure TestVersionsField;
    [Test]
    procedure TestVersionsProperty;
  end;

implementation

uses
  SysUtils;

{ TRefCounter }

constructor TIntfValue.Create(const AValue: integer);
begin
  inherited Create();
  fValue  := AValue;
end;

function TIntfValue.Value: Integer;
begin
  Result  := fValue
end;

{ TTestBase }

constructor TTestBase.Create;
begin
  inherited;
  fStrs := TStringList.Create;
end;

destructor TTestBase.Destroy;
begin
  fStrs.Free;
  fChild.Free;
  inherited;
end;

procedure TTestBase.Populate;
begin
  fInt    := fInt + 3;
  fStr    := fStr + 'A';
  fIntf   := TIntfValue.Create(fInt);
  fWhen   := Now;
  fFloat  := fInt / 2;
  fStrs.Add('Str_' + fInt.ToString);
  if  Assigned(fChild)  then
    fChild.Populate;
end;

{ TTestBranch }

constructor TTestBranch.Create;
begin
  inherited;
  fChild  := TTestBase.Create;
end;

{ TTestRoot }

constructor TTestRoot.Create;
begin
  inherited;
  fChild  := TTestBranch.Create;
end;

{ TTestMementos }

function TTestMementos.GetChanges(const Memento: TMemento): string;
var
  Changes: TChanges;
begin
  Changes := TChanges.Create;
  try
    Memento.ListChanges(Changes);
    Result  := Changes.ToString;
  finally
    Changes.Free;
  end;
end;

procedure TTestMementos.TestBackup(const MementoClass: TMementoClass);
var
  Obj: TTestRoot;
  Mem: TMemento;
  Str: string;
begin
  Obj := TTestRoot.Create;
  try
    Obj.Populate;

    Mem := MementoClass.Create(Obj);
    try
      Mem.Backup;

      Assert.IsFalse(Mem.HasChanges);

      Obj.Populate;

      Assert.IsTrue(Mem.HasChanges);
      Str := GetChanges(Mem);
      WriteLn(Str);

      Mem.Restore;

      Assert.IsFalse(Mem.HasChanges);

    finally
      Mem.Free;
    end;
  finally
    Obj.Free;
  end;
end;

procedure TTestMementos.TestBackupField;
begin
  TestBackup(TBackupFields);
end;

procedure TTestMementos.TestBackupProperty;
begin
  TestBackup(TBackupProperties);
end;

procedure TTestMementos.TestVersions(const MementoClass: TMementoVersionsClass);
var
  Obj: TTestRoot;
  Mem: TMementoVersions;
begin
  Obj := TTestRoot.Create;
  try
    Obj.Populate;

    Mem := MementoClass.Create(Obj);
    try
      Mem.Backup;

      Assert.IsFalse(Mem.HasChanges);

      Obj.Populate;

      Assert.IsTrue(Mem.HasChanges);

      Mem.Restore;

      Assert.IsFalse(Mem.HasChanges);

    finally
      Mem.Free;
    end;
  finally
    Obj.Free;
  end;
end;

procedure TTestMementos.TestVersionsField;
begin
  TestVersions(TVersionsFields);
end;

procedure TTestMementos.TestVersionsProperty;
begin
  TestVersions(TVersionsProperties);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMementos);

end.
