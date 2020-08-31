unit FDemoFormB;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Menus,
  FMX.StdCtrls, FMX.Controls.Presentation;

type
  TfrmDemoB = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    GroupBox1: TGroupBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    MainMenu1: TMainMenu;
    miFile: TMenuItem;
    miEdit: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    miLoad: TMenuItem;
    miSave: TMenuItem;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDemoB: TfrmDemoB;

implementation

{$R *.fmx}

end.
