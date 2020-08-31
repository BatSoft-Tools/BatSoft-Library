unit FDemoSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, uDemoSettings;

type
  TfrmDemoSettings = class(TForm)
    butSave: TButton;
    butLoad: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    chkClearValues: TCheckBox;
    butInit1: TButton;
    Button1: TButton;
    butInit0: TButton;
    Button2: TButton;
    procedure butSaveClick(Sender: TObject);
    procedure butLoadClick(Sender: TObject);
    procedure butInit0Click(Sender: TObject);
    procedure butInit1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    fDemo: TDemoSettings;
    function  CreateUser(const i: integer): TUserSettings;
  end;

var
  frmDemoSettings: TfrmDemoSettings;

implementation

{$R *.fmx}

uses
  Generics.Collections, RTTI,
  BatSoft.Settings, BatSoft.Settings.Ini, BatSoft.Settings.JSON;

{ TfrmDemoSettings }

procedure TfrmDemoSettings.butInit0Click(Sender: TObject);
begin
  FreeAndNil(fDemo);
  fDemo := TDemoSettings.Create;
end;

procedure TfrmDemoSettings.butInit1Click(Sender: TObject);
begin
  FreeAndNil(fDemo);
  fDemo := TDemoSettings.Create;
  fDemo.SettingA  := 'ABC';
  fDemo.SettingB  := 123;

  fDemo.Users := TUsers.Create();
  fDemo.Users.Add(CreateUser(1));
  fDemo.Users.Add(CreateUser(2));

  fDemo.UserNameAll.Add('abc');
  fDemo.UserNameAll.Add('def');
  fDemo.UserNameAll.AddObject('hij', CreateUser(3));
  fDemo.UserNameCurr  := fDemo.UserNameAll[0];
end;

procedure TfrmDemoSettings.butLoadClick(Sender: TObject);
begin
  if  OpenDialog.Execute  then
    begin
      SettingsJSON.LoadFile(fDemo, OpenDialog.FileName, chkClearValues.IsChecked);

    end;
end;

procedure TfrmDemoSettings.butSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    begin
      SettingsJSON.SaveFile(fDemo, SaveDialog.FileName);

    end;
end;

procedure TfrmDemoSettings.Button1Click(Sender: TObject);
var
  C: TClass;
begin
  C := fDemo.Users.ClassType;
  while Assigned(C) do
    begin
      ShowMessage(C.QualifiedClassName);
      C := C.ClassParent;
    end;
end;

procedure TfrmDemoSettings.Button2Click(Sender: TObject);
var
  User: TUserSettings;
begin
  for User in fDemo.Users do
    ShowMessage(User.UserName);
end;

function TfrmDemoSettings.CreateUser(const i: integer): TUserSettings;
begin
  Result  := TUserSettings.Create;
  Result.UserName := 'User '+IntToStr(i);
  Result.Access   := TAccess(i mod 3);
end;

end.
