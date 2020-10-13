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

  TProcedure = procedure ();

  TSomeRecord = record
    Int: integer;
    Str: string;
  end;
  TDynamicArray = array of TSomeRecord;
  TFixedArray = array [1..3] of TSomeRecord;

  TTestBase = class
  private
    fInt: integer;
    fStrs: TStrings;
    fStr: string;
    fIntf: IIntfValue;
    fWhen: TDateTime;
    fFloat: double;
    fChild: TTestBase;
    fMeth: TNotifyEvent;
    fProc: TProcedure;
    fGUID: TGUID;
    fRec: TSomeRecord;
    fArrDyn: TDynamicArray;
    fArrFix: TFixedArray;
    procedure Notify1(Sender: TObject);
    procedure Notify2(Sender: TObject);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Populate;
    property  Str   : string        read fStr     write fStr;
    property  Int   : integer       read fInt     write fInt;
    property  Float : double        read fFloat   write fFloat;
    property  When  : TDateTime     read fWhen    write fWhen;
    property  Intf  : IIntfValue    read fIntf    write fIntf;
    property  Strs  : TStrings      read fStrs    write fStrs;
    property  Meth  : TNotifyEvent  read fMeth    write fMeth;
    property  Proc  : TProcedure    read fProc    write fProc;
    property  GUID  : TGUID         read fGUID    write fGUID;
    property  Rec   : TSomeRecord   read fRec     write fRec;
    property  ArrDyn: TDynamicArray read fArrDyn  write fArrDyn;
    property  ArrFix: TFixedArray   read fArrFix  write fArrFix;
    [MementoDeep]
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

procedure Proc;
begin

end;

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
  fGUID := TGUID.Empty;
end;

destructor TTestBase.Destroy;
begin
  fStrs.Free;
  fChild.Free;
  inherited;
end;

procedure TTestBase.Notify1(Sender: TObject);
begin

end;

procedure TTestBase.Notify2(Sender: TObject);
begin

end;

procedure TTestBase.Populate;

  function SameMethod(const Proc1, Proc2: TNotifyEvent): Boolean;
  var
    Meth1: TMethod absolute Proc1;
    Meth2: TMethod absolute Proc2;
  begin
    Result  := (Meth1.Code = Meth2.Code) and (Meth1.Data = Meth2.Data)
  end;

  function NewSomeRec(const A: integer): TSomeRecord;
  begin
    Result.Int  := 100 + A;
    Result.Str  := 'Str' + Chr(Ord('A') + A);
  end;

var
  i: Integer;
begin
  fInt    := fInt + 3;
  fStr    := fStr + 'A';
  fIntf   := TIntfValue.Create(fInt);
  fWhen   := Now;
  fFloat  := fInt / 2;
  fStrs.Add('Str_' + fInt.ToString);
  fGUID   := TGUID.NewGuid;

  if  Assigned(fChild)  then
    fChild.Populate;

  if not Assigned(fMeth) then
    fMeth := Notify1
  else if SameMethod(fMeth, Notify1) then
    fMeth := Notify2
  else if SameMethod(fMeth, Notify2) then
    fMeth := nil;

  if not Assigned(fProc) then
    fProc := Proc
  else
    fProc := nil;

  fRec  := NewSomeRec(1);
  for i := 1 to 3 do
    fArrFix[i]  := NewSomeRec(i);

  if not Assigned(fArrDyn) then
    begin
      SetLength(fArrDyn, fInt);
      for i := 0 to Length(fArrDyn) - 1 do
        fArrDyn[i]  := NewSomeRec(i);
    end
  else
    begin
      for i := 0 to Length(fArrDyn) - 1 do
        fArrDyn[i]  := NewSomeRec(i + fInt);
    end;
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
      Obj.Populate;
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
      Assert.AreEqual(Mem.VersionMax, 1);
      Assert.AreEqual(Mem.VersionNow, 1);

      Obj.Populate;
      Assert.IsTrue(Mem.HasChanges);

      Mem.Backup;
      Assert.IsFalse(Mem.HasChanges);
      Assert.AreEqual(Mem.VersionMax, 2);
      Assert.AreEqual(Mem.VersionNow, 2);

      Obj.Populate;
      Assert.IsTrue(Mem.HasChanges);

      WriteLn(GetChanges(Mem));

      Mem.Restore;
      Assert.IsFalse(Mem.HasChanges);

      Mem.Undo;
      Assert.IsFalse(Mem.HasChanges);
      Assert.AreEqual(Mem.VersionMax, 2);
      Assert.AreEqual(Mem.VersionNow, 1);

      Obj.Populate;
      Assert.IsTrue(Mem.HasChanges);

      Mem.Restore;
      Assert.IsFalse(Mem.HasChanges);

      Mem.Redo;
      Assert.IsFalse(Mem.HasChanges);
      Assert.AreEqual(Mem.VersionMax, 2);
      Assert.AreEqual(Mem.VersionNow, 2);
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
