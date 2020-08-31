unit BatSoft.Settings.JSON;

interface

uses
  System.Rtti, BatSoft.Settings;

type
  TSettingsStoreJSON = class(TInterfacedObject, ISettingsStore)
  public
    //  ISettingsStore interface
    procedure LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean = True);
    procedure SaveFile(const Settings: TObject; const FileName: string);
  end;

  SettingsJSON = class
  public
    class procedure AsString(const Settings: TObject; const JSON: string; const ClearValues: Boolean = True); overload;
    class function  AsString(const Settings: TObject): string; overload;
    class procedure LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean = True);
    class procedure SaveFile(const Settings: TObject; const FileName: string);
  end;



  ESettingsJSON = class(ESettings);

implementation

uses
  System.SysUtils, System.TypInfo, System.IOUtils, System.JSON, System.Classes,
  Generics.Collections;

const
  SClass  = 'Class';

{ TSettingsStoreJSON }

procedure TSettingsStoreJSON.LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
begin
  SettingsJSON.AsString(Settings, TFile.ReadAllText(FileName), ClearValues);
end;

procedure TSettingsStoreJSON.SaveFile(const Settings: TObject; const FileName: string);
begin
  TFile.WriteAllText(FileName, SettingsJSON.AsString(Settings));
end;

{ SettingsJSON }

class procedure SettingsJSON.AsString(const Settings: TObject; const JSON: string; const ClearValues: Boolean);
var
  RTTI: TRttiContext;
  TypeBool: TRttiType;

  procedure JSONToSett(const SettObj: TObject; const JSONValue: TJSONValue);

    function CreateObject(const JSonValue: TJSONValue; const DefaultClass: TRttiType): TObject;
    var
      JSONChild: TJSONObject absolute JSONValue;
      ClassValue: TJSONValue;
      ChildClassName: string;
      ChildClass: TRttiType;

      Method: TRttiMethod;
    begin
      //  Determine class
      ClassValue   := JSONChild.GetValue(SClass);
      if  Assigned(ClassValue)  then
        begin
          ChildClassName  := ClassValue.Value;
          ChildClass      := RTTI.FindType(ChildClassName);
        end
      else
        ChildClass  := DefaultClass;
      //  Create object
      Result  := nil;
      if  Assigned(ChildClass)  then
        begin
          for Method in TRttiInstanceType(ChildClass).GetMethods  do
            if  Method.IsConstructor and (Length(Method.GetParameters) = 0) then
              begin
                Result  := Method.Invoke(ChildClass.AsInstance.MetaclassType, []).AsObject;
                break;
              end;
          if  not Assigned(Result)  then
            Result  := ChildClass.AsInstance.MetaclassType.Create;
        end;
    end;

    procedure LoadSettingsList(const SettObj: TObject; const JSONArray: TJSONArray);
    var
      ItemList: TObjectList<TObject>;
      Item: TObject;
      JSONChildValue: TJSONValue;
      JSONChildObject: TJSONObject;
      ItemClass: TClass;
      ItemType: TRttiInstanceType;
      i: integer;
    begin
      //  Is this a generic list?
      if  not RegisteredSettingsLists.Find(SettObj, ItemList, ItemClass)  then
        raise ESettings.Create('Tried to load an array, but the array is not of type TSettingsList<>.');
      ItemType  := RTTI.GetType(ItemClass) as TRttiInstanceType;
      //  Might clear old items
      if  ClearValues then
        ItemList.Clear;
      //  Populate list
      for i := 0 to JSONArray.Count - 1 do
        begin
          JSONChildValue  := JSONArray.Items[i];
          if  not (JSONChildValue is TJSONObject) then
            continue;
          JSONChildObject := TJSONObject(JSONChildValue);
          Item  := CreateObject(JSONChildObject, ItemType);
          JSONToSett(Item, JSONChildObject);
          ItemList.Add(Item);
        end;
    end;

    procedure ObtainChild(const Prop: TRttiProperty; var ChildObj: TObject; const JSONValue: TJSONValue);
    var
      JSONChild: TJSONObject absolute JSONValue;
      ChildClass: TClass;
    begin
      ChildClass  := (Prop.PropertyType as TRttiInstanceType).MetaclassType;
      //  If list does not exist, then create it
      if  (JSONValue is TJSONArray) and RegisteredSettingsLists.IsSettingsList(ChildClass)  then
        ChildObj  := ChildClass.Create
      //  Validate
      else if  not (JSONValue is TJSONObject)  then
        raise ESettingsJSON.Create('Value expected to be '+TJSONObject.ClassName+' but is of type '+JSONValue.ClassName+'.')
      //  If object does not exist, then create it
      else if not Assigned(ChildObj)  then
        ChildObj  := CreateObject(JSONValue, Prop.PropertyType);
      //  Assign object to the property
      Prop.SetValue(SettObj, ChildObj);
    end;

    procedure LoadStrings(const Strs: TStrings; const JSONObj: TJSONObject);
    var
      Pair: TJSONPair;
      ClassValue: TJSONValue;
      JSONChild: TJSONObject;
      ChildClass: TRttiType;
      ChildObj: TObject;
    begin
      if  ClearValues then
        Strs.Clear;
      for Pair in JSONObj do
        begin
          JSONChild := Pair.JsonValue as TJSONObject;
          //  Determine class
          ClassValue   := JSONChild.GetValue(SClass);
          if  Assigned(ClassValue)  then
            begin
              ChildClass  := RTTI.FindType(ClassValue.Value);
              if  not Assigned(ChildClass)  then
                raise ESettingsJSON.Create('Class '''+ClassValue.Value+''' not found.');
              //  Create child object
              ChildObj  := ChildClass.AsInstance.MetaclassType.Create;
              Strs.AddObject(Pair.JsonString.Value, ChildObj);
              //  Recurse loading settings
              JSONToSett(ChildObj, JSONChild);
            end;
        end;
    end;

  var
    RTTIType, RTTIClassType: TRttiType;
    RTTIProps: TArray<TRttiProperty>;
    RTTIProp: TRttiProperty;
    i: integer;
    SettName: string;
    JSONObject: TJSONObject;
    JSONProp: TJSONValue;
    Child: TObject;
    Value: TValue;
    Bytes: TBytes;
  begin
    if  JSONValue is TJSONArray then
      LoadSettingsList(SettObj, TJSONArray(JSONValue))
    else if JSONValue is TJSONObject  then
      begin
        JSONObject := TJSONObject(JSONValue);
        //  Run through each published property
        RTTIType  := RTTI.GetType(SettObj.ClassType);
        RTTIProps := RTTIType.GetProperties;
        RTTIProps := SortAndFilter(RTTIProps, False);
        for i := 0 to Length(RTTIProps) - 1 do
          begin
            RTTIProp  := RTTIProps[i];
            //  Might have ignore attibute
            if  HasSettingIgnore(RTTIProp) then
              Continue;
            //  Get the correct settings name
            SettName  := SettingNameAttribute.SettingNameOf(RTTIProp);
            //  Does the JSON value correspond to a writable property?
            JSONProp := JSONObject.GetValue(SettName);
            if  Assigned(JSONProp) and (RTTIProp.IsWritable or (RTTIProp.PropertyType.TypeKind = tkClass)) then
              begin
                //  Set the property value
                if  RTTIProp.PropertyType = TypeBool  then
                  RTTIProp.SetValue(SettObj, (JSONProp as TJSONBool).AsBoolean)
                else
                  case RTTIProp.PropertyType.TypeKind of
                    tkInteger :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, 0)
                      else
                        RTTIProp.SetValue(SettObj, (JSONProp as TJSONNumber).AsInt);
                    tkInt64 :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, 0)
                      else
                        RTTIProp.SetValue(SettObj, (JSONProp as TJSONNumber).AsInt64);
                    tkFloat :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, 0)
                      else
                        RTTIProp.SetValue(SettObj, (JSONProp as TJSONNumber).AsDouble);
                    tkEnumeration : SetEnumProp(SettObj, SettName, (JSONProp as TJSONString).Value);
                    tkSet :         SetSetProp(SettObj, SettName, (JSONProp as TJSONString).Value);
                    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString, tkVariant :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, '')
                      else
                        RTTIProp.SetValue(SettObj, (JSONProp as TJSONString).Value);
                    tkClassRef :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, nil)
                      else
                        begin
                          RTTIClassType  := RTTI.FindType((JSONProp as TJSONString).Value);
                          if  not Assigned(RTTIClassType)  then
                            raise ESettingsJSON.Create('Class '+(JSONProp as TJSONString).Value+' not found.');
                          if  RTTIClassType.TypeKind <> tkClass then
                            raise ESettingsJSON.Create('Type '+(JSONProp as TJSONString).Value+' is not a class.');
                          RTTIProp.SetValue(SettObj, TClass((RTTIClassType as TRttiInstanceType).MetaclassType));
                        end;
                    tkClass :
                      begin
                        //  Get current object
                        Child := RTTIProp.GetValue(SettObj).AsObject;
                        //  Perhaps should be null...
                        if  JSONProp is TJSONNull then
                          begin
                            Child.Free;
                            RTTIProp.SetValue(SettObj, nil);
                          end
                        //  ...or perhaps need to recurse
                        else
                          begin
                            //  Get hold of a child object
                            if  not Assigned(Child) and RTTIProp.IsWritable then
                              ObtainChild(RTTIProp, Child, JSONProp);
                            //  Load its settings
                            if  Assigned(Child) then
                              JSONToSett(Child, JSONProp);
                          end;
                      end;
                    tkDynArray :
                      if  JSONProp is TJSONNull then
                        RTTIProp.SetValue(SettObj, nil)
                      else
                        begin
                          if  not SameText(RTTIProp.PropertyType.Name, 'TArray<System.Byte>')  then
                            raise ESettingsJSON.Create('Property '+SettName+' cannot be loaded because it is a dynamic array, but not TArray<Byte>.');
                          if  JSONProp is TJSONNull  then
                            Bytes := nil
                          else
                            raise ESettingsJSON.Create('Not implemented... yet.');
                          Value.From(Bytes);
                          RTTIProp.SetValue(SettObj, Value);
                        end;
                  else
                    raise ESettingsJSON.Create('Property '+SettName+' cannot be loaded because it is of type '+RTTIProp.PropertyType.Name+'.');
                  end;
              end
            else if ClearValues and SettingClearAttribute.ShouldClear(RTTIProp, ClearValues) then
              begin
                  case RTTIProp.PropertyType.TypeKind of
                    tkInteger, tkInt64, tkFloat,
                    tkEnumeration, tkSet,
                    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString,
                    tkVariant, tkClassRef :
                      RTTIProp.SetValue(SettObj, TValue.Empty);
                    tkClass :
                      begin
                        RTTIProp.GetValue(SettObj).AsObject.Free;
                        RTTIProp.SetValue(SettObj, nil);
                      end;
                  end;
              end;
          end;
        //  Try to load the SettObj as a list
        if  SettObj is TStrings then
          LoadStrings(TStrings(SettObj), JSONObject);
      end;
  end;

var
  JSONRoot: TJSONValue;
begin
  //  Set up
  RTTI.Create;
  try
    TypeBool  := RTTI.GetType(TypeInfo(Boolean));
    //  Load the JSON structure
    JSONRoot := TJSONObject.ParseJSONValue(JSON);
    try
      JSONToSett(Settings, JSONRoot);
      //  Tidy up
    finally
      JSONRoot.Free;
    end;
  finally
    RTTI.Free;
  end;
end;

class function SettingsJSON.AsString(const Settings: TObject): string;
var
  RTTI: TRttiContext;
  TypeBool: TRttiType;

  function SettToJSON(const SettObj: TObject; const ExpectedClass: TClass): TJSONValue;
  var
    RTTIType: TRttiType;
    RTTIProps: TArray<TRttiProperty>;
    RTTIProp: TRttiProperty;
    JSONValue: TJSONValue;

    procedure SaveStrings(const Strings: TStrings; const JSONObject: TJSONObject);
    var
      i: integer;
      JSONValue: TJSONValue;
    begin
      for i := 0 to Strings.Count - 1 do
        begin
          JSONValue := SettToJSON(Strings.Objects[i], nil);
          JSONObject.AddPair(Strings[i], JSONValue);
        end;
    end;

    procedure SaveSettingsList(const SettObj: TObject; const JSONObject: TJSONArray); overload;
    var
      ItemList: TObjectList<TObject>;
      JSONValue: TJSONValue;
      ItemClass: TClass;
      i: integer;
    begin
      //  Is this a generic list?
      if  not RegisteredSettingsLists.Find(SettObj, ItemList, ItemClass)  then
        Exit;
      //  It is, so save the items
      for i := 0 to ItemList.Count - 1 do
        begin
          JSONValue := SettToJSON(ItemList[i], ItemClass);
          JSONObject.AddElement(JSONValue);
        end;
    end;

    procedure SaveSettingsList(const SettObj: TObject; const JSONObject: TJSONObject); overload;
    var
      ItemList: TObjectList<TObject>;
      JSONValue: TJSONValue;
      ItemClass: TClass;
      i: integer;
    begin
      //  Is this a generic list?
      if  not RegisteredSettingsLists.Find(SettObj, ItemList, ItemClass)  then
        Exit;
      //  It is, so save the items
      for i := 0 to ItemList.Count - 1 do
        begin
          JSONValue := SettToJSON(ItemList[i], ItemClass);
          JSONObject.AddPair(i.ToString, JSONValue);
        end;
    end;

  var
    i: integer;
    SettName: string;
    JSONObject: TJSONObject absolute Result;
  begin
    //  Don't save nil
    if  not Assigned(SettObj) then
      Exit(nil);
    //  Create result object
    if  RegisteredSettingsLists.IsSettingsList(SettObj.ClassType) then
      begin
        Result  := TJSONArray.Create;
        SaveSettingsList(SettObj, TJSONArray(Result));
        Exit;
      end
    else
      JSONObject  := TJSONObject.Create;
    //  Might have to specify the class
    if  SettObj.ClassType <> ExpectedClass  then
      JSONObject.AddPair(SClass, SettObj.QualifiedClassName);
    //  Run through each published property
    RTTIType  := RTTI.GetType(SettObj.ClassType);
    RTTIProps := SortAndFilter(RTTIType.GetProperties, True);
    for i := 0 to Length(RTTIProps) - 1 do
      begin
        RTTIProp  := RTTIProps[i];
        //  Might have ignore attibute
        if  HasSettingIgnore(RTTIProp) then
          Continue;
        //  Get the correct settings name
        SettName  := SettingNameAttribute.SettingNameOf(RTTIProp);
        //  Create JSON value
        if  RTTIProp.PropertyType = TypeBool  then
          JSONValue := TJSONBool.Create(RTTIProp.GetValue(SettObj).AsBoolean)
        else
          case RTTIProp.PropertyType.TypeKind of
            tkInteger :     JSONValue := TJSONNumber.Create(RTTIProp.GetValue(SettObj).AsInteger);
            tkInt64 :       JSONValue := TJSONNumber.Create(RTTIProp.GetValue(SettObj).AsInt64);
            tkFloat :       JSONValue := TJSONNumber.Create(RTTIProp.GetValue(SettObj).AsExtended);
            tkEnumeration : JSONValue := TJSONString.Create(GetEnumProp(SettObj, SettName));
            tkSet :         JSONValue := TJSONString.Create(GetSetProp(SettObj, SettName));
            tkChar, tkWChar, tkString, tkLString, tkWString, tkUString :
                            JSONValue := TJSONString.Create(RTTIProp.GetValue(SettObj).AsString);
            tkVariant :     JSONValue := TJSONString.Create(RTTIProp.GetValue(SettObj).AsVariant);
            tkClassRef :    JSONValue := TJSONString.Create(RTTIProp.GetValue(SettObj).AsClass.QualifiedClassName);
            tkClass :       JSONValue := SettToJSON(RTTIProp.GetValue(SettObj).AsObject, RTTIProp.PropertyType.AsInstance.MetaclassType);
          else raise ESettingsJSON.Create('Property '+SettName+' cannot be saved because it is of type '+RTTIProp.PropertyType.Name+'.');
          end;
        //  Add name/value pair
        JSONObject.AddPair(SettName, JSONValue);
      end;
    //  Try to save the SettObj as a list
    if  SettObj is TStrings then
      SaveStrings(TStrings(SettObj), JSONObject)
    else
      SaveSettingsList(SettObj, JSONObject);
  end;

var
  JSONRoot: TJSONValue;
begin
  //  Set up
  RTTI.Create;
  try
    TypeBool  := RTTI.GetType(TypeInfo(Boolean));
    //  Generate the JSON structure
    JSONRoot  := SettToJSON(Settings, Settings.ClassType);
    if  Assigned(JSONRoot)  then
      try
        //  Save to file
        Result  := JSONRoot.ToJSON;
        //  Tidy up
      finally
        JSONRoot.Free;
      end;
  finally
    RTTI.Free;
  end;
end;

class procedure SettingsJSON.LoadFile(const Settings: TObject; const FileName: string; const ClearValues: Boolean);
var
  Store: ISettingsStore;
begin
  Store := TSettingsStoreJSON.Create;
  Store.LoadFile(Settings, FileName, ClearValues);
end;

class procedure SettingsJSON.SaveFile(const Settings: TObject; const FileName: string);
var
  Store: ISettingsStore;
begin
  Store := TSettingsStoreJSON.Create;
  Store.SaveFile(Settings, FileName);
end;

end.
