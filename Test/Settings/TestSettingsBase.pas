unit TestSettingsBase;

interface

uses
  System.SysUtils, DUnitX.TestFramework, BatSoft.Settings, SettingsClasses;

type
  [TestFixture]
  TTestSettings<TReader, TWriter: TSettingsStore> = class abstract
  public
    const STestFileName = 'TestSettings.txt';
  protected
    procedure CompareFloats(const Name: string; const Float1, Float2: Double);
    procedure CompareWhens(const Name: string; const When1, When2: TDateTime);
    function  CreateStoreReader(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
    function  CreateStoreWriter(const AFileName: string; const AEnumsAsStrings: Boolean): TSettingsStore;
    function  FileName: string;
  public
//    [Setup]
//    procedure Setup;
//    [TearDown]
//    procedure TearDown;
    [Test]
    [TestCase('Test_SaveLoad_EnumsAsOrd', 'False')]
    [TestCase('Test_SaveLoad_EnumsAsStr', 'True')]
    procedure Test_SaveLoad(const EnumsAsStrings: Boolean);
  end;

  ESettingsTest = class(Exception);

implementation

uses
  System.IOUtils, BatSoft.Mementos;

{ TTestSettings<TReader, TWriter> }

procedure TTestSettings<TReader, TWriter>.CompareFloats(const Name: string; const Float1, Float2: Double);
begin
  if  Float1.ToString <> Float2.ToString  then
    raise ESettingsTest.Create(Name + ': ' + Float1.ToString + ' -> ' + Float2.ToString);
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

function TTestSettings<TReader, TWriter>.FileName: string;
begin
  Result  := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + STestFileName
end;

procedure TTestSettings<TReader, TWriter>.Test_SaveLoad(const EnumsAsStrings: Boolean);
var
  Settings1, Settings2: TAllTypes;
  Snapshot: TMementoBackup;
  Changes: TChanges;
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
    if  TFile.Exists(FileName)  then
      TFile.Delete(FileName);
    TWriter.Save(Settings1, FileName, EnumsAsStrings);

    if  Snapshot.HasChanges then
      raise ESettingsTest.Create('Writer changed contents:' + sLineBreak + Snapshot.ChangesAsString);

    //  Load from file
    TReader.Load(Settings2, FileName, EnumsAsStrings);

    Changes := TChanges.Create;
    try
      ListFieldDifferences('', Settings1, Settings2, Changes);
      if  Changes.Count > 0 then
        raise ESettingsTest.Create('Failed with changes:' + sLineBreak + Changes.ToString);
      //  Special cases that may fail due to rounding errors
      CompareFloats('Values.ValueExt',  Settings1.Values.ValueExt,    Settings2.Values.ValueExt);
      CompareWhens ('Values.DateTime',  Settings1.Values.DateTime,    Settings2.Values.DateTime);
      CompareWhens ('Values.Date',      Trunc(Settings1.Values.Date), Trunc(Settings2.Values.Date));
      CompareWhens ('Values.Time',      Frac(Settings1.Values.Time),  Frac(Settings2.Values.Time));
    finally
      Changes.Free;
    end;

    //  Tidy up
  finally
    Snapshot.Free;
    FreeAndNil(Settings1);
    FreeAndNil(Settings2);
  end;
end;

end.
