unit BatSoft.Common;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.SysUtils, System.TypInfo, System.Rtti;

type
  EBatSoft = class(Exception)
  public
    constructor Create(AMessage: string; const Params: array of const); overload;
  end;

{$region 'Attributes'}

  TAttributeArrayHelper = record helper for TArray<TCustomAttribute>
  public
    class function Has(const AttributeClass: TClass): Boolean; overload;
    class function Has<T: TCustomAttribute>(): Boolean; overload; inline;
    class function Has<T: TCustomAttribute>(const [ref] FoundAttribute: TCustomAttribute): Boolean; overload;
  end;

{$endregion}

function GetExeDir: string;

//  Conversion routines that are necessary in implementations of ISettingsStoreReader.LoadValue() and ISettingsStoreWriter.SaveValue().
//  Not using some of these will cause problems when converting enums and sets, because of how TValue works.

function  EnumToStr(const Value: TValue): string;
function  StrToEnum(const Value: string; const Info: PTypeInfo): TValue;

function  EnumToOrd(const Value: TValue): integer;
function  OrdToEnum(const Value: Int64; const Info: PTypeInfo): TValue;

function  EnumSetToStr(const Value: TValue): string;
function  StrToEnumSet(const Value: string; const Info: PTypeInfo): TValue;

function  EnumSetToOrd(const Value: TValue): Int64;
function  OrdToEnumSet(const Value: Int64; const Info: PTypeInfo): TValue;

const
  nl  = #13#10;

var
  /// Instead of re-writing instancing/tidy ups of TRttiContext all over the place, here is it, in one place.
  RTTI: TRttiContext;

resourcestring
  SEBatSoftBug          = 'BatSoft bug that should never happen. Please notify at: peter@batsoft.com.au';
  SEIncompatibleClasses = 'Incompatible classes.';
  SEIntfNotRegistered   = 'Tried to obtain an interface that is not registered.';


implementation

function GetExeDir: string;
begin
  Result  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))
end;

//  Enumeration strings

function EnumToStr(const Value: TValue): string;
begin
  Result  := GetEnumName(Value.TypeInfo, EnumToOrd(Value))
end;

function  StrToEnum(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := GetEnumValue(Info, Value);
  Result  := TValue.FromOrdinal(Info, Val)
end;

function  EnumToOrd(const Value: TValue): integer;
begin
  Result  := 0;
  Value.ExtractRawDataNoCopy(@Result);
end;

function  OrdToEnum(const Value: Int64; const Info: PTypeInfo): TValue;
begin
  TValue.Make(Value, Info, Result)
end;

function EnumSetToStr(const Value: TValue): string;
begin
  Result  := SetToString(Value.TypeInfo, EnumSetToOrd(Value))
end;

function  StrToEnumSet(const Value: string; const Info: PTypeInfo): TValue;
var
  Val: Int64;
begin
  Val := StringToSet(Info, Value);
  TValue.Make(@Val, Info, Result);
end;

function  EnumSetToOrd(const Value: TValue): Int64;
begin
  Result  := 0;
  Value.ExtractRawDataNoCopy(@Result);
end;

function  OrdToEnumSet(const Value: Int64; const Info: PTypeInfo): TValue;
begin
  TValue.Make(Value, Info, Result)
end;

{ EBatSoft }

constructor EBatSoft.Create(AMessage: string; const Params: array of const);
begin
  inherited Create(Format(AMessage, Params))
end;

{ TAttributeArrayHelper }

class function TAttributeArrayHelper.Has(const AttributeClass: TClass): Boolean;
var
  Attribute: TCustomAttribute;
begin
  Result := True;
  for Attribute in Self do
    if Attribute is AttributeClass then
      Exit;
  Result := False;
end;

class function TAttributeArrayHelper.Has<T>(const [ref] FoundAttribute: TCustomAttribute): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result  := True;
  for Attr in Self do
    if Attr is T then
      begin
        TObject(Pointer(@FoundAttribute)^) := Attr;
        Exit;
      end;
  Result  := False;
  TObject(Pointer(@FoundAttribute)^) := nil;
end;

class function TAttributeArrayHelper.Has<T>(): Boolean;
begin
  Result  := Has(T);
end;

initialization
  RTTI  := TRttiContext.Create;

finalization
  RTTI.Free;

end.
