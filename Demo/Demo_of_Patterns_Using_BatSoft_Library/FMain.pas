unit FMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts, BatSoft.Editors, uPerson;

type
  TfrmMain = class(TForm)
    Editors1: TEditors;
  private
    fThing: TPersonID;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

{ TfrmMain }

end.
