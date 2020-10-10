unit TestSettingsIni;

interface

uses
  DUnitX.TestFramework, TestSettingsBase, BatSoft.Settings, BatSoft.Settings.Ini;

type
  [TestFixture]
  TTestSettingsIni = class(TTestSettings<TSettingsIniLoader, TSettingsIniSaver>);

implementation

initialization
  TDUnitX.RegisterTestFixture(TTestSettingsIni);

end.
