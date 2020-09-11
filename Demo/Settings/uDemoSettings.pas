unit uDemoSettings;

interface

uses
  Classes, Generics.Collections, BatSoft.Settings.Base;

type
  //  Your settings classes must be enclosed with {$M+} so that RTTI exists for
  //  them.  (Also, they can inherit from classes that have had {$M+})
  //  Settings that are persisted must be published.
  //  That means that you can have some properties that are for ease of use (public),
  //  and other properties that are persisted (published).

  TAccess = (accReadOnly, accEdit, accAdmin);
  TAccesses = set of TAccess;

{$M+}
  TUserSettings = class
  private
    fUserName: string;
    fAccess: TAccess;
    fAccesses: TAccesses;
    fDateTime: TDateTime;
  published
    property  UserName  : string    read fUserName  write fUserName;
    property  Access    : TAccess   read fAccess    write fAccess;
    property  Accesses  : TAccesses read fAccesses  write fAccesses;
    property  DateTime  : TDateTime read fDateTime  write fDateTime;
  end;

  TUserSub = class(TUserSettings)
  private
    fExtraField: string;
  published
    property  ExtraField  : string  read fExtraField  write fExtraField;
  end;

  TUsers = class(TObjectList<TUserSettings>);

  TDemoSettings = class
  private
    fSettingB: integer;
    fSettingA: string;
    fUserNil: TUserSettings;
    fUserSame: TUserSettings;
    fUserSub: TUserSettings;
    fUserNameAll: TStringList;
    fUserNameCurr: string;
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
    //  Here have children
    property  UserNil   : TUserSettings read fUserNil   write fUserNil;
    property  UserSame  : TUserSettings read fUserSame  write fUserSame;
    property  UserSub   : TUserSettings read fUserSub   write fUserSub;
    //  Here we show how you can ensure that some settings are read/written before others.
    //  The attribure to use is:  [SettingsOrder(ReadOrder, WriteOrder)]
    [SettingsOrder(1, 1)] //  Ensures this is read and written before UserNameCurr
    property  UserNameAll   : TStringList   read fUserNameAll;
    [SettingsDeepField]
    property  UserNameDeep   : TStringList   read fUserNameAll;
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
  fUserSame := TUserSettings.Create;
  fUserSub  := TUserSub.Create;
  fUserNameAll  := TStringList.Create;
  fUsers  := TUsers.Create(True);
end;

destructor TDemoSettings.Destroy;
begin
  fUserSame.Free;
  fUserSub.Free;
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

initialization
  ObjectLists.Register(TUsers, TUserSettings)

end.
