unit TestSettingsJSON;

interface

uses
  DUnitX.TestFramework, TestSettingsBase, BatSoft.Settings, BatSoft.Settings.JSON;

type
  [TestFixture]
  TTestSettingsJSON = class(TTestSettings<TSettingsJSONLoader, TSettingsJSONSaver>)
  end;

implementation

initialization
  TDUnitX.RegisterTestFixture(TTestSettingsJSON);

end.
