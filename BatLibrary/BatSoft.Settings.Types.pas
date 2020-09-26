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

implementation

uses
  System.SysUtils, System.DateUtils, BatSoft.Settings;

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

initialization
  Register_DateTime_ISO8601;
  Register_GUID;

end.
