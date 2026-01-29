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
  TManagedEventHandler<TSubject: class> = class;

  TEndSubscriptionEvent<TSubject: class> = procedure (const EventHandler: TManagedEventHandler<TSubject>) of object;

  ISubscription<TSubject: class> = interface
    ['{D85704DF-BDBB-4729-BDEC-8008FF94DEE7}']
    function  GetEventHandler: TManagedEventHandler<TSubject>;
    function  GetOnEnd: TEndSubscriptionEvent<TSubject>;
    procedure SetOnEnd(const Value: TEndSubscriptionEvent<TSubject>);

    function  IsActive    : Boolean;
    property  EventHandler: TManagedEventHandler<TSubject>  read GetEventHandler; //  Might be nil, meaning subscription has ended
    property  OnEnd       : TEndSubscriptionEvent<TSubject> read GetOnEnd  write SetOnEnd;
  end;

  ISubscription = interface(ISubscription<TObject>)
    ['{72E8D170-CC4B-4591-B1C5-B71EF7FB92FE}']
  end;

  TCallCallback = reference to procedure(const Callback: TMethod);

  TManagedEventHandler<TSubject: class> = class
  private type

    TSubscription = class(TInterfacedObject, ISubscription<TSubject>)
    private
      fEventHandler: TManagedEventHandler<TSubject>;
      fCallback: TMethod;
      fOnEnd: TEndSubscriptionEvent<TSubject>;
    public
      constructor Create(const AManagedEvents: TManagedEventHandler<TSubject>; const ACallback: TMethod);
      destructor  Destroy; override;
      //  ISubscription interface
      function  IsActive: Boolean; inline;
      function  GetEventHandler: TManagedEventHandler<TSubject>; inline;
      function  GetOnEnd: TEndSubscriptionEvent<TSubject>; inline;
      procedure SetOnEnd(const Value: TEndSubscriptionEvent<TSubject>); inline;
    end;

  private
    fSubject: TSubject;
    fEnabled: Boolean;
    fSubscriptions: TList<TSubscription>;
    fEnumerators: TFlowingEnumerators<TSubscription>;
    function GetHasSubscriptions: Boolean;
  protected
    function  BeginSubscription(const Callback: TMethod): ISubscription<TSubject>;
    procedure EndSubscription(const Subscription: TSubscription);
    procedure EndAllSubscriptions;
    function  FindSubscription(const Callback: TMethod; out Subscription: TSubscription): Boolean;
    procedure CallEvents(const CallCallback: TCallCallback);
  public
    constructor Create(const ASubject: TSubject; const AThreadSafe: Boolean = False);
    destructor  Destroy; override;
    property  Subject : TSubject  read fSubject;
    property  Enabled : Boolean   read fEnabled write fEnabled;
    property  HasSubscriptions: Boolean read GetHasSubscriptions;
    procedure Clear;
  end;

  TNotifyEvents<TSubject: class> = class(TManagedEventHandler<TSubject>)
  public type
    TNotifyEvent = procedure(Subject: TSubject) of object;
  public
    procedure Call;
    function  Subscribe(const Callback: TNotifyEvent): ISubscription<TSubject>;
  end;

  TNotifyEvents = class(TNotifyEvents<TObject>)
  public
    function  Subscribe(const Callback: TNotifyEvent): ISubscription;
  end;

  TEvent1Param<TSubject: class; TParam1> = class(TManagedEventHandler<TSubject>)
  public type
    TCallback1Param = procedure(Subject: TSubject; Param: TParam1) of object;
  public
    procedure Call(Param1: TParam1);
    function  Subscribe(const Callback: TCallback1Param): ISubscription<TSubject>;
  end;

  TEvent1Param<TParam1> = class(TEvent1Param<TObject, TParam1>);

  TEvent2Param<TSubject: class; TParam1, TParam2> = class(TManagedEventHandler<TSubject>)
  public type
    TCallback2Param = procedure(Subject: TSubject; Param1: TParam1; Param2: TParam2) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2);
    function  Subscribe(const Callback: TCallback2Param): ISubscription<TSubject>;
  end;

  TEvent2Param<TParam1, TParam2> = class(TManagedEventHandler<TObject>);

  TEvent3Param<TSubject: class; TParam1, TParam2, TParam3> = class(TManagedEventHandler<TSubject>)
  public type
    TCallback3Param = procedure(Subject: TSubject; Param1: TParam1; Param2: TParam2; Param3: TParam3) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2; Param3: TParam3);
    function  Subscribe(const Callback: TCallback3Param): ISubscription<TSubject>;
  end;

  TEvent3Param<TParam1, TParam2, TParam3> = class(TManagedEventHandler<TObject>);

  TEvent4Param<TSubject: class; TParam1, TParam2, TParam3, TParam4> = class(TManagedEventHandler<TSubject>)
  public type
    TCallback4Param = procedure(Subject: TSubject; Param1: TParam1; Param2: TParam2; Param3: TParam3; Param4: TParam4) of object;
  public
    procedure Call(Param1: TParam1; Param2: TParam2; Param3: TParam3; Param4: TParam4);
    function  Subscribe(const Callback: TCallback4Param): ISubscription<TSubject>;
  end;

  TEvent4Param<TParam1, TParam2, TParam3> = class(TManagedEventHandler<TObject>);

implementation

{ TManagedEventHandler<TSubject>.TSubscription }

constructor TManagedEventHandler<TSubject>.TSubscription.Create(const AManagedEvents: TManagedEventHandler<TSubject>; const ACallback: TMethod);
begin
  inherited Create;
  fEventHandler := AManagedEvents;
  fCallback     := ACallback;
end;

destructor TManagedEventHandler<TSubject>.TSubscription.Destroy;
begin
  if  Assigned(fEventHandler)  then
    fEventHandler.EndSubscription(Self);
  //else
  //  Do nothing, because the subscription has already ended.
  //  (Something held on to this subscription interface while everything else died.)
  inherited;
end;

function TManagedEventHandler<TSubject>.TSubscription.GetEventHandler: TManagedEventHandler<TSubject>;
begin
  Result  := fEventHandler;
end;

function TManagedEventHandler<TSubject>.TSubscription.GetOnEnd: TEndSubscriptionEvent<TSubject>;
begin
  Result  := fOnEnd
end;

function TManagedEventHandler<TSubject>.TSubscription.IsActive: Boolean;
begin
  Result  := Assigned(fEventHandler)
end;

procedure TManagedEventHandler<TSubject>.TSubscription.SetOnEnd(const Value: TEndSubscriptionEvent<TSubject>);
begin
  fOnEnd := Value
end;

{ TManagedEventHandler<TSubject> }

function TManagedEventHandler<TSubject>.BeginSubscription(const Callback: TMethod): ISubscription<TSubject>;
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

procedure TManagedEventHandler<TSubject>.CallEvents(const CallCallback: TCallCallback);
var
  Subscription: TSubscription;
begin
  if  fEnabled  then
    for Subscription in fEnumerators  do
      CallCallback(Subscription.fCallback);
end;

procedure TManagedEventHandler<TSubject>.Clear;
begin
  fSubscriptions.Clear;
end;

constructor TManagedEventHandler<TSubject>.Create(const ASubject: TSubject; const AThreadSafe: Boolean);
begin
  inherited Create;
  fSubject        := ASubject;
  fSubscriptions  := TList<TSubscription>.Create;
  fEnumerators    := TFlowingEnumerators<TSubscription>.Create(fSubscriptions);
  fEnabled        := True;
end;

destructor TManagedEventHandler<TSubject>.Destroy;
begin
  EndAllSubscriptions;
  fEnumerators.Free;
  fSubscriptions.Free;
  inherited;
end;

procedure TManagedEventHandler<TSubject>.EndAllSubscriptions;
var
  i: Integer;
begin
  //  Indicate to all subscribers that their subscriptions are inactive
  //  Note: An exception in Subscription.OnEnd() will rightly abort this loop.
  //        It's better that you write stable code than I second guess some
  //        preferred behaviour that might be unsuitable.
  for i := fSubscriptions.Count - 1 downto 0 do
    EndSubscription(fSubscriptions[i]);
end;

procedure TManagedEventHandler<TSubject>.EndSubscription(const Subscription: TSubscription);
begin
  //  Indicate to observer that this subscription is inactive
  Subscription.fEventHandler  := nil;
  //  Forget this subscription
  fEnumerators.RemoveListItem(Subscription);
  //  Might need to let observer know that this subscription is inactive
  if  Assigned(Subscription.fOnEnd)  then
    Subscription.fOnEnd(Self);
end;

function TManagedEventHandler<TSubject>.FindSubscription(const Callback: TMethod; out Subscription: TSubscription): Boolean;
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

function TManagedEventHandler<TSubject>.GetHasSubscriptions: Boolean;
begin
  Result  := fSubscriptions.Count > 0
end;

{ TNotifyEvents<TSubject> }

procedure TNotifyEvents<TSubject>.Call;
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TNotifyEvent(Callback)(fSubject);
    end)
end;

function TNotifyEvents<TSubject>.Subscribe(const Callback: TNotifyEvent): ISubscription<TSubject>;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;


{ TNotifyEvents }

function TNotifyEvents.Subscribe(const Callback: TNotifyEvent): ISubscription;
begin
  Result  := BeginSubscription(TMethod(Callback)) as ISubscription
end;

{ TEvent1Param<TSubject, TParam1> }

procedure TEvent1Param<TSubject, TParam1>.Call(Param1: TParam1);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback1Param(Callback)(fSubject, Param1);
    end)
end;

function TEvent1Param<TSubject, TParam1>.Subscribe(const Callback: TCallback1Param): ISubscription<TSubject>;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;

{ TEvent2Param<TSubject, TParam1, TParam2> }

procedure TEvent2Param<TSubject, TParam1, TParam2>.Call(Param1: TParam1; Param2: TParam2);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback2Param(Callback)(fSubject, Param1, Param2);
    end)
end;

function TEvent2Param<TSubject, TParam1, TParam2>.Subscribe(const Callback: TCallback2Param): ISubscription<TSubject>;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;

{ TEvent3Param<TSubject, TParam1, TParam2, TParam3> }

procedure TEvent3Param<TSubject, TParam1, TParam2, TParam3>.Call(Param1: TParam1; Param2: TParam2; Param3: TParam3);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback3Param(Callback)(fSubject, Param1, Param2, Param3);
    end)
end;

function TEvent3Param<TSubject, TParam1, TParam2, TParam3>.Subscribe(const Callback: TCallback3Param): ISubscription<TSubject>;
begin
  Result  := BeginSubscription(TMethod(Callback))
end;

{ TEvent4Param<TSubject, TParam1, TParam2, TParam3, TParam4> }

procedure TEvent4Param<TSubject, TParam1, TParam2, TParam3, TParam4>.Call(Param1: TParam1; Param2: TParam2; Param3: TParam3; Param4: TParam4);
begin
  CallEvents(
    procedure (const Callback: TMethod)
    begin
      TCallback4Param(Callback)(fSubject, Param1, Param2, Param3, Param4);
    end)
end;

function TEvent4Param<TSubject, TParam1, TParam2, TParam3, TParam4>.Subscribe(const Callback: TCallback4Param): ISubscription<TSubject>;
begin

end;

end.
