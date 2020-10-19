unit FrEmpContract;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  System.Math.Vectors, FMX.Controls.Presentation, FMX.Edit, FMX.DateTimeCtrls,
  FMX.Layouts, FMX.Controls3D, FMX.Layers3D, uEmployment, FMX.EditBox,
  FMX.SpinBox, FMX.Objects;

type
  TframeEmpContract = class(TFrame)
    Line1: TLine;
    Line2: TLine;
    Layout1: TLayout;
    edStartDate: TDateEdit;
    Label1: TLabel;
    Layout2: TLayout;
    edHourlyRate: TSpinBox;
    Label2: TLabel;
    Layout3: TLayout;
    edDeadline: TDateEdit;
    Label3: TLabel;
    Label4: TLabel;
    Circle1: TCircle;
    procedure edStartDateChange(Sender: TObject);
    procedure edDeadlineChange(Sender: TObject);
    procedure edHourlyRateChange(Sender: TObject);
  private
    fContract: TContract;
    procedure SetContract(const Value: TContract);
  public
    property  Contract  : TContract read FContract write SetContract;
  end;

implementation

{$R *.fmx}

{ TframeEmpContract }

procedure TframeEmpContract.edDeadlineChange(Sender: TObject);
begin
  Contract.Deadline   := edDeadline.Date
end;

procedure TframeEmpContract.edHourlyRateChange(Sender: TObject);
begin
  Contract.HourlyRate := edHourlyRate.Value
end;

procedure TframeEmpContract.edStartDateChange(Sender: TObject);
begin
  Contract.StartDate  := edStartDate.Date
end;

procedure TframeEmpContract.SetContract(const Value: TContract);
begin
  fContract := Value;
  edStartDate.Date    := fContract.StartDate;
  edDeadline.Date     := fContract.Deadline;
  edHourlyRate.Value  := fContract.HourlyRate;
end;

end.
