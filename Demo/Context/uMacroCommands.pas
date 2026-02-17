unit uMacroCommands;

interface

procedure RegisterCommands;

const
  MACRO_SHOW  = 'Show'; //  Show a text dialog
  MACRO_SET   = 'Set';  //  Set a context value

implementation

uses
  System.SysUtils, System.Classes, System.Rtti, FMX.Dialogs, BatSoft.Classes,
  BatSoft.Context, uMacro;

function ReplaceContextVariables(Context: IContext; Param: string): TValue;
var
  P1, P2: integer;
  Name: string;
  Value: TValue;
begin
  repeat
    P1  := Pos('<', Param);
    P2  := Pos('>', Param, P1);
    if  P1 < P2 then
      begin        
        Name  := Copy(Param, P1 + 1, P2 - P1 - 1);
        Value := Context.GetValue(Name);
        if  (P1 = 1) and (P2 = Length(Param)) then
          Exit(Context.GetValue(Name))
        else
          Param := Copy(Param, 1, P1 - 1) + Value.ToString + Copy(Param, P2 + 1, MaxInt);
      end
    else
      Break;
  until False;
  Result  := Param
end;

procedure RegisterCommands;
begin

  //  Show command
  Macros.Register(MACRO_SHOW,
    'Shows a popup dialog.' + nl + 'Each parameter is a string in a string list.',
    procedure (Context: IContext; Params: TStrings)
    var
      i: Integer;
    begin
      for i := 0 to Params.Count - 1 do
        Params[i] := ReplaceContextVariables(Context, Params[i]).ToString;
      ShowMessage(Params.Text);
    end);

  //  Set value command
  Macros.Register(MACRO_SET,
    'First parameter is the name of a variable.' + nl +
    'The second parameter is either a value' + nl +
    'or a parameter name inside <>.',
    procedure (Context: IContext; Params: TStrings)
    var
      Name: string;
      Value: TValue;
    begin
      Name  := ReplaceContextVariables(Context, Params[0]).AsString;
      Value := ReplaceContextVariables(Context, Params[1]);
      Value := ConvertValue(Context.GetTypeOf(Name), Value);
      Context.SetValue(Name, Value)
    end);

end;

end.
