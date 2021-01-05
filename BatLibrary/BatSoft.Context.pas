unit BatSoft.Context;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

///*  Patterns:
///
///  https://en.wikipedia.org/wiki/Design_Patterns
///  https://www.oodesign.com/
///
/// - Bridge
///   https://en.wikipedia.org/wiki/Bridge_pattern
///   IContext is an abstraction that is completely separated from its
///   implementations.  But it provides a common way (a bridge) how to use them.
///
/// - Collection/Container
///   http://best-practice-software-engineering.ifs.tuwien.ac.at/patterns/container.html
///   TContexts contains references to many instances of IContext.
///
/// - Composite
///   https://en.wikipedia.org/wiki/Composite_pattern
///   When interacting with a TContexts instance, you're actually accessing any
///   number of IContext instances as though they are one IContext instance.
///
/// - Chain of Responsibiliy
///   https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern
///   TContexts passes a method call from one IContext instance to another until
///   the call has been dealt with.

uses
  System.SysUtils, System.RTTI, System.Generics.Collections;

type
  IContext = interface
    ['{8A60F553-5B8A-4FB7-B1FB-DE46788A5260}']
    function  HasValue(const Name: string): Boolean;
    function  DelValue(const Name: string): Boolean;
    function  GetValue(const Name: string): TValue;
    function  SetValue(const Name: string; const Value: TValue): Boolean;
    function  GetValueKind(const Name: string): TTypeKind;
  end;

  EContext = class(Exception)
  public
    constructor Create(const Message, Name: string); overload;
  end;

  //  Base class for partial IContext implementations

  TContextPartial = class(TInterfacedObject, IContext)
  public
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    function  GetValueKind(const Name: string): TTypeKind; virtual;
  end;

  //  Basic IContext implementations

  TContext = class(TInterfacedObject, IContext)
  private type

    TNameValue = class
    private
      fName: string;
      fValue: TValue;
      fValueKind: TTypeKind;
    public
      constructor Create(const AName: string);
      property  Name      : string      read fName;
      property  Value     : TValue      read fValue;
      property  ValueKind : TTypeKind   read fValueKind;
    end;

    TNameValues = class(TObjectList<TNameValue>)
      function ByName(const Name: string): TNameValue;
      function IndexOf(const Name: string): integer;
    end;

  private
    fNameValues: TNameValues;
  public
    constructor Create;
    destructor  Destroy; override;
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    function  GetValueKind(const Name: string): TTypeKind; virtual;
  end;

  TContexts = class(TInterfacedObject, IContext)
  private
    fChain: TList<IContext>;
    function FindContextWith(const Name: string; out Context: IContext): Boolean;
  public
    constructor Create(const AChain: array of IContext);
    destructor  Destroy; override;
    //  IContext interface
    function  HasValue(const Name: string): Boolean;
    function  DelValue(const Name: string): Boolean;
    function  GetValue(const Name: string): TValue;
    function  SetValue(const Name: string; const Value: TValue): Boolean;
    function  GetValueKind(const Name: string): TTypeKind;
  end;

resourcestring
  SENotImplemented      = 'IContext method %s() is not implemented';
  SECannotGetValue      = 'Cannot get value because ''%s'' not found.';
  SECannotGetFieldType  = 'Cannot get FieldType because ''%s'' not found.';
  SEValueNotFound       = 'Value not found for ''%s''.';
  SEValueTypeNotFound   = 'Value type not found for ''%s''.';

implementation

{ EContext }

constructor EContext.Create(const Message, Name: string);
begin
  inherited Create(Format(SENotImplemented, [Name]));
end;

{ TContextPartial }

function TContextPartial.DelValue(const Name: string): Boolean;
begin
  raise EContext.Create(SENotImplemented, 'DelValue')
end;

function TContextPartial.GetValue(const Name: string): TValue;
begin
  raise EContext.Create(SENotImplemented, 'GetValue')
end;

function TContextPartial.GetValueKind(const Name: string): TTypeKind;
begin
  raise EContext.Create(SENotImplemented, 'GetValueKind')
end;

function TContextPartial.HasValue(const Name: string): Boolean;
begin
  raise EContext.Create(SENotImplemented, 'HasValue')
end;

function TContextPartial.SetValue(const Name: string; const Value: TValue): Boolean;
begin
  raise EContext.Create(SENotImplemented, 'SetValue')
end;

{ TContext.TNameValue }

constructor TContext.TNameValue.Create(const AName: string);
begin
  inherited Create;
  fName := AName;
end;

{ TContext.TNameValues }

function TContext.TNameValues.ByName(const Name: string): TNameValue;
var
  i: integer;
begin
  i := IndexOf(Name);
  if  i >= 0  then
    Result  := Items[i]
  else
    Result  := nil;
end;

function TContext.TNameValues.IndexOf(const Name: string): integer;
begin
  Result  := Count - 1;
  while Result >= 0 do
    if  SameText(Items[Result].Name, Name)  then
      Exit
    else
      dec(Result);
end;

{ TContext }

constructor TContext.Create;
begin
  inherited;
  fNameValues := TNameValues.Create(True);
end;

function TContext.DelValue(const Name: string): Boolean;
var
  i : integer;
begin
  i := fNameValues.IndexOf(Name);
  if  i >= 0  then
    fNameValues.Delete(i);
  Result  := i >= 0
end;

destructor TContext.Destroy;
begin
  fNameValues.Free;
  inherited;
end;

function TContext.GetValue(const Name: string): TValue;
var
  NameValue: TNameValue;
begin
  NameValue := fNameValues.ByName(Name);
  if  not Assigned(NameValue) then
    raise EContext.Create(SECannotGetValue, Name);
  Result  := NameValue.Value;
end;

function TContext.GetValueKind(const Name: string): TTypeKind;
var
  NameValue: TNameValue;
begin
  NameValue := fNameValues.ByName(Name);
  if  not Assigned(NameValue) then
    raise EContext.Create(SECannotGetFieldType, Name);
  Result  := NameValue.ValueKind;
end;

function TContext.HasValue(const Name: string): Boolean;
begin
  Result  := Assigned(fNameValues.ByName(Name))
end;

function TContext.SetValue(const Name: string; const Value: TValue): Boolean;
var
  Context: TNameValue;
begin
  Context := fNameValues.ByName(Name);
  if  not Assigned(Context) then
    begin
      Context := TNameValue.Create(Name);
      fNameValues.Add(Context);
    end;
  Context.fValue      := Value;
  Context.fValueKind  := Value.Kind;
  Result              := True
end;

{ TContexts }

constructor TContexts.Create(const AChain: array of IContext);
var
  i: integer;
begin
  inherited Create;
  fChain  := TList<IContext>.Create;
  for i := 0 to Length(AChain) - 1  do
    if  Assigned(AChain[i]) then
      fChain.Add(AChain[i]);
end;

function TContexts.DelValue(const Name: string): Boolean;
var
  i: Integer;
begin
  i := 0;
  while (i < fChain.Count) and not fChain[i].DelValue(Name)  do
    inc(i);
  Result  := i < fChain.Count
end;

destructor TContexts.Destroy;
begin
  fChain.Free;
  inherited;
end;

function TContexts.FindContextWith(const Name: string; out Context: IContext): Boolean;
var
  i: integer;
begin
  for i := fChain.Count - 1 downto 0  do
    begin
      Context  := fChain[i];
      if  Context.HasValue(Name) then
        Exit(True);
    end;
  Context  := nil;
  Result    := False;
end;

function TContexts.GetValue(const Name: string): TValue;
var
  Contexts: IContext;
begin
  if  FindContextWith(Name, Contexts)  then
    Result  := Contexts.GetValue(Name)
  else
    raise EContext.Create(SEValueNotFound, Name);
end;

function TContexts.GetValueKind(const Name: string): TTypeKind;
var
  Contexts: IContext;
begin
  if  FindContextWith(Name, Contexts)  then
    Result  := Contexts.GetValueKind(Name)
  else
    raise EContext.Create(SEValueTypeNotFound, Name);
end;

function TContexts.HasValue(const Name: string): Boolean;
var
  Contexts: IContext;
begin
  Result  := FindContextWith(Name, Contexts)
end;

function TContexts.SetValue(const Name: string; const Value: TValue): Boolean;
var
  i: integer;
begin
  i := 0;
  while (i < fChain.Count) and not fChain[i].SetValue(Name, Value)  do
    inc(i);
  Result  := i < fChain.Count
end;

end.
