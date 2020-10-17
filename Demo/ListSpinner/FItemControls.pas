unit FItemControls;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls, FrEmpContract,
  FrEmpPartTime, FrEmpFullTime;

type
  TfrmItemControls = class(TForm)
    edDisplayOnly: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    edEditable: TEdit;
    Label1: TLabel;
    labDisplayOnly: TLabel;
    frameEmpContractShow: TframeEmpContract;
    frameEmpFullTimeShow: TframeEmpFullTime;
    frameEmpPartTimeShow: TframeEmpPartTime;
    frameEmpContractEdit: TframeEmpContract;
    frameEmpFullTimeEdit: TframeEmpFullTime;
    frameEmpPartTimeEdit: TframeEmpPartTime;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
  end;

var
  frmItemControls: TfrmItemControls;

implementation

{$R *.fmx}

uses
  Bat.Spinners;

{ TfrmItemControls }

procedure TfrmItemControls.FormCreate(Sender: TObject);
begin
  //  NOTE: Due to a "quirk" in the Delphi libraries, ApplyStyleLookup() *must*
  //  be called at least once before the read-only controls will show.
  //
  //  Some controls, such as TLabel, will do this when you set the Text property,
  //  but edit controls do not (TEdit, TDateEdit).  So for these we
  //  explicity call ApplyStyleLookup().

  ApplyStyleLookupToAll(Self)
end;

end.
