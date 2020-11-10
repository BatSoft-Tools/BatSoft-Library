unit BatSoft.REST.Update;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  System.Classes, System.JSON, Generics.Collections, REST.Types, REST.Client;

type
  TStringEvent = procedure (Response: string) of object;

  TRESTUpdateJSON = class(TComponent)
  private
    fExcludeFields: TStringList;
    fIncludeFields: TStringList;
    fRESTRequest, fRESTUpdateRequest: TRESTRequest;
    fRESTUpdateResponse: TRESTResponse;
    fOnExamineResponse: TStringEvent;
    procedure SetExcludeFields(const Value: TStringList);
    procedure SetfIncludeFields(const Value: TStringList);
    procedure SetRESTRequest(const Value: TRESTRequest);
  private
    function  BuildPayload(const NewJSON: TJSONObject; const FullData: Boolean): string;
    procedure Send(const Method: TRESTRequestMethod; const JSONStr: string);
  public
    constructor Create(AOwner: TComponent); overload; override;
    destructor  Destroy; override;
    procedure Patch(const JSON: TJSONObject);
    procedure Post(const JSON: TJSONObject);
    procedure Put(const JSON: TJSONObject);
    property  InternalRequest   : TRESTRequest    read fRESTUpdateRequest;
    property  InternalResponse  : TRESTResponse   read fRESTUpdateResponse;
  published
    property  RESTRequest       : TRESTRequest    read fRESTRequest       write SetRESTRequest;
    property  ExcludeFields     : TStringList     read fExcludeFields     write SetExcludeFields;
    property  IncludeFields     : TStringList     read fIncludeFields     write SetfIncludeFields;
    property  OnExamineResponse : TStringEvent    read fOnExamineResponse write fOnExamineResponse;
  end;

function JSONToStr(const JSON: TJSONValue): string;

procedure Register();

implementation

uses
  SysUtils;

function JSONToStr(const JSON: TJSONValue): string;
//var
//  Builder: TStringBuilder;
begin
  Result  := JSON.ToString
//  Builder := TStringBuilder.Create;
//  try
//    JSON.ToChars(Builder);
//    Result  := Builder.ToString;
//  finally
//    Builder.Free;
//  end;
end;

procedure Register();
begin
  RegisterComponents('REST Client', [TRESTUpdateJSON]);
end;

{ TRESTUpdateJSON }

function TRESTUpdateJSON.BuildPayload(const NewJSON: TJSONObject; const FullData: Boolean): string;
var
  OldJSON, ResJSON: TJSONObject;
  Names: TStringList;
  Name: string;
  Pair: TJSONPair;

  function IsIn(const FieldNames: TStrings): Boolean;
  begin
    Result  := FieldNames.IndexOf(Name) >= 0
  end;

  function IsChanged: Boolean;
  var
    OldValue, NewValue: TJSONValue;
  begin
    OldValue  := OldJSON.GetValue(Name);
    NewValue  := NewJSON.GetValue(Name);
    Result    := not Assigned(OldValue) or (Assigned(NewValue) and ((NewValue is TJSONArray) or not SameStr(OldValue.Value, NewValue.Value)));
  end;

  function  UseValueFrom(const JSON: TJSONObject): Boolean;
  var
    ValJSON: TJSONValue;
  begin
    ValJSON := JSON.GetValue(Name);
    Result  := Assigned(ValJSON);
    if Result then
      ResJSON.AddPair(Name, ValJSON.Clone as TJSONValue);
  end;

begin
  OldJSON  := TJSONObject.ParseJSONValue(fRESTRequest.Response.Content) as TJSONObject;
  ResJSON := TJSONObject.Create;
  try
    //  Collect all names
    Names := TStringList.Create;
    try
      Names.Duplicates  := dupIgnore;
      Names.Sorted      := True;
      for Pair in OldJSON do
        Names.Add(Pair.JsonString.Value);
      for Pair in NewJSON do
        Names.Add(Pair.JsonString.Value);
      //  Pick values according to rules
      for Name in Names do
        if IsIn(fExcludeFields) then
          Continue
        else if FullData or IsIn(fIncludeFields) or IsChanged then
          if not UseValueFrom(NewJSON) then
            UseValueFrom(OldJSON);
      //  Generate payload
      Result  := JSONToStr(ResJSON);
      //  Done
    finally
      Names.Free;
    end;
  finally
    OldJSON.Free;
    ResJSON.Free;
  end;
end;

constructor TRESTUpdateJSON.Create(AOwner: TComponent);
begin
  inherited;
  fExcludeFields      := TStringList.Create;
  fIncludeFields      := TStringList.Create;
  fRESTUpdateResponse := TRESTResponse.Create(Self);
  fRESTUpdateRequest  := TRESTRequest.Create(Self);
  fRESTUpdateRequest.Response := fRESTUpdateResponse;
end;

destructor TRESTUpdateJSON.Destroy;
begin
  fRESTUpdateRequest.Free;
  fExcludeFields.Free;
  fIncludeFields.Free;
  inherited;
end;

procedure TRESTUpdateJSON.Patch(const JSON: TJSONObject);
begin
  Send(rmPATCH, BuildPayload(JSON, False));
end;

procedure TRESTUpdateJSON.Post(const JSON: TJSONObject);
begin
  Send(rmPOST, BuildPayload(JSON, True));
end;

procedure TRESTUpdateJSON.Put(const JSON: TJSONObject);
begin
  Send(rmPUT, BuildPayload(JSON, True));
end;

procedure TRESTUpdateJSON.Send(const Method: TRESTRequestMethod; const JSONStr: string);
var
  i: integer;
  ParamReq, ParamUpd: TRESTRequestParameter;
begin
  //  Copy params
  fRESTUpdateRequest.Params.Clear;
  for i := 0 to fRESTRequest.Params.Count - 1 do
    begin
      ParamReq  := fRESTRequest.Params[i];
      ParamUpd  := fRESTUpdateRequest.Params.AddItem;
      ParamUpd.Assign(ParamReq);
    end;
  //  Body param
  ParamUpd        := fRESTUpdateRequest.Params.AddItem;
  ParamUpd.Kind   := pkREQUESTBODY;
  ParamUpd.Value  := JSONStr;
  ParamUpd.ContentType  := ctAPPLICATION_JSON;
  //  Specify update type
  fRESTUpdateRequest.Client    := fRESTRequest.Client;
  fRESTUpdateRequest.Resource  := fRESTRequest.Resource;
  fRESTUpdateRequest.Method    := Method;
  //  Send to server
  fRESTUpdateRequest.Execute;
  //  Check for success/error
  if Assigned(fOnExamineResponse) then
    fOnExamineResponse(fRESTUpdateResponse.Content);
end;

procedure TRESTUpdateJSON.SetExcludeFields(const Value: TStringList);
begin
  fExcludeFields.Assign(Value);
end;

procedure TRESTUpdateJSON.SetfIncludeFields(const Value: TStringList);
begin
  fIncludeFields.Assign(Value);
end;

procedure TRESTUpdateJSON.SetRESTRequest(const Value: TRESTRequest);
begin
  fRESTRequest := Value;
end;

end.
