unit BatSoft.SettingsJSON;

interface

uses
  RTTI, System.JSON, Generics.Collections, Classes, BatSoft.Settings.Base;

type
  TSettingsStoreReaderJSON = class(TInterfacedObject, ISettingsStoreReader)
  private type

    TPathItem = record
      Node: TJSONValue;
      Index: integer;   //  Iff Node is an array element, then this is it's index
    end;

  private
    fFileName: string;
    fJSONPath: TList<TPathItem>;
    function  GetIndex: integer;
    procedure SetIndex(const Value: integer);
    //  Stack
    procedure Push(const Node: TJSONValue);
    function  Peek: TPathItem;
    function  Parent: TPathItem;
    function  Pop: TPathItem;
    //  Arrays
    function  IsList: Boolean;
    function  GotoItem(const Index: integer): Boolean;
    property  Index : integer read GetIndex write SetIndex;
  public
    constructor CreateFile(const AFileName: string);
    destructor  Destroy; override;
    //  ISettingsStoreImplementor interface
    function State: string;
    //  Storage
    procedure BeginLoad;
    procedure EndLoad;
    //  Navigation
    procedure MoveToChild(const Name: string);
    procedure MoveToParent;
    //  Arrays
    function  ListBegin: Boolean;
    function  ListNext: Boolean;
    procedure ListEnd;
    function  ListValue: string;
    procedure LoadStrings(const Strs: TStrings);
    //  Property values
    function  ValueBegin: Boolean;
    function  ValueNext: Boolean;
    procedure ValueEnd;
    function  GetValue(const Name: string; const TypeKind: TTypeKind; out Value: TValue): Boolean;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, BatSoft.Settings;

{ TSettingsStoreReaderJSON }

procedure TSettingsStoreReaderJSON.BeginLoad;
var
  JSONStr: string;
begin
  JSONStr := TFile.ReadAllText(fFileName);
  Push(TJSONObject.ParseJSONValue(JSONStr));
end;

constructor TSettingsStoreReaderJSON.CreateFile(const AFileName: string);
begin
  inherited Create;
  fJSONPath := TList<TPathItem>.Create;
  fFileName := AFileName;
end;

destructor TSettingsStoreReaderJSON.Destroy;
begin
  fJSONPath.Free;
  inherited;
end;

procedure TSettingsStoreReaderJSON.EndLoad;
begin
  fJSONPath[0].Node.Free;
  fJSONPath.Clear;
end;

function TSettingsStoreReaderJSON.GetIndex: integer;
begin
  Result  := Peek.Index
end;

//function TSettingsStoreReaderJSON.GetNameValue(out Name: string; out Value: TValue): Boolean;
//var
//  Pair: TJSONPair;
//begin
//  Pair    := (Peek.Node as TJSONObject).Pairs[Index];
//  Result  := Assigned(Pair);
//  if  Result  then
//    begin
//      Name  := Pair.JsonString.Value;
//      Value := Pair.JsonValue;
//    end;
//end;

function TSettingsStoreReaderJSON.GetValue(const Name: string; const TypeKind: TTypeKind; out Value: TValue): Boolean;
var
  JSONValue: TJSONValue;
begin
  JSONValue := (Peek.Node as TJSONObject).GetValue(Name);
  Result    := Assigned(JSONValue);
  if  Result  then
    if  JSONValue is TJSONNull  then
      Value := TValue.Empty
    else
      case TypeKind of
        tkInteger :   Value := TValue.From(JSONValue.AsType<integer>);
        tkChar :      Value := TValue.From(JSONValue.AsType<Char>);
        tkEnumeration : Value := TValue.From(JSONValue.AsType<string>);
        tkFloat :     Value := TValue.From(JSONValue.AsType<Float32>);
        tkString :    Value := TValue.From(JSONValue.AsType<string>);
        tkSet :       Value := TValue.From(JSONValue.AsType<string>);
        tkClass :     Value := TValue.From(JSONValue);
//        tkMethod :    Value := TValue.From(JSONValue.AsType<>);
        tkWChar :     Value := TValue.From(JSONValue.AsType<WideChar>);
        tkLString :   Value := TValue.From(JSONValue.AsType<string>);
        tkWString :   Value := TValue.From(JSONValue.AsType<string>);
        tkVariant :   Value := TValue.From(JSONValue.AsType<Variant>);
//        tkArray :     Value := TValue.From(JSONValue.AsType<>);
//        tkRecord :    Value := TValue.From(JSONValue.AsType<>);
//        tkInterface : Value := TValue.From(JSONValue.AsType<>);
        tkInt64 :     Value := TValue.From(JSONValue.AsType<Int64>);
//        tkDynArray :  Value := TValue.From(JSONValue.AsType<>);
        tkUString :   Value := TValue.From(JSONValue.AsType<string>);
        tkClassRef :  Value := TValue.From(JSONValue.AsType<string>);
//        tkPointer :   Value := TValue.From(JSONValue.AsType<>);
//        tkProcedure : Value := TValue.From(JSONValue.AsType<>);
//        tkMRecord :   Value := TValue.From(JSONValue.AsType<>);
      else
        raise ESettings.Create('Unsupported type kind for ' + Name + '.');
      end;
end;

function TSettingsStoreReaderJSON.GotoItem(const Index: integer): Boolean;
var
  List: TJSONArray;
  ListItem: TPathItem;
begin
  List    := Parent.Node as TJSONArray;
  Result  := Index < List.Count;
  if  Result  then
    begin
      ListItem.Node   := List.Items[Index];
      ListItem.Index  := Index;
      fJSONPath[fJSONPath.Count - 1]  := ListItem;
    end;
end;

function TSettingsStoreReaderJSON.IsList: Boolean;
begin
  Result  := Peek.Node is TJSONArray
end;

function TSettingsStoreReaderJSON.ListBegin: Boolean;
begin
  if  not IsList  then
    raise ESettings.Create('Expected JSON type %s but found %s.', [TJSONArray.ClassName, Peek.Node.ClassName]);
  Result  := (Peek.Node as TJSONArray).Count > 0;
  if  Result  then
    begin
      Push(nil);
      GotoItem(0);
    end;
end;

procedure TSettingsStoreReaderJSON.ListEnd;
begin
  Pop;
end;

function TSettingsStoreReaderJSON.ListNext: Boolean;
begin
  Result  := GotoItem(Peek.Index + 1);
end;

function TSettingsStoreReaderJSON.ListValue: string;
var
  List: TJSONArray;
begin
  List    := Parent.Node as TJSONArray;
  Result  := List.Items[Index].Value;
end;

procedure TSettingsStoreReaderJSON.LoadStrings(const Strs: TStrings);
var
  List: TJSONArray;
  i: integer;
begin
  List  := Peek.Node as TJSONArray;
  for i := 0 to List.Count - 1 do
    Strs.Add(List.Items[i].Value);
end;

procedure TSettingsStoreReaderJSON.MoveToChild(const Name: string);
var
  Node: TJSONValue;
begin
  Node  := Peek.Node.FindValue(Name);
  if  Assigned(Node) and ((Node is TJSONObject) or (Node is TJSONArray))  then
    Push(Node)
  else
    raise ESettings.Create('Tried to move to property that is neither an object nor a node.');
end;

procedure TSettingsStoreReaderJSON.MoveToParent;
begin
  Pop;
end;

function TSettingsStoreReaderJSON.Parent: TPathItem;
begin
  Result  := fJSONPath[fJSONPath.Count - 2];
end;

function TSettingsStoreReaderJSON.Peek: TPathItem;
begin
  Result  := fJSONPath[fJSONPath.Count - 1];
end;

function TSettingsStoreReaderJSON.Pop: TPathItem;
begin
  Result  := Peek;
  fJSONPath.Delete(fJSONPath.Count - 1);
end;

procedure TSettingsStoreReaderJSON.Push(const Node: TJSONValue);
var
  PathItem: TPathItem;
begin
  PathItem.Node := Node;
  fJSONPath.Add(PathItem);
end;

procedure TSettingsStoreReaderJSON.SetIndex(const Value: integer);
var
  PathItem: TPathItem;
begin
  PathItem  := Peek;
  PathItem.Index  := Value;
  fJSONPath[fJSONPath.Count - 1]  := PathItem;
end;

function TSettingsStoreReaderJSON.State: string;
var
  i: integer;
  Item: TPathItem;
begin
  Result  := '';
  for i := 0 to fJSONPath.Count - 1 do
    begin
      Item  := fJSONPath[i];
      Result  := Result + '{';
      Result  := Result + 'Node: ' + Item.Node.ClassName;
      Result  := Result + ', ';
      Result  := Result + 'Index=' + Item.Index.ToString;
      Result  := Result + '}';
    end;
end;

function TSettingsStoreReaderJSON.ValueBegin: Boolean;
begin
  Result  := Index < (Peek.Node as TJSONObject).Count;
end;

procedure TSettingsStoreReaderJSON.ValueEnd;
begin
  //  Nothing to do
end;

function TSettingsStoreReaderJSON.ValueNext: Boolean;
begin
  Index   := Index + 1;
  Result  := Index < (Peek.Node as TJSONObject).Count;
end;

end.
