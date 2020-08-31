unit BatSoft.Settings.Ini;

interface

uses
  System.Rtti, BatSoft.Settings;

type
  TSettingsStoreIni = class(TInterfacedObject, ISettingsStore)
  public
    //  ISettingsStore interface
    procedure LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
    procedure SaveFile(const Settings: TObject; const FileName: string);
  end;

  SettingsIni = class
  public
    class procedure LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
    class procedure SaveFile(const Settings: TObject; const FileName: string);
  end;

  ESettingsIni = class(ESettings);

implementation

uses
  System.TypInfo, System.IniFiles, System.Classes;

const
  SClass  = 'Class';

type
  TIniPath = type string;

  TIniPathHelper = record helper for TIniPath
  private const
    CDiv = '/';
  public
    function Add(const Name: string): TIniPath;
  end;

{ TIniPathHelper }

function TIniPathHelper.Add(const Name: string): TIniPath;
begin
  Result  := Self + CDiv + Name
end;

{ TSettingsStoreIni }

procedure TSettingsStoreIni.LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
var
  IniFile: TIniFile;
  RTTI: TRttiContext;

  procedure IniToSett(const SettObj: TObject; const Section: TIniPath);

    procedure ObtainChild(const Prop: TRttiProperty; var ChildObj: TObject);
    var
      ChildClassName: string;
      ChildClass: TRttiType;
    begin
      //  If object does not exist, then create it
      if  not Assigned(ChildObj)  then
        begin
          //  Determine class
          if  IniFile.ValueExists(Section, Prop.Name) then
            begin
              ChildClassName  := IniFile.ReadString(Section, Prop.Name, '');
              ChildClass      := RTTI.FindType(ChildClassName);
              if  not Assigned(ChildClass)  then
                raise ESettingsIni.Create('Class '''+ChildClassName+''' not found.');
            end
          else
            ChildClass  := Prop.PropertyType;
          //  Create object
          ChildObj  := ChildClass.AsInstance.MetaclassType.Create;
          Prop.SetValue(SettObj, ChildObj);
        end;
    end;

    procedure LoadStrings(const Strs: TStrings);
    var
      ChildSection: TIniPath;
      ChildClassName: string;
      ChildClass: TRttiType;
      ChildObj: TObject;
      ChildSections: TStringList;
    begin
      if  ClearValues then
        Strs.Clear;
      //  Read values
      ChildSections := TStringList.Create;
      try
        IniFile.ReadSections(Section, ChildSections);
        for ChildSection in ChildSections do
          begin
            //  Determine class
            if  IniFile.ValueExists(ChildSection, SClass) then
              begin
                ChildClassName  := IniFile.ReadString(ChildSection, SClass, '');
                ChildClass  := RTTI.FindType(ChildClassName);
                if  not Assigned(ChildClass)  then
                  raise ESettingsIni.Create('Class '''+ChildClassName+''' not found.');
                //  Create child object
                ChildObj  := ChildClass.AsInstance.MetaclassType.Create;
                Strs.AddObject(ChildSection, ChildObj);
                //  Recurse loading settings
                IniToSett(ChildObj, ChildSection);
              end;
          end;
      finally
        ChildSections.Free;
      end;
    end;

  var
    RTTIType: TRttiType;
    Props: TArray<TRttiProperty>;
    Prop: TRttiProperty;
    i: integer;
    Child: TObject;
    ClassValue: TRttiType;
    ValueAsString: string;
  begin
    //  Run through each published property
    RTTIType  := RTTI.GetType(SettObj.ClassType);
    Props := RTTIType.GetProperties;
    Props := SortAndFilter(Props, False);
    for i := 0 to Length(Props) - 1 do
      begin
        Prop  := Props[i];
        if  Prop.Visibility = TMemberVisibility.mvPublished then
          begin
            if  IniFile.SectionExists(Section) and (Prop.IsWritable or (Prop.PropertyType.TypeKind = tkClass))  then
              begin
                ValueAsString := IniFile.ReadString(Section, Prop.Name, Prop.GetValue(SettObj).AsString);
                case Prop.PropertyType.TypeKind of
                  tkInteger :     Prop.SetValue(SettObj, IniFile.ReadInteger(Section, Prop.Name, Prop.GetValue(SettObj).AsInteger));
                  tkInt64 :       raise ESettingsIni.Create(ClassName+' does not support Int64.');
                  tkFloat :       Prop.SetValue(SettObj, IniFile.ReadFloat(Section, Prop.Name, Prop.GetValue(SettObj).AsInteger));
                  tkEnumeration : SetEnumProp(SettObj, Prop.Name, IniFile.ReadString(Section, Prop.Name, GetEnumProp(SettObj, Prop.Name)));
                  tkSet :         SetSetProp(SettObj, Prop.Name, IniFile.ReadString(Section, Prop.Name, GetSetProp(SettObj, Prop.Name)));
                  tkChar, tkWChar, tkString, tkLString, tkWString, tkUString, tkVariant :
                                  Prop.SetValue(SettObj, ValueAsString);
                  tkClassRef :
                    begin
                      ClassValue  := RTTI.FindType(ValueAsString);
                      if  not Assigned(ClassValue)  then
                        raise ESettingsIni.Create('Class '+ValueAsString+' not found.');
                      if  ClassValue.TypeKind <> tkClass then
                        raise ESettingsIni.Create('Type '+ValueAsString+' is not a class.');
                      Prop.SetValue(SettObj, TClass((ClassValue as TRttiInstanceType).MetaclassType));
                    end;
                  tkClass :
                    begin
                      //  Try to get hold of a child object
                      Child := Prop.GetValue(SettObj).AsObject;
                      if  not Assigned(Child) and Prop.IsWritable then
                        ObtainChild(Prop, Child);
                      //  Recurse
                      if  Assigned(Child) then
                        IniToSett(Child, Section.Add(Prop.Name));
                    end;
                else raise ESettingsIni.Create('Property '+Prop.Name+' cannot be loaded because it is of type '+Prop.PropertyType.Name+'.');
                end;
              end
            else if ClearValues then
              begin
                  case Prop.PropertyType.TypeKind of
                    tkInteger, tkInt64, tkFloat,
                    tkEnumeration, tkSet,
                    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString,
                    tkVariant, tkClassRef :
                      Prop.SetValue(SettObj, TValue.Empty);
                    tkClass :
                      begin
                        Prop.GetValue(SettObj).AsObject.Free;
                        Prop.SetValue(SettObj, nil);
                      end;
                  end;
              end;
          end;
      end;
    //  Load objects if this is a TStrings object
    if  SettObj is TStrings then
      LoadStrings(SettObj as TStrings);
  end;

begin
  //  Set up
  RTTI.Create;
  try
    //  Load the .ini file
    IniFile := TIniFile.Create(FileName);
    try
      IniToSett(Settings, '/');
    finally
      IniFile.Free;
    end;
  finally
    RTTI.Free;
  end;
end;

procedure TSettingsStoreIni.SaveFile(const Settings: TObject; const FileName: string);
var
  IniFile: TIniFile;
  RTTI: TRttiContext;

  procedure SettToIni(const SettObj: TObject; const ExpectedClass: TClass; const Section: TIniPath);
  var
    RTTIType: TRttiType;
    Props: TArray<TRttiProperty>;
    Prop: TRttiProperty;

    procedure SaveStrings(const Strings: TStrings);
    var
      i: integer;
    begin
      for i := 0 to Strings.Count - 1 do
        SettToIni(Strings.Objects[i], nil, Section.Add(Strings[i]));
    end;

  var
    i: integer;
  begin
    //  Don't save nil
    if  not Assigned(SettObj) then
      Exit;
    //  Might have to specify the class
    if  SettObj.ClassType <> ExpectedClass  then
      IniFile.WriteString(Section, SClass, SettObj.QualifiedClassName);
    //  Run through each published property
    RTTIType  := RTTI.GetType(SettObj.ClassType);
    Props := SortAndFilter(RTTIType.GetProperties, True);
    for i := 0 to Length(Props) - 1 do
      begin
        Prop  := Props[i];
        if  (Prop.Visibility = TMemberVisibility.mvPublished) and Prop.IsReadable then
          case Prop.PropertyType.TypeKind of
            tkInteger :     IniFile.WriteInteger(Section, Prop.Name, Prop.GetValue(SettObj).AsInteger);
            tkInt64 :       raise ESettingsIni.Create(ClassName+' does not support Int64.');
            tkFloat :       IniFile.WriteFloat(Section, Prop.Name, Prop.GetValue(SettObj).AsExtended);
            tkEnumeration : IniFile.WriteString(Section, Prop.Name, GetEnumProp(SettObj, Prop.Name));
            tkSet :         IniFile.WriteString(Section, Prop.Name, GetSetProp(SettObj, Prop.Name));
            tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
                            IniFile.WriteString(Section, Prop.Name, Prop.GetValue(SettObj).AsString);
            tkVariant :     IniFile.WriteString(Section, Prop.Name, Prop.GetValue(SettObj).AsVariant);
            tkClassRef :    IniFile.WriteString(Section, Prop.Name, Prop.GetValue(SettObj).AsClass.QualifiedClassName);
            tkClass :       SettToIni(Prop.GetValue(SettObj).AsObject, Prop.PropertyType.AsInstance.MetaclassType, Section.Add(Prop.Name));
          else raise ESettingsIni.Create('Property '+Prop.Name+' cannot be saved because it is of type '+Prop.PropertyType.Name+'.');
          end;
      end;
    //  Save TStrings
    if  SettObj is TStrings then
      SaveStrings(SettObj as TStrings);
  end;

begin
  //  Set up
  RTTI.Create;
  try
    //  Generate the Ini structure
    IniFile := TIniFile.Create(FileName);
    try
      SettToIni(Settings, Settings.ClassType, '/');
    finally
      IniFile.Free;
    end;
  finally
    RTTI.Free;
  end;
end;

{ SettingsIni }

class procedure SettingsIni.LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
var
  Store: ISettingsStore;
begin
  Store := TSettingsStoreIni.Create;
  Store.LoadFile(Settings, FileName, ClearValues);
end;

class procedure SettingsIni.SaveFile(const Settings: TObject; const FileName: string);
var
  Store: ISettingsStore;
begin
  Store := TSettingsStoreIni.Create;
  Store.SaveFile(Settings, FileName);
end;

end.
