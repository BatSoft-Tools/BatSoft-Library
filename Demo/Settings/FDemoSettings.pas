unit FDemoSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, BatSoft.Settings, uDemoSettings;

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
    butIniCreate: TButton;
    butIniLoad: TButton;
    butSaveIni: TButton;
    butJsonLoad: TButton;
    butSaveJSON: TButton;
    butInit2: TButton;
    Button3: TButton;
    procedure butInit0Click(Sender: TObject);
    procedure butInit1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure butSaveJSONClick(Sender: TObject);
    procedure butSaveIniClick(Sender: TObject);
    procedure butInit2Click(Sender: TObject);
    procedure butIniLoadClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure butJsonLoadClick(Sender: TObject);
  private
    function  CreateUser(const i: integer): TUserSettings;
  end;

var
  frmDemoSettings: TfrmDemoSettings;
  fDemo: TDemoSettings = nil;

implementation

{$R *.fmx}

uses
  Generics.Collections, RTTI,
  BatSoft.Settings.Ini, BatSoft.Settings.Json;

{ TfrmDemoSettings }

procedure TfrmDemoSettings.butIniLoadClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    TSettingsReaderIni.Load<TDemoSettings>(fDemo, OpenDialog.FileName)
end;

procedure TfrmDemoSettings.butInit0Click(Sender: TObject);
begin
  FreeAndNil(fDemo);
  fDemo := TDemoSettings.Create;
end;

procedure TfrmDemoSettings.butInit1Click(Sender: TObject);
begin
  FreeAndNil(fDemo);
  fDemo := TDemoSettings.Create;
  fDemo.Prop_Str    := 'ABC';
  fDemo.Prop_Int    := 123;
  fDemo.Prop_Int64  := 456;
  fDemo.Prop_Dbl    := Now;
  fDemo.Prop_Ext    := Now;
  fDemo.Prop_Curr   := 1234.5678;

  fDemo.Users := TUsers.Create();
  fDemo.Users.Add(CreateUser(1));
  fDemo.Users.Add(nil);
  fDemo.Users.Add(nil);

  fDemo.UserNameAll.AddObject('abc', nil);
  fDemo.UserNameAll.AddObject('def', nil);
  fDemo.UserNameAll.AddObject('hij', CreateUser(3));
  fDemo.UserNameCurr  := fDemo.UserNameAll[0];
end;

procedure TfrmDemoSettings.butInit2Click(Sender: TObject);
begin
  fDemo.Users[1]  := CreateUser(2);
  fDemo.UserNameAll.Objects[0]  := CreateUser(1);
end;

procedure TfrmDemoSettings.butJsonLoadClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    TSettingsReaderJSON.Load<TDemoSettings>(fDemo, OpenDialog.FileName)
end;

procedure TfrmDemoSettings.butSaveIniClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    TSettingsWriterIni.Save(fDemo, SaveDialog.FileName)
end;

procedure TfrmDemoSettings.butSaveJSONClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    TSettingsWriterJSON.Save(fDemo, SaveDialog.FileName)
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

procedure TfrmDemoSettings.Button3Click(Sender: TObject);
var
  Obj: TUserSettings;
  RTTI: TRttiContext;
  RTTIType: TRttiType;
  RTTIProps: TArray<TRttiProperty>;
  RTTIProp: TRttiProperty;
  Value: TValue;
begin
  Obj := fDemo.Users[1];

  RTTI  := TRttiContext.Create;
  try
    RTTIType  := RTTI.GetType(Obj.ClassType);
    RTTIProps := RTTIType.GetProperties;
    for RTTIProp in RTTIProps do
      if RTTIProp.Name = 'Accesses' then
        begin
          Value := RTTIProp.GetValue(Obj);
          RTTIProp.SetValue(Obj, Value);
        end;
  finally
    RTTI.Free;
  end;
end;

function TfrmDemoSettings.CreateUser(const i: integer): TUserSettings;
begin
  Result  := TUserSettings.Create;
  Result.UserName := 'User '+IntToStr(i);
  Result.Access   := TAccess(i mod 3);
  Result.Accesses := [TAccess(i mod 3), TAccess((i+1) mod 3)];
end;

end.
