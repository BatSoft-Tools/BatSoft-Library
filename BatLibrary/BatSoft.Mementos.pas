unit BatSoft.Mementos;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

//  This unit contains four implementations of the Memento pattern:
//   - TBackupFields
//   - TBackupProperties
//   - TVersionsFields
//   - TVersionsProperties
//  The <Backup> classes hold only one backup of the originator, whereas
//  the <Versions> classes enable a multiple-version history of changes.
//  The <Fields> classes back up the originator's field values. Generally the best option.
//  The <Properties> classes back up the property values. Not advisable.
//
//  NOTE:  I'd advise you do NOT use the Properties mementos because of potentially
//         unknown consequenses when calling property getters and setters.
//
//  This implementation will compare the contents of records and arrays,
//  but NOT what they point to (such as string contents).
//
//  TChanges.ToString will not show *what* changes there are in records and arrays,
//  only *that* there are changes. If you would like more detail, then ask at:
//     peter@batsoft.com.au

interface

uses
  SysUtils, RTTI, Generics.Collections;

type
{$region 'Attributes'}

  /// Specifies backing up and comparing of sub-objects, rather than their pointers.
  /// (Does NOT apply to properties.)
  MementoDeep   = class(TCustomAttribute);

  /// Mementos will ignore this field/property.
  MementoIgnore = class(TCustomAttribute);

{$endregion}

{$region 'Changes'}

  TChange = record
  public
    Name: string;
    Original, Backup: TValue;
  end;

  TChanges = class(TList<TChange>)
  public
    function Ignore(const ChangeName: string): Boolean;
    function IndexOf(const Name: string): integer;
    function ToString: string; override;
  end;

{$endregion}

  /// Base class.  Don't instantiate this.
  TMemento = class abstract
    constructor Create(const AOriginator: TObject); virtual; abstract;
    procedure Backup; overload; virtual; abstract;
    procedure Restore; virtual; abstract;
    procedure ListChanges(const Changes: TChanges); virtual; abstract;
    function  HasChanges: Boolean; virtual; abstract;
    function  ChangesAsString: string;
  end;
  TMementoClass = class of TMemento;

{$region 'Single version backup'}

  /// Base class.  Don't instantiate this.
  TMementoBackup = class abstract (TMemento)
  private
    fOriginator: TObject;
    fMemento: TObject;
  private
    procedure CopyValues(const FromObj, ToObj: TObject); virtual; abstract;
  protected
    procedure ValidateBackup;
  public
    constructor Create(const AOriginator: TObject); override;
    destructor  Destroy; override;
    procedure Backup; override;
    procedure Restore; override;
  end;
  TMementoBackupClass = class of TMementoBackup;

  /// Single version memento of an object's internal values.
  TBackupFields = class(TMementoBackup)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

  /// Single version memento of an object's property values.
  TBackupProperties = class(TMementoBackup)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

{$endregion}

{$region 'Multiple version backup'}

  /// Base class.  Don't instantiate this.
  TMementoVersions = class abstract (TMemento)
  private type

    TMementos = class(TList<TObject>)
      Now: integer;
    end;

  private
    fOriginator: TObject;
    fMementos: TMementos;
    function  GetVersionMax: integer;
    function  GetVersionNow: integer;
    procedure CopyValues(const FromObj, ToObj: TObject); virtual; abstract;
    procedure ForgetFutureMementos;
    function  MementoNow: TObject;
    procedure SetVersionNow(const Value: integer);
  protected
    procedure ValidateBackup(const Version: integer);
  public
    constructor Create(const AOriginator: TObject); override;
    destructor  Destroy; override;
    procedure Backup; overload; override;
    procedure Backup(const EvenIfIdentical: Boolean); overload;
    procedure Restore; override;
    procedure Redo;
    procedure Undo;
    property  VersionMax: integer read GetVersionMax;
    property  VersionNow: integer read GetVersionNow  write SetVersionNow;
  end;
  TMementoVersionsClass = class of TMementoVersions;

  /// Multi-version memento of an object's internal values.
  TVersionsFields = class(TMementoVersions)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

  /// Multi-version memento of an object's property values.
  TVersionsProperties = class(TMementoVersions)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

{$endregion}

  EMemento = class(Exception);

resourcestring
  SErrorNotBackedUp = '%s object not backed up.';
  SErrorNoSnapshot  = '%s object does not have version %d.';
  SNullStrings      = 'Cannot assign a string value to a nil TStrings object.';
  SInvalidMethod    = 'Invalid method pointer';
  SIncomparableType = 'Incomparable type kind: %s';

function  SameValue(const Value1, Value2: TValue): Boolean;
procedure ListFieldDifferences(const FieldPrefix: string; const Object1, Object2: TObject; const Changes: TChanges);

implementation

uses
  Classes, TypInfo, BatSoft.Classes;

var
  Ctx: TRttiContext;

procedure RaiseNotBackedUp(const ClassTyp: TClass); inline;
begin
  raise EMemento.Create(Format(SErrorNotBackedUp, [ClassTyp.ClassName]));
end;

function DynamicArraySize(const DynArr: Pointer): Cardinal;
begin
  Result  := integer(Pointer(integer(DynArr)-4)^) * integer(Pointer(integer(DynArr)-8)^)
end;

function CopyDynamicArray(const Value: TValue): TValue;
var
  Arr: array of TValue;
  i, ArrLen: Integer;
begin
  if Value.IsEmpty then
    Exit(nil);
  //  Copy array
  ArrLen := Value.GetArrayLength;
  SetLength(Arr, ArrLen);
  for i := 0 to ArrLen - 1 do
    Arr[i]  := Value.GetArrayElement(i);
  //  Assign array
  Result  := TValue.FromArray(Value.TypeInfo, Arr);
end;

{ TChanges }

function ValueToStr(const Value: TValue): string;
const
  SNil  = 'nil';
var
  Method: TMethod;
  RTTIClass: TRttiType;
  RTTIMethods: TArray<TRttiMethod>;
  RTTIMethod: TRttiMethod;
begin
  if Value.TypeInfo = TypeInfo(TGUID) then
    Result  := Value.AsType<TGUID>().ToString
  else if Value.TypeInfo.Kind = tkMethod then
    try
      //  Obtain method
      Value.ExtractRawDataNoCopy(@Method);
      if  not Assigned(Method.Data) then
        Exit('nil');
      //  Obtain method name
      RTTIClass := Ctx.GetType(TObject(Method.Data).ClassType);
      RTTIMethods := RTTIClass.GetMethods;
      Result  := IntToHex(integer(Method.Code));
      for RTTIMethod in RTTIMethods do
        if  RTTIMethod.CodeAddress = Method.Code  then
          begin
            Result  := RTTIMethod.Name;
            break;
          end;
      //  Add class name
      Result  := TObject(Method.Data).ClassName + '(' + IntToHex(integer(Method.Data)) + ').' + Result + '()';
    except
      raise EMemento.Create(SInvalidMethod);
    end
  else
    Result  := Value.ToString
end;

function TChanges.Ignore(const ChangeName: string): Boolean;
var
  i: integer;
begin
  i := IndexOf(ChangeName);
  Result  := i >= 0;
  if  Result  then
    Delete(i);
end;

function TChanges.IndexOf(const Name: string): integer;
begin
  Result  := Count - 1;
  while (Result >= 0) and not SameText(Items[Result].Name, Name)  do
    dec(Result)
end;

function TChanges.ToString: string;
var
  Change: TChange;
  Strs: TStringList;
begin
  Strs  := TStringList.Create;
  try
    for Change in Self  do
      Strs.Add(Change.Name+': ' + ValueToStr(Change.Backup) +' -> ' + ValueToStr(Change.Original));
    Result  := Strs.Text
  finally
    Strs.Free;
  end;
end;

{ TMemento }

function TMemento.ChangesAsString: string;
var
  Changes: TChanges;
begin
  Changes := TChanges.Create;
  try
    ListChanges(Changes);
    Result  := Changes.ToString;
  finally
    Changes.Free;
  end;
end;

{$region 'RTTI utilities'}

function GetFields(const ClassTyp: TClass): TArray<TRttiField>;
var
  ClassRTTI: TRttiInstanceType;
begin
  ClassRTTI := Ctx.GetType(ClassTyp) as TRttiInstanceType;
  Result := ClassRTTI.GetFields;
end;

function GetProperties(const ClassTyp: TClass): TArray<TRttiProperty>;
var
  ClassRTTI: TRttiInstanceType;
begin
  ClassRTTI := Ctx.GetType(ClassTyp) as TRttiInstanceType;
  Result := ClassRTTI.GetProperties;
end;

function IgnoreField(const Field: TRttiField): Boolean; overload;
begin
  Result := Field.GetAttributes.Has<MementoIgnore>()
end;

function IgnoreProp(const Prop: TRttiProperty): Boolean; overload;
begin
  Result := Prop.GetAttributes.Has<MementoIgnore>()
end;

function IsDeepField(const Field: TRttiField): Boolean; overload;
begin
  Result := (Field.FieldType.TypeKind = tkClass) and Field.GetAttributes.Has<MementoDeep>()
end;

function IsDeepProp(const Prop: TRttiProperty): Boolean; overload;
begin
  Result := (Prop.PropertyType.TypeKind = tkClass) and Prop.GetAttributes.Has<MementoDeep>()
end;

{$region 'TStrings compatibility'}

function IsMementoStrs(const Field: TRttiType): Boolean;
begin
  Result  := (Field.TypeKind = tkClass) and
              Field.AsInstance.MetaclassType.InheritsFrom(TStrings)
end;

function GetMementoStrsAsStr(const Field: TRttiField; const Memento: TObject): string; overload;
var
  MementoStr: ^string;
begin
  MementoStr  := Pointer(integer(Memento) + Field.Offset);
  Result      := MementoStr^;
end;

procedure SetMementoStrsAsStr(const Field: TRttiField; const Memento: TObject; const Value: string);
var
  MementoStr: ^string;
begin
  MementoStr  := Pointer(integer(Memento) + Field.Offset);
  MementoStr^ := Value;
end;

procedure ClearMementoStrs(const Field: TRttiField; const Memento: TObject);
begin
  SetMementoStrsAsStr(Field, Memento, EmptyStr);
end;

function GetOriginatorStrsAsStr(const ValOrigin: TValue): string;
begin
  if  ValOrigin.IsEmpty then
    Result  := EmptyStr
  else
    Result  := (ValOrigin.AsObject as TStrings).Text
end;

procedure SetOriginatorStrsAsStr(const ValOrigin: TValue; const Value: string);
begin
  if  ValOrigin.IsEmpty then
    raise EMemento.Create(SNullStrings)
  else
    (ValOrigin.AsObject as TStrings).Text := Value
end;

{$endregion}

{$endregion}

{$region 'Memento memory management'}

function ObtainMemento(const ClassTyp: TClass): TObject;
begin
  GetMem(Pointer(Result), ClassTyp.InstanceSize);
  ClassTyp.InitInstance(Result);
end;

procedure ReleaseMemento(const Memento: TObject);

  procedure ReleaseDeep;
  var
    Fields: TArray<TRttiField>;
    Field: TRttiField;
    Value: TObject;
  begin
    Fields  := GetFields(Memento.ClassType);
    for Field in Fields do
      if  not IgnoreField(Field)  then
        //  Special free for TStrings objects because mementos store them as simple strings
        if  IsMementoStrs(Field.FieldType)  then
          ClearMementoStrs(Field, Memento)
        //  Free in depth
        else if  Field.GetAttributes.Has(MementoDeep) then
          begin
            Value := Field.GetValue(Memento).AsObject;
            ReleaseMemento(Value);
            Field.SetValue(Memento, nil);
          end
  end;

begin
  if Assigned(Memento) then
    begin
      ReleaseDeep;
      Memento.CleanupInstance;
      FreeMem(Pointer(Memento));
    end;
end;

{$endregion}

{$region 'Fields'}

procedure CopyFieldsToMemento(const Originator, Memento: TObject);
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  ValOriginator, ValMemento: TValue;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
    if  not IgnoreField(Field)  then
      begin
        ValOriginator := Field.GetValue(Originator);
        //  Special backup for TStrings objects
        if  IsMementoStrs(Field.FieldType)  then
          begin
            SetMementoStrsAsStr(Field, Memento, GetOriginatorStrsAsStr(ValOriginator));
            Continue;
          end;
        //  Might do deep backup
        if IsDeepField(Field) and not ValOriginator.IsEmpty then
          begin
            ValMemento := ObtainMemento(ValOriginator.AsObject.ClassType);
            Field.SetValue(Memento, ValMemento);
            CopyFieldsToMemento(ValOriginator.AsObject, ValMemento.AsObject);
          end
        //  Copy dynamic array
        else if Field.FieldType.TypeKind = tkDynArray then
          Field.SetValue(Memento, CopyDynamicArray(ValOriginator))
        //  Regular direct backup
        else
          Field.SetValue(Memento, ValOriginator);
      end;
end;

procedure CopyFieldsToOriginator(const Memento, Originator: TObject);
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  ValOriginator, ValMemento: TValue;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
    if  not IgnoreField(Field)  then
      begin
        ValOriginator := Field.GetValue(Originator);
        //  Special restore for TStrings objects
        if  IsMementoStrs(Field.FieldType)  then
          begin
            SetOriginatorStrsAsStr(ValOriginator, GetMementoStrsAsStr(Field, Memento));
            Continue;
          end;
        //  Might do deep restore
        ValMemento := Field.GetValue(Memento);
        if IsDeepField(Field) and not ValOriginator.IsEmpty and not ValMemento.IsEmpty then
          CopyFieldsToOriginator(ValMemento.AsObject, ValOriginator.AsObject)
        //  Regular direct restore
        else
          Field.SetValue(Originator, ValMemento);
      end;
end;

function SameValue(const Value1, Value2: TValue): Boolean;

  function  EnumSetToOrd(const Value: TValue): Int64;
  begin
    Result  := 0;
    Value.ExtractRawDataNoCopy(@Result);
  end;

var
  Data1, Data2: TBytes;
  DynArr1, DynArr2: Pointer;
begin
  if  Value1.TypeInfo.Kind <> Value2.TypeInfo.Kind  then
    Exit(False)
  else
    case Value1.TypeInfo.Kind of
      tkFloat :       Result  := Value1.AsExtended = Value2.AsExtended;

      tkInteger :     Result  := Value1.AsInteger = Value2.AsInteger;

      tkInt64 :       Result  := Value1.AsInt64 = Value2.AsInt64;

      tkEnumeration :
                      Result  := Value1.AsOrdinal = Value2.AsOrdinal;
      tkSet :
                      Result  := EnumSetToOrd(Value1) = EnumSetToOrd(Value2);

      tkChar :        Result  := Value1.AsString = Value2.AsString;

      tkString, tkWChar, tkLString, tkWString, tkUString :
                      Result  := Value1.AsString = Value2.AsString;

      tkClass :       Result  := Value1.AsObject = Value2.AsObject;
      tkClassRef :    Result  := Value1.AsClass = Value2.AsClass;
      tkPointer :     Result  := Value1.AsInteger = Value2.AsInteger;
      tkInterface :   Result  := Value1.AsInterface = Value2.AsInterface;
      tkVariant :     Result  := Value1.AsVariant = Value2.AsVariant;

      tkMethod, tkProcedure,
      tkArray,
      tkRecord, tkMRecord :
        if (Value1.TypeInfo <> Value2.TypeInfo) or (Value1.DataSize <> Value2.DataSize) then
          Result  := False
        else
          begin
            SetLength(Data1, Value1.DataSize);
            SetLength(Data2, Value2.DataSize);
            Value1.ExtractRawDataNoCopy(Data1);
            Value2.ExtractRawDataNoCopy(Data2);
            Result  := CompareMem(Data1, Data2, Value1.DataSize);
          end;

      tkDynArray :
        if  Value1.TypeInfo <> Value2.TypeInfo  then
          Result  := False
        else
          begin
            Value1.ExtractRawDataNoCopy(@DynArr1);
            Value2.ExtractRawDataNoCopy(@DynArr2);
            if DynamicArraySize(DynArr1) <> DynamicArraySize(DynArr2) then
              Result  := False
            else
              Result  := CompareMem(DynArr1, DynArr2, Value1.DataSize);
          end;

    else  //  tkUnknown
      raise EMemento.Create(Format(SIncomparableType, [GetEnumName(TypeInfo(TTypeKind), Ord(Value1.TypeInfo.Kind))]));
    end;
end;

function HasFieldChanges(const ClassTyp: TClass; const Originator, Memento: TObject): Boolean;
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  ValOriginator, ValMemento: TValue;
begin
  Result := False;
  Fields := GetFields(ClassTyp);
  for Field in Fields do
    if  not IgnoreField(Field)  then
      begin
        //  Compare TStrings
        ValOriginator := Field.GetValue(Originator);
        if  IsMementoStrs(Field.FieldType)  then
          begin
            ValOriginator := TValue.From(GetOriginatorStrsAsStr(ValOriginator));
            ValMemento := TValue.From(GetMementoStrsAsStr(Field, Memento));
            if  SameValue(ValOriginator, ValMemento) then
              Continue
            else
              Exit(True);
          end;
        //  Deep comparison
        ValMemento := Field.GetValue(Memento);
        if  IsDeepField(Field) and not ValOriginator.IsEmpty and not ValMemento.IsEmpty  then
          Exit(HasFieldChanges(ValOriginator.AsObject.ClassType, ValOriginator.AsObject, ValMemento.AsObject));
        //  Plain comparison
        if not SameValue(ValOriginator, ValMemento) then
          Exit(True)
      end;
end;

procedure ListFieldChanges(const FieldPrefix: string; const Originator, Memento: TObject; const Changes: TChanges);
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Change: TChange;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
    if  not IgnoreField(Field)  then
      begin
        Change.Name     := FieldPrefix + Field.Name;
        if  not Assigned(Field.FieldType) then
          Continue;
        //  Compare TStrings
        Change.Original := Field.GetValue(Originator);
        if  IsMementoStrs(Field.FieldType)  then
          begin
            Change.Original := TValue.From(GetOriginatorStrsAsStr(Change.Original));
            Change.Backup   := TValue.From(GetMementoStrsAsStr(Field, Memento));
            if  not SameValue(Change.Original, Change.Backup) then
              Changes.Add(Change);
            Continue;
          end;
        //  Deep comparison
        Change.Backup   := Field.GetValue(Memento);
        if  IsDeepField(Field) and
            not Change.Original.IsEmpty and not Change.Backup.IsEmpty
        then
          ListFieldChanges(FieldPrefix + Field.Name + '.', Change.Original.AsObject, Change.Backup.AsObject, Changes)
        //  Plain comparison
        else if not SameValue(Change.Original, Change.Backup) then
          Changes.Add(Change);
      end;
end;

procedure ListFieldDifferences(const FieldPrefix: string; const Object1, Object2: TObject; const Changes: TChanges);
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Change: TChange;
begin
  Fields := GetFields(Object1.ClassType);
  for Field in Fields do
    if  not IgnoreField(Field)  then
      begin
        Change.Name := FieldPrefix + Field.Name;
        if  not Assigned(Field.FieldType) then
          Continue;
        //  Compare TStrings
        if  IsMementoStrs(Field.FieldType)  then
          begin
            Change.Backup   := TValue.From(GetOriginatorStrsAsStr(Field.GetValue(Object1)));
            Change.Original := TValue.From(GetOriginatorStrsAsStr(Field.GetValue(Object2)));
            if  not SameValue(Change.Original, Change.Backup) then
              Changes.Add(Change);
            Continue;
          end;
        //  Deep comparison
        Change.Backup   := Field.GetValue(Object1);
        Change.Original := Field.GetValue(Object2);
        if  IsDeepField(Field) and
            not Change.Original.IsEmpty and not Change.Backup.IsEmpty
        then
          ListFieldDifferences(FieldPrefix + Field.Name + '.', Change.Original.AsObject, Change.Backup.AsObject, Changes)
        //  Plain comparison
        else if not SameValue(Change.Original, Change.Backup) then
          Changes.Add(Change);
      end;
end;

{$endregion}

{$region 'Properties'}

procedure CopyPropertyValues(const ClassTyp: TClass; const FromObj, ToObj: TObject);
var
  Props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
begin
  Props := GetProperties(ClassTyp);
  for Prop in Props do
    if Prop.IsReadable and Prop.IsWritable and not IgnoreProp(Prop) then
      Prop.SetValue(ToObj, Prop.GetValue(FromObj));
end;

function HasPropertyChanges(const ClassTyp: TClass; const Originator, Memento: TObject): Boolean;
var
  Props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
  Val1, Val2: TValue;
begin
  Result := False;
  Props := GetProperties(ClassTyp);
  for Prop in Props do
    if not IgnoreProp(Prop) then
      begin
        Val1 := Prop.GetValue(Originator);
        Val2 := Prop.GetValue(Memento);
        if not SameValue(Val1, Val2) then
          Exit(True)
      end;
end;

procedure ListPropertyChanges(const ClassTyp: TClass; const Originator, Memento: TObject; const Changes: TChanges);
var
  Props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
  Change: TChange;
begin
  Changes.Clear;
  Props := GetProperties(ClassTyp);
  for Prop in Props do
    if  Prop.IsReadable and not IgnoreProp(Prop)  then
      begin
        Change.Name     := Prop.Name;
        Change.Original := Prop.GetValue(Originator);
        Change.Backup   := Prop.GetValue(Memento);
        if not SameValue(Change.Original, Change.Backup) then
          Changes.Add(Change);
      end;
end;

{$endregion}

{$region 'Single version backup'}

{ TMementoBackup }

procedure TMementoBackup.Backup;
begin
  if not Assigned(fMemento) then
    fMemento := ObtainMemento(fOriginator.ClassType);
  CopyValues(fOriginator, fMemento);
end;

constructor TMementoBackup.Create(const AOriginator: TObject);
begin
  inherited;
  fOriginator := AOriginator;
end;

destructor TMementoBackup.Destroy;
begin
  ReleaseMemento(fMemento);
  inherited;
end;

procedure TMementoBackup.Restore;
begin
  ValidateBackup;
  CopyValues(fMemento, fOriginator);
end;

procedure TMementoBackup.ValidateBackup;
begin
  if not Assigned(fMemento) then
    RaiseNotBackedUp(fOriginator.ClassType);
end;

{ TBackupFields }

procedure TBackupFields.CopyValues(const FromObj, ToObj: TObject);
begin
  if FromObj = fOriginator then
    CopyFieldsToMemento(FromObj, ToObj)
  else
    CopyFieldsToOriginator(FromObj, ToObj)
end;

function TBackupFields.HasChanges: Boolean;
begin
  ValidateBackup;
  Result := HasFieldChanges(fOriginator.ClassType, fOriginator, fMemento)
end;

procedure TBackupFields.ListChanges(const Changes: TChanges);
begin
  ValidateBackup;
  ListFieldChanges('', fOriginator, fMemento, Changes);
end;

{ TBackupProperties }

procedure TBackupProperties.CopyValues(const FromObj, ToObj: TObject);
begin
  CopyPropertyValues(fOriginator.ClassType, FromObj, ToObj);
end;

function TBackupProperties.HasChanges: Boolean;
begin
  ValidateBackup;
  Result := HasPropertyChanges(fOriginator.ClassType, fOriginator, fMemento)
end;

procedure TBackupProperties.ListChanges(const Changes: TChanges);
begin
  ValidateBackup;
  ListPropertyChanges(fOriginator.ClassType, fOriginator, fMemento, Changes);
end;

{$endregion}

{$region 'Multiple version backup'}

{ TMementoVersions }

procedure TMementoVersions.Backup(const EvenIfIdentical: Boolean);
var
  DoingBackup: Boolean;
  Memento: TObject;
begin
  //  Determine whether to do backup
  if not Assigned(fMementos) or (fMementos.Count = 0) or EvenIfIdentical then
    DoingBackup := True
  else
    DoingBackup := HasChanges;
  if not DoingBackup then
    Exit;
  //  Prepare
  if not Assigned(fMementos) then
    fMementos := TMementos.Create;
  ForgetFutureMementos;
  //  Create memento
  Memento := ObtainMemento(fOriginator.ClassType);
  CopyValues(fOriginator, Memento);
  fMementos.Now := fMementos.Add(Memento) + 1;
end;

procedure TMementoVersions.Backup;
begin
  Backup(False)
end;

constructor TMementoVersions.Create(const AOriginator: TObject);
begin
  inherited;
  fOriginator := AOriginator;
end;

destructor TMementoVersions.Destroy;
begin
  if Assigned(fMementos) then
    begin
      fMementos.Now := 0;
      ForgetFutureMementos;
      fMementos.Free;
    end;
  inherited;
end;

procedure TMementoVersions.ForgetFutureMementos;
begin
  while VersionNow < VersionMax do
    begin
      ReleaseMemento(fMementos[fMementos.Count - 1]);
      fMementos.Delete(fMementos.Count - 1);
    end;
end;

function TMementoVersions.GetVersionMax: integer;
begin
  if Assigned(fMementos) then
    Result := fMementos.Count
  else
    Result := 0
end;

function TMementoVersions.GetVersionNow: integer;
begin
  if Assigned(fMementos) then
    Result := fMementos.Now
  else
    Result := 0
end;

function TMementoVersions.MementoNow: TObject;
begin
  Result := fMementos[VersionNow - 1]
end;

procedure TMementoVersions.Redo;
begin
  ValidateBackup(VersionNow + 1);
  inc(fMementos.Now);
  CopyValues(MementoNow, fOriginator);
end;

procedure TMementoVersions.Restore;
begin
  ValidateBackup(VersionNow);
  CopyValues(MementoNow, fOriginator);
end;

procedure TMementoVersions.SetVersionNow(const Value: integer);
begin
  ValidateBackup(Value);
  fMementos.Now := Value;
  CopyValues(MementoNow, fOriginator);
end;

procedure TMementoVersions.Undo;
begin
  ValidateBackup(VersionNow - 1);
  dec(fMementos.Now);
  CopyValues(MementoNow, fOriginator);
end;

procedure TMementoVersions.ValidateBackup(const Version: integer);
begin
  if not Assigned(fMementos) then
    RaiseNotBackedUp(fOriginator.ClassType);
  if (Version < 1) or (VersionMax < Version) then
    raise EMemento.Create(Format(SErrorNoSnapshot, [fOriginator.ClassName, Version]));
end;

{ TVersionsFields }

procedure TVersionsFields.CopyValues(const FromObj, ToObj: TObject);
begin
  if FromObj = fOriginator then
    CopyFieldsToMemento(FromObj, ToObj)
  else
    CopyFieldsToOriginator(FromObj, ToObj)
end;

function TVersionsFields.HasChanges: Boolean;
begin
  ValidateBackup(VersionNow);
  Result := HasFieldChanges(fOriginator.ClassType, fOriginator, MementoNow)
end;

procedure TVersionsFields.ListChanges(const Changes: TChanges);
begin
  Changes.Clear;
  ValidateBackup(VersionNow);
  ListFieldChanges('', fOriginator, MementoNow, Changes);
end;

{ TVersionsProperties }

procedure TVersionsProperties.CopyValues(const FromObj, ToObj: TObject);
begin
  CopyPropertyValues(fOriginator.ClassType, FromObj, ToObj);
end;

function TVersionsProperties.HasChanges: Boolean;
begin
  ValidateBackup(VersionNow);
  Result := HasPropertyChanges(fOriginator.ClassType, fOriginator, MementoNow)
end;

procedure TVersionsProperties.ListChanges(const Changes: TChanges);
begin
  ValidateBackup(VersionNow);
  ListPropertyChanges(fOriginator.ClassType, fOriginator, MementoNow, Changes);
end;

{$endregion}

initialization
  Ctx := TRttiContext.Create;

finalization
  Ctx.Free;

end.
