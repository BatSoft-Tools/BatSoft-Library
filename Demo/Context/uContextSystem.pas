unit uContextSystem;

interface

uses
  System.TypInfo, System.Rtti, System.Classes, BatSoft.Context;

type
  //  This context gives access to information from the system
  TContextSystem = class(TContextBase)
  public const
    //  http://docwiki.embarcadero.com/Libraries/XE2/en/System.SysUtils.GetEnvironmentVariable
    //Environment variable    Description
    ALLUSERSPROFILE         = 'ALLUSERSPROFILE';        //  Generic user profile.
    APPDATA                 = 'APPDATA';                //  Path of the application data folder.
    CLIENTNAME              = 'CLIENTNAME';             //  Name of Client machine.
    COMMONPROGRAMFILES      = 'COMMONPROGRAMFILES';     //  Path of common program files folder.
    COMPUTERNAME            = 'COMPUTERNAME';           //  Name of Computer code is running on.
    COMSPEC                 = 'COMSPEC';                //  Path of the cmd.exe program.
    HOMEDRIVE               = 'HOMEDRIVE';              //  Current home drive designation, such as ''C:''
    HOMEPATH                = 'HOMEPATH';               //  Path to current location for document storage.
    LOGONSERVER             = 'LOGONSERVER';            //  Specifies a domain controller for user logon authentication.
    NUMBER_OF_PROCESSORS    = 'NUMBER_OF_PROCESSORS';   //  Number of processors on current machine.
    OS                      = 'OS';                     //  Base name of the Operating System. Note that Windows XP is given as Windows_NT.
    PATH                    = 'PATH';                   //  The current program path.
    PATHEXT                 = 'PATHEXT';                //  Extension types of executable files.
    PROCESSOR_ARCHITECTURE  = 'PROCESSOR_ARCHITECTURE'; //  Type of CPU architecture. For example, X86 for Intel Pentium processors.
    PROCESSOR_IDENTIFIER    = 'PROCESSOR_IDENTIFIER';   //  ID number of current machine.
    PROCESSOR_LEVEL         = 'PROCESSOR_LEVEL';        //  More detailed description of the CPU architecture.
    PROCESSOR_REVISION      = 'PROCESSOR_REVISION';     //  Processor revision level.
    PROGRAMFILES            = 'PROGRAMFILES';           //  Path of the program files folder.
    SESSIONNAME             = 'SESSIONNAME';            //  Name of the current OS session.
    SYSTEMDRIVE             = 'SYSTEMDRIVE';            //  Drive the OS operates from.
    SYSTEMROOT              = 'SYSTEMROOT';             //  Sets the system directory.
    TEMP                    = 'TEMP';                   //  Path of the temporary files folder.
    TMP                     = 'TMP';                    //  Directory to store temporary files to.
    USERDOMAIN              = 'USERDOMAIN';             //  Specifies the domain of the current machine.
    USERNAME                = 'USERNAME';               //  Name of the current user.
    USERPROFILE             = 'USERPROFILE';            //  Path of the folder holding the current user''s information.
    WINDIR                  = 'WINDIR';                 //  Path of the Windows folder.
    const VarNames  : array [1..27] of string =
     (ALLUSERSPROFILE, APPDATA, CLIENTNAME, COMMONPROGRAMFILES, COMPUTERNAME,
      COMSPEC, HOMEDRIVE, HOMEPATH, LOGONSERVER, NUMBER_OF_PROCESSORS, OS, PATH,
      PATHEXT, PROCESSOR_ARCHITECTURE, PROCESSOR_IDENTIFIER, PROCESSOR_LEVEL,
      PROCESSOR_REVISION, PROGRAMFILES, SESSIONNAME, SYSTEMDRIVE, SYSTEMROOT,
      TEMP, TMP, USERDOMAIN, USERNAME, USERPROFILE, WINDIR);
  private
    function IsValidName(const Name: string): Boolean;
  public
    //  IContext interface
    function  HasValue(const Name: string): Boolean; override;
    function  GetValue(const Name: string): TValue; override;
    function  GetTypeOf(const Name: string): PTypeInfo; override;
    //  IContextNames interface
    function  GetNames(const Names: TStrings): Boolean; override;
  end;

implementation

uses
  System.SysUtils;

{ TContextSystem }

function TContextSystem.GetNames(const Names: TStrings): Boolean;
var
  VarName: string;
begin
  for VarName in VarNames do
    Names.Add(VarName);
  Result  := True;
end;

function TContextSystem.GetTypeOf(const Name: string): PTypeInfo;
begin
  if  IsValidName(Name) then
    Result  := TypeInfo(string)
  else
    Result  := nil
end;

function TContextSystem.GetValue(const Name: string): TValue;
begin
  if  IsValidName(Name) then
    Result  := GetEnvironmentVariable(Name)
  else
    raise EContext.CreateValueNotFound(Name);
end;

function TContextSystem.HasValue(const Name: string): Boolean;
begin
  Result  := IsValidName(Name)
end;

function TContextSystem.IsValidName(const Name: string): Boolean;
var
  VarName: string;
begin
  Result := False;
  for VarName in VarNames do
    if  SameText(VarName, Name) then
      Exit(True);
end;

end.
