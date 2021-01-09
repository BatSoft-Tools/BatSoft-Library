unit uContextObject;

interface

uses
  System.Rtti, System.TypInfo, System.Classes, Generics.Collections, BatSoft.Context;

type
  TContextObject = class(TContextBase)
  private
    fObject: TObject;
    fProps: TDictionary<string, TRttiProperty>;
  public
    constructor Create(const AObject: TObject; const APrefix: string; const AMemberVisibility: TMemberVisibility);
    //  IContext interface
    function  HasValue(const Name: string): Boolean; override;
    function  GetValue(const Name: string): TValue; override;
    function  SetValue(const Name: string; const Value: TValue): Boolean; override;
    function  GetNames(const Names: TStrings): Boolean; override;
  end;

implementation

uses
  System.SysUtils, BatSoft.Classes;

{ TContextObject }

constructor TContextObject.Create(const AObject: TObject; const APrefix: string; const AMemberVisibility: TMemberVisibility);
var
  PropArr: TArray<TRttiProperty>;
  Prop: TRttiProperty;
begin
  inherited Create;
  fObject := AObject;
  //  Collect a shortlist of the properties
  PropArr := RTTI.GetType(fObject.ClassType).GetProperties;
  for Prop in PropArr do
    if  AMemberVisibility <= Prop.Visibility  then
      fProps.Add(APrefix + Prop.Name, Prop);
end;

function TContextObject.GetNames(const Names: TStrings): Boolean;
var
  Key: string;
begin
  for Key in fProps.Keys do
    Names.Add(Key);
  Result  := True;
end;

function TContextObject.GetValue(const Name: string): TValue;
var
  Prop: TRttiProperty;
begin
  if  not fProps.TryGetValue(Name, Prop)  then
    raise EContext.CreateValueNotFound(Name);
  Result  := Prop.GetValue(fObject)
end;

function TContextObject.HasValue(const Name: string): Boolean;
begin
  Result  := fProps.ContainsKey(Name)
end;

function TContextObject.SetValue(const Name: string; const Value: TValue): Boolean;
var
  Prop: TRttiProperty;
begin
  Result  := fProps.TryGetValue(Name, Prop);
  if  Result  then
    Prop.SetValue(fObject, Value)
end;

end.
