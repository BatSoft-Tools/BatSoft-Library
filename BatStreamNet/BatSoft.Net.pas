unit BatSoft.Net;

interface

uses
  SysUtils, SyncObjs, Generics.Collections, Classes, IdTCPServer, IdTCPClient;

type
  IPier = interface;

  TPierEvent = procedure (Pier: IPier) of object;
  TResponseReply = procedure (Pier: IPier; Bytes: TBytes) of object;
  TResponseError = procedure (Pier: IPier; Error: Exception) of object;

  TResponse = record
    OnReply: TResponseReply;
    OnError: TResponseError;
  end;

  IPier = interface
    ['{0A1F5E27-3E85-4825-8A91-4811C128C8FB}']
    function  SendSync(Bytes: TBytes): TBytes;
    procedure SendAsync(Bytes: TBytes; const Response: TResponse);
  end;

  IPiers = interface
    ['{0CCEFA3D-EB16-4DAC-9C53-8F40F053DAA0}']

  end;

  TPiers = class(TComponent)
  private
    fPiers: TList<IPier>;
    fCritical: TCriticalSection;
    fOnReply: TResponseReply;
    fOnError: TResponseError;
    function Response: TResponse; inline;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function  Connect(): IPier;
    procedure Disconnect(Pier: IPier);
    procedure Clear;
    procedure Multicast(Bytes: TBytes);
    procedure Broadcast(Bytes: TBytes);
    property  OnReply: TResponseReply read fOnReply write fOnReply;
    property  OnError: TResponseError read fOnError write fOnError;
  end;

implementation

uses
  Math;

{ TPiers }

procedure TPiers.Broadcast(Bytes: TBytes);
begin

end;

procedure TPiers.Clear;
begin
  fPiers.Clear;
end;

function TPiers.Connect: IPier;
begin

  fPiers.Add(Result);
end;

constructor TPiers.Create(AOwner: TComponent);
begin
  inherited;
  fPiers  := TList<IPier>.Create;
  fCritical := TCriticalSection.Create;
end;

destructor TPiers.Destroy;
begin
  fCritical.Free;
  fPiers.Free;
  inherited;
end;

procedure TPiers.Disconnect(Pier: IPier);
begin
  fPiers.Remove(Pier);

end;

procedure TPiers.Multicast(Bytes: TBytes);
var
  i: integer;
begin
  i := fPiers.Count;
  repeat
    i := Min(i, fPiers.Count) - 1;
    if i >= 0 then
      fPiers[i].SendAsync(Bytes, Response);
  until i < 0;
end;

function TPiers.Response: TResponse;
begin
  Result.OnReply  := fOnReply;
  Result.OnError  := fOnError;
end;

end.
