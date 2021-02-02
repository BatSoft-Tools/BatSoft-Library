unit FPerson;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  BatSoft.Spinners, FMX.Controls.Presentation, FMX.StdCtrls, FrPerson,
  FMX.Layouts;

type
  TfrmPerson = class(TForm)
    Layout1: TLayout;
    Splitter1: TSplitter;
    Layout2: TLayout;
    framePerson1: TframePerson;
    Layout3: TLayout;
    Panel1: TPanel;
    lstPeople: TListSpinner;
  end;

var
  frmPerson: TfrmPerson;

implementation

{$R *.fmx}

uses
  FPersonListItems;

{ TForm2 }

end.
