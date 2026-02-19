unit BatSoft.Editors.Enum;

interface

uses
  System.TypInfo, System.Rtti, System.Classes, FMX.Controls, FMX.ListBox, BatSoft.Editors;

type
{$M+}
  TEnumEditor = class(TCustomComboBox, ITypeInfoEditor)
  private
    fTypeInfo: PTypeInfo;
    procedure SetTypeInfo(const Value: PTypeInfo);
    function  GetValue: TValue;
    procedure SetValue(const Value: TValue);
    procedure Populate;
  public
    property  TypeInfo  : PTypeInfo read fTypeInfo  write SetTypeInfo;
    property  Value     : TValue    read GetValue   write SetValue;
    function  OrdAt(const Index: integer): Int64;
  published
    property  OnChange;
  end;
{$M-}

implementation

uses
  BatSoft.Common;

{ TEnumEditor }

function TEnumEditor.GetValue: TValue;
begin
  Result  := OrdToEnum(OrdAt(ItemIndex), fTypeInfo);
end;

function TEnumEditor.OrdAt(const Index: integer): Int64;
begin
  Result  := Int64(Items.Objects[Index])
end;

procedure TEnumEditor.Populate;
var
  TypeData: PTypeData;
  ord: integer;
begin
  TypeData := GetTypeData(fTypeInfo);
  Items.Clear;
  for ord := TypeData.MinValue to TypeData.MaxValue do
    Items.AddObject(GetEnumName(fTypeInfo, ord), Pointer(ord));
end;

procedure TEnumEditor.SetTypeInfo(const Value: PTypeInfo);
begin
  fTypeInfo := Value;
  Populate;
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

end.
