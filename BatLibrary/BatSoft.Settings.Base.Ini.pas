unit BatSoft.Settings.Base.Ini;

interface

uses
  System.Rtti, System.Classes, System.TypInfo, System.IniFiles, BatSoft.Settings.Base;

type
  TSettingsIni = class abstract(TSettingsStore)
  public
    const DefaultPathDelimiter  = '/';
  private
    fIni: TIniFile;
    fPath: TStrings;
    fPathDelimiter: Char;
    function CurrentSection: string; inline;
    procedure StoreBegin;
    procedure StoreEnd;
  public
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True); overload; override;
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char); reintroduce; overload;
    destructor  Destroy; override;
  end;

  TSettingsReaderIni = class(TSettingsIni, ISettingsStoreReader)
  public
    //  ISettingsStoreReader interface
    //  Storage
    procedure LoadBegin;
    procedure LoadEnd;
    //  Navigation
    procedure NodeChildren(const Names: TStrings);
    function  NodeEnter(const Name: string): Boolean;
    procedure NodeLeave;
    //  Arrays
//    function  ListBegin(const Name: string): Boolean;
//    procedure ListEnd;
//    //  Array elements
//    function  ElemEnter(const Index: integer): Boolean;
//    procedure ElemLeave;
    //  Simple values
    function  LoadValue(const Name: string; const Info: PTypeInfo): TValue;

  end;

  TSettingsWriterIni = class(TSettingsIni, ISettingsStoreWriter)
  protected
    //  For use in subclasses' SaveValue() overrides
  public
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
  System.SysUtils, System.Variants, uDemoSettings;

{ TSettingsIni }

constructor TSettingsIni.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  Create(AFileName, AEnumsAsStrings, DefaultPathDelimiter)
end;

constructor TSettingsIni.Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char);
begin
  inherited Create(AFileName, AEnumsAsStrings);
  fPath           := TStringList.Create;
  fPathDelimiter  := APathDelimiter
end;

function TSettingsIni.CurrentSection: string;
begin
  Result  := fPath.DelimitedText
end;

destructor TSettingsIni.Destroy;
begin
  fPath.Free;
  inherited;
end;

procedure TSettingsIni.StoreBegin;
begin
  fIni  := TIniFile.Create(fFileName);
  fPath := TStringList.Create;
  fPath.Delimiter := fPathDelimiter;
end;

procedure TSettingsIni.StoreEnd;
begin
  fIni.Free;
end;

{ TSettingsReaderIni }

procedure TSettingsReaderIni.LoadBegin;
begin
  StoreBegin
end;

procedure TSettingsReaderIni.LoadEnd;
begin
  StoreEnd
end;

function TSettingsReaderIni.LoadValue(const Name: string; const Info: PTypeInfo): TValue;
var
  Path: string;
begin
  Path  := CurrentSection;
  case Info.Kind of
    tkInteger :
      Result  := fIni.ReadInteger(Path, Name, 0);
    tkInt64 :
      Result  := fIni.ReadInt64(Path, Name, 0);
    tkFloat :
      if  Info = TypeInfo(TDate)      then  Result  := fIni.ReadDate    (Path, Name, 0)  else
      if  Info = TypeInfo(TTime)      then  Result  := fIni.ReadTime    (Path, Name, 0)  else
      if  Info = TypeInfo(TDateTime)  then  Result  := fIni.ReadDateTime(Path, Name, 0)  else
                                            Result  := fIni.ReadFloat   (Path, Name, 0);
    tkEnumeration :
      if  fEnumsAsStrings then
        Result  := Enum_StringToValue(fIni.ReadString(Path, Name, ''), Info)
      else
        Result  := fIni.ReadInteger(Path, Name, 0);
    tkSet :
      if  fEnumsAsStrings then
        Result  := EnumSet_StringToValue(fIni.ReadString(Path, Name, ''), Info)
      else
        Result  := fIni.ReadInt64(Path, Name, 0);
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      Result  := fIni.ReadString(Path, Name, '');
    tkVariant :
      if  fIni.ValueExists(Path, Name)  then
        Result  := fIni.ReadString(Path, Name, '')
      else
        Result  := TValue.FromVariant(Null)
  end;
end;

function TSettingsReaderIni.NodeEnter(const Name: string): Boolean;
begin
  fPath.Add(Name);
  Result  := not SameText(fIni.ReadString(CurrentSection, SClass, string.Empty), SNil);
  if  not Result  then
    fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsReaderIni.NodeLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsReaderIni.NodeChildren(const Names: TStrings);
var
  i, Start: integer;
begin
  fIni.ReadSections(CurrentSection, Names);
  Start := Length(CurrentSection + fPathDelimiter) + 1;
  for i := 0 to Names.Count - 1 do
    Names[i]  := Copy(Names[i], Start, MaxInt);
end;

{ TSettingsWriterIni }

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
  StoreBegin
end;

procedure TSettingsWriterIni.SaveEnd;
begin
  StoreEnd
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
        fIni.WriteInt64(Path, Name, Value.AsOrdinal);
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      fIni.WriteString(Path, Name, Value.AsString);
    tkVariant :
      fIni.WriteString(Path, Name, Value.AsString);
  end;
end;

end.
