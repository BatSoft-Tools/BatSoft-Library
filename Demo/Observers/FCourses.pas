unit FCourses;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ListBox, BatSoft.Observer.Managed, uCourses, FmCourse;

type
  TfrmCourses = class(TForm)
    lstCourses: TListBox;
    frameCourse1: TframeCourse;
    procedure FormCreate(Sender: TObject);
    procedure lstCoursesChange(Sender: TObject);
  private
    fSubscription: ISubscription<TCourses>;
    procedure UpdatedRooms(Rooms: TCourses);
    function GetSelectedCourse: TCourse;
  public
    property  SelectedCourse  : TCourse read GetSelectedCourse;
  end;

var
  frmCourses: TfrmCourses;

implementation

{$R *.fmx}

{ TfrmRooms }

procedure TfrmCourses.FormCreate(Sender: TObject);
begin
  fSubscription := Courses.OnChanged.Subscribe(UpdatedRooms);
end;

function TfrmCourses.GetSelectedCourse: TCourse;
begin
  if lstCourses.ItemIndex < 0 then
    Result  := nil
  else
    Result  := lstCourses.Items.Objects[lstCourses.ItemIndex] as TCourse
end;

procedure TfrmCourses.lstCoursesChange(Sender: TObject);
begin
  frameCourse1.Course := SelectedCourse
end;

procedure TfrmCourses.UpdatedRooms(Rooms: TCourses);
begin
  Rooms.AssignTo(lstCourses.Items);
end;

end.
