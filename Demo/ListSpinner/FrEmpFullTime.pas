unit FrEmpFullTime;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uEmployment, System.Math.Vectors, FMX.Objects, FMX.Edit, FMX.EditBox,
  FMX.SpinBox, FMX.DateTimeCtrls, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Controls3D, FMX.Layers3D;

type
  TframeEmpFullTime = class(TFrame)
    Layout3D1: TLayout3D;
    edStartDate: TDateEdit;
    edSalary: TSpinBox;
    Line1: TLine;
    Line2: TLine;
    Layout1: TLayout;
    Layout2: TLayout;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Circle1: TCircle;
    labIndex: TLabel;
    procedure edStartDateChange(Sender: TObject);
    procedure edSalaryChange(Sender: TObject);
  private
    fFullTime: TFullTime;
    procedure SetFullTime(const Value: TFullTime);
  public
    property  FullTime  : TFullTime read fFullTime write SetFullTime;
  end;

implementation

{$R *.fmx}

{ TframeEmpFullTime }

procedure TframeEmpFullTime.edSalaryChange(Sender: TObject);
begin
  FullTime.Salary     := edSalary.Value
end;

procedure TframeEmpFullTime.edStartDateChange(Sender: TObject);
begin
  FullTime.StartDate  := edStartDate.Date
end;

procedure TframeEmpFullTime.SetFullTime(const Value: TFullTime);
begin
  fFullTime := Value;
  edStartDate.Date  := fFullTime.StartDate;
  edSalary.Value    := fFullTime.Salary;
end;

end.
