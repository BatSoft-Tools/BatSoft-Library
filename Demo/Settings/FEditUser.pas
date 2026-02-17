unit FEditUser;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Controls.Presentation, uDemoSettings,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  TfrmEditUser = class(TForm)
    panUser: TGroupBox;
    edUserName: TEdit;
    edUserID: TLabel;
    Layout1: TLayout;
    butOK: TButton;
    butCancel: TButton;
    panExtraInfo: TGroupBox;
    memExtraInfo: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure memExtraInfoChange(Sender: TObject);
  private
    fUser: TUser;
    procedure SetUser(const Value: TUser);
  public
    class function  Edit(const AUser: TUser): Boolean;
    property  User  : TUser read fUser  write SetUser;
  end;

implementation

{$R *.fmx}

{ TfrmEditUser }

class function TfrmEditUser.Edit(const AUser: TUser): Boolean;
var
  frmEditUser: TfrmEditUser;
begin
  frmEditUser := TfrmEditUser.Create(Application);
  try
    //  Fetch form position
    if  Settings.UserForm.Height > 0  then
      frmEditUser.SetBounds(Settings.UserForm);
    //  Usual form code
    frmEditUser.User  := AUser;
    Result  := frmEditUser.ShowModal = mrOk;
    //  Save form position
    Settings.UserForm := frmEditUser.GetBounds;
  finally
    frmEditUser.ReleaseForm;
  end;
end;

procedure TfrmEditUser.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if  ModalResult = mrOk  then
    fUser.Name  := edUserName.Text;
end;

procedure TfrmEditUser.memExtraInfoChange(Sender: TObject);
begin
  (fUser as TUserSpecial).ExtraInfo := memExtraInfo.Text;
end;

procedure TfrmEditUser.SetUser(const Value: TUser);
begin
  fUser           := Value;
  edUserID.Text   := fUser.ID.ToString;
  edUserName.Text := fUser.Name;
  panExtraInfo.Visible  := Value is TUserSpecial;
  if Value is TUserSpecial then
    memExtraInfo.Text := (Value as TUserSpecial).ExtraInfo;
end;

end.
