unit Bat.Spinners;

interface

uses
  System.Types, System.Classes, System.UITypes,
  FMX.Types, FMX.Controls, FMX.InertialMovement, FMX.StdCtrls;

const
  DefaultSpinnerItemHeight = 20;

type
  TSpinner = class(TStyledControl)
  private
    fCalcs: TAniCalculations;
    FMouseEvents: Boolean;
  protected
    //  Input
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DoMouseLeave; override;
    //  Output
    procedure CalcsStart(Sender: TObject);
    procedure CalcsChanged(Sender: TObject); virtual;
    procedure CalcsStop(Sender: TObject);
    procedure CMGesture(var EventInfo: TGestureEventInfo); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Invalidate;
  published
    property  Align;  //  Specifies the alignment options (top, left, client, and so on) of this control.
    property  Anchors;  //  Specifies how the control is anchored to its parent.
//    property  AutoCapture;  //  Specifies whether the control captures mouse events.
    property  BoundsRect; //  Specifies the bounding rectangle of the control.
    property  CanFocus; //  Specifies whether the current control can receive focus.
    property  Cursor; //  Image to use to represent the mouse pointer when it passes into the region covered by the control.
    property  DisableFocusEffect; //  Specifies whether the control has the focus effect disabled.
    property  DragMode; //  Specifies how the control initiates drag-and-drop operations.
    property  Enabled;  //  Specifies whether the control responds to mouse, keyboard, and timer events.
    property  EnableDragHighlight;  //  Specifies whether the control is highlighted when the dragged object is over it.
//    property  Height; //  Specifies the vertical size of the control (in pixels).
    property  Hint; //  Specifies the text string that appears when the user moves the mouse over the control.
    property  HitTest;  //  Specifies whether mouse-click events are captured by this control.
//    property  Left; //  Specifies the horizontal coordinate of the left edge of a component, relative to its parent.
//    property  Locked; //  Specifies whether the control is locked at design time.
    property  Margins;  //  Specifies the control's margins.
//    property  Name; //  Specifies the name of the component as referenced in code.
    property  Opacity;  //  Specifies the control opacity.
    property  Padding;  //  Specifies the control's padding.
    property  PopupMenu;  //  Specifies the context (pop-up) menu object.
    property  Position; //  Specifies the upper-left corner of the current control, relative to its parent.
    property  Scale;  //  Specifies the scale of the control.
    property  ShowHint; //  Specifies whether the Hint can be shown.
    property  Size;
    property  StyleLookup;  //
    property  StyleName;  //  Specifies the style name for this FMX component.
    property  TabOrder; //  Indicates the position of the control in its parent's tab order.
    property  TabStop;  //
    property  Tag;  //  Stores a NativeInt integral value as a part of a component.
    property  TagFloat; //  Custom property that stores any floating-point value.
//    property  TagObject;  //  Custom property that stores any object value.
    property  TagString;  //  Custom property that stores any string value.
//    property  Top;  //  Specifies the vertical coordinate of the upper-left corner of a control, relative to its parent, in pixels.
    property  Touch;  //  Specifies the touch manager component associated with the control.
    property  TouchTargetExpansion; //  Set of optional pixel values you can specify to expand the touch target of a FireMonkey styled control.
    property  Visible;  //  Specifies whether the component appears onscreen.
//    property  Width;  //  Specifies the horizontal size of the control (in pixels).
  end;

  TListSpinner = class;

  TListSpinnerEvent = function (Sender: TListSpinner; Index: integer): TControl of object;

  TListSpinner = class(TSpinner)
  //  Scrollbar
  private
    fScrollbar: TScrollBar;
    function  GetShowScrollbar: Boolean; inline;
    procedure SetShowScrollbar(const Value: Boolean);
    procedure ScrollbarChange(Sender: TObject);
  published
    property  ShowScrollbar : Boolean           read GetShowScrollbar write SetShowScrollbar  default False;
  //  Read only code
  private
    fItemCount: integer;
    fItemHeight: integer;
    fOnPaintBegin: TNotifyEvent;
    fOnPaintEnd: TNotifyEvent;
    fOnGetShowItem: TListSpinnerEvent;
    procedure SetItemCount(const Value: integer);
    procedure SetItemHeight(const Value: integer);
  protected
    procedure RefreshFloorSize;
    procedure Paint; override;
    procedure CalcsChanged(Sender: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure JumpTo(Index: integer);
  published
    property  ItemCount     : integer           read fItemCount       write SetItemCount;
    property  ItemHeight    : integer           read fItemHeight      write SetItemHeight default DefaultSpinnerItemHeight;
    property  OnPaintBegin  : TNotifyEvent      read fOnPaintBegin    write fOnPaintBegin;
    property  OnPaintEnd    : TNotifyEvent      read fOnPaintEnd      write fOnPaintEnd;
    property  OnGetShowItem : TListSpinnerEvent read fOnGetShowItem   write fOnGetShowItem;
  //  Editor  code
  private
    fItemIndex: integer;
    fEditor: TControl;
    fOnGetEditItem: TListSpinnerEvent;
    procedure SetItemIndex(const Value: integer);
    procedure PlaceEditor;
  protected
    procedure Loaded; override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single); override;
  published
    property  ItemIndex     : integer           read fItemIndex       write SetItemIndex  default -1;
    property  OnGetEditItem : TListSpinnerEvent read fOnGetEditItem   write fOnGetEditItem;
  end;

//  NOTE: Due to a "quirk" in the Delphi libraries, ApplyStyleLookup() *must*
//  be called at least once before the OnGetShowItem() controls will show.
//
//  Some controls, such as TLabel, will do this when you set the Text property,
//  but edit controls do not (TEdit, TDateEdit).
//
//  So, call ApplyStyleLookupToAll() once on objects that will be returned by
//  OnGetShowItem() to ensure that they will be shown as intended.
//  If you have them all on the same form, then to keep it simple, you can simply
//  call this on the form itself in the FormCreate() event.
procedure ApplyStyleLookupToAll(const Control: TFmxObject);

procedure Register;

implementation

uses
  System.SysUtils, Math, FMX.Platform, FMX.Graphics;

procedure Register;
begin
  RegisterComponents('BatControls', [TListSpinner]);
end;

procedure ApplyStyleLookupToAll(const Control: TFmxObject);
var
  Child: TFmxObject;
begin
  if  Control is TStyledControl then
    (Control as TStyledControl).ApplyStyleLookup;
  if  Assigned(Control.Children)  then
    for Child in Control.Children do
      ApplyStyleLookupToAll(Child);
end;

{ TSpinner }

procedure TSpinner.CalcsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TSpinner.CalcsStart(Sender: TObject);
begin
  Invalidate;
end;

procedure TSpinner.CalcsStop(Sender: TObject);
begin
  Invalidate;
end;

procedure TSpinner.CMGesture(var EventInfo: TGestureEventInfo);
var
  LP: TPointF;
begin
  //This is used when scrolling with the finger on top of a control (like a TButton on a TListItem).
  if EventInfo.GestureID = igiPan then
  begin
    FMouseEvents := False;
    LP  := EventInfo.Location;// - fCalcs.ViewportPositionF;
    if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
      fCalcs.MouseDown(EventInfo.Location.X, EventInfo.Location.Y)
    else
      if EventInfo.Flags = [] then
        fCalcs.MouseMove(EventInfo.Location.X, EventInfo.Location.Y)
      else
      if fCalcs.Down then
        fCalcs.MouseUp(EventInfo.Location.X, EventInfo.Location.Y);
  end
  else
    inherited;
end;

constructor TSpinner.Create(AOwner: TComponent);
begin
  inherited;
  ClipChildren  := True;
  AutoCapture   := True;
  fCalcs  := TAniCalculations.Create(Self);
  fCalcs.Animation        := True;
  fCalcs.Averaging        := True;
  fCalcs.BoundsAnimation  := True;
  fCalcs.DecelerationRate := 0.95;
  fCalcs.OnStart          := CalcsStart;
  fCalcs.OnChanged        := CalcsChanged;
  fCalcs.OnStop           := CalcsStop;
  Touch.DefaultInteractiveGestures := Touch.DefaultInteractiveGestures + [TInteractiveGesture.Pan];
  Touch.InteractiveGestures := Touch.InteractiveGestures + [TInteractiveGesture.Pan];
end;

destructor TSpinner.Destroy;
begin
  fCalcs.Free;
  inherited;
end;

procedure TSpinner.DoMouseLeave;
begin
  inherited;
  if FMouseEvents and fCalcs.Down then
    fCalcs.MouseLeave;
end;

procedure TSpinner.Invalidate;
begin
  InvalidateRect(TRectF.Create(0, 0, Width, Height));
end;

procedure TSpinner.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FMouseEvents  := True;
  inherited;
  fCalcs.MouseDown(X, Y);
end;

procedure TSpinner.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  FMouseEvents  := True;
  inherited;
  fCalcs.MouseMove(X, Y);
end;

procedure TSpinner.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FMouseEvents  := True;
  inherited;
  fCalcs.MouseUp(X, Y);
end;

procedure TSpinner.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  inherited;
  fCalcs.MouseWheel(0, -WheelDelta);
end;

{ TListSpinner }

procedure TListSpinner.CalcsChanged(Sender: TObject);
begin
  inherited;
  if  ShowScrollbar then
    fScrollbar.Value  := fCalcs.ViewportPosition.Y;
end;

constructor TListSpinner.Create(AOwner: TComponent);
begin
  inherited;
  fItemIndex  := -1;
  fItemHeight := DefaultSpinnerItemHeight;
end;

destructor TListSpinner.Destroy;
begin
  fScrollbar.Free;
  inherited;
end;

function TListSpinner.GetShowScrollbar: Boolean;
begin
  Result  := Assigned(fScrollbar)
end;

procedure TListSpinner.JumpTo(Index: integer);
begin
  if  ItemCount <= Index  then
    Index := ItemCount - 1;
  if  Index < 0 then
    Index := 0;
  fCalcs.ViewportPositionF  := Point(0, Index * ItemHeight);
end;

procedure TListSpinner.Loaded;
var
  Nx: integer;
begin
  inherited;
  //  If ItemIndex was set before OnGetEditItem, then set ItemIndex again
  if  not Assigned(fEditor) then
    begin
      Nx          := fItemIndex;
      fItemIndex  := -1;
      ItemIndex   := Nx;
    end;
end;

procedure TListSpinner.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if  (Button = TMouseButton.mbLeft) and not fCalcs.Moved then
    ItemIndex := Trunc((Y + fCalcs.ViewportPosition.Y) / ItemHeight);
end;

procedure TListSpinner.Paint;
var
  Index: integer;
  Top: integer;
  ItemWidth: Single;
  Item: TControl;
begin
  if  Assigned(fOnPaintBegin) then
    fOnPaintBegin(Self);
  try
    inherited;
    Index := Trunc(fCalcs.ViewportPosition.Y / fItemHeight);
    Top   := Trunc(Index * fItemHeight - fCalcs.ViewportPosition.Y);
    ItemWidth := Self.Width;
    if  ShowScrollbar then
      ItemWidth := ItemWidth - fScrollbar.Width;
    while (Index < fItemCount) and (Top < Self.Height) do
      begin
        Item  := nil;
        if  Assigned(fOnGetShowItem) and (0 <= Index) and (Index < ItemCount)  then
          if  not Assigned(fOnGetEditItem) or (Index <> fItemIndex) then
            Item  := fOnGetShowItem(Self, Index);
        if  Assigned(Item)  then
          begin
            Item.Width  := ItemWidth;
            Item.Height := fItemHeight;
            Item.PaintTo(Self.Canvas, RectF(0, Top, ItemWidth, Top + Item.Height), Self);
          end;
        inc(Index);
        inc(Top, fItemHeight);
      end;
  finally
    if  Assigned(fOnPaintEnd) then
      fOnPaintEnd(Self);
  end;
  PlaceEditor;
end;

procedure TListSpinner.PlaceEditor;
var
  Top: integer;
begin
  if  not Assigned(fEditor) then
    Exit;
  Top   := Trunc(ItemIndex * fItemHeight - fCalcs.ViewportPosition.Y);
  fEditor.Parent  := Self;
  fEditor.Position.Point  := TPointF.Create(0, Top);
  fEditor.Width   := Self.Width;
  fEditor.Height  := fItemHeight;
  fEditor.Visible := True;
end;

procedure TListSpinner.RefreshFloorSize;
var
  Targets: array of TAniCalculations.TTarget;
begin
  SetLength(Targets, 2);
  Targets[0].TargetType := TAniCalculations.TTargetType.Min;
  Targets[0].Point      := TPointD.Create(0, 0);
  Targets[1].TargetType := TAniCalculations.TTargetType.Max;
  Targets[1].Point      := TPointD.Create(0, Max(0, fItemCount * fItemHeight - Height));
  fCalcs.SetTargets(Targets);
  if  ShowScrollbar then
    fScrollbar.Max  := ItemCount * fItemHeight - Height;
  Invalidate;
end;

procedure TListSpinner.ScrollbarChange(Sender: TObject);
begin
  fCalcs.ViewportPositionF  := PointF(0, TScrollBar(Sender).Value);
end;

procedure TListSpinner.SetItemCount(const Value: integer);
begin
  fItemCount := Value;
  RefreshFloorSize;
end;

procedure TListSpinner.SetItemHeight(const Value: integer);
begin
  fItemHeight := Max(1, Value);
  RefreshFloorSize;
end;

procedure TListSpinner.SetItemIndex(const Value: integer);
begin
  if  Value = fItemIndex  then
    Exit;
  if  Assigned(fEditor) then
    fEditor.Visible := False;
  fItemIndex  := Value;
  if  ((fItemIndex < 0) or (fItemCount <= fItemIndex)) and Assigned(fEditor)  then
    fEditor.Visible := False;
  if  Assigned(fOnGetEditItem) then
    fEditor := fOnGetEditItem(Self, fItemIndex);
  if  (fItemIndex < 0) or (fItemCount <= fItemIndex)  then
    fEditor := nil;
  PlaceEditor;
end;

procedure TListSpinner.SetShowScrollbar(const Value: Boolean);
begin
  if  Value = GetShowScrollbar  then
    Exit;
  if  Value then
    begin
      fScrollbar := TScrollBar.Create(Self);
      fScrollbar.Parent       := Self;
      fScrollbar.Orientation  := TOrientation.Vertical;
      fScrollbar.Align        := TAlignLayout.Right;
      fScrollbar.Stored       := False;
      fScrollbar.OnChange     := ScrollbarChange;
    end
  else
    FreeAndNil(fScrollbar);
end;

end.
