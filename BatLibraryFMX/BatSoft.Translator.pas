unit BatSoft.Translator;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

//  This is used for internationalising apps in a simple way during runtime.
//
//  To get an idea of how to use it...
//  1. Run BatSoftTranslatorDemo and save a file.
//  2. Run BatSoftTranslatorEditor and edit some of the strings.
//  3. Save the edited file with a new file name.
//  4. In BatSoftTranslatorDemo, load the files and
//     see how the strings change in the demo application.
//
//  There were other plans to have default strings.
//  For example, instead of translating every OK and Cancel button, you'd
//  translate a default instead.
//  If anyone wants me to complete this project, then e-mail me at:
//  peter@batsoft.com.au

uses
  System.SysUtils, System.Classes, System.JSON, System.Rtti, Generics.Collections;

type
  TTranslate = class
  private type

    TObj = record
      JSON: TJSONObject;
      Comp: TComponent;
    end;

    TObjs = TList<TObj>;

  private
    fCntx: TRttiContext;
    fDictionary: TJSONObject;
    function  GetObjRTTI(const ObjComp: TComponent): TRttiType;
    function  IsValidProp(const Prop: TRttiProperty): Boolean;
    procedure ListObjs(const Comp: TComponent; const Sect: TJSONObject; const Objs: TObjs);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure AddWords(const Component: TComponent; const PropertyNames: string); overload;
    procedure AddWords(const Component: TComponent; const PropertyNames: TStrings); overload;
    procedure AddWords(const SectionName: string; const Component: TComponent; const PropertyNames: string); overload;
    procedure AddWords(const SectionName: string; const Component: TComponent; const PropertyNames: TStrings); overload;
    procedure ApplyTo(const Component: TComponent); overload;
    procedure ApplyTo(const SectionName: string; const Component: TComponent); overload;
    procedure Clear;
    procedure Load(const FileFull: string);
    procedure Save(const FileFull: string);
  end;

  ETranslate = class(Exception);

var
  Translation: TTranslate;

implementation

uses
  System.TypInfo, System.IOUtils, FMX.Forms;

const
  CNoValue  : Char  = #$00;

{ TTranslate }

procedure TTranslate.AddWords(const Component: TComponent; const PropertyNames: string);
begin
  AddWords(Component.ClassName, Component, PropertyNames);
end;

procedure TTranslate.AddWords(const SectionName: string; const Component: TComponent; const PropertyNames: string);
var
  Strs: TStrings;
begin
  Strs  := TStringList.Create;
  try
    Strs.CommaText  := PropertyNames;
    AddWords(SectionName, Component, Strs);
  finally
    Strs.Free;
  end;
end;

procedure TTranslate.AddWords(const SectionName: string; const Component: TComponent; const PropertyNames: TStrings);

  function  ObtainSecJSON(const SecName: string): TJSONObject;
  begin
    Result  := fDictionary.GetValue(SecName) as TJSONObject;
    if  not Assigned(Result)  then
      begin
        Result  := TJSONObject.Create;
        fDictionary.AddPair(SecName, Result);
      end;
  end;

  function  ValText(const ValRTTI: TRttiProperty; const ObjComp: TComponent): string;
  begin
    Result  := ValRTTI.GetValue(ObjComp).AsString;
    if  Result.IsEmpty  then
      Result  := CNoValue;
  end;

  procedure AddObjJSON(const SecJSON: TJSONObject; const ObjComp: TComponent);
  var
    PropertyName: string;
    ObjJSON: TJSONObject;
    ValJSON: TJSONString;
    ObjRTTI: TRttiType;
    ValRTTI: TRttiProperty;
  begin
    ObjJSON := SecJSON.GetValue(ObjComp.Name) as TJSONObject;
    ObjRTTI := GetObjRTTI(ObjComp);
    //  Find matching words in ObjComp
    for PropertyName in PropertyNames do
      begin
        //  Find value as property
        ValRTTI := ObjRTTI.GetProperty(PropertyName);
        if  not IsValidProp(ValRTTI) then
          Continue;
        //  Obtain ObjJSON for component
        if  not Assigned(ObjJSON)  then
          begin
            ObjJSON  := TJSONObject.Create;
            SecJSON.AddPair(ObjComp.Name, ObjJSON);
          end;
        //  Add value
        ValJSON := ObjJSON.GetValue(PropertyName) as TJSONString;
        if  Assigned(ValJSON) then
          ObjJSON.RemovePair(PropertyName);
        ObjJSON.AddPair(PropertyName, ValText(ValRTTI, ObjComp));
      end;
  end;

var
  SecJSON: TJSONObject;
  ObjComp: TComponent absolute Component;
  i: integer;
begin
  //  Ensure we have a dictionary
  if  not Assigned(fDictionary) then
    fDictionary := TJSONObject.Create;
  //  Obtain section
  SecJSON := ObtainSecJSON(SectionName);
  //  Add translations
  AddObjJSON(SecJSON, ObjComp);
  //  Do children
  for i := 0 to ObjComp.ComponentCount - 1 do
    if  ObjComp.Components[i] is TFrame then
      AddWords(ObjComp.Components[i].ClassName, ObjComp.Components[i], PropertyNames)
    else
      AddObjJSON(SecJSON, ObjComp.Components[i]);
end;

procedure TTranslate.AddWords(const Component: TComponent; const PropertyNames: TStrings);
begin
  AddWords(Component.ClassName, Component, PropertyNames);
end;

procedure TTranslate.ApplyTo(const Component: TComponent);
begin
  ApplyTo(Component.ClassName, Component);
end;

procedure TTranslate.ApplyTo(const SectionName: string; const Component: TComponent);
var
  SecJSON: TJSONObject;
  Objs: TObjs;
  Obj: TObj;
  ObjRTTI: TRttiType;
  ValRTTI: TRttiProperty;
  ValPair: TJSONPair;
  i: integer;
  Child: TComponent;
begin
  //  Ensure we have a dictionary
  if  not Assigned(fDictionary) then
    Exit;
  //  Obtain section
  SecJSON := fDictionary.GetValue(SectionName) as TJSONObject;
  if  not Assigned(SecJSON) then  Exit;
  //  List components for which we have translations
  Objs  := TObjs.Create;
  try
    ListObjs(Component, SecJSON, Objs);
    //  Go through each component
    for Obj in Objs do
      begin
        ObjRTTI := GetObjRTTI(Obj.Comp);
        //  Go through each translation
        for ValPair in Obj.JSON  do
          begin
            ValRTTI  := ObjRTTI.GetProperty(ValPair.JsonString.Value);
            if  IsValidProp(ValRTTI) then
              ValRTTI.SetValue(Obj.Comp, ValPair.JsonValue.Value);
          end;
      end;
    //  Apply to frames as well
    for i := 0 to Component.ComponentCount - 1  do
      begin
        Child := Component.Components[i];
        if  Child is TFrame then
          ApplyTo(Child);
      end;
    //  Tidy up
  finally
    Objs.Free;
  end;
end;

procedure TTranslate.Clear;
begin
  FreeAndNil(fDictionary);
end;

constructor TTranslate.Create;
begin
  inherited;
  fCntx := TRttiContext.Create;
end;

destructor TTranslate.Destroy;
begin
  fDictionary.Free;;
  fCntx.Free;
  inherited;
end;

function TTranslate.GetObjRTTI(const ObjComp: TComponent): TRttiType;
var
  ObjType: TClass;
  ObjTypeName: string;
begin
  //  Validate ObjComp
  if  not Assigned(ObjComp) then  raise ETranslate.Create('Component is nil.');
  //  Validate ObjComp.ClassType
  try
    ObjType     := ObjComp.ClassType;
    ObjTypeName := ObjType.ClassName;
  except on X: Exception do
    raise ETranslate.Create('Component class is invalid.');
  end;
  //  Get result
  Result  := fCntx.GetType(ObjType);
  //  Validate result
  if  not Assigned(Result)  then  raise ETranslate.Create('Component is not registered: '+ObjTypeName);
end;

function TTranslate.IsValidProp(const Prop: TRttiProperty): Boolean;
begin
  Result  :=
    Assigned(Prop) and Prop.IsReadable and Prop.IsWritable and
    (Prop.Visibility = TMemberVisibility.mvPublished) and
    (Prop.PropertyType.TypeKind in [tkString, tkWChar, tkLString, tkWString, tkUString]) and
    not SameText(Prop.Name, 'Name')
end;

procedure TTranslate.ListObjs(const Comp: TComponent; const Sect: TJSONObject; const Objs: TObjs);

  procedure AddObj(const Component: TComponent);
  var
    Obj: TObj;
  begin
    Obj.Comp  := Component;
    Obj.JSON  := Sect.GetValue(Component.Name) as TJSONObject;
    if  Assigned(Obj.JSON)  then
      Objs.Add(Obj);
  end;

var
  i: integer;
begin
  //  Add parent component (typically TForm or TFrame)
  AddObj(Comp);
  //  Add all child components
  for i := 0 to Comp.ComponentCount - 1 do
    AddObj(Comp.Components[i]);
end;

procedure TTranslate.Load(const FileFull: string);
begin
  fDictionary := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileFull)) as TJSONObject;
end;

procedure TTranslate.Save(const FileFull: string);
begin
  if  Assigned(fDictionary) then
    TFile.WriteAllText(FileFull, fDictionary.ToJSON)
  else
    TFile.WriteAllText(FileFull, '')
end;

initialization
  Translation := TTranslate.Create;

finalization
  Translation.Free;

end.
