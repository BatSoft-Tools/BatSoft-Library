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
  System.SysUtils, System.RTTI, System.Classes, System.Generics.Collections;

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
  end;

  /// <summary>Some implementations of IContext can provide summaries of their
  ///  values. This method is meant to add names without clearing them.</summary>
  IContextNames = interface(IContext)
    ['{00FF40F0-2BDC-4134-A439-8A6122DDB4EE}']
    procedure GetNames(const Names: TStrings);
  end;

  EContext = class(Exception)
  public
    constructor Create(const Message, Name: string); overload;
    constructor CreateNotImplemented(const AContext: TObject; const AMethodName: string);
  end;

  //  Base class for IContext implementations

  /// <summary>Handy base class (ie. methods are not implemented) of IContext implementations.</summary>
  TContextBase = class(TInterfacedObject, IContext)
  public
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    //  IContextNames interface
    procedure GetNames(const Names: TStrings);
  end;

  //  Basic IContext implementations

  /// <summary>This simply contains names-values.</summary>
  TContextValues = class(TInterfacedObject, IContext, IContextNames)
  private
    fNameValues: TDictionary<string, TValue>;
  public
    constructor Create;
    destructor  Destroy; override;
    //  IContext interface
    function  HasValue(const Name: string): Boolean; virtual;
    function  DelValue(const Name: string): Boolean; virtual;
    function  GetValue(const Name: string): TValue; virtual;
    function  SetValue(const Name: string; const Value: TValue): Boolean; virtual;
    //  IContextNames interface
    procedure GetNames(const Names: TStrings);
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
  end;

resourcestring
  SENotImplemented  = 'IContext method %s() is not implemented';
  SEValueNotFound   = 'Value not found for ''%s''.';

implementation

{ EContext }

constructor EContext.Create(const Message, Name: string);
begin
  inherited Create(Format(Message, [Name]));
end;

constructor EContext.CreateNotImplemented(const AContext: TObject; const AMethodName: string);
begin
  Create(SENotImplemented, AContext.ClassName + '.' + AMethodName)
end;

{ TContextBase }

function TContextBase.DelValue(const Name: string): Boolean;
begin
  Result  := False;
end;

procedure TContextBase.GetNames(const Names: TStrings);
begin
  raise EContext.CreateNotImplemented(Self, 'GetNames')
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

constructor TContextValues.Create;
begin
  inherited;
  fNameValues := TDictionary<string, TValue>.Create;
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

procedure TContextValues.GetNames(const Names: TStrings);
begin
  Names.AddStrings(fNameValues.Keys.ToArray);
end;

function TContextValues.GetValue(const Name: string): TValue;
begin
  if  not fNameValues.TryGetValue(Name, Result) then
    raise EContext.Create(SEValueNotFound, Name);
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

function TContexts.GetValue(const Name: string): TValue;
var
  Contexts: IContext;
begin
  if  FindContextWith(Name, Contexts)  then
    Result  := Contexts.GetValue(Name)
  else
    raise EContext.Create(SEValueNotFound, Name);
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
