program DemoObservers;

uses
  System.StartUpCopy,
  FMX.Forms,
  uPeople in 'uPeople.pas',
  uCourses in 'uCourses.pas',
  uNameGenerator in 'uNameGenerator.pas',
  FMain in 'FMain.pas' {frmMain},
  FPeople in 'FPeople.pas' {frmPeople},
  FPerson in 'FPerson.pas' {frmPerson},
  FCourses in 'FCourses.pas' {frmCourses},
  FmCourse in 'FmCourse.pas' {frameCourse: TFrame},
  FCourse in 'FCourse.pas' {frmCourse};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPeople, frmPeople);
  Application.CreateForm(TfrmCourses, frmCourses);
  Application.Run;
end.
