unit uHardwareState;

interface

uses
  BatSoft.Observer.Managed;

type
  TDeviceState = class
  private
    fActive: Boolean;
    fOnChange: TNotifyEvents;
    procedure SetActive(const Value: Boolean);
  public
    constructor Create;
    destructor  Destroy; override;
    property  Active    : Boolean       read fActive    write SetActive;
    property  OnChange  : TNotifyEvents read fOnChange;
  end;

  THardwareState = class

  end;

implementation

{ TDeviceState }

constructor TDeviceState.Create;
begin
  inherited;
  fOnChange := TNotifyEvents.Create(Self);
end;

destructor TDeviceState.Destroy;
begin
  fOnChange.Free;
  inherited;
end;

procedure TDeviceState.SetActive(const Value: Boolean);
begin
  if fActive <> Value then
    begin
      fActive := Value;
      fOnChange.Call;
    end;
end;

end.
