unit uEmployment;

interface

uses
  Generics.Collections;

type
  TEmployment = class
  private
    fName: string;
  public
    property  Name  : string  read fName  write fName;
  end;

  TContract = class(TEmployment)
  private
    fStartDate: TDate;
    fDeadline: TDate;
    fHourlyRate: Currency;
  public
    constructor CreateRandom;
    property  StartDate   : TDate     read fStartDate     write fStartDate;
    property  Deadline    : TDate     read fDeadline      write fDeadline;
    property  HourlyRate  : Currency  read fHourlyRate    write fHourlyRate;
  end;

  TFullTime = class(TEmployment)
  private
    fStartDate: TDate;
    fSalary: Currency;
  public
    constructor CreateRandom;
    property  StartDate   : TDate     read fStartDate     write fStartDate;
    property  Salary      : Currency  read fSalary        write fSalary;
  end;

  TPartTime = class(TEmployment)
  private
    fHourlyRate: Currency;
    fHoursPerWeek: integer;
  public
    constructor CreateRandom;
    property  HourlyRate  : Currency  read fHourlyRate    write fHourlyRate;
    property  HoursPerWeek: integer   read fHoursPerWeek  write fHoursPerWeek;
  end;

  TEmploymentList = class(TObjectList<TEmployment>)
  public
    procedure Populate(const HowMany: integer);
  end;

implementation

uses
  System.SysUtils;

{ TContract }

constructor TContract.CreateRandom;
begin
  inherited Create;
  fStartDate  := Date - Random(1000);
  fDeadline   := Date + Random(1000);
  fHourlyRate := 40 + Random(5) * 10;
end;

{ TFullTime }

constructor TFullTime.CreateRandom;
begin
  inherited Create;
  fStartDate  := Date - Random(5000);
  fSalary     := 70000 + Random(5) * 10000;
end;

{ TPartTime }

constructor TPartTime.CreateRandom;
begin
  inherited Create;
  fHourlyRate   := 40 + Random(5) * 10;
  fHoursPerWeek := 10 + Random(5) * 5;
end;

{ TEmploymentList }

procedure TEmploymentList.Populate(const HowMany: integer);
var
  i: integer;
  Item: TEmployment;
begin
  Item  := nil;
  for i := 1 to HowMany do
    begin
      case Random(3)  of
        0 : Item  := TContract.CreateRandom;
        1 : Item  := TFullTime.CreateRandom;
        2 : Item  := TPartTime.CreateRandom;
      end;
      Item.Name := 'Employer ' + i.ToString;
      Add(Item);
    end;
end;

end.
