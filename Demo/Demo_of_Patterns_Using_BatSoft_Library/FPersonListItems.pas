unit FPersonListItems;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation;

type
  TfrmPersonListItems = class(TForm)
    labPersonLine: TLabel;
    loPersonEdit: TLayout;
    Label1: TLabel;
    Button1: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPersonListItems: TfrmPersonListItems;

implementation

{$R *.fmx}

end.
