unit FMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TfrmMain = class(TForm)
    butShowPeople: TButton;
    butAddPerson: TButton;
    butShowRooms: TButton;
    butAddRoom: TButton;
    procedure butShowPeopleClick(Sender: TObject);
    procedure butAddPersonClick(Sender: TObject);
    procedure butAddRoomClick(Sender: TObject);
    procedure butShowRoomsClick(Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  uNameGenerator, uPeople, FPeople, uCourses, FCourses;

var
  RoomNumber  : Char = 'A';

{ TfrmMain }

procedure TfrmMain.butAddPersonClick(Sender: TObject);
begin
  People.Add(TPerson.Create(NewName));
end;

procedure TfrmMain.butAddRoomClick(Sender: TObject);
begin
  Courses.Add(TCourse.Create('Room ' + RoomNumber));
  RoomNumber  := Succ(RoomNumber);
end;

procedure TfrmMain.butShowPeopleClick(Sender: TObject);
begin
  frmPeople.Show;
end;

procedure TfrmMain.butShowRoomsClick(Sender: TObject);
begin
  frmCourses.Show;
end;

end.
