unit BatSoft.Settings.JSON;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

//  For streaming objects to/from .json files.
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
//  var
//    SettingsStore: ISettingsStore<TMySettings>;
//  begin
//    SettingsStore := TSettingsStoreJSON<TMySettings>.Create(FileName);
//    SettingsStore.Save(Settings);
//
//  Load settings:
//  var
//    SettingsStore: ISettingsStore<TMySettings>;
//  begin
//    SettingsStore := TSettingsStoreJSON<TMySettings>.Create(FileName);
//    SettingsStore.Load(Settings);
//
//  It is possible to store object lists, string lists and other more complex or
//  specific types.  To see how, look at the unit tests and the demos.

interface

uses
  System.Classes, System.TypInfo, System.Rtti, System.Generics.Collections,
  System.JSON, BatSoft.Settings;

type
  TSettingsStoreJSON<T: class> = class(TSettingsStore<T>)
  var
    fFileName: string;
    fEnumsAsStrings: Boolean;
  type

    TSettingsJSONBase = class abstract(TInterfacedObject)
    protected
      fFileName: string;
      fEnumsAsStrings: Boolean;
      fRoot: TJSONObject;
      fPath: TStack<TJSONValue>;
      procedure StoreBegin;
      procedure StoreEnd;
      //  For use in subclasses' SaveValue() overrides
      function  CurrentNode: TJSONObject; inline;
    public
      constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean);
    end;

    TSettingsJSONReader = class(TSettingsJSONBase, ISettingsStoreReader)
    private
      fIterators: TStack<TJSONArray.TEnumerator>;
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

    TSettingsJSONWriter = class(TSettingsJSONBase, ISettingsStoreWriter)
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
    constructor Create(const AFileName: string; const AEnumsAsStrings: Boolean = True);
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

{ TSettingsStoreJSON<T> }

constructor TSettingsStoreJSON<T>.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  inherited Create;
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
end;

function TSettingsStoreJSON<T>.CreateSettingsStoreReader: ISettingsStoreReader;
begin
  Result  := TSettingsJSONReader.Create(fFileName, fEnumsAsStrings);
end;

function TSettingsStoreJSON<T>.CreateSettingsStoreWriter: ISettingsStoreWriter;
begin
  Result  := TSettingsJSONWriter.Create(fFileName, fEnumsAsStrings);
end;

{ TSettingsJSON<T>.TSettingsJSONBase }

constructor TSettingsStoreJSON<T>.TSettingsJSONBase.Create(const AFileName: string; const AEnumsAsStrings: Boolean);
begin
  inherited Create;
  fFileName       := AFileName;
  fEnumsAsStrings := AEnumsAsStrings;
end;

function TSettingsStoreJSON<T>.TSettingsJSONBase.CurrentNode: TJSONObject;
begin
  Result  := fPath.Peek as TJSONObject
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONBase.StoreBegin;
begin
  fRoot := TJSONObject.Create;
  fPath := TStack<TJSONValue>.Create;
  fPath.Push(fRoot);
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONBase.StoreEnd;
begin
  fPath.Free;
  FreeAndNil(fRoot);
end;

{ TSettingsJSON<T>.TSettingsJSONReader }

function TSettingsStoreJSON<T>.TSettingsJSONReader.ElemEnter: Boolean;
var
  Value: TJSONValue;
begin
  Value   := fIterators.Peek.GetCurrent;
  Result  := not (Value is TJSONNull);
  if  Result  then
    fPath.Push(Value);
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.ElemLeave;
begin
  fPath.Pop
end;

function TSettingsStoreJSON<T>.TSettingsJSONReader.ElemNext: Boolean;
begin
  Result  := fIterators.Peek.MoveNext
end;

function TSettingsStoreJSON<T>.TSettingsJSONReader.ListBegin(const Name: string): Boolean;
var
  Pair: TJSONPair;
begin
  Pair    := CurrentNode.Get(Name);
  Result  := Pair.JsonValue is TJSONArray;
  if  Result  then
    begin
      fPath.Push(Pair.JsonValue);
      fIterators.Push((Pair.JsonValue as TJSONArray).GetEnumerator);
    end;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.ListEnd;
begin
  fPath.Pop;
  fIterators.Pop.Free;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.LoadBegin;
var
  JSONStr: string;
begin
  StoreBegin;
  fIterators  := TStack<TJSONArray.TEnumerator>.Create;
  //  Load file
  JSONStr := TFile.ReadAllText(fFileName);
  fPath.Push(TJSONObject.ParseJSONValue(JSONStr));
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.LoadEnd;
begin
  while fIterators.Count > 0 do
    fIterators.Pop.Free;
  StoreEnd;
end;

function TSettingsStoreJSON<T>.TSettingsJSONReader.LoadValue(const Name: string; const Info: PTypeInfo): TValue;
var
  JSONVal: TJSONValue;
begin
  JSONVal := CurrentNode.GetValue(Name);
  if  Assigned(JSONVal) then
    case Info.Kind of
      tkInteger :
        Result  := (JSONVal as TJSONNumber).AsInt;
      tkInt64 :
        Result  := (JSONVal as TJSONNumber).AsInt64;
      tkFloat :
        Result  := (JSONVal as TJSONNumber).AsDouble;
      tkEnumeration :
        if  Info = TypeInfo(Boolean)  then
          Result  := (JSONVal as TJSONBool).AsBoolean
        else if  fEnumsAsStrings then
          Result  := StrToEnum((JSONVal as TJSONString).Value, Info)
        else
          Result  := OrdToEnum((JSONVal as TJSONNumber).AsInt, Info);
      tkSet :
        if  fEnumsAsStrings then
          Result  := StrToEnumSet((JSONVal as TJSONString).Value, Info)
        else
          Result  := OrdToEnum((JSONVal as TJSONNumber).AsInt64, Info);
      tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
        Result  := (JSONVal as TJSONString).Value;
      tkVariant :
        Result  := TValue.FromVariant((JSONVal as TJSONString).Value);
    else
      raise ESettings.Create(SEUnsupportedType, [Name, Info.Name]);
    end
  else
    Result  := TValue.Empty;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.NodeChildren(const Names: TStrings);
var
  i: integer;
begin
  Names.Clear;
  for i := 0 to CurrentNode.Count - 1 do
    Names.Add(CurrentNode.Pairs[i].JsonString.Value);
end;

function TSettingsStoreJSON<T>.TSettingsJSONReader.NodeEnter(const Name: string): Boolean;
var
  Pair: TJSONPair;
begin
  Pair    := CurrentNode.Get(Name);
  Result  := Assigned(Pair) and not (Pair.JsonValue is TJSONNull);
  if  Result  then
    fPath.Push(Pair.JsonValue)
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONReader.NodeLeave;
begin
  fPath.Pop;
end;

{ TSettingsJSON<T>.TSettingsJSONWriter }

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.ElemEnter(const Index: integer; const IsNil: Boolean);
var
  Child: TJSONValue;
begin
  if  IsNil then
    Child := TJSONNull.Create
  else
    Child := TJSONObject.Create;
  (fPath.Peek as TJSONArray).AddElement(Child);
  fPath.Push(Child);
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.ElemLeave;
begin
  fPath.Pop;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.ListBegin(const Name: string; const IsNil: Boolean);
var
  Arr: TJSONArray;
begin
  Arr := TJSONArray.Create;
  if  fPath.Peek is TJSONArray  then
    (fPath.Peek as TJSONArray).Add(Arr)
  else
    (fPath.Peek as TJSONObject).AddPair(Name, Arr);
  fPath.Push(Arr);
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.ListClear(const Name: string);
begin
  //  Nothing to do
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.ListEnd;
begin
  fPath.Pop;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.NodeClear(const Name: string);
begin
  //  Nothing to do
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.NodeEnter(const Name: string; const IsNil: Boolean);
var
  Child: TJSONValue;
begin
  if  IsNil then
    Child := TJSONNull.Create
  else
    Child := TJSONObject.Create;
  if  fPath.Peek is TJSONArray  then
    (fPath.Peek as TJSONArray).AddElement(Child)
  else
    (fPath.Peek as TJSONObject).AddPair(Name, Child);
  fPath.Push(Child);
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.NodeLeave;
begin
  fPath.Pop;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.SaveBegin;
begin
  StoreBegin;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.SaveEnd;
begin
  //  Save to file
  TFile.WriteAllText(fFileName, fRoot.ToJSON);
  //  Tidy up
  StoreEnd;
end;

procedure TSettingsStoreJSON<T>.TSettingsJSONWriter.SaveValue(const Name: string; const Value: TValue);
var
  JSONValue: TJSONValue;
begin
  case Value.TypeInfo.Kind of
    tkInteger :
      JSONValue := TJSONNumber.Create(Value.AsInteger);
    tkInt64 :
      JSONValue := TJSONNumber.Create(Value.AsInt64);
    tkFloat :
      JSONValue := TJSONNumber.Create(Value.AsExtended);
    tkEnumeration :
      if  Value.TypeInfo = TypeInfo(Boolean)  then
        JSONValue := TJSONBool.Create(Value.AsBoolean)
      else if  fEnumsAsStrings then
        JSONValue := TJSONString.Create(EnumToStr(Value))
      else
        JSONValue := TJSONNumber.Create(EnumToOrd(Value));
    tkSet :
      if  fEnumsAsStrings then
        JSONValue := TJSONString.Create(EnumSetToStr(Value))
      else
        JSONValue := TJSONNumber.Create(EnumSetToOrd(Value));
    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
      JSONValue := TJSONString.Create(Value.AsString);
    tkVariant :
      JSONValue := TJSONString.Create(Value.AsString);
  else
    raise ESettings.Create(SEUnsupportedType, [Name, Value.TypeInfo.Name]);
  end;
  CurrentNode.AddPair(Name, JSONValue);
end;

end.
