unit FEditUser;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Controls.Presentation, uDemoSettings;

type
  TfrmEditUser = class(TForm)
    panUser: TGroupBox;
    edUserName: TEdit;
    edUserID: TLabel;
    Layout1: TLayout;
    butOK: TButton;
    butCancel: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fUser: TUser;
    procedure SetUser(const Value: TUser);
  public
    function  New(out AUser: TUser): Boolean;
    function  Edit(const AUser: TUser): Boolean;
    property  User  : TUser read fUser  write SetUser;
  end;

var
  frmEditUser: TfrmEditUser;

implementation

{$R *.fmx}

{ TfrmEditUser }

function TfrmEditUser.Edit(const AUser: TUser): Boolean;
begin
  User    := AUser;
  Result  := ShowModal = mrOk
end;

procedure TfrmEditUser.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if  ModalResult = mrOk  then
    begin
      fUser.Name  := edUserName.Text;
    end;
end;

function TfrmEditUser.New(out AUser: TUser): Boolean;
begin
  AUser   := TUser.CreateNew;
  Result  := Edit(AUser);
  if  not Result  then
    FreeAndNil(AUser);
end;

procedure TfrmEditUser.SetUser(const Value: TUser);
begin
  fUser           := Value;
  edUserID.Text   := fUser.ID.ToString;
  edUserName.Text := fUser.Name;
end;

end.
