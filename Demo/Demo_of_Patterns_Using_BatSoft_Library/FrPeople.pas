unit FrPeople;

interface

uses
  System.Classes, FMX.Types, FMX.Controls, FMX.Forms,
  BatSoft.Spinners, uPerson, uPersonStore;

type
  TframePeople = class(TFrame)
    lstPeople: TListSpinner;
    function lstPeopleGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
  private
    fPeople: TPeople;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  end;

implementation

{$R *.fmx}

uses
  FPersonListItems;

{ TframePeople }

constructor TframePeople.Create(AOwner: TComponent);
begin
  inherited;
  fPeople := TPeople.Create;
end;

destructor TframePeople.Destroy;
begin
  fPeople.Free;
  inherited;
end;

function TframePeople.lstPeopleGetShowItem(Sender: TListSpinner; Index: Integer): TControl;
begin
  frmPersonListItems.labPersonLine.Text := fPeople[Index].FullName;
  Result  := frmPersonListItems.labPersonLine;
end;

end.
