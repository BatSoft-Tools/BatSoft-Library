unit BatSoft.Settings.Base.JSON;

interface

uses
  System.Rtti, System.Classes, System.Generics.Collections, System.JSON,
  BatSoft.Settings.Base;

type
  TSettingsWriterJSON = class(TSettingsStore, ISettingsStoreWriter)
  private
    fRoot: TJSONObject;
    fPath: TStack<TJSONValue>;
  protected
    //  For use in subclasses' SaveValue() overrides
    function  CurrentNode: TJSONObject; inline;
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
  System.SysUtils, System.TypInfo, System.IOUtils;

{ TSettingsWriterJSON }

function TSettingsWriterJSON.CurrentNode: TJSONObject;
begin
  Result  := fPath.Peek as TJSONObject
end;

procedure TSettingsWriterJSON.ElemEnter(const Index: integer; const IsNil: Boolean);
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

procedure TSettingsWriterJSON.ElemLeave;
begin
  fPath.Pop;
end;

procedure TSettingsWriterJSON.ListBegin(const Name: string; const IsNil: Boolean);
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

procedure TSettingsWriterJSON.ListClear(const Name: string);
begin
  //  Nothing to do
end;

procedure TSettingsWriterJSON.ListEnd;
begin
  fPath.Pop;
end;

procedure TSettingsWriterJSON.NodeClear(const Name: string);
begin
  //  Nothing to do
end;

procedure TSettingsWriterJSON.NodeEnter(const Name: string; const IsNil: Boolean);
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

procedure TSettingsWriterJSON.NodeLeave;
begin
  fPath.Pop;
end;

procedure TSettingsWriterJSON.SaveBegin;
begin
  fRoot := TJSONObject.Create;
  fPath := TStack<TJSONValue>.Create;
  fPath.Push(fRoot);
end;

procedure TSettingsWriterJSON.SaveEnd;
begin
  //  Save to file
  TFile.WriteAllText(fFileName, fRoot.ToJSON);
  //  Tidy up
  fPath.Free;
  FreeAndNil(fRoot);
end;

procedure TSettingsWriterJSON.SaveValue(const Name: string; const Value: TValue);
var
  JSONValue: TJSONValue;
begin
  case Value.TypeInfo.Kind of
    tkInteger :
      JSONValue := TJSONNumber.Create(Value.AsInteger);
    tkInt64 :
      JSONValue := TJSONNumber.Create(Value.AsInt64);
    tkFloat :
      if  (Value.TypeInfo = TypeInfo(TDate)) or
          (Value.TypeInfo = TypeInfo(TTime)) or
          (Value.TypeInfo = TypeInfo(TDateTime))
      then
        JSONValue := TJSONNumber.Create(Value.AsExtended) { TODO : JSON save Date/Time }
      else
        JSONValue := TJSONNumber.Create(Value.AsExtended);
    tkEnumeration :
      if  fEnumsAsStrings then
        JSONValue := TJSONString.Create(EnumToStr(Value))
      else
        JSONValue := TJSONNumber.Create(Value.AsOrdinal);
    tkSet :
      if  fEnumsAsStrings then
        JSONValue := TJSONString.Create(EnumSetToStr(Value))
      else
        JSONValue := TJSONNumber.Create(Value.AsOrdinal);
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
