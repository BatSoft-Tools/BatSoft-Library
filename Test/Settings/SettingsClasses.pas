unit SettingsClasses;

interface

uses
  System.Types, System.Classes, System.Generics.Collections,
  BatSoft.Classes, BatSoft.Settings, BatSoft.Mementos, BatSoft.Settings.Types;

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
    fDate: TDate;
    [MementoIgnore] //  Don't do memento comparison because of rounding errors
    fTime: TTime;
    [MementoIgnore] //  Don't do memento comparison because of rounding errors
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

  //  This has specific conversion routines in procedure RegisterComplexType
  TTestRecord = record
  private
    fStr: string;
    fDate: TDate;
  public
    property  Str   : string  read fStr   write fStr;
    property  When  : TDate   read fDate  write fDate;
  end;

//  Streaming of TList<> is not yet supported.
//  It might actually work, but I haven't implementted comparison of TList<> in
//  memento's yet, so the unit test don't work.
//
//  NOTE: Ask me if you want it, and I'll make it happen.
//
//  TRecList = class(TRegisteredList<TTestRecord>)
//  public
//    procedure Init;
//    function  AddRec(const Value: integer): integer;
//  end;
//
//  TIntList = class(TList<integer>);

  TComplexValues = class
  private
    fGUID: TGUID;
    fRect: TRect;
    fTestRec: TTestRecord;
  public
    function  Init: TComplexValues;
  published
    property  ValueGUID   : TGUID       read fGUID      write fGUID;
    property  ValueRect   : TRect       read fRect      write fRect;
    property  ValueTestRec: TTestRecord read fTestRec   write fTestRec;
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

  TCntrTypes = class
  private
    [MementoIgnore]
    fObjList: TObjList;
    fStrs: TStringList;
    [MementoDeep]
    fStrsDeep: TStringList;
//    fRecList: TRecList;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Init1; virtual;
    procedure Init2;
  published
    property  ObjList   : TObjList      read fObjList   write fObjList;
    property  Strs      : TStringList   read fStrs      write fStrs;
    [SettingsDeep]
    property  StrsDeep  : TStringList   read fStrsDeep  write fStrsDeep;
//    //  Record list
//    property  RecList   : TRecList   read fRecList   write fRecList;
  end;

  TAllTypes = class(TCntrTypes)
  private
    [MementoDeep]
    fSimple: TSimpleValues;
    [MementoDeep]
    fComplex: TComplexValues;
    [MementoDeep]
    fObj: TObjBase;
    [MementoDeep]
    fObjExt: TObjBase;
    [MementoDeep]
    fObjNil: TObjBase;
  public
    destructor  Destroy; override;
    procedure Init1; override;
  published
    property  Simple    : TSimpleValues   read fSimple    write fSimple;
    property  Complex   : TComplexValues  read fComplex   write fComplex;
    property  Obj       : TObjBase        read fObj       write fObj;
    property  ObjExt    : TObjBase        read fObjExt    write fObjExt;
    property  ObjNil    : TObjBase        read fObjNil    write fObjNil;
  end;
{$M-}

implementation

uses
  SysUtils, RTTI;

var
  When  : TDateTime;

procedure RegisterComplexType;
begin
  SettingsTypes.Register(TypeInfo(TTestRecord),
    procedure (const Value: TValue; const SaveValue: TSimpleSaver)
    var
      TestRec: TTestRecord;
      Temp: TValue;
    begin
      TestRec := Value.AsType<TTestRecord>(True);
      SaveValue('Str', TestRec.Str);
      Temp    := TestRec.When;
      Temp    := SettingsTypes.ConvertToStore(TypeInfo(TDate), Temp);
      SaveValue('When', Temp);
    end,
    function (const LoadValue: TSimpleLoader): TValue
    var
      TestRec: TTestRecord;
      Temp: TValue;
      Ext: Extended;
    begin
      TestRec.Str   := LoadValue('Str', TypeInfo(string)).AsString;
      Temp    := LoadValue('When', TypeInfo(string)).AsString;
      Temp    := SettingsTypes.ConvertToProperty(TypeInfo(TDate), Temp);
      Ext     := Temp.AsExtended;
      TestRec.When  := Ext;
      Result  := TValue.From(TestRec);
    end
    );
end;

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
  fDate         := Trunc(When);
  fTime         := Frac(When);
  fDateTime     := When;
end;

//{ TRecList }
//
//function TRecList.AddRec(const Value: integer): integer;
//var
//  Rec: TTestRecord;
//begin
//  Rec.fStr  := 'Rec Str ' + Value.ToString;
//  Rec.fDate := Date + Value;
//  Result    := Add(Rec)
//end;
//
//procedure TRecList.Init;
//begin
//  AddRec(1);
//  AddRec(2);
//  AddRec(3);
//end;

{ TComplexValues }

function TComplexValues.Init: TComplexValues;
begin
  Result  := Self;
  fGUID   := TGUID.NewGuid;
  fRect   := Rect(100, 200, 300, 400);
  fTestRec.Str  := 'ABC';
  fTestRec.When := Date;
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

{ TCntrTypes }

constructor TCntrTypes.Create;
begin
  inherited;
  fStrs     := TStringList.Create;
  fStrsDeep := TStringList.Create;
  fObjList  := TObjList.Create;
//  fRecList  := TRecList.Create;
end;

destructor TCntrTypes.Destroy;
var
  i: integer;
begin
  for i := 0 to fStrsDeep.Count - 1 do
    fStrsDeep.Objects[i].Free;
  fStrs.Free;
  fStrsDeep.Free;
  fObjList.Free;
//  fRecList.Free;
  inherited;
end;

procedure TCntrTypes.Init1;
begin
  fObjList.Add(TObjBase.Create.Init(1));
  fObjList.Add(nil);
  fObjList.Add(TObjBase.Create.Init(3));
  fStrs.Add('ABC');
  fStrs.Add('DEF');
  fStrs.Add('HIJ');
  fStrsDeep.AddObject('Elem X', TObjBase.Create.Init(4));
  fStrsDeep.AddObject('Elem Y', nil);
  fStrsDeep.AddObject('Elem Z', TObjSub.Create.Init(5));
end;

procedure TCntrTypes.Init2;
begin
  fObjList.Add(nil);
  fObjList.Add(TObjBase.Create.Init(1));
  fStrs.Add('ABC');
  fStrs.Add('XYZ');
  fStrsDeep.AddObject('Elem X', nil);
  fStrsDeep.AddObject('Elem Y', TObjBase.Create.Init(4));
end;

{ TAllTypes }

destructor TAllTypes.Destroy;
begin
  fSimple.Free;
  fComplex.Free;
  fObj.Free;
  fObjExt.Free;
  inherited;
end;

procedure TAllTypes.Init1;
begin
  inherited;
  fSimple   := TSimpleValues.Create.Init(1);
  fComplex  := TComplexValues.Create.Init;
  fObj      := TObjBase.Create.Init(2);
  fObjExt   := TObjSub.Create.Init(3);
  fObjNil   := nil;
end;

initialization
  RegisteredLists.Register(TObjList, TObjBase);
  RegisterComplexType;
  When  := Now;

end.
