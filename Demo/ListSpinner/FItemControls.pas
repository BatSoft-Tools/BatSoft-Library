unit FItemControls;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls, FrEmpContract,
  FrEmpPartTime, FrEmpFullTime;

type
  TfrmItemControls = class(TForm)
    frameEmpContractShow: TframeEmpContract;
    frameEmpFullTimeShow: TframeEmpFullTime;
    frameEmpPartTimeShow: TframeEmpPartTime;
    frameEmpContractEdit: TframeEmpContract;
    frameEmpFullTimeEdit: TframeEmpFullTime;
    frameEmpPartTimeEdit: TframeEmpPartTime;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
  end;

var
  frmItemControls: TfrmItemControls;

implementation

{$R *.fmx}

uses
  BatSoft.Spinners;

end.
