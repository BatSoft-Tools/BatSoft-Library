unit BatSoft.StreamNet;

interface

uses
  SysUtils, Classes, RTTI, Generics.Collections;

type
  TMessageID    = UInt16;
  TMessage      = TObject;
  TMessageType  = class of TMessage;

  TMessageRegister = class
  private
    fRegisterIDType: TDictionary<TMessageID, TMessageType>;
    fRegisterTypeID: TDictionary<TMessageType, TMessageID>;
    procedure MessageToStream(const Message: TMessage; const Stream: TStream);
    function  StreamToMessage(const Stream: TStream): TMessage;
    function HasAttribute(const Attributes: TArray<TCustomAttribute>; const AttributeType: TClass): Boolean;
    function ObtainMessage(const MessageID: TMessageID): TMessage;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Register(const MessageID: TMessageID; const MessageType: TMessageType);
    function  MessageID(const MessageType: TMessageType): TMessageID;
    function  MessageType(const MessageID: TMessageID): TMessageType;
    function  Convert(const Message: TMessage): TBytes; overload;
    function  Convert(const Bytes: TBytes): TMessage; overload;
  end;

  IgnoreFieldAttribute = class(TCustomAttribute);

  IStreamNet = interface
    ['{0CF144F2-CFBB-457A-A7A0-AEE0C8943069}']
   end;

  EStreamNet = class(Exception);

var
  MessageRegister: TMessageRegister;

implementation

var
  RTTI: TRttiContext;

{ TMessageRegister }

function TMessageRegister.Convert(const Bytes: TBytes): TMessage;
var
  Stream: TBytesStream;
begin
  Stream  := TBytesStream.Create(Bytes);
  try
    Result  := StreamToMessage(Stream);
  finally
    Stream.Free;
  end;
end;

function TMessageRegister.Convert(const Message: TMessage): TBytes;
var
  Stream: TBytesStream;
begin
  Stream  := TBytesStream.Create;
  try
    MessageToStream(Message, Stream);
    Stream.Position := 0;
    Result := Stream.Bytes;
  finally
    Stream.Free;
  end;
end;

constructor TMessageRegister.Create;
begin
  inherited;
  fRegisterIDType := TDictionary<TMessageID, TMessageType>.Create();
  fRegisterTypeID := TDictionary<TMessageType, TMessageID>.Create();
  Register(0, nil);
end;

destructor TMessageRegister.Destroy;
begin
  fRegisterIDType.Free;
  fRegisterTypeID.Free;
  inherited;
end;

function TMessageRegister.HasAttribute(const Attributes: TArray<TCustomAttribute>; const AttributeType: TClass): Boolean;
var
  Attribute: TCustomAttribute;
begin
  Result  := True;
  for Attribute in Attributes do
    if Attribute is AttributeType then
      Exit;
  Result  := False;
end;

function TMessageRegister.MessageID(const MessageType: TMessageType): TMessageID;
begin
  if  not fRegisterTypeID.TryGetValue(MessageType, Result)  then
    raise EStreamNet.Create('MessageType ' + MessageType.ClassName + ' not registered.');
end;

procedure TMessageRegister.MessageToStream(const Message: TMessage; const Stream: TStream);

  procedure Write(const Stream: TStream; const Buffer; const Count: integer);
  begin
    if  Stream.Write(Buffer, Count) < Count then
      raise EStreamNet.Create('Failed to write correctly to stream.');
  end;

  procedure WriteOrdinal(const Value: UInt64; const TypeSize: integer);
  var
    Val8 : UInt8;
    Val16: UInt16;
    Val32: UInt32;
    Val64: UInt64;
  begin
    if TypeSize = 1 then
      begin
        Val8  := Value;
        Write(Stream, Val8, 1);
      end
    else if TypeSize = 2 then
      begin
        Val16 := Value;
        Write(Stream, Val16, 1);
      end
    else if TypeSize = 4 then
      begin
        Val32 := Value;
        Write(Stream, Val32, 1);
      end
    else if TypeSize = 8 then
      begin
        Val64 := Value;
        Write(Stream, Val64, 1);
      end
    else
      raise EStreamNet.Create('Strange byte count ' + TypeSize.ToString + '.');
  end;

  procedure WriteInteger(const Value: integer; const TypeSize: integer);
  begin
    Write(Stream, Value, TypeSize);
  end;

  procedure WriteInt64(const Value: UInt64);
  begin
    Write(Stream, Value, SizeOf(UInt64));
  end;

  procedure WriteExtended(const Value: Extended);
  begin
    Write(Stream, Value, SizeOf(Extended));
  end;

  procedure WriteString(const Value: string);
  var
    Bytes: RawByteString;
    Len: Integer;
  begin
    Bytes := UTF8Encode(Value);
    Len   := Length(Bytes);
    Write(Stream, Len, SizeOf(Integer));
    Write(Stream, Bytes, Len);
  end;

var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Value: TValue;
begin
  //  Write the MessageType (ie. ID of class)
  WriteInteger(MessageRegister.MessageID(Message.ClassType), SizeOf(TMessageID));
  //  Stream contents of Message
  Fields  := RTTI.GetType(Message.ClassType).GetFields;
  for Field in Fields do
    begin
      if HasAttribute(Field.GetAttributes, IgnoreFieldAttribute) then
        Continue;
      Value := Field.GetValue(Message);
      case Field.FieldType.TypeKind of
        tkInteger, tkEnumeration, tkSet :
          WriteInteger(Value.AsInteger, Field.FieldType.TypeSize);
        tkInt64 :
          WriteInt64(Value.AsUInt64);
        tkFloat :
          WriteExtended(Value.AsExtended);
        tkChar, tkWChar,
//          Write(Stream, Value.AsString[0], Field.FieldType.TypeSize);
        tkString, tkLString, tkWString, tkUString :
          WriteString(Value.AsString);
        tkClass :
          MessageToStream(Value.AsObject, Stream);
      else  //  tkMethod, tkVariant, tkArray, tkInterface, tkDynArray, tkClassRef, tkPointer, tkProcedure
//        tkRecord
//        tkMRecord
        raise EStreamNet.Create('Unhandleable field type ' + Field.FieldType.Name + ' for ' + Message.ClassName + '.' + Field.Name + '.');
      end;
    end;
end;

function TMessageRegister.MessageType(const MessageID: TMessageID): TMessageType;
begin
  if  not fRegisterIDType.TryGetValue(MessageID, Result)  then
    raise EStreamNet.Create('MessageID ' + MessageID.ToString + ' not registered.');
end;

function TMessageRegister.ObtainMessage(const MessageID: TMessageID): TMessage;
var
  MessageClass: TMessageType;
begin
  MessageClass  := MessageType(MessageID);
  if  not Assigned(MessageClass)  then
    Result  := nil
  else
    Result  := MessageClass.Create; { TODO : Incomplete! }
end;

procedure TMessageRegister.Register(const MessageID: TMessageID; const MessageType: TMessageType);

  function NameOfMessageType(): string;
  begin
    if  Assigned(MessageType) then
      Result  := MessageType.ClassName
    else
      Result  := 'nil'
  end;

begin
  if  fRegisterIDType.ContainsKey(MessageID)  then
    raise EStreamNet.Create('MessageID ' + MessageID.ToString + ' already registered as ' + NameOfMessageType + '.');
  fRegisterIDType.Add(MessageID, MessageType);
  fRegisterTypeID.Add(MessageType, MessageID);
end;

function TMessageRegister.StreamToMessage(const Stream: TStream): TMessage;

  function ReadString: string;
  var
    Len: integer;
    Bytes: RawByteString;
  begin
    Len := Stream.ReadData(Len, SizeOf(Integer));
    SetLength(Bytes, Len);
    if  Stream.Read(Bytes, Len) < Len then
      raise EStreamNet.Create('Failed to read correctly from stream.');
    Result  := UTF8ToWideString(Bytes)
  end;

var
  MessageID: TMessageID;
  Message: TMessage absolute Result;
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Value: TValue;
begin
  MessageID := Stream.ReadData(MessageID, SizeOf(TMessageID));
  Message   := ObtainMessage(MessageID);
  if  not Assigned(Message) then
    exit; //  Return nil
  Fields    := RTTI.GetType(Message.ClassType).GetFields;
  for Field in Fields do
    begin
      if HasAttribute(Field.GetAttributes, IgnoreFieldAttribute) then
        Continue;
      case Field.FieldType.TypeKind of
        tkInteger, tkEnumeration, tkSet :
          Value := Stream.ReadData(MessageID, Field.FieldType.TypeSize);
        tkInt64 :
          Value := Stream.ReadData(MessageID, Field.FieldType.TypeSize);
        tkFloat :
          Value := Stream.ReadData(MessageID, Field.FieldType.TypeSize);
        tkChar, tkWChar,
//          Write(Stream, Value.AsString[0], Field.FieldType.TypeSize);
        tkString, tkLString, tkWString, tkUString :
          Value := ReadString;
        tkClass :
          Value := StreamToMessage(Stream);
      else
        raise EStreamNet.Create('Unhandleable field type ' + Field.FieldType.Name + ' for ' + Message.ClassName + '.' + Field.Name + '.');
      end;
      Field.SetValue(Message, Value);
    end;
end;

initialization
  RTTI  := TRttiContext.Create;

finalization
  RTTI.Free;

end.
