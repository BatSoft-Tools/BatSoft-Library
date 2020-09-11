unit BatSoft.Settings.Base.Ini;

interface

uses
  System.Rtti, System.Classes, System.IniFiles, BatSoft.Settings.Base;

type
  TSettingsWriterIni = class(TSettingsStore, ISettingsStoreWriter)
  public
    const DefaultPathDelimiter  = '/';
  private
    fIni: TIniFile;
    fPath: TStrings;
    fPathDelimiter: Char;
  protected
    //  For use in subclasses' SaveValue() overrides
    function CurrentSection: string; inline;
  public
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True); overload; override;
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char); reintroduce; overload;
    destructor  Destroy; override;
    //  ISettingsStoreWriter interface
    //  Storage
    procedure SaveBegin;
    procedure SaveEnd;
    //  Navigation
    procedure NodeClear(const Name: string);
    procedure NodeEnter(const Name: string; const IsNil: Boolean);
    procedure NodeLeave;
    //  Arrays
    procedure ListClear(const Name: string);
    procedure ListBegin(const Name: string; const IsNil: Boolean);
    procedure ListEnd;
    //  Array elements
    procedure ElemEnter(const Index: integer; const IsNil: Boolean);
    procedure ElemLeave;
    //  Simple values
    procedure SaveValue(const Name: string; const Value: TValue); virtual;
  end;

implementation

uses
  System.SysUtils, System.TypInfo;

{ TSettingsWriterIni }

constructor TSettingsWriterIni.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  Create(AFileName, AEnumsAsStrings, DefaultPathDelimiter)
end;

constructor TSettingsWriterIni.Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char);
begin
  inherited Create(AFileName, AEnumsAsStrings);
  fPath           := TStringList.Create;
  fPathDelimiter  := APathDelimiter
end;

function TSettingsWriterIni.CurrentSection: string;
begin
  Result  := fPath.DelimitedText
end;

destructor TSettingsWriterIni.Destroy;
begin
  fPath.Free;
  inherited;
end;

procedure TSettingsWriterIni.ElemEnter(const Index: integer; const IsNil: Boolean);
begin
  NodeEnter('(' + Index.ToString + ')', IsNil)
end;

procedure TSettingsWriterIni.ElemLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsWriterIni.ListBegin(const Name: string; const IsNil: Boolean);
begin
  fPath.Add(Name);
end;

procedure TSettingsWriterIni.ListClear(const Name: string);
begin
  NodeClear(Name)
end;

procedure TSettingsWriterIni.ListEnd;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsWriterIni.NodeClear(const Name: string);
var
  Sections: TStrings;
  Section, Path: string;
begin
  Sections  := TStringList.Create;
  try
    //  Erase this
    Path  := fPath.DelimitedText;
    if  Path.IsEmpty  then
      Path  := Name
    else
      Path  := path + fPathDelimiter + Name;
    fIni.EraseSection(Path);
    //  Erase children
    fIni.ReadSubSections(Path, Sections, True);
    Path  := Path + fPathDelimiter;
    for Section in Sections do
      fIni.EraseSection(Path + Section);
  finally
    Sections.Free;
  end;
end;

procedure TSettingsWriterIni.NodeEnter(const Name: string; const IsNil: Boolean);
begin
  fPath.Add(Name);
  if  IsNil then
    fIni.WriteString(fPath.DelimitedText, SClass, 'Null')
  else
    fIni.DeleteKey(fPath.DelimitedText, SClass)
end;

procedure TSettingsWriterIni.NodeLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsWriterIni.SaveBegin;
begin
  fIni  := TIniFile.Create(fFileName);
  fPath := TStringList.Create;
  fPath.Delimiter := fPathDelimiter;
end;

procedure TSettingsWriterIni.SaveEnd;
begin
  fIni.Free;
end;

procedure TSettingsWriterIni.SaveValue(const Name: string; const Value: TValue);
var
  Path: string;
begin
  Path  := CurrentSection;
  case Value.TypeInfo.Kind of
    tkInteger :
      fIni.WriteInteger(Path, Name, Value.AsInteger);
    tkInt64 :
      fIni.WriteInt64(Path, Name, Value.AsInt64);
    tkFloat :
      if  Value.TypeInfo = TypeInfo(TDate)      then  fIni.WriteDate    (Path, Name, Value.AsExtended)  else
      if  Value.TypeInfo = TypeInfo(TTime)      then  fIni.WriteTime    (Path, Name, Value.AsExtended)  else
      if  Value.TypeInfo = TypeInfo(TDateTime)  then  fIni.WriteDateTime(Path, Name, Value.AsExtended)  else
                                                      fIni.WriteFloat   (Path, Name, Value.AsExtended);
    tkEnumeration :
      if  fEnumsAsStrings then
        fIni.WriteString(Path, Name, EnumToStr(Value))
      else
        fIni.WriteInteger(Path, Name, Value.AsInteger);
    tkSet :
      if  fEnumsAsStrings then
        fIni.WriteString(Path, Name, EnumSetToStr(Value))
      else
        fIni.WriteFloat(Path, Name, Value.AsOrdinal);
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      fIni.WriteString(Path, Name, Value.AsString);
    tkVariant :
      fIni.WriteString(Path, Name, Value.AsString);
  end;
end;

end.
