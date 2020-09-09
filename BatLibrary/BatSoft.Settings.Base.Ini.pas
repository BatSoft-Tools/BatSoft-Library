unit BatSoft.Settings.Base.Ini;

interface

uses
  System.Rtti, System.Classes, System.IniFiles, BatSoft.Settings.Base;

type
  TSettingsWriterIni = class(TInterfacedObject, ISettingsStoreWriter)
  private
    fFileName, fPathDelimiter: string;
    fEnumsAsStrings: Boolean;
    fIni: TIniFile;
    fPath: string;
  public
    constructor Create(const AFileName: string; const APathDelimiter: string = '/'; const AEnumsAsStrings: Boolean = True);
    //  ISettingsStoreWriter interface
    //  Storage
    procedure BeginSave;
    procedure EndSave;
    //  Navigation
    procedure MoveToChild(const Name: string);
    procedure MoveToParent;
    //  Arrays
    //  - Iterators
    function  IsList: Boolean;
    function  ListBegin: Boolean;
    function  ListNext: Boolean;
    procedure ListEnd;
    procedure SaveStrings(const Strs: TStrings);
    //  - Modifiers
    procedure ListClear;
    procedure ListAdd;
    //  Property values
    procedure SetValue(const Name: string; const Value: TValue);
  end;

implementation

uses
  System.SysUtils;

{ TSettingsWriterIni }

procedure TSettingsWriterIni.BeginSave;
begin
  fPath := '';
  fIni  := TIniFile.Create(fFileName);
end;

constructor TSettingsWriterIni.Create(const AFileName, APathDelimiter: string; const AEnumsAsStrings: Boolean);
begin
  inherited Create();
  fFileName       := AFileName;
  fPathDelimiter  := APathDelimiter;
  fEnumsAsStrings := AEnumsAsStrings;
end;

procedure TSettingsWriterIni.EndSave;
begin
  fIni.Free;
end;

function TSettingsWriterIni.IsList: Boolean;
begin

end;

procedure TSettingsWriterIni.ListAdd;
begin

end;

function TSettingsWriterIni.ListBegin: Boolean;
begin

end;

procedure TSettingsWriterIni.ListClear;
begin

end;

procedure TSettingsWriterIni.ListEnd;
begin

end;

function TSettingsWriterIni.ListNext: Boolean;
begin

end;

procedure TSettingsWriterIni.MoveToChild(const Name: string);
begin
  if  fPath.IsEmpty then
    fPath := Name
  else
    fPath := fPath + fPathDelimiter + Name;
end;

procedure TSettingsWriterIni.MoveToParent;
var
  i: integer;
begin
  i := fPath.LastIndexOf(fPathDelimiter);
  fPath := Copy(fPath, 0, i);
end;

procedure TSettingsWriterIni.SaveStrings(const Strs: TStrings);
begin

end;

procedure TSettingsWriterIni.SetValue(const Name: string; const Value: TValue);
begin
  case Value.TypeInfo.Kind of
    tkInteger :
      fIni.WriteInteger(fPath, Name, Value.AsInteger);
    tkInt64 :
      fIni.WriteInt64(fPath, Name, Value.AsInt64);
    tkFloat :
      if  (Value.TypeInfo = TypeInfo(TDate)) or
          (Value.TypeInfo = TypeInfo(TTime)) or
          (Value.TypeInfo = TypeInfo(TDateTime))
      then
        fIni.WriteString(fPath, Name, Value.AsString)
      else
        fIni.WriteFloat(fPath, Name, Value.AsExtended);
    tkEnumeration :
      if  fEnumsAsStrings then
        fIni.WriteFloat(fPath, Name, Value.AsOrdinal)
      else
        fIni.WriteString(fPath, Name, Value.AsString);
    tkSet :
      if  fEnumsAsStrings then
        fIni.WriteFloat(fPath, Name, Value.AsOrdinal)
      else
        fIni.WriteString(fPath, Name, Value.AsString);
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      fIni.WriteString(fPath, Name, Value.AsString);
    tkVariant :
      fIni.WriteString(fPath, Name, Value.AsString);
  end;

end;

end.
