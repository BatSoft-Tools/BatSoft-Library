unit FDemoSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, uDemoSettings,
  FMX.Layouts, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.ListBox;

type
  TfrmDemoSettings = class(TForm)
    panUsers: TGroupBox;
    lstUsers: TListView;
    panControl: TGroupBox;
    butSaveINI: TButton;
    butSaveJSON: TButton;
    SaveDialog: TSaveDialog;
    butLoadINI: TButton;
    butLoadJSON: TButton;
    OpenDialog: TOpenDialog;
    butSeedData: TButton;
    panActiveUser: TGroupBox;
    cmbActiveUser: TComboBox;
    Splitter1: TSplitter;
    Layout1: TLayout;
    butClearData: TButton;
    butUserAdd: TButton;
    butUserEdit: TButton;
    butUserDelete: TButton;
    GridLayout1: TGridLayout;
    butUserSpecialAdd: TButton;
    procedure butSaveINIClick(Sender: TObject);
    procedure butSaveJSONClick(Sender: TObject);
    procedure butLoadINIClick(Sender: TObject);
    procedure butLoadJSONClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure butSeedDataClick(Sender: TObject);
    procedure butClearDataClick(Sender: TObject);
    procedure cmbActiveUserExit(Sender: TObject);
    procedure butUserAddClick(Sender: TObject);
    procedure butUserEditClick(Sender: TObject);
    procedure lstUsersChange(Sender: TObject);
    procedure butUserDeleteClick(Sender: TObject);
    procedure butUserSpecialAddClick(Sender: TObject);
  private
    procedure EditNew(const NewUser: TUser);
    procedure ClearSettings;
    procedure PopulateState;
    procedure PopulateUsers;
    function  SelectedUser: TUser;
  end;

var
  frmDemoSettings: TfrmDemoSettings;

implementation

{$R *.fmx}

uses
  BatSoft.Settings, BatSoft.Settings.Ini, BatSoft.Settings.JSON, FEditUser;

const
  SIni  = '.ini';
  SJson = '.json';

{ TfrmDemoSettings2 }

procedure TfrmDemoSettings.butClearDataClick(Sender: TObject);
begin
  ClearSettings;
  PopulateUsers;
end;

procedure TfrmDemoSettings.butLoadINIClick(Sender: TObject);
var
  Store: ISettingsStore<TAppSettings>;
begin
  OpenDialog.DefaultExt   := SIni;
  OpenDialog.FilterIndex  := 1;
  if  OpenDialog.Execute  then
    begin
      //  I normally allow cumulative loading of multiple settings sources.
      //  In this demo we'll clear the settings first.
      ClearSettings;
      //  This is the line that loads from an ini file
      Store := TSettingsStoreIni<TAppSettings>.Create(OpenDialog.FileName, True);
      Store.Load(Settings);
    end;
  PopulateUsers;
end;

procedure TfrmDemoSettings.butLoadJSONClick(Sender: TObject);
var
  Store: ISettingsStore<TAppSettings>;
begin
  OpenDialog.DefaultExt   := SJson;
  OpenDialog.FilterIndex  := 2;
  if  OpenDialog.Execute  then
    begin
      //  I normally allow cumulative loading of multiple settings sources.
      //  In this demo we'll clear the settings first.
      ClearSettings;
      //  This is the line that loads from a JSON file
      Store := TSettingsStoreJSON<TAppSettings>.Create(OpenDialog.FileName, True);
      Store.Load(Settings);
    end;
  PopulateUsers;
end;

procedure TfrmDemoSettings.butSaveINIClick(Sender: TObject);
var
  Store: ISettingsStore<TAppSettings>;
begin
  Settings.UserForm := Self.Bounds;
  //  Set up the save dialog
  SaveDialog.DefaultExt   := SIni;
  SaveDialog.FilterIndex  := 1;
  if  SaveDialog.Execute  then
      //  This is the line that saves to an ini file
    begin
      Store := TSettingsStoreIni<TAppSettings>.Create(SaveDialog.FileName, True);
      Store.Save(Settings);
    end;
end;

procedure TfrmDemoSettings.butSaveJSONClick(Sender: TObject);
var
  Store: ISettingsStore<TAppSettings>;
begin
  Settings.UserForm := Self.Bounds;
  //  Set up the save dialog
  SaveDialog.DefaultExt   := SJson;
  SaveDialog.FilterIndex  := 2;
  if  SaveDialog.Execute  then
    //  This is the line that saves to a JSON file
    begin
      Store := TSettingsStoreJSON<TAppSettings>.Create(SaveDialog.FileName, True);
      Store.Save(Settings);
    end;
end;

procedure TfrmDemoSettings.butSeedDataClick(Sender: TObject);
begin
  Settings.Users.Add(TUser.CreateNew('John Stag'));
  Settings.Users.Add(TUser.CreateNew('Jane Doe'));
  Settings.Users.Add(TUser.CreateNew('Sonny Skye'));
  Settings.Users.Add(TUserSpecial.CreateNew('Dawn Breaker'));
  Settings.Users.Add(TUser.CreateNew('May-June Summers'));
  Settings.UserNames.Add('John Stag');
  Settings.UserNames.Add('Jane Doe');
  Settings.UserNames.Add('Sonny Skye');
  Settings.UserForm := Self.Bounds;
  PopulateUsers;
end;

procedure TfrmDemoSettings.butUserAddClick(Sender: TObject);
begin
  EditNew(TUser.CreateNew(''))
end;

procedure TfrmDemoSettings.butUserSpecialAddClick(Sender: TObject);
begin
  EditNew(TUserSpecial.CreateNew(''))
end;

procedure TfrmDemoSettings.EditNew(const NewUser: TUser);
begin
  if  TfrmEditUser.Edit(NewUser)  then
    Settings.Users.Add(NewUser)
  else
    NewUser.Free;
  PopulateUsers;
end;

procedure TfrmDemoSettings.butUserEditClick(Sender: TObject);
begin
  if  lstUsers.ItemIndex >= 0 then
    if  TfrmEditUser.Edit(SelectedUser) then
      PopulateUsers;
end;

procedure TfrmDemoSettings.butUserDeleteClick(Sender: TObject);
begin
  if  SelectedUser <> nil then
    begin
      Settings.Users.DeleteUser(SelectedUser.ID);
      PopulateUsers;
    end;
end;

procedure TfrmDemoSettings.ClearSettings;
begin
  Settings.Free;
  Settings  := TAppSettings.Create;
end;

procedure TfrmDemoSettings.cmbActiveUserExit(Sender: TObject);
begin
  if  cmbActiveUser.ItemIndex < 0 then
    Settings.ActiveUser := nil
  else
    Settings.ActiveUser := cmbActiveUser.Items.Objects[cmbActiveUser.ItemIndex] as TUser;
end;

procedure TfrmDemoSettings.FormCreate(Sender: TObject);
begin
  Settings  := TAppSettings.Create;
  PopulateState;
end;

procedure TfrmDemoSettings.FormDestroy(Sender: TObject);
begin
  Settings.Free;
end;

procedure TfrmDemoSettings.lstUsersChange(Sender: TObject);
begin
  PopulateState;
end;

procedure TfrmDemoSettings.PopulateState;
begin
  butUserEdit.Enabled   := SelectedUser <> nil;
  butUserDelete.Enabled := SelectedUser <> nil;
end;

procedure TfrmDemoSettings.PopulateUsers;
var
  User: TUser;
  Item: TListViewItem;
begin
  //  Users
  lstUsers.BeginUpdate;
  try
    lstUsers.Items.Clear;
    for User in Settings.Users  do
      begin
        Item  := lstUsers.Items.Add;
        Item.TagObject  := User;
        Item.Text       := User.Name;
      end;
  finally
    lstUsers.EndUpdate;
  end;
  //  Active user
  cmbActiveUser.Items.BeginUpdate;
  try
    cmbActiveUser.Items.Clear;
    for User in Settings.Users  do
      cmbActiveUser.Items.AddObject(User.Name, User);
    cmbActiveUser.ItemIndex := cmbActiveUser.Items.IndexOfObject(Settings.ActiveUser);
  finally
    cmbActiveUser.Items.EndUpdate;
  end;
  //  Form position
  if not Settings.UserForm.IsEmpty then
    Self.Bounds := Settings.UserForm;
  //  Update UI state
  PopulateState;
end;

function TfrmDemoSettings.SelectedUser: TUser;
begin
  if  lstUsers.ItemIndex < 0  then
    Result  := nil
  else
    Result  := lstUsers.Items[lstUsers.ItemIndex].TagObject as TUser
end;

end.
