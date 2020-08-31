unit BatSoft.Net.Indy;

interface

uses
  SysUtils, Classes, Generics.Collections, IdTCPServer, IdTCPClient, IdContext,
  BatSoft.Net;

type
  TPierTCP = class(TInterfacedObject, IPier)
  private
    fContext: TIdContext;
    constructor Create(const AContext: TIdContext);
  public
    //  IPier interface
    function  SendSync(Bytes: TBytes): TBytes;
    procedure SendAsync(Bytes: TBytes; const Response: TResponse);
  end;

  TPiersTCP = class(TComponent)
  private
    fPiers: TDictionary<TIdContext, IPier>;
    fServerTCP: TIdTCPServer;
    fOnConnected: TPierEvent;
    fOnDisconnected: TPierEvent;
    fPort: Word;
    procedure Connect(AContext: TIdContext);
    procedure Disconnect(AContext: TIdContext);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
//    function  Connect(const Host: string; const Port: Word): IPier;
    property  OnConnected   : TPierEvent read fOnConnected    write fOnConnected;
    property  OnDisconnected: TPierEvent read fOnDisconnected write fOnDisconnected;
  published
    property  Port: Word  read fPort  write fPort;
  end;

implementation

//uses
//  IdCustomTCPServer, IdBaseComponent, IdComponent, IdTCPConnection;

{ TPierTCP }

constructor TPierTCP.Create(const AContext: TIdContext);
begin
  inherited Create();
  fContext  := AContext;
end;

procedure TPierTCP.SendAsync(Bytes: TBytes; const Response: TResponse);
begin

end;

function TPierTCP.SendSync(Bytes: TBytes): TBytes;
begin

end;

{ TPiersTCP }

procedure TPiersTCP.Connect(AContext: TIdContext);
var
  Pier: IPier;
begin
  Pier  := TPierTCP.Create(AContext);
  fPiers.Add(AContext, Pier);
  if Assigned(fOnConnected) then
    fOnConnected(Pier);
end;

constructor TPiersTCP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fPiers      := TDictionary<TIdContext, IPier>.Create();
  fServerTCP  := TIdTCPServer.Create(Self);
  fServerTCP.Bindings.Add.Port  := Port;
  fServerTCP.OnConnect    := Connect;
  fServerTCP.OnDisconnect := Disconnect;
  fServerTCP.Active := True;
  fServerTCP.StartListening;
end;

destructor TPiersTCP.Destroy;
begin
  fServerTCP.StopListening;
  fServerTCP.Free;
  fPiers.Free;
  inherited;
end;

procedure TPiersTCP.Disconnect(AContext: TIdContext);
var
  Pier: IPier;
  PierTCP: TPierTCP;
begin
  if  not fPiers.TryGetValue(AContext, Pier)  then
    Exit;
  PierTCP := Pier as TPierTCP;
  PierTCP.fContext  := nil;
  if Assigned(fOnDisconnected) then
    fOnDisconnected(Pier);
end;

end.
