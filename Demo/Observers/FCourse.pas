unit FCourse;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FmCourse,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Edit,
  BatSoft.Observer.Managed, uCourses, uPeople;

type
  TfrmCourse = class(TForm)
    edCourseName: TEdit;
    frameCourse1: TframeCourse;
    edHistory: TMemo;
  private
    fCourse: TCourse;
    fSubscription: ISubscription<TCourse>;
    procedure SetCourse(const Value: TCourse);
    procedure CourseChanged(Course: TCourse; Person: TPerson; Action: TEnrolmentAction);
  public
    property  Course  : TCourse read FCourse write SetCourse;
  end;

procedure ShowCourse(Course: TCourse);

implementation

{$R *.fmx}

uses
  System.TypInfo;

procedure ShowCourse(Course: TCourse);
var
  NewForm: TfrmCourse;
begin
  NewForm := TfrmCourse.Create(Application);
  NewForm.Course  := Course;
  NewForm.Show;
end;

{ TfrmCourse }

procedure TfrmCourse.CourseChanged(Course: TCourse; Person: TPerson; Action: TEnrolmentAction);
begin
  edHistory.Lines.Add(Person.Name + ' ' + GetEnumName(TypeInfo(TEnrolmentAction), Ord(Action)));
end;

procedure TfrmCourse.SetCourse(const Value: TCourse);
begin
  fCourse := Value;
  edCourseName.Text := fCourse.Name;
  frameCourse1.Course := Course;
  fSubscription := Course.OnChange.Subscribe(CourseChanged);
end;

end.
