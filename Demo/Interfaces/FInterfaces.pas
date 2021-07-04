unit FInterfaces;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TfrmInterfaces = class(TForm)
    butDoAlpha: TButton;
    butDoBeta: TButton;
    butDoGamma: TButton;
    butTryObtain: TButton;
    procedure butDoAlphaClick(Sender: TObject);
    procedure butDoBetaClick(Sender: TObject);
    procedure butDoGammaClick(Sender: TObject);
    procedure butTryObtainClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmInterfaces: TfrmInterfaces;

implementation

{$R *.fmx}

uses
  uModule;

type
  IGamma = interface
    ['{EE39CB37-3D8F-4D57-BCEF-C0F037B6D9EC}']
    procedure DoXYZ;
  end;

{ TfrmInterfaces }

procedure TfrmInterfaces.butDoAlphaClick(Sender: TObject);
begin
  //  We should have no access the IAlpha implementation,
  //  but we can still obtain it (provided it has been registered).
  Modules.Obtain<IAlpha>().DoSomething('From main form');
end;

procedure TfrmInterfaces.butDoBetaClick(Sender: TObject);
begin
  //  We should have no access the IBeta implementation,
  //  but we can still obtain it (provided it has been registered).
  Modules.Obtain<IBeta>().SomeBetaFunctionality();
end;

procedure TfrmInterfaces.butDoGammaClick(Sender: TObject);
begin
  //  We should have no access the IGamma implementation,
  //  but we can still obtain it (provided it has been registered).
  Modules.Obtain<IGamma>().DoXYZ;
end;

procedure TfrmInterfaces.butTryObtainClick(Sender: TObject);
var
  Alpha: IAlpha;
  Gamma: IGamma;
begin
  if  Modules.TryObtain<IAlpha>(Alpha)  then
    ShowMessage('IAlpha obtained')
  else
    ShowMessage('IAlpha not obtained');

  if  Modules.TryObtain<IGamma>(Gamma)  then
    ShowMessage('IGamma obtained')
  else
    ShowMessage('IGamma not obtained');
end;

end.
