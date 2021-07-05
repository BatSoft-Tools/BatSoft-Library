unit uMacro;

interface

uses
  System.SysUtils, System.Classes, Generics.Collections, System.Rtti,
  BatSoft.Classes, BatSoft.Context;

type
  TMacro = reference to procedure (Context: IContext; Params: TStrings);

  TMacros = class
  private
    fMacros: TDictionary<string, TMacro>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(const MacroName: string; const Macro: TMacro; const Force: Boolean = False);
    procedure Run(const MacroLines: TStrings; Context: IContext); overload;
    procedure Run(const MacroLine: string; Context: IContext); overload;
  public
    //  Alas, I could not make a helper for TMacro, so utilities are here instead.
    class function  IsLiteral(ParamName: string): Boolean;
    class function  GetValue(Context: IContext; ParamName: string): TValue;
    class function  GetValueAsString(Context: IContext; ParamName: string): string;
    class procedure SetValue(Context: IContext; ParamName: string; Value: TValue);
  end;

  EMacro = class(EBatSoft);

var
  Macros: TMacros;

const
  SParamIndicator = '@';
  
resourcestring
  SEMacroUnnamed        = 'Tried to register macro without a name.';
  SEMacroRegistered     = 'Macro is %s already registered.';
  SEMacroNotRegistered  = 'Macro %s is not registered.';
  SEMacroSetLiteral     = 'Cannot set a literal value: %s';
  SEUnhandledType       = 'Unhandled type: %s';

implementation

uses
  System.TypInfo, System.Variants, FMX.Dialogs;

procedure RegisterStandardMacros(const Macros: TMacros);
begin
  //  Macro: Put <context name> <value>
  Macros.Register('Put', 
    procedure (Context: IContext; Params: TStrings)
    var
      Value: TValue;
    begin
      Value := TMacros.GetValue(Context, Params[1]);
      TMacros.SetValue(Context, Params[2], Value);
    end);
  //  Macro: ShowMessage <message name>
  Macros.Register('ShowMessage', 
    procedure (Context: IContext; Params: TStrings)
    var
      Msg: string;
    begin
      Msg := TMacros.GetValueAsString(Context, Params[1]);
      ShowMessage(Msg);
    end);
end;

{ TMacros }

constructor TMacros.Create;
begin
  inherited;
  fMacros := TDictionary<string, TMacro>.Create;
end;

destructor TMacros.Destroy;
begin
  fMacros.Free;
  inherited;
end;

class function TMacros.GetValue(Context: IContext; ParamName: string): TValue;
begin
  if  IsLiteral(ParamName)  then
    Result  := ParamName
  else
    Result  := Context.GetValue(ParamName)
end;

class function TMacros.GetValueAsString(Context: IContext; ParamName: string): string;
var
  Value: TValue;
begin
  Value := Context.GetValue(ParamName);
  case Value.Kind of
    tkInteger :
      Result  := Value.AsInteger.ToString;
    tkInt64 :
      Result  := Value.AsInt64.ToString;
    tkFloat :
      Result  := Value.AsExtended.ToString;
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString :
      Result  := Value.AsString;
    tkVariant :
      Result  := VarToStr(Value.AsVariant);
    tkClassRef :
      Result  := Value.AsClass.ClassName;
  else    
    raise EMacro.Create(SEUnhandledType, [GetEnumName(TypeInfo(TTypeKind), Ord(Value.Kind))]);
  //  tkUnknown, tkEnumeration, tkSet, tkClass, tkMethod, tkArray, tkRecord,
  //  tkInterface, tkDynArray, tkPointer, tkProcedure, tkMRecord
  end;
end;

class function TMacros.IsLiteral(ParamName: string): Boolean;
begin
  Result  := not ParamName.StartsText(SParamIndicator, ParamName)
end;

procedure TMacros.Register(const MacroName: string; const Macro: TMacro; const Force: Boolean);
begin
  if  MacroName.IsEmpty then
    raise EMacro.Create(SEMacroUnnamed);
  if  Force then
    fMacros.AddOrSetValue(MacroName, Macro)
  else if not fMacros.TryAdd(MacroName, Macro)  then
    raise EMacro.Create(SEMacroRegistered, [MacroName]);
end;

procedure TMacros.Run(const MacroLines: TStrings; Context: IContext);
var
  i: integer;
begin
  for i := 0 to MacroLines.Count - 1  do
    Run(MacroLines[i], Context);
end;

procedure TMacros.Run(const MacroLine: string; Context: IContext);
var
  Parts: TStringList;
  i: integer;
  MacroName: string;
  Macro: TMacro;
begin
  //  Separate by spaces
  Parts := TStringList.Create;
  try
    Parts.Delimiter := ' ';
    Parts.DelimitedText := MacroLine;
    //  Remove whitespace
    for i := Parts.Count - 1 downto 0 do
      if  Parts[i].Trim.IsEmpty then
        Parts.Delete(i);
    //  Extract macro name
    if  Parts.Count > 0 then
      begin
        MacroName := Parts[0];
        //  Find macro
        if  not fMacros.TryGetValue(MacroName, Macro) then
          raise EBatSoft.Create(SEMacroNotRegistered, [MacroName]);
        //  Run macro
        Macro(Context, Parts);
      end;
    //  Tidy up
  finally
    Parts.Free;
  end;
end;

class procedure TMacros.SetValue(Context: IContext; ParamName: string; Value: TValue);
begin
  if  IsLiteral(ParamName)  then
    raise EMacro.Create(SEMacroSetLiteral, [ParamName]);
  Context.SetValue(ParamName, Value);
end;

initialization
  Macros  := TMacros.Create;
  RegisterStandardMacros(Macros);

finalization
  Macros.Free;

end.
