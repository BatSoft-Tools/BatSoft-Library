unit uStatisticsTree;

interface

uses
  System.Generics.Collections, BatSoft.Observer.Managed;

type
  TOnChangeAmount = TEvent2Param<integer, integer>;

  TStatisticsTree = class
  private
    //  Changes to this object's state
    fOnChangeCount: TOnChangeAmount;
    fOnChangeTotal: TOnChangeAmount;
  protected
    function GetCount: integer; virtual; abstract;
    function GetTotal: integer; virtual; abstract;
    function GetAverage: double;
  public
    constructor Create;
    destructor  Destroy; override;
    //  Scores
    property  Count   : integer read GetCount;
    property  Total   : integer read GetTotal;
    property  Average : double  read GetAverage;
    //  Reactions
    property  OnChangeCount : TOnChangeAmount read fOnChangeCount;
    property  OnChangeTotal : TOnChangeAmount read fOnChangeTotal;
  end;

implementation

{ TStatisticsTree }

constructor TStatisticsTree.Create;
begin
  inherited;
  fOnChangeCount  := TOnChangeAmount.Create(Self);
  fOnChangeTotal  := TOnChangeAmount.Create(Self);
end;

destructor TStatisticsTree.Destroy;
begin
  fOnChangeCount.Free;
  fOnChangeTotal.Free;
  inherited;
end;

function TStatisticsTree.GetAverage: double;
begin
  Result  := Total / Count
end;

end.
