unit BatSoft.Editors.Enum;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.TypInfo, System.Rtti, System.Types, System.Classes,
  FMX.Controls, FMX.StdCtrls, FMX.ListBox, BatSoft.Editors;

const
  DropDownRowCount = 20;

type
{$M+}
  TEnumEditor = class(TCustomComboBox)
  private
    fTypeInfo: PTypeInfo;
    function  GetValue: TValue;
    procedure SetValue(const Value: TValue);
    function  GetOrdinal: Int64;
    procedure SetOrdinal(const Ord: Int64);
  protected
    procedure PopulateItems(const TypeInfo: PTypeInfo);
  public
    procedure DropDown; override;
    property  TypeInfo  : PTypeInfo read fTypeInfo;
    property  Value     : TValue    read GetValue   write SetValue;
    property  Ordinal   : Int64     read GetOrdinal write SetOrdinal;
    function  OrdAt(const Index: integer): Int64;
  published
    property  OnChange;
  end;

  TEnumSetEditor = class(TButton)
  public const
    DefaultExtraSize: TPoint  = (X: 16; Y: 6);
  private
    fTypeInfo: PTypeInfo;
    fPopup: TPopup;
    fListBox: TListBox;
    fExtraSize: TPoint;
    fOnChange: TNotifyEvent;
    function  GetValue: TValue;
    procedure SetValue(const Value: TValue);
  protected
    procedure PopulateItems(const TypeInfo: PTypeInfo);
    procedure Click; override;
    procedure SizePopup;
    procedure ChangeCheck(Sender: TObject);
    procedure UpdateButtonText;
  public
    constructor Create(AOwner: TComponent); override;
    property  TypeInfo  : PTypeInfo     read fTypeInfo;
    property  Value     : TValue        read GetValue   write SetValue;
    property  ExtraSize : TPoint        read fExtraSize write fExtraSize;
  published
    property  OnChange  : TNotifyEvent  read fOnChange  write fOnChange;
  end;
{$M-}

procedure Register;

resourcestring
  SEExpectedEnum    = '{0}.Value must be an enumeration.';
  SEExpectedEnumSet = '{0}.Value must be an enumeration set.';

implementation

uses
  System.Math, FMX.Graphics, BatSoft.Common;

procedure Register;
begin
  RegisterComponents('BatSoft', [TEnumEditor, TEnumSetEditor]);
end;

{ TEnumEditor }

procedure TEnumEditor.DropDown;
begin
  DropDownCount := DropDownRowCount;
  inherited;
end;

function TEnumEditor.GetOrdinal: Int64;
begin
  Result  := EnumToOrd(Value);
end;

function TEnumEditor.GetValue: TValue;
begin
  Result  := OrdToEnum(OrdAt(ItemIndex), fTypeInfo);
end;

function TEnumEditor.OrdAt(const Index: integer): Int64;
begin
  Result  := Int64(Items.Objects[Index])
end;

procedure TEnumEditor.PopulateItems(const TypeInfo: PTypeInfo);
begin
  if  fTypeInfo = TypeInfo  then
    Exit;
  if  Assigned(fTypeInfo) and (fTypeInfo.Kind <> tkEnumeration) then
    raise EBatSoft.Create(SEExpectedEnum, [ClassName]);
  fTypeInfo := TypeInfo;
  ListEnumValues(Items, fTypeInfo);
end;

procedure TEnumEditor.SetOrdinal(const Ord: Int64);
begin
  Value   := OrdToEnum(Ord, fTypeInfo);
end;

procedure TEnumEditor.SetValue(const Value: TValue);
var
  Index: integer;
begin
  PopulateItems(Value.TypeInfo);
  //  Select value
  Index := Items.Count - 1;
  while Index >= 0  do
    if  Value.AsOrdinal = OrdAt(Index)  then
      break
    else
      dec(Index);
  ItemIndex := Index;
end;

{ TEnumSetEditor }

procedure TEnumSetEditor.ChangeCheck(Sender: TObject);
begin
  UpdateButtonText;
  if  Assigned(fOnChange) then
    fOnChange(Self);
end;

procedure TEnumSetEditor.Click;
begin
  inherited;
  fPopup.Popup();
end;

constructor TEnumSetEditor.Create(AOwner: TComponent);
begin
  inherited;
  fPopup  := TPopup.Create(Self);
  fPopup.Parent           := Self;
  fPopup.PlacementTarget  := Self;
  fPopup.Placement        := TPlacement.Bottom;
  fListBox  := TListBox.Create(fPopup);
  fListBox.Parent         := fPopup;
  fListBox.ShowCheckboxes := True;
  fListBox.OnChangeCheck  := ChangeCheck;
  fPopup.AddObject(fListBox);
  fExtraSize  := DefaultExtraSize;
end;

function TEnumSetEditor.GetValue: TValue;
var
  i: integer;
  Ints: TIntegerList;
//  Buffer: set of byte;
  Ord: Int64;
  Values: array of TValue;
begin
//  Ints  := TIntegerList.Create;
//  try
//    for i := 0 to fListBox.Items.Count - 1 do
//      if  fListBox.ListItems[i].IsChecked then
//        Ints.Add(integer(fListBox.Items.Objects[i]));
//    SetLength(Values, Ints.Count);
//    for i := 0 to Ints.Count - 1 do
//        Values[i] := Ints[i];
//    Result  := TValue.FromArray(TypeInfo, Values)
//  finally
//    Ints.Free;
//  end;


  Ord := 0;
  for i := 0 to fListBox.Items.Count - 1 do
    if  fListBox.ListItems[i].IsChecked then
      Ord := Ord or Round(Power(2, integer(fListBox.Items.Objects[i])));
  Result  := OrdToEnumSet(Ord, fTypeInfo);
//    Result  := TValue.FromOrdinal(TypeInfo, Ord);
//
//  Buffer  :=
end;

procedure TEnumSetEditor.PopulateItems(const TypeInfo: PTypeInfo);
begin
  if  fTypeInfo = TypeInfo  then
    Exit;
  if  Assigned(fTypeInfo) and (fTypeInfo.Kind <> tkSet) then
    raise EBatSoft.Create(SEExpectedEnumSet, [ClassName]);
  fTypeInfo := TypeInfo;
  ListEnumSetValues(fListBox.Items, fTypeInfo);
  SizePopup;
end;

procedure TEnumSetEditor.SetValue(const Value: TValue);
var
  FullSet: TStrings;
  Selected: TIntegerList;
  i: integer;
begin
  PopulateItems(Value.TypeInfo);
  //  Select values
  FullSet   := fListBox.Items;
  Selected  := TIntegerList.Create;
  try
    ListEnumSetSelected(Value, Selected, TypeInfo);
    for i := 0 to FullSet.Count - 1 do
      fListBox.ListItems[i].IsChecked := Selected.Contains(i);
  finally
    Selected.Free;
  end;
  UpdateButtonText;
end;

procedure TEnumSetEditor.SizePopup;
var
  Canvas: TCanvas;
  Control: TControl;
  MaxWidth, MaxHeight: Single;
  i: Integer;
  Item: TListBoxItem;
begin
  fListBox.PrepareForPaint;
  //  Find a canvas
  Control := fListBox;
  repeat
    Canvas  := Control.Canvas;
  until not Assigned(Control) or Assigned(Canvas);
  if  not Assigned(Canvas)  then
    raise EBatSoft.Create('No Canvas');
  //  Work out the size
  MaxWidth  := -1;
  MaxHeight := -1;
  for i := 0 to Min(fListBox.Items.Count, DropDownRowCount) - 1  do
    begin
      Item      := fListBox.ItemByIndex(i);
      Item.PrepareForPaint;
      MaxWidth  := Max(MaxWidth, Item.Height + Canvas.TextWidth(Item.Text));
      MaxHeight := MaxHeight + Item.Height;
    end;
  fListBox.Width  := Max(MaxWidth + ExtraSize.X, Self.BoundsRect.Width);
  fListBox.Height := MaxHeight + ExtraSize.Y;
  fPopup.Width    := fListBox.Width;
  fPopup.Height   := fListBox.Height;
end;

procedure TEnumSetEditor.UpdateButtonText;
var
  Strs: TStringList;
begin
  Strs  := TStringList.Create;
  try
    ListEnumSetSelected(Value, Strs);
    Self.Text := Strs.CommaText;
  finally
    Strs.Free;
  end;
end;

end.
