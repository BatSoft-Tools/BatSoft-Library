unit FListControls;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FrComplexListItem;

type
  TfrmListControls = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    CheckBox1: TCheckBox;
    frameComplexListItem1: TframeComplexListItem;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmListControls: TfrmListControls;

implementation

{$R *.fmx}

procedure TfrmListControls.FormCreate(Sender: TObject);
begin
  Edit1.ApplyStyleLookup;
  frameComplexListItem1.Edit1.ApplyStyleLookup;
end;

end.
