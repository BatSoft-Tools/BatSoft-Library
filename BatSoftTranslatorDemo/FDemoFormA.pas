unit FDemoFormA;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FrDemoFrame,
  FMX.StdCtrls, FMX.Controls.Presentation;

type
  TfrmDemoA = class(TForm)
    frameDemo1: TframeDemo;
    frameDemo2: TframeDemo;
    Label1: TLabel;
    Button1: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDemoA: TfrmDemoA;

implementation

{$R *.fmx}

end.
