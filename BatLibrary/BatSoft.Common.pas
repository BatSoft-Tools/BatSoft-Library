unit BatSoft.Common;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.SysUtils, System.Rtti;

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
