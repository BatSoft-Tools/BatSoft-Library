unit BatSoft.Editors.Enum;

interface

uses
  System.TypInfo, System.Rtti, System.Classes, FMX.Controls, FMX.ListBox, BatSoft.Editors;

const
  DropDownRowCount = 20;

type
{$M+}
  TEnumEditor = class(TCustomComboBox, ITypeInfoEditor)
  private
    fTypeInfo: PTypeInfo;
    procedure SetTypeInfo(const Value: PTypeInfo);
    function  GetValue: TValue;
    procedure SetValue(const Value: TValue);
  public
    constructor Create(AOwner: TComponent);
    property  TypeInfo  : PTypeInfo read fTypeInfo  write SetTypeInfo;
    property  Value     : TValue    read GetValue   write SetValue;
    function  OrdAt(const Index: integer): Int64;
  published
    property  OnChange;
  end;

  TEnumSetEditor = class(TCustomComboBox, ITypeInfoEditor)
  private
    fTypeInfo: PTypeInfo;
    fPopup: TListBox;
    procedure SetTypeInfo(const Value: PTypeInfo);
    function  GetValue: TValue;
    procedure SetValue(const Value: TValue);
  public
    constructor Create(AOwner: TComponent);
    property  TypeInfo  : PTypeInfo read fTypeInfo  write SetTypeInfo;
    property  Value     : TValue    read GetValue   write SetValue;
  published
    property  OnChange;
  end;
{$M-}

implementation

uses
  BatSoft.Common;

{ TEnumEditor }

constructor TEnumEditor.Create(AOwner: TComponent);
begin
  inherited;
  DropDownCount := DropDownRowCount;
end;

function TEnumEditor.GetValue: TValue;
begin
  Result  := OrdToEnum(OrdAt(ItemIndex), fTypeInfo);
end;

function TEnumEditor.OrdAt(const Index: integer): Int64;
begin
  Result  := Int64(Items.Objects[Index])
end;

procedure TEnumEditor.SetTypeInfo(const Value: PTypeInfo);
begin
  fTypeInfo := Value;
  ListEnumValues(Items, fTypeInfo);
end;

procedure TEnumEditor.SetValue(const Value: TValue);
var
  Index: integer;
begin
  Index := Items.Count - 1;
  while Index >= 0  do
    if  Value.AsOrdinal = OrdAt(Index)  then
      break
    else
      dec(Index);
  ItemIndex := Index;
end;

{ TEnumSetEditor }

constructor TEnumSetEditor.Create(AOwner: TComponent);
begin
  inherited;
  DropDownCount := DropDownRowCount;
end;

function TEnumSetEditor.GetValue: TValue;
begin
  Result  := 0
end;

procedure TEnumSetEditor.SetTypeInfo(const Value: PTypeInfo);
begin
  fTypeInfo := Value;
  ListEnumSetValues(Items, fTypeInfo);
end;

procedure TEnumSetEditor.SetValue(const Value: TValue);
begin

end;

end.
