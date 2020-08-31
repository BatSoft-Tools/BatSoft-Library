unit BatSoft.Mementos;

interface

uses
  SysUtils, RTTI, Generics.Collections;

type
  TChange = record
  public
    Name: string;
    Original, Backup: TValue;
  end;

  TChanges = class(TList<TChange>)
  public
    function ToString: string; override;
  end;

  TMemento = class abstract
    constructor Create(const AOriginator: TObject); virtual; abstract;
    procedure Backup; overload; virtual; abstract;
    procedure Restore; virtual; abstract;
    procedure ListChanges(const Changes: TChanges); virtual; abstract;
    function  HasChanges: Boolean; virtual; abstract;
  end;
  TMementoClass = class of TMemento;

{$region 'Single version backup'}

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

  TBackupFields = class(TMementoBackup)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

  TBackupProperties = class(TMementoBackup)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

{$endregion}

{$region 'Multiple version backup'}

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
    property  VersionNow: integer read GetVersionNow;
  end;
  TMementoVersionsClass = class of TMementoVersions;

  TVersionsFields = class(TMementoVersions)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

  TVersionsProperties = class(TMementoVersions)
  private
    procedure CopyValues(const FromObj, ToObj: TObject); override;
  public
    procedure ListChanges(const Changes: TChanges); override;
    function  HasChanges: Boolean; override;
  end;

{$endregion}

{$region 'Attributes'}

  MementoDeepField = class(TCustomAttribute);

{$endregion}

  EMemento = class(Exception);

resourcestring
  SErrorNotBackedUp = '%s object not backed up.';
  SErrorNoSnapshot  = '%s object does not have version %d.';
  SNullStrings      = 'Cannot assign a string value to a nil TStrings object.';

procedure ListFieldChanges(const FieldPrefix: string; const Originator, Memento: TObject; const Changes: TChanges);

implementation

uses
  Classes, Delphi.Mocks.Helpers, BatSoft.Classes;

var
  Ctx: TRttiContext;

procedure RaiseNotBackedUp(const ClassTyp: TClass); inline;
begin
  raise EMemento.Create(Format(SErrorNotBackedUp, [ClassTyp.ClassName]));
end;

{ TChanges }

function TChanges.ToString: string;
var
  Change: TChange;
  Strs: TStringList;
begin
  Strs    := TStringList.Create;
  try
    for Change in Self  do
      Strs.Add(Change.Name+': '+Change.Backup.ToString+' -> '+Change.Original.ToString);
    Result  := Strs.Text
  finally
    Strs.Free;
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

function IsDeepField(const Field: TRttiField): Boolean; overload;
begin
  Result := (Field.FieldType.TypeKind = tkClass) and TCustomAttribute.HasAttribute<MementoDeepField>(Field.GetAttributes)
end;

function IsDeepField(const Field: TRttiProperty): Boolean; overload;
begin
  Result := (Field.PropertyType.TypeKind = tkClass) and TCustomAttribute.HasAttribute<MementoDeepField>(Field.GetAttributes)
end;

{$region 'TStrings compatibility'}

function IsMementoStrs(const Field: TRttiType): Boolean;
begin
  Result  := (Field.TypeKind = tkClass) and
              Field.AsInstance.MetaclassType.InheritsFrom(TStrings)
end;

function GetMementoStrsAsStr(const Field: TRttiField; const Memento: TObject): string;
var
  StrBackup: PString;
begin
  StrBackup := Pointer(integer(Memento) + Field.Offset);
  Result    := StrBackup^;
end;

procedure SetMementoStrsAsStr(const Field: TRttiField; const Memento: TObject; const Value: string);
var
  StrBackup: PString;
begin
  StrBackup   := Pointer(integer(Memento) + Field.Offset);
  StrBackup^  := Value;
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
      //  Special free for TStrings objects because mementos store them as simple strings
      if  IsMementoStrs(Field.FieldType)  then
        ClearMementoStrs(Field, Memento)
      //  Free in depth
      else if  TCustomAttribute.HasAttribute(Field.GetAttributes, MementoDeepField) then
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
  ValOrigin, ValBackup: TValue;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
    begin
      ValOrigin := Field.GetValue(Originator);
      //  Special backup for TStrings objects
      if  IsMementoStrs(Field.FieldType)  then
        begin
          SetMementoStrsAsStr(Field, Memento, GetOriginatorStrsAsStr(ValOrigin));
          Continue;
        end;
      //  Might do deep backup
      if IsDeepField(Field) and not ValOrigin.IsEmpty then
        begin
          ValBackup := ObtainMemento(ValOrigin.AsObject.ClassType);
          Field.SetValue(Memento, ValBackup);
          CopyFieldsToMemento(ValOrigin.AsObject, ValBackup.AsObject);
        end
      //  Regular direct backup
      else
        Field.SetValue(Memento, ValOrigin);
    end;
end;

procedure CopyFieldsToOriginator(const Memento, Originator: TObject);
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  ValOrigin, ValBackup: TValue;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
    begin
      ValOrigin := Field.GetValue(Originator);
      //  Special restore for TStrings objects
      if  IsMementoStrs(Field.FieldType)  then
        begin
          SetOriginatorStrsAsStr(ValOrigin, GetMementoStrsAsStr(Field, Memento));
          Continue;
        end;
      //  Might do deep restore
      ValBackup := Field.GetValue(Memento);
      if IsDeepField(Field) and not ValOrigin.IsEmpty and not ValBackup.IsEmpty then
        CopyFieldsToOriginator(ValBackup.AsObject, ValOrigin.AsObject)
      //  Regular direct restore
      else
        Field.SetValue(Originator, ValBackup);
    end;
end;

function SameValue(const Value1, Value2: TValue): Boolean; inline;
begin
  Result  := Value1.Equals(Value2)
end;

function HasFieldChanges(const ClassTyp: TClass; const Originator, Memento: TObject): Boolean;
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  ValOrigin, ValBackup: TValue;
begin
  Result := False;
  Fields := GetFields(ClassTyp);
  for Field in Fields do
    begin
      //  Compare TStrings
      ValOrigin := Field.GetValue(Originator);
      if  IsMementoStrs(Field.FieldType)  then
        begin
          ValOrigin := TValue.From(GetOriginatorStrsAsStr(ValOrigin));
          ValBackup := TValue.From(GetMementoStrsAsStr(Field, Memento));
          if  SameValue(ValOrigin, ValBackup) then
            Continue
          else
            Exit(True);
        end;
      //  Deep comparison
      ValBackup := Field.GetValue(Memento);
      if  IsDeepField(Field) and not ValOrigin.IsEmpty and not ValBackup.IsEmpty  then
        Exit(HasFieldChanges(ValOrigin.AsObject.ClassType, ValOrigin.AsObject, ValBackup.AsObject));
      //  Plain comparison
      if not SameValue(ValOrigin, ValBackup) then
        Exit(True)
    end;
end;

procedure ListFieldChanges(const FieldPrefix: string; const Originator, Memento: TObject; const Changes: TChanges);
const
  ValueTypeKinds = [tkInteger, tkInt64, tkEnumeration, tkSet, tkFloat, tkClass,
      tkString, tkLString, tkWString, tkUString, tkWChar, tkChar, tkInterface,
      tkClassRef, tkPointer, tkVariant];
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Change: TChange;
begin
  Fields := GetFields(Originator.ClassType);
  for Field in Fields do
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
      //  Ignore un-comparable fields
      else if not (Change.Original.Kind in ValueTypeKinds) or not (Change.Backup.Kind in ValueTypeKinds) then

      //  Plain comparison
      else if not SameValue(Change.Original, Change.Backup) then
        Changes.Add(Change);
    end;
end;

{$endregion}

{$region 'Properties'}

procedure CopyPropertyValues(const ClassTyp: TClass; const FromObj, ToObj: TObject);
var
  Fields: TArray<TRttiProperty>;
  Field: TRttiProperty;
begin
  Fields := GetProperties(ClassTyp);
  for Field in Fields do
    if Field.IsReadable and Field.IsWritable then
      Field.SetValue(ToObj, Field.GetValue(FromObj));
end;

function HasPropertyChanges(const ClassTyp: TClass; const Originator, Memento: TObject): Boolean;
//var
//  Fields: TArray<TRttiProperty>;
//  Field: TRttiProperty;
//  ValOrigin, ValBackup: TValue;
//begin
//  Result := False;
//  Fields := GetProperties(ClassTyp);
//  for Field in Fields do
//    begin
//      //  Compare TStrings
//      ValOrigin := Field.GetValue(Originator);
//      if  IsMementoStrs(Field.PropertyType)  then
//        begin
//          ValOrigin := TValue.From(GetOriginatorStrsAsStr(ValOrigin));
//          ValBackup := TValue.From(GetMementoStrsAsStr(Field, Memento));
//          if  SameValue(ValOrigin, ValBackup) then
//            Continue
//          else
//            Exit(True);
//        end;
//      //  Deep comparison
//      ValBackup := Field.GetValue(Memento);
//      if  IsDeepField(Field) and not ValOrigin.IsEmpty and not ValBackup.IsEmpty  then
//        Exit(HasFieldChanges(ValOrigin.AsObject.ClassType, ValOrigin.AsObject, ValBackup.AsObject));
//      //  Plain comparison
//      if not SameValue(ValOrigin, ValBackup) then
//        Exit(True)
//    end;
//end;
var
  Fields: TArray<TRttiProperty>;
  Field: TRttiProperty;
  Val1, Val2: TValue;
begin
  Result := False;
  Fields := GetProperties(ClassTyp);
  for Field in Fields do
    begin
      Val1 := Field.GetValue(Originator);
      Val2 := Field.GetValue(Memento);
      if not SameValue(Val1, Val2) then
        Exit(True)
    end;
end;

procedure ListPropertyChanges(const ClassTyp: TClass; const Obj, Memento: TObject; const Changes: TChanges);
var
  Fields: TArray<TRttiProperty>;
  Field: TRttiProperty;
  Change: TChange;
begin
  Changes.Clear;
  Fields := GetProperties(ClassTyp);
  for Field in Fields do
    begin
      Change.Name     := Field.Name;
      Change.Original := Field.GetValue(Obj);
      Change.Backup   := Field.GetValue(Memento);
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
