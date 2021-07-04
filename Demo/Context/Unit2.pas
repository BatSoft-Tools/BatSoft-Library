unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm2 = class(TForm)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  end;

  TTestLabel = class(TLabel)
  protected
    procedure Paint; override;
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

uses
  BatSoft.Classes;

type
  IMyIntf = interface
    ['{864DE902-0A11-4ED7-9879-F84D9B4F69A5}']
  end;

  TMyImpl = class(TInterfacedObject, IMyIntf)

  end;

var
  IntfReg: TInterfaceRegistry;

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
begin
  ChangeClass(Label1, TTestLabel);
end;

{ TTestLabel }

procedure TTestLabel.Paint;
var
  Intf: IMyIntf;
begin
  inherited;
  //  Test code here

  IntfReg.Register(IMyIntf, TMyImpl.Create);

  if intf then


end;

end.
