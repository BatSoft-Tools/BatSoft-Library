unit BatSoft.Editors;

interface

uses
  System.TypInfo, System.Types, System.Classes, System.Generics.Collections, System.Rtti,
  FMX.Types, FMX.Layouts, FMX.StdCtrls, FMX.Controls, BatSoft.Classes, BatSoft.Classes.FMX;

type
  TEditors = class(TLayout)
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
    fLayoutLabels, fLayoutEditors: TLayout;
    fSplitter: TSplitter;
    fChildMargins: TBounds;
    procedure SetEditObject(const Value: TObject);
    procedure OnEvent(Sender: TObject);
  protected
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
      GetValue: TEditorValueGetter;
      SetValue: TEditorValueSetter;
      Event: TRttiProperty;
    end;

  private
    fEditorTypes: TObjectList<TEditorInfo>;
    fEditors: TDictionary<PTypeInfo, TEditorInfo>;
    function  FindEvent(const EditorClass: TControlClass; const EventName: string): TRttiProperty;
  protected
    function  GetEditor(const TypeInfo: PTypeInfo): TControlClass;
    function  EditorValueGetter(const TypeInfo: PTypeInfo): TEditorValueGetter;
    function  EditorValueSetter(const TypeInfo: PTypeInfo): TEditorValueSetter;
    function  GetInfo(const Prop: TRttiProperty): TEditorInfo;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(const TypeInfo: PTypeInfo; const EditorClass: TControlClass; const ChangeEventName: string; const GetEditValue: TEditorValueGetter; const SetEditValue: TEditorValueSetter);
  end;

  EEditors = class(EBatSoft);

var
  EditorTypes: TEditorTypes;

procedure Register;

procedure RegisterStandardEditors;

implementation

uses
  System.SysUtils, System.Math, FMX.Objects, FMX.Edit, FMX.SpinBox;

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
  Height: Single;
begin
  Props := RTTI.GetType(fEditObject.ClassType).GetProperties;
  for Prop in Props do
    begin
      EditorInfo  := EditorTypes.GetInfo(Prop);
      if  not Assigned(EditorInfo)  then
        Continue;
      PropInfo  := TEditors.TPropInfo.Create;
      PropInfo.Prop := Prop;
      //  Create label
      PropInfo.Label_ := CreateControl(TLabel, fLayoutLabels, TAlignLayout.Top, ChildMargins.Rect) as TLabel;
      PropInfo.Label_.Text := Prop.Name;
      //  Create editor
      PropInfo.Editor := CreateControl(EditorInfo.EditorClass, fLayoutEditors, TAlignLayout.Top, ChildMargins.Rect);
      EditorInfo.Event.SetValue(PropInfo.Editor, TValue.From<TNotifyEvent>(OnEvent));
      //  Register them
      fProps.Add(PropInfo.Editor, PropInfo);
      //  Make their heights the same
      Height  := Max(PropInfo.Label_.Height, PropInfo.Editor.Height);
      PropInfo.Label_.Height  := Height;
      PropInfo.Editor.Height  := Height;
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
end;

function TEditors.CreateControl(const T: TControlClass; const Parent: TControl; const Align: TAlignLayout; const Margins: TRectF): TControl;
begin
  Result  := T.Create(Self);
  Result.Parent   := Parent;
  Result.Stored   := False;
  Result.Align    := Align;
  Result.Margins.Rect := Margins;
end;

destructor TEditors.Destroy;
begin
  EditObject  := nil;
  fProps.Free;
  fPropObjs.Free;
  fChildMargins.Free;
  inherited;
end;

procedure TEditors.OnEvent(Sender: TObject);
var
  Editor: TControl absolute Sender;
  PropInfo: TPropInfo;
  EditorInfo: TEditorTypes.TEditorInfo;
begin
  PropInfo    := fProps[Editor];
  EditorInfo  := EditorTypes.GetInfo(PropInfo.Prop);
  PropInfo.Prop.SetValue(fEditObject, EditorInfo.GetValue(Editor));
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
      EditorInfo  := EditorTypes.GetInfo(PropInfo.Prop);
      Value := PropInfo.Prop.GetValue(fEditObject);
      EditorInfo.SetValue(Editor, Value);
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
    end;
end;

{ TEditorTypes }

constructor TEditorTypes.Create;
begin
  inherited;
  fEditorTypes  := TObjectList<TEditorInfo>.Create(True);
  fEditors      := TDictionary<PTypeInfo, TEditorInfo>.Create;
end;

destructor TEditorTypes.Destroy;
begin
  fEditors.Free;
  fEditorTypes.Free;
  inherited;
end;

function TEditorTypes.EditorValueGetter(const TypeInfo: PTypeInfo): TEditorValueGetter;
begin
  Result  := fEditors[TypeInfo].GetValue
end;

function TEditorTypes.EditorValueSetter(const TypeInfo: PTypeInfo): TEditorValueSetter;
begin
  Result  := fEditors[TypeInfo].SetValue
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

function TEditorTypes.GetEditor(const TypeInfo: PTypeInfo): TControlClass;
begin
  Result  := fEditors[TypeInfo].EditorClass
end;

function TEditorTypes.GetInfo(const Prop: TRttiProperty): TEditorInfo;
begin
  if  not EditorTypes.fEditors.TryGetValue(Prop.PropertyType.Handle, Result)  then
    Result  := nil;
end;

procedure TEditorTypes.Register(const TypeInfo: PTypeInfo;
  const EditorClass: TControlClass; const ChangeEventName: string;
  const GetEditValue: TEditorValueGetter;
  const SetEditValue: TEditorValueSetter);
var
  Info: TEditorInfo;
begin
  Info  := TEditorInfo.Create;
  try
    Info.EditorClass  := EditorClass;
    Info.GetValue  := GetEditValue;
    Info.SetValue  := SetEditValue;
    Info.Event := FindEvent(EditorClass, ChangeEventName);
  except
    Info.Free;
    raise;
  end;
  fEditorTypes.Add(Info);
  fEditors.AddOrSetValue(TypeInfo, Info);
end;

initialization
  EditorTypes := TEditorTypes.Create;
  RegisterStandardEditors;

finalization
  EditorTypes.Free;

end.
