unit FrEmpPartTime;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uEmployment, FMX.Controls.Presentation, FMX.Edit, FMX.EditBox, FMX.SpinBox,
  FMX.Layouts, FMX.Objects;

type
  TframeEmpPartTime = class(TFrame)
    Layout2: TLayout;
    edHourlyRate: TSpinBox;
    Label2: TLabel;
    Layout1: TLayout;
    edHoursPerWeek: TSpinBox;
    Label1: TLabel;
    Line2: TLine;
    Line1: TLine;
    Label4: TLabel;
    Circle1: TCircle;
    labIndex: TLabel;
    procedure edHourlyRateChange(Sender: TObject);
    procedure edHoursPerWeekChange(Sender: TObject);
  private
    fPartTime: TPartTime;
    procedure SetPartTime(const Value: TPartTime);
  public
    property  PartTime  : TPartTime read fPartTime write SetPartTime;
  end;

implementation

{$R *.fmx}

{ TframeEmpPartTime }

procedure TframeEmpPartTime.edHourlyRateChange(Sender: TObject);
begin
  PartTime.HourlyRate   := edHourlyRate.Value
end;

procedure TframeEmpPartTime.edHoursPerWeekChange(Sender: TObject);
begin
  PartTime.HoursPerWeek := Trunc(edHoursPerWeek.Value)
end;

procedure TframeEmpPartTime.SetPartTime(const Value: TPartTime);
begin
  fPartTime := Value;
  edHourlyRate.Value    := fPartTime.HourlyRate;
  edHoursPerWeek.Value  := fPartTime.HoursPerWeek;
end;

end.
