unit uDemoSettings;

interface

uses
  System.Types, System.Classes, Generics.Collections, BatSoft.Classes, BatSoft.Settings,
  //  Note: By including BatSoft.Settings.Types in the project,
  //  we ensure that the default converters are registered and active.
  BatSoft.Settings.Types;

type
//  Your settings classes must be enclosed with {$M+} so that RTTI exists for
//  them.  (Or they can inherit from classes that have {$M+}.)
//  Only published settings are persisted/streamed.
//  That means that you can have some properties that are for ease of use (public),
//  and other properties that are persisted (published).

//  Ensure we have RTTI for the settings classes
{$M+}

  TUser = class
  private
    fID: TGUID;
    fName: string;
    fBDate: TDate;
  public
    constructor CreateNew(const AName: string = '');
    constructor CreateSeeded(const AID: TGUID; const AName: string);
  published
    property  ID    : TGUID   read fID    write fID;
    property  Name  : string  read fName  write fName;
    property  BDate : TDate   read fBDate write fBDate;
  end;

  //  This is registered (as the bottom of this unit) as a list class.
  //  In some formats (ex. JSON) a list is saved differently from an object,
  //  therefore properties will not be saved.
  //  So a registered list object (like this one) must not have any other settings.
  TUsers = class(TObjectList<TUser>)
  public
    function  FindByID(const UserID: TGUID): TUser;
    procedure DeleteUser(const UserID: TGUID);
    function  IndexOf(const UserID: TGUID): integer; overload;
  end;

  TAppSettings = class
  private
    fActiveUser: TUser;
    fUsers: TUsers;
    fUserForm: TRect;
    fUserNames: TStrings;
    function  GetActiveUserID: TGUID;
    procedure SetActiveUserID(const Value: TGUID);
  public
    constructor Create;
    destructor  Destroy; override;
  published
    //  Let's not save this.  Rather, let's persist the active user's ID.
    //  Another way is to make this property public instead of published.
    [SettingsIgnore]
    property  ActiveUser    : TUser   read fActiveUser      write fActiveUser;

    //  First load all the users, then load and look up the user ID.
    //  In this example we don't care about the save order.
    [SettingsLoadOrder(2)]
    property  ActiveUserID  : TGUID   read GetActiveUserID  write SetActiveUserID;

    //  Persistance of all the users.
    //  Do this before looking up the active user.
    [SettingsLoadOrder(1)]
    property  Users         : TUsers  read fUsers           write fUsers;

    //  Form positions
    property  UserForm      : TRect   read fUserForm        write fUserForm;

    [SettingsDeep]
    property  UserNames     : TStrings  read fUserNames;
  end;

//  Tidy up the RTTI flag
{$M-}

//  Keep the settings in a central unit, such as the unit where it's classes are defined, as in this example.
var
  Settings: TAppSettings  = nil;

implementation

uses
  System.SysUtils;

{ TUser }

constructor TUser.CreateNew(const AName: string);
begin
  CreateSeeded(TGUID.NewGUID, AName)
end;

constructor TUser.CreateSeeded(const AID: TGUID; const AName: string);
begin
  inherited Create;
  fID   := AID;
  fName := AName;
end;

{ TUsers }

procedure TUsers.DeleteUser(const UserID: TGUID);
var
  i: integer;
begin
  i := IndexOf(UserID);
  if  i >= 0  then
    Delete(i);
end;

function TUsers.FindByID(const UserID: TGUID): TUser;
var
  i: integer;
begin
  i := IndexOf(UserID);
  if  i >= 0  then
    Result  := Items[i]
  else
    Result  := nil;
end;

function TUsers.IndexOf(const UserID: TGUID): integer;
begin
  Result  := Count - 1;
  while (Result >= 0) and (UserID <> Items[Result].ID) do
    dec(Result);
end;

{ TAppSettings }

constructor TAppSettings.Create;
begin
  inherited;
  fUsers  := TUsers.Create;
  fUserNames  := TStringList.Create;
end;

destructor TAppSettings.Destroy;
begin
  fUserNames.Free;
  fUsers.Free;
  inherited;
end;

function TAppSettings.GetActiveUserID: TGUID;
begin
  if  Assigned(fActiveUser)  then
    Result  := fActiveUser.ID
  else
    Result  := TGUID.Empty;
end;

procedure TAppSettings.SetActiveUserID(const Value: TGUID);
begin
  fActiveUser := fUsers.FindByID(Value);
end;

initialization
  RegisteredLists.Register(TUsers, TUser);

end.
