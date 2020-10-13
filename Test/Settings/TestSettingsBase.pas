unit TestSettingsBase;

interface

uses
  System.SysUtils, DUnitX.TestFramework, BatSoft.Mementos,
  BatSoft.Settings, SettingsClasses;

type
  [TestFixture]
  TTestSettings<TReader, TWriter: TSettingsStore> = class abstract
  public
    const STestFileName = 'TestSettings.txt';
  protected
    procedure DeleteFile;
    procedure CompareAllSettings(const Settings1, Settings2: TAllTypes);
    procedure CompareCntnrs(const Settings1, Settings2: TCntrTypes);
    procedure CompareFloats(const Name: string; const Float1, Float2: Double);
    procedure CompareStrs(const Name: string; const Str1, Str2: string);
    procedure CompareWhens(const Name: string; const When1, When2: TDateTime);
    function  CreateStoreReader(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
    function  CreateStoreWriter(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
    function  FileName: string;
  public
    [Test]
    [TestCase('Test_SaveLoad_EnumsAsOrd', 'False')]
    [TestCase('Test_SaveLoad_EnumsAsStr', 'True')]
    procedure Test_SaveLoad(const EnumsAsStrings: Boolean);
    [Test]
    procedure Test_Repeat;
  end;

  ESettingsTest = class(Exception);

implementation

uses
  System.IOUtils;

{ TTestSettings<TReader, TWriter> }

procedure TTestSettings<TReader, TWriter>.CompareAllSettings(const Settings1, Settings2: TAllTypes);
var
  Changes: TChanges;
  i: integer;
begin
  Changes := TChanges.Create;
  try
    ListFieldDifferences('', Settings1, Settings2, Changes);
    //  Ignore these and test a lilttle further down
    Changes.Ignore('fComplex.fTestRec');
//    Changes.Ignore('fRecList');
    //  Do we have obvious changes?
    if  Changes.Count > 0 then
      raise ESettingsTest.Create('Failed with changes:' + sLineBreak + Changes.ToString);
  finally
    Changes.Free;
  end;
  //  Special cases that may fail due to rounding errors
  CompareFloats('Values.ValueExt',            Settings1.Simple.ValueExt,            Settings2.Simple.ValueExt);
  CompareWhens ('Values.DateTime',            Settings1.Simple.DateTime,            Settings2.Simple.DateTime);
  CompareWhens ('Values.Time',                Settings1.Simple.Time,                Settings2.Simple.Time);
  CompareStrs  ('Complex.ValueTestRec.Str',   Settings1.Complex.ValueTestRec.Str,   Settings2.Complex.ValueTestRec.Str);
  CompareWhens ('Complex.ValueTestRec.When',  Settings1.Complex.ValueTestRec.When,  Settings2.Complex.ValueTestRec.When);
//  Assert.AreEqual(Settings1.RecList.Count, Settings2.RecList.Count);
//  for i := 0 to Settings1.RecList.Count - 1 do
//    begin
//      CompareStrs ('RecList['+i.ToString+'].Str',   Settings1.RecList[i].Str,   Settings2.RecList[i].Str);
//      CompareWhens('RecList['+i.ToString+'].When',  Settings1.RecList[i].When,  Settings2.RecList[i].When);
//    end;
end;

procedure TTestSettings<TReader, TWriter>.CompareCntnrs(const Settings1, Settings2: TCntrTypes);
var
  Changes: TChanges;
begin
  Changes := TChanges.Create;
  try
    ListFieldDifferences('', Settings1, Settings2, Changes);
    if  Changes.Count > 0 then
      raise ESettingsTest.Create('Failed with changes:' + sLineBreak + Changes.ToString);
  finally
    Changes.Free;
  end;
end;

procedure TTestSettings<TReader, TWriter>.CompareFloats(const Name: string; const Float1, Float2: Double);
begin
  if  Float1.ToString <> Float2.ToString  then
    raise ESettingsTest.Create(Name + ': ' + Float1.ToString + ' -> ' + Float2.ToString);
end;

procedure TTestSettings<TReader, TWriter>.CompareStrs(const Name, Str1, Str2: string);
begin
  if  Str1 <> Str2  then
    raise ESettingsTest.Create(Name + ': ' + Str1 + ' -> ' + Str2);
end;

procedure TTestSettings<TReader, TWriter>.CompareWhens(const Name: string; const When1, When2: TDateTime);
var
  Hour1, Min1, Sec1, MSec1: Word;
  Hour2, Min2, Sec2, MSec2: Word;
begin
  DecodeTime(When1, Hour1, Min1, Sec1, MSec1);
  DecodeTime(When2, Hour2, Min2, Sec2, MSec2);
  if  (Trunc(When1) <> Trunc(When2)) or
      (Hour1 <> Hour2) or (Min1 <> Min2) or (Sec1 <> Sec2) or (MSec1 <> MSec2)
  then
    raise ESettingsTest.Create(Name + ': ' + DateTimeToStr(When1) + ' -> ' + DateTimeToStr(When2));
end;

function TTestSettings<TReader, TWriter>.CreateStoreReader(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
begin
  Result  := TReader.Create(AFileName, AEnumsAsStrings);
end;

function TTestSettings<TReader, TWriter>.CreateStoreWriter(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
begin
  Result  := TWriter.Create(AFileName, AEnumsAsStrings);
end;

procedure TTestSettings<TReader, TWriter>.DeleteFile;
begin
  if  TFile.Exists(FileName)  then
    TFile.Delete(FileName);
end;

function TTestSettings<TReader, TWriter>.FileName: string;
begin
  Result  := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + STestFileName
end;

procedure TTestSettings<TReader, TWriter>.Test_Repeat;
var
  Settings1, Settings2, Settings3: TCntrTypes;
begin
  DeleteFile;
  Settings1 := TCntrTypes.Create;
  Settings2 := TCntrTypes.Create;
  Settings3 := TCntrTypes.Create;
  try
    //  Save 1
    Settings1.Init1;
    TWriter.Save(Settings1, FileName, True);

    //  Save different
    Settings2.Init2;
    TWriter.Save(Settings2, FileName, True);

    //  Load...
    TReader.Load(Settings3, FileName, True);
    //  ...then test to see that invalid remnants of 1 don't remain
    CompareCntnrs(Settings2, Settings3);
  finally
    FreeAndNil(Settings1);
    FreeAndNil(Settings2);
    FreeAndNil(Settings3);
  end;
end;

procedure TTestSettings<TReader, TWriter>.Test_SaveLoad(const EnumsAsStrings: Boolean);
var
  Settings1, Settings2: TAllTypes;
  Snapshot: TMementoBackup;
begin
  //  Create empty settings
  Settings1 := TAllTypes.Create;
  Settings2 := TAllTypes.Create;
  Snapshot  := TBackupFields.Create(Settings1);
  try
    //  Populate settings
    Settings1.Init1;
    Snapshot.Backup;

    //  Save to file
    DeleteFile;
    TWriter.Save(Settings1, FileName, EnumsAsStrings);

    if  Snapshot.HasChanges then
      raise ESettingsTest.Create('Writer changed contents:' + sLineBreak + Snapshot.ChangesAsString);

    //  Load from file
    TReader.Load(Settings2, FileName, EnumsAsStrings);

    CompareAllSettings(Settings1, Settings2);
    //  Tidy up
  finally
    Snapshot.Free;
    FreeAndNil(Settings1);
    FreeAndNil(Settings2);
  end;
end;

end.
