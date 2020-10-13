unit BatSoft.Observer.Manual;

//  This unit implements the observer pattern.
//  (This pattern is like component events such as OnClick, OnChanged, etc.)
//
//  TManualEventHandler enables multiple objects to subscribe to the same event.
//
//  With TManualEventHandler the lifetime of a subscription must happen in the following order:
//  - Observer calls Subscribe()
//  - [The event handler is called... however many times.]
//  - Observer calls Unsubscribe()
//  - Observer and event handler can now be freed at will, as they're no longer connected.
//
//  Use TNotifyEvents or implement one of the generics or use them as examples
//  for writing your own explicit event handlers.
//
//  To add an event handler to a subject (the object that observers are observing)
//  do the following, in this example a TNotifyEvents (which does not take parameters)...
//
//  In the subject add:
//    TMySubject = class
//    private
//      fOnChanged: TNotifyEvents;
//    public
//      property  OnChanged: TNotifyEvents  read fOnChanged;
//
//  In the constructor add:
//      fOnChanged  := TNotifyEvents.Create(Self);
//  ...and don't forget to free it in the destructor.
//
//  The observers subscribe by calling:
//    Declarations...
//      MySubj: TMySubject;
//    Code...
//      MySubj.Subscribe(CallbackMethod);
//
//  To unsubscribe:
//      MySubj.Unsubscribe(CallbackMethod);
//
//  To fire the event, the TMySubject object calls:
//    fOnChanged.Call();

interface

uses
  System.Classes, Generics.Collections, BatSoft.Observer.Base;

type
  TCallCallback = reference to procedure(const Callback: TMethod);

  TManualEventHandler = class
  private
    fSubject: TObject;
    fEnabled: Boolean;
    fCallbacks: TList<TMethod>;
    fEnumerators: TFlowingEnumerators<TMethod>;
    function GetHasSubscriptions: Boolean;
  protected
    procedure InternalSubscribe(const Callback: TMethod);
    procedure InternalUnsubscribe(const Callback: TMethod);
    procedure CallEvents(const CallCallback: TCallCallback);
    function  IsSubscribed(const Event: TNotifyEvent): Boolean;
  public
    constructor Create(const ASubject: TObject);
    destructor  Destroy; override;
    property  Subject : TObject read fSubject;
    property  Enabled : Boolean read fEnabled write fEnabled;
    property  HasSubscriptions: Boolean read GetHasSubscriptions;
    procedure Clear;
  end;

  //  This is an implementation of the Observer pattern.

  //  TNotifyEvents can be used as is.
  TNotifyEvents = class(TManualEventHandler)
  public
    procedure Call;
    procedure Subscribe(const Event: TNotifyEvent);
    procedure Unsubscribe(const Event: TNotifyEvent);
    function  TryUnsubscribe(const Event: TNotifyEvent): Boolean;
  end;

  //  The following generics are provided as premade multi-parameter observer implementations.

  TEvent1Param<TParam1> = class(TManualEventHandler)
  public type
    TCallback1Param = procedure(Sender: TObject; Param: TParam1) of object;
  public
    procedure Call(Param1: TParam1);
    procedure Subscribe(const Callback: TCallback1Param);
    procedure Unsubscribe(const Callback: TCallback1Param);
  end;

  TEvent2Param<TParam1, TParam2> = class(TManualEventHandler)
  public type
    TCallback2Param = procedure(Sender: TObject; Param1: TParam1; Param2: TParam2) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2);
    procedure Subscribe(const Callback: TCallback2Param);
    procedure Unsubscribe(const Callback: TCallback2Param);
  end;

  TEvent3Param<TParam1, TParam2, TParam3> = class(TManualEventHandler)
  public type
    TCallback3Param = procedure(Sender: TObject; Param1: TParam1; Param2: TParam2; Param3: TParam3) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2; Param3: TParam3);
    procedure Subscribe(const Callback: TCallback3Param);
    procedure Unsubscribe(const Callback: TCallback3Param);
  end;

implementation

{ TManualEventHandler }

procedure TManualEventHandler.CallEvents(const CallCallback: TCallCallback);
var
  Callback: TMethod;
begin
  if  fEnabled  then
    for Callback in fEnumerators do
      CallCallback(Callback);
end;

procedure TManualEventHandler.Clear;
begin
  fCallbacks.Clear;
end;

constructor TManualEventHandler.Create(const ASubject: TObject);
begin
  inherited Create;
  fSubject      := ASubject;
  fCallbacks    := TList<TMethod>.Create;
  fEnumerators  := TFlowingEnumerators<TMethod>.Create(fCallbacks);
  fEnabled      := True;
end;

destructor TManualEventHandler.Destroy;
begin
  fEnumerators.Free;
  fCallbacks.Free;
  inherited;
end;

function TManualEventHandler.GetHasSubscriptions: Boolean;
begin
  Result  := fCallbacks.Count > 0
end;

procedure TManualEventHandler.InternalSubscribe(const Callback: TMethod);
begin
  //  Avoid duplicate entries
  if  not fCallbacks.Contains(Callback) then
    fCallbacks.Add(Callback)
end;

procedure TManualEventHandler.InternalUnsubscribe(const Callback: TMethod);
var
  iCallback: integer;
begin
  //  Do not unsubscribe what isn't there
  iCallback := fCallbacks.IndexOf(Callback);
  if  iCallback >= 0  then
    fEnumerators.DeleteListItem(iCallback);
end;

function TManualEventHandler.IsSubscribed(const Event: TNotifyEvent): Boolean;
begin
  Result  := fCallbacks.IndexOf(TMethod(Event)) >= 0
end;

{ TNotifyEvents }

procedure TNotifyEvents.Call;
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TNotifyEvent(Callback)(fSubject);
    end)
end;

procedure TNotifyEvents.Subscribe(const Event: TNotifyEvent);
begin
  InternalSubscribe(TMethod(Event));
end;

function TNotifyEvents.TryUnsubscribe(const Event: TNotifyEvent): Boolean;
begin
  Result  := False;
  if  IsSubscribed(Event) then
    begin
      Unsubscribe(Event);
      Result  := True;
    end
end;

procedure TNotifyEvents.Unsubscribe(const Event: TNotifyEvent);
begin
  InternalUnsubscribe(TMethod(Event));
end;

{ TEvent1Param<TParam> }

procedure TEvent1Param<TParam1>.Call(Param1: TParam1);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback1Param(Callback)(fSubject, Param1);
    end)
end;

procedure TEvent1Param<TParam1>.Subscribe(const Callback: TCallback1Param);
begin
  InternalSubscribe(TMethod(Callback));
end;

procedure TEvent1Param<TParam1>.Unsubscribe(const Callback: TCallback1Param);
begin
  InternalUnsubscribe(TMethod(Callback));
end;

{ TEvent2Param<TParam1, TParam2> }

procedure TEvent2Param<TParam1, TParam2>.Call(Param1: TParam1; Param2: TParam2);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback2Param(Callback)(fSubject, Param1, Param2);
    end)
end;

procedure TEvent2Param<TParam1, TParam2>.Subscribe(const Callback: TCallback2Param);
begin
  InternalSubscribe(TMethod(Callback));
end;

procedure TEvent2Param<TParam1, TParam2>.Unsubscribe(const Callback: TCallback2Param);
begin
  InternalUnsubscribe(TMethod(Callback));
end;

{ TEvent3Param<TParam1, TParam2, TParam3> }

procedure TEvent3Param<TParam1, TParam2, TParam3>.Call(Param1: TParam1; Param2: TParam2; Param3: TParam3);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback3Param(Callback)(fSubject, Param1, Param2, Param3);
    end)
end;

procedure TEvent3Param<TParam1, TParam2, TParam3>.Subscribe(const Callback: TCallback3Param);
begin
  InternalSubscribe(TMethod(Callback));
end;

procedure TEvent3Param<TParam1, TParam2, TParam3>.Unsubscribe(const Callback: TCallback3Param);
begin
  InternalUnsubscribe(TMethod(Callback));
end;

end.
