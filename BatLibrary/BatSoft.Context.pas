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
///   TContexts contains references to multiple instances of IContext.
///
/// - Composite
///   https://en.wikipedia.org/wiki/Composite_pattern
///   When interacting with a TContexts instance, you're actually accessing any
///   number of IContext instances as though they are one IContext instance.
///
/// - Chain of Responsibility
///   https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern
///   TContexts passes a method call from one IContext instance to another until
///   the call has been dealt with.

uses
  System.SysUtils, System.TypInfo, System.RTTI, System.Classes,
  System.Generics.Collections, System.Generics.Defaults;

type
  /// <summary>IContext objects provide values given some specific context. Use
  /// TContexts (as IContext) to access and manage them.<br>
  /// The methods DelValue() and SetValue() should return True iff they do their thing.</summary>
  IContext = interface
    ['{8A60F553-5B8A-4FB7-B1FB-DE46788A5260}']
    function  HasValue(const Name: string): Boolean;
    function  DelValue(const Name: string): Boolean;
    function  GetValue(const Name: string): TValue;
    function  SetValue(const Name: string; const Value: TValue): Boolean;
    /// <summary>Return the type of the value, or nil.<br>
    /// Note: For the sake of other IContext implementations, always return nil when the variable Name is not found.</summary>
    function  GetTypeOf(const Name: string): PTypeInfo;
    /// <summary>Add names to list (without clearing the list).<br>
    /// Note: Contexts are NOT obliged to implement this method, but it sure helps.</summary>
    function  GetNames(const Names: TStrings): Boolean;
  end;

  EContext = class(Exception)
  public
    constructor Create(const Message, Name: string); overload;
    constructor CreateNotImplemented(const AContext: TObject; const AMethodName: string);
    constructor CreateValueNotFound(const ValueName: string);
  end;

  /// <summary>Handy base class for IContext implementations. (ie. methods are not implemented)</summary>
  TContextBase = class(TInterfacedObject, IContext)
  public
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    function  GetTypeOf(const Name: string): PTypeInfo; virtual;
    function  GetNames(const Names: TStrings): Boolean; virtual;
  end;

  /// <summary>Basic IContext implementation that simply contains names-values.</summary>
  TContextValues = class(TInterfacedObject, IContext)
  private
    fNameValues: TDictionary<string, TValue>;
  public
    constructor Create(const CaseSensitiveNames: Boolean = False);
    destructor  Destroy; override;
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    function  GetTypeOf(const Name: string): PTypeInfo;
    function  GetNames(const Names: TStrings): Boolean;
  end;

  /// <summary>This is an IContext container. See it as a stack, in that the
  /// later IContext's stack on top of the prior IContext's. Thus, operations
  /// are tried/applied from the end of the list first, moving to the
  /// left/beginning of the list until successful.</summary>
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
    function  GetTypeOf(const Name: string): PTypeInfo;
    function  GetNames(const Names: TStrings): Boolean;
  end;

function ChangeTypeOfValue(const Context: IContext; const Name: string; const Value: TValue): TValue;

type
  TCaseInsensitiveComparer = class(TEqualityComparer<string>)
  public
    function Equals(const Left, Right: string): Boolean; override;
    function GetHashCode(const Value: string): Integer; override;
  end;

var
  CaseInsensitiveComparer: IEqualityComparer<string>;

resourcestring
  SENotImplemented  = 'IContext method %s() is not implemented';
  SEValueNotFound   = 'Value not found for ''%s''.';

implementation

uses
  BatSoft.Settings;

function ChangeTypeOfValue(const Context: IContext; const Name: string; const Value: TValue): TValue;
var
  LeftSide: TValue;
begin
  if  Context.HasValue(Name)  then
    begin
      LeftSide  := Context.GetValue(Name);
      if  not Value.TryCast(LeftSide.TypeInfo, Result)  then
        case LeftSide.Kind of
          tkInteger :
            Result  := StrToInt(Value.AsString);

          tkInt64 :
            Result  := StrToInt64(Value.AsString);

          tkFloat :
            Result  := StrToFloat(Value.AsString);

          tkChar, tkString, tkWChar, tkLString, tkWString, tkUString :
            Result  := Value.ToString;

          tkEnumeration :
            Result  := StrToEnum(Value.ToString, LeftSide.TypeInfo);

          tkSet :
            Result  := StrToEnumSet(Value.ToString, LeftSide.TypeInfo);
        else
          raise EContext.Create('Conversion failed.');
        end;
    end
  else
    Result  := Value
end;

{ TCaseInsensitiveComparer }

function TCaseInsensitiveComparer.Equals(const Left, Right: string): Boolean;
begin
  Result  := SameText(Left, Right)
end;

function TCaseInsensitiveComparer.GetHashCode(const Value: string): Integer;
begin
  Result  := UpperCase(Value).GetHashCode
end;

{ EContext }

constructor EContext.Create(const Message, Name: string);
begin
  inherited Create(Format(Message, [Name]));
end;

constructor EContext.CreateNotImplemented(const AContext: TObject; const AMethodName: string);
begin
  Create(SENotImplemented, AContext.ClassName + '.' + AMethodName)
end;

constructor EContext.CreateValueNotFound(const ValueName: string);
begin
  Create(SEValueNotFound, ValueName)
end;

{ TContextBase }

function TContextBase.DelValue(const Name: string): Boolean;
begin
  Result  := False;
end;

function TContextBase.GetNames(const Names: TStrings): Boolean;
begin
  Result  := False;
end;

function TContextBase.GetTypeOf(const Name: string): PTypeInfo;
begin
  if  HasValue(Name) then
    Result  := GetValue(Name).TypeInfo
  else
    Result  := nil
end;

function TContextBase.GetValue(const Name: string): TValue;
begin
  raise EContext.CreateNotImplemented(Self, 'GetValue')
end;

function TContextBase.HasValue(const Name: string): Boolean;
begin
  Result  := False;
end;

function TContextBase.SetValue(const Name: string; const Value: TValue): Boolean;
begin
  Result  := False;
end;

{ TContext }

constructor TContextValues.Create(const CaseSensitiveNames: Boolean);
begin
  inherited Create();
  if  CaseSensitiveNames then
    fNameValues := TDictionary<string, TValue>.Create
  else  //  Not case sensitive
    begin
      if  not Assigned(CaseInsensitiveComparer)  then
        CaseInsensitiveComparer  := TCaseInsensitiveComparer.Create;
      fNameValues := TDictionary<string, TValue>.Create(CaseInsensitiveComparer);
    end
end;

function TContextValues.DelValue(const Name: string): Boolean;
begin
  Result  := fNameValues.ContainsKey(Name);
  if  Result  then
    fNameValues.Remove(Name)
end;

destructor TContextValues.Destroy;
begin
  fNameValues.Free;
  inherited;
end;

function TContextValues.GetNames(const Names: TStrings): Boolean;
begin
  Names.AddStrings(fNameValues.Keys.ToArray);
  Result  := True;
end;

function TContextValues.GetTypeOf(const Name: string): PTypeInfo;
var
  Value: TValue;
begin
  if  fNameValues.TryGetValue(Name, Value) then
    Result  := Value.TypeInfo
  else
    Result  := nil
end;

function TContextValues.GetValue(const Name: string): TValue;
begin
  if  not fNameValues.TryGetValue(Name, Result) then
    raise EContext.CreateValueNotFound(Name);
end;

function TContextValues.HasValue(const Name: string): Boolean;
begin
  Result  := fNameValues.ContainsKey(Name)
end;

function TContextValues.SetValue(const Name: string; const Value: TValue): Boolean;
begin
  fNameValues.AddOrSetValue(Name, Value);
  Result  := True
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
  i := fChain.Count - 1;
  while (i >= 0) and not fChain[i].DelValue(Name) do
    dec(i);
  Result  := i >= 0
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

function TContexts.GetNames(const Names: TStrings): Boolean;
var
  SubContext  : IContext;
begin
  for SubContext in fChain  do
    SubContext.GetNames(Names);
  Result  := True;
end;

function TContexts.GetTypeOf(const Name: string): PTypeInfo;
var
  Contexts: IContext;
begin
  if  FindContextWith(Name, Contexts)  then
    Result  := Contexts.GetTypeOf(Name)
  else
    Result  := nil
end;

function TContexts.GetValue(const Name: string): TValue;
var
  Contexts: IContext;
begin
  if  FindContextWith(Name, Contexts)  then
    Result  := Contexts.GetValue(Name)
  else
    raise EContext.CreateValueNotFound(Name);
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
  i := fChain.Count - 1;
  while (i >= 0) and not fChain[i].SetValue(Name, Value)  do
    dec(i);
  Result  := i >= 0
end;

end.
