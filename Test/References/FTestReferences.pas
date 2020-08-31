unit FTestReferences;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, BatSoft.References,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  RHObject = ReferenceOnOnHeap<TObject>;
  RRObject = ReferenceOnStackOrGlobal<TObject>;

  TThing = class
  public
    Value: integer;
    constructor Create;
    destructor  Destroy; override;
  end;
  RHThing = ReferenceOnOnHeap<TThing>;
  RRThing = ReferenceOnStackOrGlobal<TThing>;

  TfrmTestReferences = class(TForm)
    frmCreateThing: TButton;
    frmReleaseThing: TButton;
    procedure frmCreateThingClick(Sender: TObject);
  private
    fThing: RHThing;
  end;

var
  frmTestReferences: TfrmTestReferences;

implementation

{$R *.fmx}

{ TThing }

constructor TThing.Create;
begin
  inherited;
  Value := 100;
end;

destructor TThing.Destroy;
begin
  Value := 0;
  inherited;
end;

{ TfrmTestReferences }

procedure TfrmTestReferences.frmCreateThingClick(Sender: TObject);
begin
  fThing  := RHThing.New(TThing.Create);
  fThing.Obj.Value  := 30;
end;

end.
