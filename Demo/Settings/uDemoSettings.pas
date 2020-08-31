unit uDemoSettings;

interface

uses
  Classes, Generics.Collections, BatSoft.Settings;

type
  //  Your settings classes must be enclosed with {$M+} so that RTTI exists for
  //  them.  (Also, they can inherit from classes that have had {$M+})
  //  Settings that are persisted must be published.
  //  That means that you can have some properties that are for ease of use (public),
  //  and other properties that are persisted (published).

  TAccess = (accReadOnly, accEdit, accAdmin);

{$M+}
  TUserSettings = class
  private
    fUserName: string;
    fAccess: TAccess;
  published
    property  UserName  : string  read fUserName  write fUserName;
    property  Access    : TAccess read fAccess    write fAccess;
  end;

  TUsers = class(TSettingsList<TUserSettings>);

  TDemoSettings = class
  private
    fUserNameCurr: string;
    fUserNameAll: TStringList;
    fSettingB: integer;
    fSettingA: string;
    fUsers: TUsers;
    function GetUserCurr: TUserSettings;
  //  Ease of use properties (because they're public)
  public
    constructor Create;
    destructor  Destroy; override;
    property  UserCurr      : TUserSettings read GetUserCurr;
  //  Saved properties (because they're published)
  published
    //  To add a new setting, simply add a new published property
    property  SettingA  : string  read fSettingA  write fSettingA;
    property  SettingB  : integer read fSettingB  write fSettingB;
    //  Here we show how you can ensure that some settings are read/written before others.
    //  The attribure to use is:  [SettingsOrder(ReadOrder, WriteOrder)]
    [SettingsOrder(1, 1)] //  Ensures this is read and written before UserNameCurr
    property  UserNameAll   : TStringList   read fUserNameAll;
    [SettingsOrder(2, 2)]
    property  UserNameCurr  : string  read fUserNameCurr  write fUserNameCurr;
    //  Here we persist containers of settings
    property  Users : TUsers  read fUsers write fUsers;
  end;
{$M-}

implementation

{ TDemoSettings }

constructor TDemoSettings.Create;
begin
  fUserNameAll  := TStringList.Create;
  fUsers  := TUsers.Create(True);
end;

destructor TDemoSettings.Destroy;
begin
  fUserNameAll.Free;
  fUsers.Free;
  inherited;
end;

function TDemoSettings.GetUserCurr: TUserSettings;
var
  i: integer;
begin
  if  UserNameAll.Find(UserNameCurr, i) then
    Result  :=UserNameAll.Objects[i] as TUserSettings
  else
    Result  := nil
end;

end.
