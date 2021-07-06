unit FDemoListSpinner;

interface

uses
  FMX.Forms, System.Classes, FMX.Types, FMX.Controls, FMX.Controls.Presentation,
  FMX.StdCtrls;

type
  TfrmDemoListSpinner = class(TForm)
    butShowExample1: TButton;
    butShowExample2: TButton;
    butShowExample3: TButton;
    procedure butShowExample1Click(Sender: TObject);
    procedure butShowExample2Click(Sender: TObject);
    procedure butShowExample3Click(Sender: TObject);
  private
  end;

var
  frmDemoListSpinner: TfrmDemoListSpinner;

implementation

{$R *.fmx}

uses
  FExample1, FExample2, FExample3;

{ TfrmDemoListSpinner }

procedure TfrmDemoListSpinner.butShowExample1Click(Sender: TObject);
begin
  frmExample1.Show;
end;

procedure TfrmDemoListSpinner.butShowExample2Click(Sender: TObject);
begin
  frmExample2.Show;
end;

procedure TfrmDemoListSpinner.butShowExample3Click(Sender: TObject);
begin
  frmExample3.Show;
end;

end.
