unit BatSoft.Observer.Managed;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

//  This unit implements the observer pattern.
//  (This pattern is like component events such as OnClick, OnChanged, etc.)
//
//  TManagedEventHandler enables multiple objects to subscribe to the same event.
//
//  When an observer subscribes to a TManagedEventHandler event, it recieves an
//  interface that represents the subscription.
//  - When either the observer or the event handler releases the subscription object, the subscription ends.
//  - When the subscription ends, the event ISubscription.OnEnd() fires.
//  - You can see the state of the subscription by calling ISubscription.IsActive().
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
//      fSubscription: ISubscription;
//    Code...
//      fSubscription := MySubj.Subscribe(CallbackMethod);
//
//  To unsubscribe:
//      fSubscription := nil;
//
//  To fire the event, the TMySubject object calls:
//    fOnChanged.Call();

interface

uses
  System.Classes, Generics.Collections, BatSoft.Observer.Base;

type
  TManagedEventHandler = class;

  TEndSubscriptionEvent = procedure (const EventHandler: TManagedEventHandler) of object;

  ISubscription = interface
    ['{D85704DF-BDBB-4729-BDEC-8008FF94DEE7}']
    function  GetEventHandler: TManagedEventHandler;
    function  GetOnEnd: TEndSubscriptionEvent;
    procedure SetOnEnd(const Value: TEndSubscriptionEvent);

    function  IsActive    : Boolean;
    property  EventHandler: TManagedEventHandler  read GetEventHandler; //  Might be nil, meaning subscription has ended
    property  OnEnd       : TEndSubscriptionEvent read GetOnEnd  write SetOnEnd;
  end;

  TCallCallback = reference to procedure(const Callback: TMethod);

  TManagedEventHandler = class
  private type

    TSubscription = class(TInterfacedObject, ISubscription)
    private
      fEventHandler: TManagedEventHandler;
      fCallback: TMethod;
      fOnEnd: TEndSubscriptionEvent;
    public
      constructor Create(const AManagedEvents: TManagedEventHandler; const ACallback: TMethod);
      destructor  Destroy; override;
      //  ISubscription interface
      function  IsActive: Boolean; inline;
      function  GetEventHandler: TManagedEventHandler; inline;
      function  GetOnEnd: TEndSubscriptionEvent; inline;
      procedure SetOnEnd(const Value: TEndSubscriptionEvent); inline;
    end;

  private
    fSubject: TObject;
    fEnabled: Boolean;
    fSubscriptions: TList<TSubscription>;
    fEnumerators: TFlowingEnumerators<TSubscription>;
    function GetHasSubscriptions: Boolean;
  protected
    function  BeginSubscription(const Callback: TMethod): ISubscription;
    procedure EndSubscription(const Subscription: TSubscription);
    procedure EndAllSubscriptions;
    function  FindSubscription(const Callback: TMethod; out Subscription: TSubscription): Boolean;
    procedure CallEvents(const CallCallback: TCallCallback);
  public
    constructor Create(const ASubject: TObject; const AThreadSafe: Boolean = False);
    destructor  Destroy; override;
    property  Subject : TObject read fSubject;
    property  Enabled : Boolean read fEnabled write fEnabled;
    property  HasSubscriptions: Boolean read GetHasSubscriptions;
    procedure Clear;
  end;

  TNotifyEvents = class(TManagedEventHandler)
  public
    procedure Call;
    function  Subscribe(const Callback: TNotifyEvent): ISubscription;
  end;

  TEvent1Param<TParam1> = class(TManagedEventHandler)
  public type
    TCallback1Param = procedure(Subject: TObject; Param: TParam1) of object;
  public
    procedure Call(Param1: TParam1);
    function  Subscribe(const Callback: TCallback1Param): ISubscription;
  end;

  TEvent2Param<TParam1, TParam2> = class(TManagedEventHandler)
  public type
    TCallback2Param = procedure(Subject: TObject; Param1: TParam1; Param2: TParam2) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2);
    function  Subscribe(const Callback: TCallback2Param): ISubscription;
  end;

  TEvent3Param<TParam1, TParam2, TParam3> = class(TManagedEventHandler)
  public type
    TCallback3Param = procedure(Subject: TObject; Param1: TParam1; Param2: TParam2; Param3: TParam3) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2; Param3: TParam3);
    function  Subscribe(const Callback: TCallback3Param): ISubscription;
  end;

implementation

{ TManagedEventHandler.TSubscription }

constructor TManagedEventHandler.TSubscription.Create(const AManagedEvents: TManagedEventHandler; const ACallback: TMethod);
begin
  inherited Create;
  fEventHandler  := AManagedEvents;
  fCallback       := ACallback;
end;

destructor TManagedEventHandler.TSubscription.Destroy;
begin
  if  Assigned(fEventHandler)  then
    fEventHandler.EndSubscription(Self);
  //else
  //  Do nothing, because the subscription has already ended.
  //  (Something held on to this subscription interface while everything else died.)
  inherited;
end;

function TManagedEventHandler.TSubscription.GetEventHandler: TManagedEventHandler;
begin
  Result  := fEventHandler;
end;

function TManagedEventHandler.TSubscription.GetOnEnd: TEndSubscriptionEvent;
begin
  Result  := fOnEnd
end;

function TManagedEventHandler.TSubscription.IsActive: Boolean;
begin
  Result  := Assigned(fEventHandler)
end;

procedure TManagedEventHandler.TSubscription.SetOnEnd(const Value: TEndSubscriptionEvent);
begin
  fOnEnd := Value
end;

{ TManagedEventHandler }

function TManagedEventHandler.BeginSubscription(const Callback: TMethod): ISubscription;
var
  Subscription: TSubscription;
begin
  if  not FindSubscription(Callback, Subscription)  then
    begin
      Subscription  := TSubscription.Create(Self, Callback);
      fSubscriptions.Add(Subscription);
    end;
  Result  := Subscription;
end;

procedure TManagedEventHandler.CallEvents(const CallCallback: TCallCallback);
var
  Subscription: TSubscription;
begin
  if  fEnabled  then
    for Subscription in fEnumerators  do
      CallCallback(Subscription.fCallback);
end;

procedure TManagedEventHandler.Clear;
begin
  fSubscriptions.Clear;
end;

constructor TManagedEventHandler.Create(const ASubject: TObject; const AThreadSafe: Boolean);
begin
  inherited Create;
  fSubject        := ASubject;
  fSubscriptions  := TList<TSubscription>.Create;
  fEnumerators    := TFlowingEnumerators<TSubscription>.Create(fSubscriptions);
  fEnabled        := True;
end;

destructor TManagedEventHandler.Destroy;
begin
  EndAllSubscriptions;
  fEnumerators.Free;
  fSubscriptions.Free;
  inherited;
end;

procedure TManagedEventHandler.EndAllSubscriptions;
var
  i: Integer;
begin
  //  Indicate to all subscribers that their subscriptions are inactive
  //  Note: An exception in Subscription.OnEnd() will rightly abort this loop.
  //        It's better that you write stable code than that I second guess some
  //        preferred behaviour that might be unsuitable.
  for i := fSubscriptions.Count - 1 downto 0 do
    EndSubscription(fSubscriptions[i]);
end;

procedure TManagedEventHandler.EndSubscription(const Subscription: TSubscription);
begin
  //  Indicate to observer that this subscription is inactive
  Subscription.fEventHandler  := nil;
  //  Forget this subscription
  fEnumerators.RemoveListItem(Subscription);
  //  Might need to let observer know that this subscription is inactive
  if  Assigned(Subscription.fOnEnd)  then
    Subscription.fOnEnd(Self);
end;

function TManagedEventHandler.FindSubscription(const Callback: TMethod; out Subscription: TSubscription): Boolean;
var
  Index: integer;
begin
  Result  := False;
  for Index := fSubscriptions.Count - 1 downto 0 do
    if fSubscriptions[Index].fCallback = Callback then
      begin
        Subscription  := fSubscriptions[Index];
        Exit(True);
      end;
end;

function TManagedEventHandler.GetHasSubscriptions: Boolean;
begin
  Result  := fSubscriptions.Count > 0
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

function TNotifyEvents.Subscribe(const Callback: TNotifyEvent): ISubscription;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;

{ TEvent1Param<TParam1> }

procedure TEvent1Param<TParam1>.Call(Param1: TParam1);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback1Param(Callback)(fSubject, Param1);
    end)
end;

function TEvent1Param<TParam1>.Subscribe(const Callback: TCallback1Param): ISubscription;
begin
  Result  := BeginSubscription(TMethod(Callback))
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

function TEvent2Param<TParam1, TParam2>.Subscribe(const Callback: TCallback2Param): ISubscription;
begin
  Result  := BeginSubscription(TMethod(Callback))
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

function TEvent3Param<TParam1, TParam2, TParam3>.Subscribe(const Callback: TCallback3Param): ISubscription;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;

end.
