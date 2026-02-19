unit BatSoft.Context.Objects;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.Rtti, System.TypInfo, System.Classes, Generics.Collections, BatSoft.Context;

type
  //  This context gives access to the properties of an object.
  //  The prefix can be used (optional) to distingush between contexts.
  TContextObject = class(TContextBase)
  private
    fObject: TObject;
    fProps: TDictionary<string, TRttiProperty>;
  public
    constructor Create(const AObject: TObject; const APrefix: string = ''; const AMemberVisibility: TMemberVisibility = mvPublic);
    destructor  Destroy; override;
    //  IContext interface
    function  HasValue(const Name: string): Boolean; override;
    function  GetValue(const Name: string): TValue; override;
    function  SetValue(const Name: string; const Value: TValue): Boolean; override;
    function  GetTypeOf(const Name: string): PTypeInfo; override;
    function  GetNames(const Names: TStrings): Boolean; override;
  end;

implementation

uses
  System.SysUtils, BatSoft.Common;

{ TContextObject }

constructor TContextObject.Create(const AObject: TObject; const APrefix: string; const AMemberVisibility: TMemberVisibility);
var
  PropArr: TArray<TRttiProperty>;
  Prop, OldProp: TRttiProperty;
begin
  inherited Create;
  fObject := AObject;
  fProps  := TDictionary<string, TRttiProperty>.Create(CaseInsensitiveComparer);
  //  Collect a shortlist of the property accessors
  PropArr := RTTI.GetType(fObject.ClassType).GetProperties;
  for Prop in PropArr do
    if  AMemberVisibility <= Prop.Visibility  then
      //  It seems that classes can have properties repeated.
      if  not fProps.TryGetValue(Prop.Name, OldProp) or (OldProp.Visibility < Prop.Visibility)  then
        fProps.AddOrSetValue(APrefix + Prop.Name, Prop);
end;

destructor TContextObject.Destroy;
begin
  fProps.Free;
  inherited;
end;

function TContextObject.GetNames(const Names: TStrings): Boolean;
var
  Key: string;
begin
  for Key in fProps.Keys do
    Names.Add(Key);
  Result  := True;
end;

function TContextObject.GetTypeOf(const Name: string): PTypeInfo;
var
  Prop: TRttiProperty;
begin
  if  fProps.TryGetValue(Name, Prop)  then
    Result  := Prop.DataType.Handle
  else
    Result  := nil
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
