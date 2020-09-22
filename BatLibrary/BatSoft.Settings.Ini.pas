unit BatSoft.Settings.Ini;

interface

uses
  System.Rtti, System.Classes, System.TypInfo, System.IniFiles,
  System.Generics.Collections, BatSoft.Settings;

type
  TSettingsIni = class abstract(TSettingsStore)
  public
    const DefaultPathDelimiter  = '/';
  private
    fIni: TIniFile;
    fPath: TStrings;
    fPathDelimiter: Char;
    function  CurrentSection: string; inline;
    procedure StoreBegin;
    procedure StoreEnd;
  public
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True); overload; override;
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char); reintroduce; overload;
    destructor  Destroy; override;
  end;

  TSettingsReaderIni = class(TSettingsIni, ISettingsStoreReader)
  private
    fIterators: TStack<TStrings>;
    fElemName: string;
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
    function  ListBegin(const Name: string): Boolean;
    procedure ListEnd;
    //  Array elements
    function  ElemEnter: Boolean;
    procedure ElemLeave;
    function  ElemNext: Boolean;
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
  System.SysUtils, System.Variants;

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

function TSettingsReaderIni.ElemEnter: Boolean;
begin
  Result  := NodeEnter(fElemName)
end;

procedure TSettingsReaderIni.ElemLeave;
begin
  NodeLeave;
end;

function TSettingsReaderIni.ElemNext: Boolean;
begin
  //  Do we have a next element?
  Result  := fIterators.Peek.Count > 0;
  if  Result  then
    begin
      //  Note the name of the element
      fElemName := fIterators.Peek[0];
      //  Iterate
      fIterators.Peek.Delete(0);
    end;
end;

function TSettingsReaderIni.ListBegin(const Name: string): Boolean;
var
  Iterator: TStringList;
begin
  fPath.Add(Name);
  Result  := True;
  if  Result  then
    begin
      Iterator  := TStringList.Create;
      fIterators.Push(Iterator);
      NodeChildren(Iterator);
    end;
end;

procedure TSettingsReaderIni.ListEnd;
begin
  fIterators.Pop.Free;
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsReaderIni.LoadBegin;
begin
  StoreBegin;
  fIterators  := TStack<TStrings>.Create;
end;

procedure TSettingsReaderIni.LoadEnd;
begin
  while fIterators.Count > 0 do
    fIterators.Pop.Free;
  fIterators.Free;
  StoreEnd;
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
      Result  := fIni.ReadFloat (Path, Name, 0);
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
        Result  := TValue.FromVariant(fIni.ReadString(Path, Name, ''))
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
  i: integer;
  Path: TStringList;
  CurrPath: string;
begin
  fIni.ReadSections(CurrentSection, Names);
  //  Filter down to the immediate children
  CurrPath  := CurrentSection + fPathDelimiter;
  Path  := TStringList.Create;
  try
    Path.Delimiter  := fPathDelimiter;
    for i := Names.Count - 1 downto 0 do
      begin
        if  not Names[i].StartsWith(CurrPath, True) then
          begin
            Names.Delete(i);
            Continue;
          end;
        Path.DelimitedText  := Names[i];
        if  Path.Count > fPath.Count + 1  then
          Names.Delete(i)
        else
          Names[i]  := Path[fPath.Count];
      end;
  finally
    Path.Free;
  end;
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
      fIni.WriteFloat(Path, Name, Value.AsExtended);
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
