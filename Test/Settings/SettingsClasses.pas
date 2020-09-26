unit SettingsClasses;

interface

uses
  System.Classes, System.Generics.Collections, BatSoft.Settings, BatSoft.Mementos;

type
  TEnum = (enumABC, enumDEF, enumXYZ);
  TEnumSet = set of TEnum;
const
  EnumCount = Ord(High(TEnum)) - Ord(Low(TEnum));
var
  EnumSetCount  : integer;

type
{$M+}
  TSimpleValues = class
  private
    fValueInt: integer;
    fValueCar: Cardinal;
    fValueDouble: Double;
    [MementoIgnore]
    fValueExt: Extended;
    fValueCurr: Currency;
    fValueStr: string;
    fValueBool: Boolean;
    fValueEnum: TEnum;
    fValueEnumSet: TEnumSet;
    fValueClass: TClass;
    [MementoIgnore]
    fDate: TDate;
    [MementoIgnore]
    fTime: TTime;
    [MementoIgnore]
    fDateTime: TDateTime;
  public
    function  Init(const A: integer): TSimpleValues; virtual;
  published
    property  ValueInt    : integer   read fValueInt      write fValueInt;
    property  ValueCar    : Cardinal  read fValueCar      write fValueCar;
    property  ValueDouble : Double    read fValueDouble   write fValueDouble;
    property  ValueExt    : Extended  read fValueExt      write fValueExt;
    property  ValueCurr   : Currency  read fValueCurr     write fValueCurr;
    property  ValueStr    : string    read fValueStr      write fValueStr;
    property  ValueBool   : Boolean   read fValueBool     write fValueBool;
    property  ValueEnum   : TEnum     read fValueEnum     write fValueEnum;
    property  ValueEnumSet: TEnumSet  read fValueEnumSet  write fValueEnumSet;
    property  ValueClass  : TClass    read fValueClass    write fValueClass;
    property  Date        : TDate     read fDate          write fDate;
    property  Time        : TTime     read fTime          write fTime;
    property  DateTime    : TDateTime read fDateTime      write fDateTime;
  end;

  TObjBase = class
  private
    fValueInt: integer;
    fValueStr: string;
  public
    function  Init(const A: integer): TObjBase; virtual;
  published
    property  ValueInt    : integer   read fValueInt      write fValueInt;
    property  ValueStr    : string    read fValueStr      write fValueStr;
  end;

  TObjSub = class(TObjBase)
  private
    fValueEnum: TEnum;
  public
    function  Init(const A: integer): TObjBase; override;
  published
    property  ValueEnum   : TEnum     read fValueEnum     write fValueEnum;
  end;

  TObjList = class(TObjectList<TObjBase>);

  TAllTypes = class
  private
    [MementoDeepField]
    fValues: TSimpleValues;
    [MementoDeepField]
    fObj: TObjBase;
    [MementoDeepField]
    fObjExt: TObjBase;
    [MementoDeepField]
    fObjNil: TObjBase;
    [MementoIgnore]
    fObjList: TObjList;
    fStrs: TStringList;
    [MementoDeepField]
    fStrsDeep: TStringList;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Init1;
  published
    property  Values    : TSimpleValues   read fValues    write fValues;
    property  Obj       : TObjBase        read fObj       write fObj;
    property  ObjExt    : TObjBase        read fObjExt    write fObjExt;
    property  ObjNil    : TObjBase        read fObjNil    write fObjNil;
    property  ObjList   : TObjList        read fObjList   write fObjList;
    property  Strs      : TStringList     read fStrs      write fStrs;
    [SettingsDeepField]
    property  StrsDeep  : TStringList     read fStrsDeep  write fStrsDeep;
  end;
{$M-}

implementation

uses
  SysUtils;

var
  When  : TDateTime;

{ TSimpleValues }

function TSimpleValues.Init(const A: integer): TSimpleValues;
begin
  Result  := Self;
  fValueInt     := 100 + A;
  fValueCar     := 200 + A;
  fValueDouble  := 300.456 + A;
  fValueExt     := 400.456 + A;
  fValueCurr    := 1.2345;
  fValueStr     := 'ABC' + A.ToString;
  fValueBool    := Odd(A);
  fValueEnum    := TEnum(A mod EnumCount);
  fValueEnumSet := [enumABC, enumXYZ];
  fValueClass   := TObjBase;
  fDate         := When;
  fTime         := When;
  fDateTime     := When;
end;

{ TObjBase }

function TObjBase.Init(const A: integer): TObjBase;
begin
  Result    := Self;
  fValueInt := 100 + A;
  fValueStr := 'ABC' + A.ToString;
end;

{ TObjSub }

function TObjSub.Init(const A: integer): TObjBase;
begin
  Result      := inherited;
  fValueEnum  := TEnum(A mod EnumCount);
end;

{ TAllTypes }

constructor TAllTypes.Create;
begin
  inherited;
  fStrs     := TStringList.Create;
  fStrsDeep := TStringList.Create;
  fObjList  := TObjList.Create;
end;

destructor TAllTypes.Destroy;
begin
  fStrs.Free;
  fStrsDeep.Free;
  fObjList.Free;
  inherited;
end;

procedure TAllTypes.Init1;
begin
  fValues   := TSimpleValues.Create.Init(1);
  fObj      := TObjBase.Create.Init(2);
  fObjExt   := TObjSub.Create.Init(3);
  fObjNil   := nil;
  fStrs.Add('ABC');
  fStrs.Add('DEF');
  fStrs.Add('HIJ');
  fStrsDeep.AddObject('Elem X', TObjBase.Create.Init(4));
  fStrsDeep.AddObject('Elem Y', nil);
  fStrsDeep.AddObject('Elem Z', TObjSub.Create.Init(5));
end;

initialization
  ObjectLists.Register(TObjList, TObjBase);
  When  := Now;

end.
