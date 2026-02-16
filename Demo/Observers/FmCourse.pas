unit FmCourse;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Memo.Types, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, BatSoft.Observer.Managed, uCourses, uPeople;

type
  TframeCourse = class(TFrame)
    lstEnrolled: TListBox;
  private
    fCourse: TCourse;
    fSubscription: ISubscription<TCourse>;
    procedure SetCourse(const Value: TCourse);
    procedure CourseChanged(Course: TCourse; Person: TPerson; Action: TEnrolmentAction);
  public
    property  Course  : TCourse read fCourse write SetCourse;
  end;

implementation

{$R *.fmx}

{ TframeCourse }

procedure TframeCourse.CourseChanged(Course: TCourse; Person: TPerson; Action: TEnrolmentAction);
begin
  Course.PeopleInRoom(lstEnrolled.Items);
end;

procedure TframeCourse.SetCourse(const Value: TCourse);
begin
  fCourse := Value;
  fCourse.PeopleInRoom(lstEnrolled.Items);
  fSubscription := Course.OnChange.Subscribe(CourseChanged)
end;

end.
