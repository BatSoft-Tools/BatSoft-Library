unit BatSoft.Settings.Types;

interface

uses
  System.TypInfo, System.Rtti;

function DateToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;
function TimeToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;
function DateTimeToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;

function InternationalStrToDate(const Value: TValue; const Info: PTypeInfo): TValue;
function InternationalStrToTime(const Value: TValue; const Info: PTypeInfo): TValue;
function InternationalStrToDateTime(const Value: TValue; const Info: PTypeInfo): TValue;

procedure Register_DateTime_ISO8601;
procedure Register_GUID;

procedure Register_Point;
procedure Register_Rect;

implementation

uses
  System.SysUtils, System.Types, System.DateUtils, BatSoft.Settings;

const
  SDateFormat = 'yyyy/mm/dd';

  ISO8601Format : TFormatSettings =
    (
    DateSeparator: '-';
    TimeSeparator: ':';
    ShortDateFormat: SDateFormat;
    LongDateFormat: SDateFormat;
    ShortTimeFormat: 'hh:nn:ss';
    LongTimeFormat: 'hh:nn:ss.zzz';
    DecimalSeparator: '.';
    );

function DateToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  Result  := DateToStr(Value.AsExtended, ISO8601Format)
end;

function TimeToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  Result  := TimeToStr(Value.AsExtended, ISO8601Format)
end;

function DateTimeToInternationalStr(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  Result  := DateToISO8601(Value.AsExtended)
end;

function InternationalStrToDate(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  if  Value.IsEmpty then
    Result  := 0
  else
    Result  := StrToDate(Value.AsString, ISO8601Format)
end;

function InternationalStrToTime(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  if  Value.IsEmpty then
    Result  := 0
  else
    Result  := StrToTime(Value.AsString, ISO8601Format)
end;

function InternationalStrToDateTime(const Value: TValue; const Info: PTypeInfo): TValue;
begin
  if  Value.IsEmpty then
    Result  := 0
  else
    Result  := ISO8601ToDate(Value.AsString);
end;

procedure Register_DateTime_ISO8601;
begin
  SettingsTypes.Register(TypeInfo(TTime),     TypeInfo(string), InternationalStrToTime,     TimeToInternationalStr);
  SettingsTypes.Register(TypeInfo(TDate),     TypeInfo(string), InternationalStrToDate,     DateToInternationalStr);
  SettingsTypes.Register(TypeInfo(TDateTime), TypeInfo(string), InternationalStrToDateTime, DateTimeToInternationalStr);
end;

procedure Register_GUID;
begin
  SettingsTypes.Register(TypeInfo(TGUID), TypeInfo(string),
    function(const Value: TValue; const Info: PTypeInfo): TValue
    begin
      Result  := TValue.From(TGUID.Create(Value.AsString));
    end,
    function(const Value: TValue; const Info: PTypeInfo): TValue
    var
      GUID: TGUID;
    begin
      Value.ExtractRawDataNoCopy(@GUID);
      Result  := GUID.ToString;
    end)
end;

procedure Register_Point;
begin
  //  TPoint
  SettingsTypes.Register(TypeInfo(TPoint),
    procedure (const Value: TValue; const SaveValue: TSimpleSaver)
    var
      Point: TPoint;
    begin
      Point  := Value.AsType<TPoint>(False);
      SaveValue('X', Point.X);
      SaveValue('Y', Point.Y);
    end,
    function (const LoadValue: TSimpleLoader): TValue
    var
      Point: TPoint;
    begin
      Point.X   := LoadValue('X', TypeInfo(integer)).AsInteger;
      Point.Y   := LoadValue('Y', TypeInfo(integer)).AsInteger;
      Result    := TValue.From(Point);
    end);
  //  TPoint
  SettingsTypes.Register(TypeInfo(TPointF),
    procedure (const Value: TValue; const SaveValue: TSimpleSaver)
    var
      Point: TPointF;
    begin
      Point  := Value.AsType<TPointF>(False);
      SaveValue('X', Point.X);
      SaveValue('Y', Point.Y);
    end,
    function (const LoadValue: TSimpleLoader): TValue
    var
      Point: TPointF;
    begin
      Point.X   := LoadValue('X', TypeInfo(integer)).AsInteger;
      Point.Y   := LoadValue('Y', TypeInfo(integer)).AsInteger;
      Result    := TValue.From(Point);
    end);
end;

procedure Register_Rect;
begin
  //  TRect
  SettingsTypes.Register(TypeInfo(TRect),
    procedure (const Value: TValue; const SaveValue: TSimpleSaver)
    var
      Rect: TRect;
    begin
      Rect  := Value.AsType<TRect>(False);
      SaveValue('Left', Rect.Left);
      SaveValue('Top', Rect.Top);
      SaveValue('Right', Rect.Right);
      SaveValue('Bottom', Rect.Bottom);
    end,
    function (const LoadValue: TSimpleLoader): TValue
    var
      Rect: TRect;
    begin
      Rect.Left   := LoadValue('Left', TypeInfo(integer)).AsInteger;
      Rect.Top    := LoadValue('Top', TypeInfo(integer)).AsInteger;
      Rect.Right  := LoadValue('Right', TypeInfo(integer)).AsInteger;
      Rect.Bottom := LoadValue('Bottom', TypeInfo(integer)).AsInteger;
      Result      := TValue.From(Rect);
    end);
  //  TRectF
  SettingsTypes.Register(TypeInfo(TRectF),
    procedure (const Value: TValue; const SaveValue: TSimpleSaver)
    var
      Rect: TRectF;
    begin
      Rect  := Value.AsType<TRectF>(False);
      SaveValue('Left', Rect.Left);
      SaveValue('Top', Rect.Top);
      SaveValue('Right', Rect.Right);
      SaveValue('Bottom', Rect.Bottom);
    end,
    function (const LoadValue: TSimpleLoader): TValue
    var
      Rect: TRectF;
    begin
      Rect.Left   := LoadValue('Left', TypeInfo(integer)).AsInteger;
      Rect.Top    := LoadValue('Top', TypeInfo(integer)).AsInteger;
      Rect.Right  := LoadValue('Right', TypeInfo(integer)).AsInteger;
      Rect.Bottom := LoadValue('Bottom', TypeInfo(integer)).AsInteger;
      Result      := TValue.From(Rect);
    end);
end;

initialization
  Register_DateTime_ISO8601;
  Register_GUID;
  Register_Point;
  Register_Rect;

end.
