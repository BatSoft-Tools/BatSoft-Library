unit BatSoft.Editors;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.TypInfo, System.Types, System.Classes, System.Generics.Collections, System.Rtti,
  FMX.Types, FMX.Layouts, FMX.Controls, FMX.StdCtrls, BatSoft.Common, BatSoft.Classes.FMX;

type
  TEditors = class(TVertScrollBox)
  private type

    TPropInfo = class
      Prop: TRttiProperty;
      Label_: TLabel;
      Editor: TControl;
      destructor Destroy; override;
    end;

  private
    fEditObject: TObject;
    fPropObjs: TObjectList<TPropInfo>;
    fProps: TDictionary<TControl, TPropInfo>;
    fLayoutLabels, fLayoutEditors, fPusher: TLayout;
    fSplitter: TSplitter;
    fChildMargins: TBounds;
    procedure SetEditObject(const Value: TObject);
    procedure OnEvent(Sender: TObject);
  protected
    function  GetProperties: TArray<TRttiProperty>;
    procedure ClearControls;
    procedure BuildControls;
    function  CreateControl(const T: TControlClass; const Parent: TControl; const Align: TAlignLayout; const Margins: TRectF): TControl;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  published
    procedure Populate;
    property  EditObject  : TObject read fEditObject    write SetEditObject;
    property  ChildMargins: TBounds read fChildMargins  write fChildMargins;
  end;

  TEditorValueGetter = reference to function (const Editor: TControl): TValue;
  TEditorValueSetter = reference to procedure (const Editor: TControl; Value: TValue);

  TEditorTypes = class
  private type

    TEditorInfo = class
      EditorClass: TControlClass;
      GetEditValue: TEditorValueGetter;
      SetEditValue: TEditorValueSetter;
      Event: TRttiProperty;
    end;

  private
    fEditorInfosLifetime: TObjectList<TEditorInfo>;
    fEditorInfos: TDictionary<PTypeInfo, TEditorInfo>;
    function  FindEvent(const EditorClass: TControlClass; const EventName: string): TRttiProperty;
    function  GetEditorInfo(const Prop: TRttiProperty): TEditorInfo;
  public
    constructor Create;
    destructor  Destroy; override;
    function  Register(const TypeInfo: PTypeInfo; const EditorClass: TControlClass; const ChangeEventName: string; const GetEditValue: TEditorValueGetter; const SetEditValue: TEditorValueSetter): TEditorInfo;
  end;

  EEditors = class(EBatSoft);

var
  EditorTypes: TEditorTypes;

procedure Register;

procedure RegisterStandardEditors;

implementation

uses
  System.SysUtils, System.Math, FMX.Graphics, FMX.Objects, FMX.Edit, FMX.SpinBox,
  BatSoft.Editors.Enum;

const
  NoBounds  : TRect = (Left:0; Top:0; Right:0; Bottom:0);

procedure Register;
begin
  RegisterComponents('BatSoft', [TEditors]);
end;

procedure RegisterStandardEditors;
begin
  EditorTypes.Register(TypeInfo(string), TEdit, 'OnTyping',
    function (const Editor: TControl): TValue
    begin
      Result  := TEdit(Editor).Text
    end,
    procedure (const Editor: TControl; Value: TValue)
    begin
      TEdit(Editor).Text  := Value.AsString
    end
  );

  EditorTypes.Register(TypeInfo(integer), TSpinBox, 'OnChange',
    function (const Editor: TControl): TValue
    begin
      Result  := Trunc(TSpinBox(Editor).Value)
    end,
    procedure (const Editor: TControl; Value: TValue)
    begin
      (Editor as TSpinBox).Value  := Value.AsInteger
    end
  );

  EditorTypes.Register(TypeInfo(Single), TSpinBox, 'OnChange',
    function (const Editor: TControl): TValue
    begin
      Result  := TSpinBox(Editor).Value
    end,
    procedure (const Editor: TControl; Value: TValue)
    var
      SpinBox: TSpinBox;
    begin
      SpinBox := Editor as TSpinBox;
      SpinBox.Max   := +MaxInt;
      SpinBox.Min   := -MaxInt;
      SpinBox.Value := Value.AsExtended
    end
  );

  EditorTypes.Register(TypeInfo(Boolean), TCheckBox, 'OnChange',
    function (const Editor: TControl): TValue
    begin
      Result  := TCheckBox(Editor).IsChecked
    end,
    procedure (const Editor: TControl; Value: TValue)
    begin
      (Editor as TCheckBox).IsChecked := Value.AsBoolean
    end
  );

end;

{ TEditors.TPropInfo }

destructor TEditors.TPropInfo.Destroy;
begin
  Label_.Free;
  Editor.Free;
  inherited;
end;

{ TEditors }

procedure TEditors.BuildControls;
var
  Props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
  PropInfo: TPropInfo;
  EditorInfo: TEditorTypes.TEditorInfo;
  RowHeight, TotalHeight, LabelWidth, MaxLabelWidth: Single;
begin
  PropInfo  := nil;
  BeginUpdate;
  try
    Props := GetProperties;
    TotalHeight   := 0;
    MaxLabelWidth := 0;
    for Prop in Props do
      begin
        EditorInfo  := EditorTypes.GetEditorInfo(Prop);
        if  not Assigned(EditorInfo)  then
          Continue;
        PropInfo  := TEditors.TPropInfo.Create;
        PropInfo.Prop := Prop;
        //  Create label
        PropInfo.Label_ := CreateControl(TLabel, fLayoutLabels, TAlignLayout.Top, ChildMargins.Rect) as TLabel;
        PropInfo.Label_.Text := Prop.Name;
        //  Create editor
        PropInfo.Editor := CreateControl(EditorInfo.EditorClass, fLayoutEditors, TAlignLayout.Top, ChildMargins.Rect);
        EditorInfo.SetEditValue(PropInfo.Editor, Prop.GetValue(fEditObject));
        EditorInfo.Event.SetValue(PropInfo.Editor, TValue.From<TNotifyEvent>(OnEvent));
        //  Register them
        fProps.Add(PropInfo.Editor, PropInfo);
        fPropObjs.Add(PropInfo);
        //  Make their heights the same
        RowHeight     := Max(PropInfo.Label_.Height, PropInfo.Editor.Height);
        PropInfo.Label_.Height  := RowHeight;
        PropInfo.Editor.Height  := RowHeight;
        //  Keep track of max sizes
        TotalHeight   := TotalHeight + RowHeight;
        LabelWidth    := PropInfo.Label_.Canvas.TextWidth(PropInfo.Label_.Text);
        if  MaxLabelWidth < LabelWidth  then
          MaxLabelWidth := LabelWidth;
      end;
    //  Scale according to contents
    fLayoutLabels.Width := MaxLabelWidth + ChildMargins.Left + ChildMargins.Right;
  finally
    EndUpdate;
  end;
  BeginUpdate;
  try
    if  Assigned(PropInfo) then
      fPusher.BoundsRect  := PropInfo.Label_.BoundsRect
    else
      fPusher.BoundsRect  := NoBounds;
  finally
    EndUpdate;
  end;
end;

procedure TEditors.ClearControls;
begin
  fProps.Clear;
  fPropObjs.Clear;
end;

constructor TEditors.Create(AOwner: TComponent);
begin
  inherited;
  fChildMargins   := TBounds.Create(RectF(8, 8, 8, 0));
  fPropObjs := TObjectList<TPropInfo>.Create(True);
  fProps    := TDictionary<TControl, TPropInfo>.Create;
  fLayoutLabels   := CreateControl(TLayout,   Self, TAlignLayout.MostLeft,  NoBounds) as TLayout;
  fSplitter       := CreateControl(TSplitter, Self, TAlignLayout.Left,      NoBounds) as TSplitter;
  fLayoutEditors  := CreateControl(TLayout,   Self, TAlignLayout.Client,    NoBounds) as TLayout;
  fPusher         := CreateControl(TLayout,   Self, TAlignLayout.None,      NoBounds) as TLayout;
  fPusher.BoundsRect  := NoBounds;
  //  Debug tool to see where the fPusher is
//  CreateControl(TButton, fPusher, TAlignLayout.Client, NoBounds);
end;

function TEditors.CreateControl(const T: TControlClass; const Parent: TControl; const Align: TAlignLayout; const Margins: TRectF): TControl;
begin
  Result  := T.Create(Self);
  Result.Parent   := Parent;
  Result.Stored   := False;
  Result.Align    := Align;
  Result.Margins.Rect := Margins;
  Result.Position.Y := MaxInt;
end;

destructor TEditors.Destroy;
begin
  EditObject  := nil;
  fProps.Free;
  fPropObjs.Free;
  fChildMargins.Free;
  inherited;
end;

function TEditors.GetProperties: TArray<TRttiProperty>;
var
  ByName: TStringList;
  Prop: TRttiProperty;
  i: Integer;
  Name: string;
begin
  Result  := RTTI.GetType(fEditObject.ClassType).GetProperties;
  ByName  := TStringList.Create;
  try
    //  Collect viable properties
    for Prop in Result  do
      if  Prop.IsReadable and Prop.IsWritable and (Prop.Visibility = mvPublished) then
        ByName.AddObject(Prop.Name, Prop);
    //  Sort and remove duplicates
    ByName.Sort;
    //  Remove duplicates (more efficient than using Duplicates property)
    if  ByName.Count > 1  then
      begin
        Name  := ByName[ByName.Count - 1];
        for i := ByName.Count - 2 downto 0 do
          if  SameText(ByName[i], Name) then
            ByName.Delete(i)
          else
            Name  := ByName[i];
      end;
    //  Produce result
    SetLength(Result, ByName.Count);
    for i := 0 to ByName.Count - 1 do
      Result[i] := Pointer(ByName.Objects[i]);
  finally
    ByName.Free;
  end;
end;

procedure TEditors.OnEvent(Sender: TObject);
var
  Editor: TControl absolute Sender;
  PropInfo: TPropInfo;
  EditorInfo: TEditorTypes.TEditorInfo;
begin
  PropInfo    := fProps[Editor];
  EditorInfo  := EditorTypes.GetEditorInfo(PropInfo.Prop);
  PropInfo.Prop.SetValue(fEditObject, EditorInfo.GetEditValue(Editor));
end;

procedure TEditors.Populate;
var
  PropInfoPair: TPair<TControl, TPropInfo>;
  PropInfo: TPropInfo;
  Editor: TControl;
  EditorInfo: TEditorTypes.TEditorInfo;
  Value: TValue;
begin
  for PropInfoPair in fProps  do
    begin
      Editor      := PropInfoPair.Key;
      PropInfo    := PropInfoPair.Value;
      EditorInfo  := EditorTypes.GetEditorInfo(PropInfo.Prop);
      Value := PropInfo.Prop.GetValue(fEditObject);
      EditorInfo.SetEditValue(Editor, Value);
    end;
end;

procedure TEditors.SetEditObject(const Value: TObject);
begin
  ClearControls;
  fEditObject := Value;
  if  Assigned(fEditObject) then
    begin
      BuildControls;
      Populate;
    end
  else
    fPusher.BoundsRect  := NoBounds;
end;

{ TEditorTypes }

constructor TEditorTypes.Create;
begin
  inherited;
  fEditorInfosLifetime        := TObjectList<TEditorInfo>.Create(True);
  fEditorInfos  := TDictionary<PTypeInfo, TEditorInfo>.Create;
end;

destructor TEditorTypes.Destroy;
begin
  fEditorInfos.Free;
  fEditorInfosLifetime.Free;
  inherited;
end;

function TEditorTypes.FindEvent(const EditorClass: TControlClass; const EventName: string): TRttiProperty;
var
  Props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
begin
  Props := RTTI.GetType(EditorClass).GetProperties;
  for Prop in Props do
    if  SameText(Prop.Name, EventName)  then
      Exit(Prop);
  raise EEditors.Create('Property %s.%s not found.', [EditorClass.ClassName, EventName]);
end;

function TEditorTypes.GetEditorInfo(const Prop: TRttiProperty): TEditorInfo;
var
  TypeInfo: PTypeInfo;
begin
  TypeInfo  := Prop.PropertyType.Handle;
  //  Try to find already registered editor
  if  EditorTypes.fEditorInfos.TryGetValue(TypeInfo, Result)  then
  //  ...otherwise try to create a suitable editor
  else if Prop.PropertyType.TypeKind = tkEnumeration  then
    Result  := Register(TypeInfo, TEnumEditor, 'OnChange',
      function (const Editor: TControl): TValue
      begin
        Result  := TEnumEditor(Editor).Value
      end,
      procedure (const Editor: TControl; Value: TValue)
      begin
        (Editor as TEnumEditor).Value := Value
      end)
  else if Prop.PropertyType.TypeKind = tkSet  then
    Result  := Register(TypeInfo, TEnumSetEditor, 'OnChange',
      function (const Editor: TControl): TValue
      begin
        Result  := TEnumSetEditor(Editor).Value
      end,
      procedure (const Editor: TControl; Value: TValue)
      begin
        (Editor as TEnumSetEditor).Value := Value
      end)
  //  We might not be able to support this type
  else
    Result  := nil;
end;

function TEditorTypes.Register(const TypeInfo: PTypeInfo;
  const EditorClass: TControlClass; const ChangeEventName: string;
  const GetEditValue: TEditorValueGetter;
  const SetEditValue: TEditorValueSetter): TEditorInfo;
var
  Info: TEditorInfo;
begin
  Info  := TEditorInfo.Create;
  try
    Info.EditorClass  := EditorClass;
    Info.GetEditValue  := GetEditValue;
    Info.SetEditValue  := SetEditValue;
    Info.Event := FindEvent(EditorClass, ChangeEventName);
  except
    Info.Free;
    raise;
  end;
  fEditorInfos.AddOrSetValue(TypeInfo, Info);
  fEditorInfosLifetime.Add(Info);
  Result  := Info;
end;

initialization
  EditorTypes := TEditorTypes.Create;
  RegisterStandardEditors;

finalization
  EditorTypes.Free;

end.
