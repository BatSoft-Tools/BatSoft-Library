unit uStatisticsLeaf_Text;

interface

uses
  uStatisticsTree;

type
  TStatisticsLeaf_Text = class(TStatisticsTree)
  private
    fText: string;
    procedure SetText(const Value: string);
  protected
    function GetCount: Integer; override;
    function GetTotal: Integer; override;
  public
    property  Text  : string  read fText  write SetText;
  end;

implementation

{ TStatisticsLeaf_Text }

function TStatisticsLeaf_Text.GetCount: Integer;
begin
  Result  := 1;
end;

function TStatisticsLeaf_Text.GetTotal: Integer;
begin
  Result  := Length(fText)
end;

procedure TStatisticsLeaf_Text.SetText(const Value: string);
var
  OldTotal: integer;
begin
  OldTotal  := Total;
  fText     := Value;
//  OnChangeTotal.Call(OldTotal, Total);
end;

end.
