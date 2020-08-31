unit TestObjects;

interface

uses
  SysUtils, Classes, Math;

type
  TEnum = (enumABC, enumDEF, enumXYZ);
  TEnumSet = set of TEnum;
const
  EnumCount = Ord(High(TEnum)) - Ord(Low(TEnum));
var
  EnumSetCount  : integer;

type
  TEnumHelper = record helper for TEnum
  public
    function ToString: string;
  end;

  TEnumSetHelper = record helper for TEnumSet
  public
    function ToString: string;
  end;

{$M+}
  TSettLeaf = class
  private
    fA: integer;
    fValueInt: integer;
    fValueCar: Cardinal;
    fValueDouble: Double;
    fValueExt: Extended;
    fValueStr: string;
    fValueBool: Boolean;
    fValueEnum: TEnum;
    fValueEnumSet: TEnumSet;
    fValueClass: TClass;
  public
    function  Init(const A: integer): TSettLeaf;
    procedure Test;
  published
    property  ValueInt    : integer   read fValueInt      write fValueInt;
    property  ValueCar    : Cardinal  read fValueCar      write fValueCar;
    property  ValueDouble : Double    read fValueDouble   write fValueDouble;
    property  ValueExt    : Extended  read fValueExt      write fValueExt;
    property  ValueStr    : string    read fValueStr      write fValueStr;
    property  ValueBool   : Boolean   read fValueBool     write fValueBool;
    property  ValueEnum   : TEnum     read fValueEnum     write fValueEnum;
    property  ValueEnumSet: TEnumSet  read fValueEnumSet  write fValueEnumSet;
    property  ValueClass  : TClass    read fValueClass    write fValueClass;
  end;

  TSettList = class(TStringList)
  public
    function  Init: TSettList;
    procedure Test;
  end;

  TSettBranch = class
  private
    fValueLeaf: TSettLeaf;
    fValueNil: TSettLeaf;
    fValueRead: TSettLeaf;
    fValueWrite: TSettLeaf;
    fValueList: TSettList;
  public
    procedure Init;
    procedure Test;
  published
    property  ValueLeaf   : TSettLeaf read fValueLeaf     write fValueLeaf;
    property  ValueNil    : TSettLeaf read fValueNil;
    property  ValueRead   : TSettLeaf read fValueRead;
    property  ValueWrite  : TSettLeaf                     write fValueWrite;
    property  ValueList   : TSettList read fValueList     write fValueList;
  end;
{$M-}

  ESett = class(Exception);

implementation

uses
  TypInfo, RTTI;

{ TEnumHelper }

function TEnumHelper.ToString: string;
begin
  Result  := GetEnumName(TypeInfo(TEnum), Ord(Self))
end;

{ TEnumSetHelper }

function TEnumSetHelper.ToString: string;
var
  Enum: TEnum;
begin
  Result  := '';
  for Enum := Low(TEnum) to High(TEnum) do
    if  Enum in Self  then
      begin
        if  not Result.IsEmpty  then
          Result  := Result + ', ';
        Result  := Result + Enum.ToString
      end;
end;

{ TSettLeaf }

function TSettLeaf.Init(const A: integer): TSettLeaf;
begin
  fA  := A;
  fValueInt     := 100 + A;
  fValueCar     := 200 + A;
  fValueDouble  := 300.456 + A;
  fValueExt     := 400.456 + A;
  fValueStr     := 'ABC' + A.ToString;
  fValueBool    := Odd(A);
  fValueEnum    := TEnum(A mod EnumCount);
  fValueEnumSet := [enumABC, enumXYZ];
  fValueClass   := TPersistent;
  Result  := Self;
end;

procedure TSettLeaf.Test;

  procedure CompareValues(const PropName: string; const IsSame: Boolean; const ValueAct, ValueExp: string);
  begin
    if  not IsSame  then
      raise ESett.Create('Property '+PropName+' is '+ValueAct+' but expected '+ValueExp+'.');
  end;

var
  Comp: TSettLeaf;
begin
  Comp  := TSettLeaf.Create;
  try
    Comp.Init(fA);
    CompareValues('ValueInt',     Self.ValueInt = Comp.ValueInt,          Self.ValueInt.ToString,     Comp.ValueInt.ToString);
    CompareValues('ValueCar',     Self.ValueCar = Comp.ValueCar,          Self.ValueCar.ToString,     Comp.ValueCar.ToString);
    CompareValues('ValueDouble',  Self.ValueDouble = Comp.ValueDouble,    Self.ValueDouble.ToString,  Comp.ValueDouble.ToString);
    CompareValues('ValueExt',     Self.ValueExt = Comp.ValueExt,          Self.ValueExt.ToString,     Comp.ValueExt.ToString);
    CompareValues('ValueStr',     Self.ValueStr = Comp.ValueStr,          Self.ValueStr,              Comp.ValueStr);
    CompareValues('ValueBool',    Self.ValueBool = Comp.ValueBool,        Self.ValueBool.ToString,    Comp.ValueBool.ToString);
    CompareValues('ValueEnum',    Self.ValueEnum = Comp.ValueEnum,        Self.ValueEnum.ToString,    Comp.ValueEnum.ToString);
    CompareValues('ValueEnumSet', Self.ValueEnumSet = Comp.ValueEnumSet,  Self.ValueEnumSet.ToString, Comp.ValueEnumSet.ToString);
    CompareValues('ValueClass',   Self.ValueClass = Comp.ValueClass,      Self.ValueClass.ClassName,  Comp.ValueClass.ClassName);
  finally
    Comp.Free;
  end;
end;

{ TSettList }

function TSettList.Init: TSettList;
begin
  AddObject('Leaf1', TSettLeaf.Create.Init(2));
  AddObject('Leaf2', TSettLeaf.Create.Init(6));
  AddObject('LeafNil', nil);
  Result  := Self;
end;

procedure TSettList.Test;
var
  i: integer;
  CompList: TSettList;
  Leaf, CompLeaf: TSettLeaf;
begin
  if  Count <> 2  then
    raise ESett.Create('Expected 3 items, but has '+Count.ToString+' items.');
  //  Compare each item
  CompList  := TSettList.Create.Init;
  try
    for i := 0 to Self.Count - 1  do
      begin
        Leaf      := Self.Objects[i] as TSettLeaf;
        CompLeaf  := CompList.Objects[CompList.IndexOf(Self[i])] as TSettLeaf;
        Leaf.Test;
      end;

  finally
    CompList.Free;
  end;
end;

{ TSettBranch }

procedure TSettBranch.Init;
begin
  fValueLeaf  := TSettLeaf.Create.Init(5);
  fValueNil   := nil;
  fValueRead  := TSettLeaf.Create.Init(1);
  fValueWrite := TSettLeaf.Create.Init(2);
  fValueList  := TSettList.Create.Init;
end;

procedure TSettBranch.Test;
begin
  fValueLeaf  := TSettLeaf.Create;
  fValueNil   := nil;
  fValueRead  := TSettLeaf.Create;
  fValueWrite := TSettLeaf.Create;
  fValueList  := TSettList.Create;
end;

initialization
  EnumSetCount :=  Round(Power(2, EnumCount) - 1);

end.
