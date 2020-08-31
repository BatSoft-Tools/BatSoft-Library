unit TestBinaryList;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, BatSoft.Classes;

type
  [TestFixture]
  TMyTestObject = class
  private const
    SAll  = '1,2,3,4,5,6,7,8,9';
    SOdd  = '1,3,5,7,9';
    SEven = '2,4,8,6';
  private
    fBinaryList: TBinaryList<string>;
    fUnsortedOdd, fUnsortedEven: TList<string>;
    function  GetState: string;
    procedure Add5();
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestAdd;
    [Test]
    procedure TestAddRangeArray;
    [Test]
    procedure TestAddRangeEnumerator;
    [Test]
    procedure TestClearAndCount;
    [Test]
    procedure TestDelete;
    [Test]
    procedure TestDeleteRange;
    [Test]
    procedure TestDuplicates;
    [Test]
    procedure TestIndexOf;
  end;

implementation

uses
  SysUtils, Classes;

{ TMyTestObject }

procedure TMyTestObject.Add5;
begin
  fBinaryList.Add('5');
end;

function TMyTestObject.GetState: string;
var
  Strs: TStringList;
  i: Integer;
begin
  Strs  := TStringList.Create;
  try
    for i := 0 to fBinaryList.Count - 1 do
      Strs.Add(fBinaryList[i]);
    Result  := Strs.CommaText;
  finally
    Strs.Free;
  end;
end;

procedure TMyTestObject.Setup;
begin
  fBinaryList := TBinaryList<string>.Create;
  //  Odd
  fUnsortedOdd  := TList<string>.Create;
  fUnsortedOdd.Add('5');
  fUnsortedOdd.Add('1');
  fUnsortedOdd.Add('7');
  fUnsortedOdd.Add('3');
  fUnsortedOdd.Add('9');
  //  Even
  fUnsortedEven := TList<string>.Create;
  fUnsortedEven.Add('2');
  fUnsortedEven.Add('4');
  fUnsortedEven.Add('8');
  fUnsortedEven.Add('6');
end;

procedure TMyTestObject.TearDown;
begin
  fBinaryList.Free;
  fUnsortedOdd.Free;
  fUnsortedEven.Free;
end;

procedure TMyTestObject.TestAdd;
begin
  fBinaryList.Add('5');
  fBinaryList.Add('1');
  fBinaryList.Add('7');
  fBinaryList.Add('2');
  fBinaryList.Add('3');
  fBinaryList.Add('4');
  fBinaryList.Add('8');
  fBinaryList.Add('6');
  fBinaryList.Add('9');

  Assert.AreEqual(GetState, SAll);
end;

procedure TMyTestObject.TestAddRangeArray;
begin
  fBinaryList.AddRange(fUnsortedOdd.ToArray);
  fBinaryList.AddRange(fUnsortedEven.ToArray);

  Assert.AreEqual(GetState, SAll);
end;

procedure TMyTestObject.TestAddRangeEnumerator;
begin
  fBinaryList.AddRange(fUnsortedOdd);
  fBinaryList.AddRange(fUnsortedEven);

  Assert.AreEqual(GetState, SAll);
end;

procedure TMyTestObject.TestClearAndCount;
begin
  fBinaryList.AddRange(fUnsortedOdd);

  Assert.AreEqual(fBinaryList.Count, 5);

  fBinaryList.Clear;

  Assert.AreEqual(fBinaryList.Count, 0);
end;

procedure TMyTestObject.TestDelete;
begin
  fBinaryList.AddRange(fUnsortedOdd);

  fBinaryList.Remove('7');
  Assert.AreEqual(GetState, '1,3,5,9');

  fBinaryList.Delete(1);
  Assert.AreEqual(GetState, '1,5,9');

  fBinaryList.Delete(0);
  Assert.AreEqual(GetState, '5,9');

  fBinaryList.Delete(1);
  Assert.AreEqual(GetState, '5');

  fBinaryList.Remove('5');
  Assert.AreEqual(GetState, '');
end;

procedure TMyTestObject.TestDeleteRange;
begin
  fBinaryList.AddRange(fUnsortedOdd);
  fBinaryList.AddRange(fUnsortedEven);
  fBinaryList.DeleteRange(3, 4);

  Assert.AreEqual(GetState, '1,2,3,8,9');
end;

procedure TMyTestObject.TestDuplicates;
begin
  fBinaryList.AddRange(fUnsortedOdd);

  //  Ignore
  fBinaryList.Duplicates  := TDuplicates.dupIgnore;
  fBinaryList.Add('3');

  Assert.AreEqual(GetState, SOdd);

  //  Exception
  fBinaryList.Duplicates  := TDuplicates.dupError;

  Assert.WillRaise(Add5, EArgumentException);

  //  Ignore/Allow
  fBinaryList.Duplicates  := TDuplicates.dupAccept;
  fBinaryList.Add('7');

  Assert.AreEqual(GetState, '1,3,5,7,7,9');
end;

procedure TMyTestObject.TestIndexOf;
begin
  fBinaryList.AddRange(fUnsortedEven);

  Assert.AreEqual(fBinaryList.IndexOf('2'),  0);
  Assert.AreEqual(fBinaryList.IndexOf('4'),  1);
  Assert.AreEqual(fBinaryList.IndexOf('8'),  3);

  Assert.AreEqual(fBinaryList.IndexOf('0'), -1);
  Assert.AreEqual(fBinaryList.IndexOf('1'), -1);
  Assert.AreEqual(fBinaryList.IndexOf('3'), -1);
  Assert.AreEqual(fBinaryList.IndexOf('9'), -1);
end;

end.
