unit uMacro;

interface

uses
  System.SysUtils, System.Classes, Generics.Collections,
  BatSoft.Classes, BatSoft.Context;

type
  TMacroCommand = reference to procedure (Context: IContext; Params: TStrings);

  TMacros = class
  private
    fMacros: TDictionary<string, TMacroCommand>;
    fDescriptions: TDictionary<string, string>;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(MacroName, Description: string; const Macro: TMacroCommand; const Force: Boolean = False);
    procedure Run(const MacroLines: TStrings; Context: IContext); overload;
    procedure Run(const MacroLine: string; Context: IContext); overload;
    procedure ListCommands(const CommandNames: TStrings);
    function  DescriptionOf(MacroName: string): string;
  end;

  EMacro = class(EBatSoft);

var
  Macros: TMacros;

resourcestring
  SEMacroUnnamed        = 'Tried to register macro without a name.';
  SEMacroRegistered     = 'Macro is %s already registered.';
  SEMacroNotRegistered  = 'Macro %s is not registered.';

implementation

{ TMacros }

constructor TMacros.Create;
begin
  inherited;
  fMacros := TDictionary<string, TMacroCommand>.Create;
  fDescriptions := TDictionary<string, string>.Create;
end;

function TMacros.DescriptionOf(MacroName: string): string;
begin
  Result  := fDescriptions[MacroName]
end;

destructor TMacros.Destroy;
begin
  fMacros.Free;
  fDescriptions.Free;
  inherited;
end;

procedure TMacros.ListCommands(const CommandNames: TStrings);
var
  Pair: TPair<string, TMacroCommand>;
begin
  CommandNames.Clear;
  for Pair in fMacros do
    CommandNames.Add(Pair.Key);
end;

procedure TMacros.Register(MacroName, Description: string; const Macro: TMacroCommand; const Force: Boolean);
begin
  if  MacroName.IsEmpty then
    raise EMacro.Create(SEMacroUnnamed);
  MacroName := UpperCase(MacroName);
  if  Force then
    begin
      fMacros.AddOrSetValue(MacroName, Macro);
      fDescriptions.AddOrSetValue(MacroName, Description);
    end
  else if fMacros.TryAdd(MacroName, Macro)  then
    fDescriptions.AddOrSetValue(MacroName, Description)
  else
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
  Macro: TMacroCommand;
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
        MacroName := UpperCase(Parts[0]);
        Parts.Delete(0);
        //  Find macro
        if  not fMacros.TryGetValue(MacroName, Macro) then
          raise EMacro.Create(SEMacroNotRegistered, [MacroName]);
        //  Run macro
        Macro(Context, Parts);
      end;
    //  Tidy up
  finally
    Parts.Free;
  end;
end;

initialization
  Macros  := TMacros.Create;

finalization
  Macros.Free;

end.
