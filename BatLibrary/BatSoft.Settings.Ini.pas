unit BatSoft.Settings.Ini;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

//  For streaming objects to/from .ini files.
//
//  type
//  {$M+}   <- Ensure that we have RTTI for these classes.
//    TMySubSettings = class
//    published
//      property  Value1  : string  read fValue1  write fValue1;
//    end;
//
//    TMySettings = class
//    published
//      property  Value2  : integer         read fValue2  write SetValue2;
//      property  Value3  : TMySubSettings  read fValue3  write fValue3;
//    end;
//  {$M-}   <- Don't generate more RTTI than necessary.
//
//  Save settings:
//  var
//    SettingsStore: ISettingsStore<TMySettings>;
//  begin
//    SettingsStore := TSettingsStoreIni<TMySettings>.Create(FileName);
//    SettingsStore.Save(Settings);
//
//  Load settings:
//  var
//    SettingsStore: ISettingsStore<TMySettings>;
//  begin
//    SettingsStore := TSettingsStoreIni<TMySettings>.Create(FileName);
//    SettingsStore.Load(Settings);
//
//  It is possible to store object lists, string lists and other more complex or
//  specific types.  To see how, look at the unit tests and the demos.

interface

uses
  System.Rtti, System.Classes, System.TypInfo, System.IniFiles,
  System.Generics.Collections, BatSoft.Settings;

type
  TSettingsStoreIni<T: class> = class(TSettingsStore<T>)
  public
    const DefaultPathDelimiter  = '/';
  var
    fFileName: string;
    fEnumsAsStrings: Boolean;
    fPathDelimiter: Char;
  type

    TSettingsIniBase = class abstract(TInterfacedObject)
    private
      fFileName: string;
      fEnumsAsStrings: Boolean;
      fPathDelimiter: Char;
      fIni: TIniFile;
      fPath: TStrings;
    protected
      function  CurrentSection: string; inline;
      procedure StoreBegin;
      procedure StoreEnd;
    public
      constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char); overload;
      destructor  Destroy; override;
    end;

    TSettingsIniReader = class(TSettingsIniBase, ISettingsStoreReader)
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

    TSettingsIniWriter = class(TSettingsIniBase, ISettingsStoreWriter)
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

  protected
    function CreateSettingsStoreReader: ISettingsStoreReader; override;
    function CreateSettingsStoreWriter: ISettingsStoreWriter; override;
  public
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True); overload;
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char); overload;
  end;

implementation

uses
  System.SysUtils, System.Variants, BatSoft.Common;

{ TSettingsStoreIni<T> }

constructor TSettingsStoreIni<T>.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  Create(AFileName, AEnumsAsStrings, DefaultPathDelimiter)
end;

constructor TSettingsStoreIni<T>.Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char);
begin
  inherited Create;
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
  fPathDelimiter  := APathDelimiter;
end;

function TSettingsStoreIni<T>.CreateSettingsStoreReader: ISettingsStoreReader;
begin
  Result  := TSettingsIniReader.Create(fFileName, fEnumsAsStrings, fPathDelimiter);
end;

function TSettingsStoreIni<T>.CreateSettingsStoreWriter: ISettingsStoreWriter;
begin
  Result  := TSettingsIniWriter.Create(fFileName, fEnumsAsStrings, fPathDelimiter);
end;

{ TSettingsIni<T>.TSettingsIniBase }

constructor TSettingsStoreIni<T>.TSettingsIniBase.Create(const AFileName: string; const AEnumsAsStrings: Boolean; const APathDelimiter: Char);
begin
  inherited Create;
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
  fPathDelimiter  := APathDelimiter;
end;

function TSettingsStoreIni<T>.TSettingsIniBase.CurrentSection: string;
begin
  Result  := fPath.DelimitedText
end;

destructor TSettingsStoreIni<T>.TSettingsIniBase.Destroy;
begin
  fPath.Free;
  inherited;
end;

procedure TSettingsStoreIni<T>.TSettingsIniBase.StoreBegin;
begin
  fIni  := TIniFile.Create(fFileName);
  fPath := TStringList.Create;
  fPath.Delimiter := fPathDelimiter;
end;

procedure TSettingsStoreIni<T>.TSettingsIniBase.StoreEnd;
begin
  fIni.Free;
end;

{ TSettingsIni<T>.TSettingsIniReader }

function TSettingsStoreIni<T>.TSettingsIniReader.ElemEnter: Boolean;
begin
  Result  := NodeEnter(fElemName)
end;

procedure TSettingsStoreIni<T>.TSettingsIniReader.ElemLeave;
begin
  NodeLeave;
end;

function TSettingsStoreIni<T>.TSettingsIniReader.ElemNext: Boolean;
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

function TSettingsStoreIni<T>.TSettingsIniReader.ListBegin(const Name: string): Boolean;
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

procedure TSettingsStoreIni<T>.TSettingsIniReader.ListEnd;
begin
  fIterators.Pop.Free;
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniReader.LoadBegin;
begin
  StoreBegin;
  fIterators  := TStack<TStrings>.Create;
end;

procedure TSettingsStoreIni<T>.TSettingsIniReader.LoadEnd;
begin
  while fIterators.Count > 0 do
    fIterators.Pop.Free;
  fIterators.Free;
  StoreEnd;
end;

function TSettingsStoreIni<T>.TSettingsIniReader.LoadValue(const Name: string; const Info: PTypeInfo): TValue;
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
        Result  := StrToEnum(fIni.ReadString(Path, Name, ''), Info)   //        Result  := Enum_StringToValue(fIni.ReadString(Path, Name, ''), Info)
      else
        Result  := OrdToEnum(fIni.ReadInteger(Path, Name, 0), Info);
    tkSet :
      if  fEnumsAsStrings then
        Result  := StrToEnumSet(fIni.ReadString(Path, Name, ''), Info)  //        Result  := EnumSet_StringToValue(fIni.ReadString(Path, Name, ''), Info)
      else
        Result  := OrdToEnumSet(fIni.ReadInt64(Path, Name, 0), Info);
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      Result  := fIni.ReadString(Path, Name, '');
    tkVariant :
      if  fIni.ValueExists(Path, Name)  then
        Result  := TValue.FromVariant(fIni.ReadString(Path, Name, ''))
      else
        Result  := TValue.FromVariant(Null)
  end;
end;

function TSettingsStoreIni<T>.TSettingsIniReader.NodeEnter(const Name: string): Boolean;
begin
  fPath.Add(Name);
  Result  := not SameText(fIni.ReadString(CurrentSection, SClass, string.Empty), SNil);
  if  not Result  then
    fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniReader.NodeLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniReader.NodeChildren(const Names: TStrings);
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

{ TSettingsIni<T>.TSettingsIniWriter }

procedure TSettingsStoreIni<T>.TSettingsIniWriter.ElemEnter(const Index: integer; const IsNil: Boolean);
begin
  NodeEnter('(' + Index.ToString + ')', IsNil)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.ElemLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.ListBegin(const Name: string; const IsNil: Boolean);
begin
  fPath.Add(Name);
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.ListClear(const Name: string);
begin
  NodeClear(Name)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.ListEnd;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.NodeClear(const Name: string);
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

procedure TSettingsStoreIni<T>.TSettingsIniWriter.NodeEnter(const Name: string; const IsNil: Boolean);
begin
  fPath.Add(Name);
  if  IsNil then
    fIni.WriteString(fPath.DelimitedText, SClass, 'Null')
  else
    fIni.DeleteKey(fPath.DelimitedText, SClass)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.NodeLeave;
begin
  fPath.Delete(fPath.Count - 1)
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.SaveBegin;
begin
  StoreBegin
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.SaveEnd;
begin
  StoreEnd
end;

procedure TSettingsStoreIni<T>.TSettingsIniWriter.SaveValue(const Name: string; const Value: TValue);
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
        fIni.WriteInteger(Path, Name, EnumToOrd(Value));
    tkSet :
      if  fEnumsAsStrings then
        fIni.WriteString(Path, Name, EnumSetToStr(Value))
      else
        fIni.WriteInt64(Path, Name, EnumSetToOrd(Value));
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      fIni.WriteString(Path, Name, Value.AsString);
    tkVariant :
      fIni.WriteString(Path, Name, Value.AsString);
  end;
end;

end.
