unit FSpinner;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Edit, FMX.StdCtrls, uSpinner, FMX.Controls.Presentation, FMX.EditBox,
  FMX.SpinBox;

type
  TfrmSpinner = class(TForm)
    Panel1: TPanel;
    butClose: TButton;
    edCount: TSpinBox;
    edHeight: TSpinBox;
    ScrollBox: TVertScrollBox;
    procedure butCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edCountChange(Sender: TObject);
    procedure edHeightChange(Sender: TObject);
    procedure SpinnerBeginPaint(Sender: TObject);
    procedure SpinnerEndPaint(Sender: TObject);
    function  SpinnerObtainItem(Sender: TListSpinner; Index: integer): TControl;
  private
    Spinner: TListSpinner;
  protected
    procedure Resize; override;
  end;

var
  frmSpinner: TfrmSpinner;

implementation

{$R *.fmx}

uses
  Generics.Collections;

type
  ItemFactory = class
  private
    class var fItems: TObjectList<TControl>;
    class var fObtained: TList<TControl>;
  public
    class constructor Create;
    class procedure BeginObtain;
    class function  Obtain(const Index: integer; const Owner: TComponent; const Parent: TFmxObject): TControl;
    class procedure EndObtain;
  end;

{ TfrmSpinner }

procedure TfrmSpinner.butCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSpinner.edCountChange(Sender: TObject);
begin
  Spinner.ItemCount  := Trunc(edCount.Value)
end;

procedure TfrmSpinner.edHeightChange(Sender: TObject);
begin
  Spinner.ItemHeight := Trunc(edHeight.Value)
end;

procedure TfrmSpinner.FormCreate(Sender: TObject);

  procedure AddButton(const X, Y: integer);
  var
    Button: TButton;
  begin
    Button  := TButton.Create(Self);
    Button.Parent := ScrollBox;
    Button.Position.Point := TPointF.Create(X, Y);
    Button.Width  := 50;
    Button.Height := 30;
    Button.Text := IntToStr(X) + ',' + IntToStr(Y);
  end;

begin
  Spinner  := TListSpinner.Create(Self);
  Spinner.Parent        := Self;
  Spinner.Align         := TAlignLayout.Client;
  Spinner.OnBeginPaint  := SpinnerBeginPaint;
  Spinner.OnObtainItem  := SpinnerObtainItem;
  Spinner.OnEndPaint    := SpinnerEndPaint;
  edCountChange(nil);
  edHeightChange(nil);

  AddButton(0,   0);
  AddButton(0,  40);
  AddButton(0,  80);
  AddButton(0, 120);
  AddButton(0, 160);
  AddButton(0, 200);
  AddButton(1000,    0);
  AddButton(   0, 1000);
  AddButton(1000, 1000);
end;

procedure TfrmSpinner.FormDestroy(Sender: TObject);
begin
  Spinner.Free;
end;

procedure TfrmSpinner.Resize;
begin
  inherited;
  ScrollBox.Height  := (Self.Height - Panel1.Height) / 2
end;

procedure TfrmSpinner.SpinnerBeginPaint(Sender: TObject);
begin
  ItemFactory.BeginObtain;
end;

procedure TfrmSpinner.SpinnerEndPaint(Sender: TObject);
begin
  ItemFactory.EndObtain;
end;

function TfrmSpinner.SpinnerObtainItem(Sender: TListSpinner; Index: integer): TControl;
begin
  Result  := ItemFactory.Obtain(Index, Self, Sender);
end;

{ ItemFactory }

class procedure ItemFactory.BeginObtain;
var
  i: integer;
begin
  for i := fObtained.Count - 1 downto 0 do
    begin
      fObtained[i].Visible  := False;
      fObtained[i].HitTest  := False;
    end;
  fObtained.Clear;
end;

class constructor ItemFactory.Create;
begin
  fItems    := TObjectList<TControl>.Create;
  fObtained := TList<TControl>.Create;
end;

class procedure ItemFactory.EndObtain;
begin

end;

class function ItemFactory.Obtain(const Index: integer; const Owner: TComponent; const Parent: TFmxObject): TControl;

  function Create0: TControl;
  var
    Button: TButton absolute Result;
  begin
    Button  := TButton.Create(Owner);
    Button.Text   := IntToStr(Index);
  end;

  function Create1: TControl;
  var
    Edit: TEdit absolute Result;
  begin
    Edit  := TEdit.Create(Owner);
    Edit.Text   := IntToStr(Index);
  end;

  function Create2: TControl;
  var
    Check: TCheckBox absolute Result;
  begin
    Check  := TCheckBox.Create(Owner);
    Check.Text   := IntToStr(Index);
  end;

  function CreatePanel(const Control: TControl): TControl;
  var
    Panel: TPanel absolute Result;
  begin
    Panel  := TPanel.Create(Owner);
    Panel.Parent := Parent;
    Control.Parent  := Panel;
    Control.Align   := TAlignLayout.Left;
    Result  := Panel;
    Control.HitTest := True;
    Panel.HitTest   := False;
  end;

begin
  if  Index < 0 then
    Exit(nil);
  if  fItems.Count <= Index then
    fItems.Count  := Index + 1;
  if  not Assigned(fItems[Index]) then
    case Index mod 3 of
      0 : fItems[Index] := CreatePanel(Create0);
      1 : fItems[Index] := CreatePanel(Create1);
      2 : fItems[Index] := CreatePanel(Create2);
    end;
  Result  := fItems[Index];
  Result.Visible  := True;
  fObtained.Add(Result);
end;

end.
