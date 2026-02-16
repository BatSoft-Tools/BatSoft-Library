unit uStatisticsBranch;

interface

uses
  System.Generics.Collections, BatSoft.Observer.Managed, uStatisticsTree;

type
  TStatisticsBranch = class(TStatisticsTree)
  private
    fCount: integer;
    fTotal: integer;
  protected
    function GetCount: Integer; override;
    function GetTotal: Integer; override;
  private
    //  Subscriptions and callbacks
    fCountSubscriptions: TList<ISubscription>;
    fTotalSubscriptions: TList<ISubscription>;
    procedure ChangedCount(Sender: TObject; OldValue, NewValue: integer);
    procedure ChangedTotal(Sender: TObject; OldValue, NewValue: integer);
    procedure LostSubItem(const EventHandler: TManagedEventHandler);
  public
    //  Actions
    procedure Add(SubTree: TStatisticsTree);
  end;

implementation

{ TStatisticsBranch }

procedure TStatisticsBranch.Add(SubTree: TStatisticsTree);
begin
  fCount        := fCount + SubTree.Count;
  fTotal        := fTotal + SubTree.Total;
  fCountSubscriptions.Add(SubTree.OnChangeCount.Subscribe(ChangedCount));
  fTotalSubscriptions.Add(SubTree.OnChangeTotal.Subscribe(ChangedTotal));
end;

procedure TStatisticsBranch.ChangedCount(Sender: TObject; OldValue, NewValue: integer);
var
  OldCount: integer;
begin
  OldCount  := fCount;
  fCount    := fCount - OldValue + NewValue;
  OnChangeCount.Call(OldCount, fCount);
end;

procedure TStatisticsBranch.ChangedTotal(Sender: TObject; OldValue, NewValue: integer);
var
  OldTotal: integer;
begin
  OldTotal  := fTotal;
  fTotal    := fTotal - OldValue + NewValue;
  OnChangeTotal.Call(OldTotal, fTotal);
end;

function TStatisticsBranch.GetCount: Integer;
begin
  Result  := fCount
end;

function TStatisticsBranch.GetTotal: Integer;
begin
  Result  := fTotal
end;

procedure TStatisticsBranch.LostSubItem(const EventHandler: TManagedEventHandler);
var
  LostSubItem: TStatisticsTree;
begin
  LostSubItem := EventHandler.Subject as TStatisticsTree;
  fCount  := fCount - LostSubItem.Count;
  fTotal  := fTotal - LostSubItem.Total;
//  OnChangeCount.Call()
end;

end.
