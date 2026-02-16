unit uNameGenerator;

interface

function NewName: string;

implementation

type
  TNameSet = record
    Male, Female, Family: string
  end;

const
  HundredNames : array [0..99] of TNameSet =
  (
    (Male: 'James'; Female:	'Mary'; Family: 'Smith'),
    (Male: 'Michael'; Female:	'Patricia'; Family:	'Johnson'),
    (Male: 'John'; Female:	'Jennifer'; Family:	'Williams'),
    (Male: 'Robert'; Female:	'Linda'; Family: 'Brown'),
    (Male: 'Davi'; Female: 'Elizabeth'; Family: 'Jones'),
    (Male: 'Willia'; Female: 'Barbara'; Family: 'Garcia'),
    (Male: 'Richar'; Female: 'Susan'; Family: 'Miller'),
    (Male: 'Josep'; Female: 'Jessica'; Family: 'Davis'),
    (Male: 'Thoma'; Female: 'Karen'; Family: 'Rodriguez'),
    (Male: 'Christophe'; Female: 'Sarah'; Family: 'Martinez'),
    (Male: 'Charle'; Female: 'Lisa'; Family: 'Hernandez'),
    (Male: 'Danie'; Female: 'Nancy'; Family: 'Lopez'),
    (Male: 'Matthe'; Female: 'Sandra'; Family: 'Gonzales'),
    (Male: 'Anthon'; Female: 'Ashley'; Family: 'Wilson'),
    (Male: 'Mar'; Female: 'Emily'; Family: 'Anderson'),
    (Male: 'Steve'; Female: 'Kimberly'; Family: 'Thomas'),
    (Male: 'Donal'; Female: 'Betty'; Family: 'Taylor'),
    (Male: 'Andre'; Female: 'Margaret'; Family: 'Moore'),
    (Male: 'Joshu'; Female: 'Donna'; Family: 'Jackson'),
    (Male: 'Pau'; Female: 'Michelle'; Family: 'Martin'),
    (Male: 'Kennet'; Female: 'Carol'; Family: 'Lee'),
    (Male: 'Kevi'; Female: 'Amanda'; Family: 'Perez'),
    (Male: 'Bria'; Female: 'Melissa'; Family: 'Thompson'),
    (Male: 'Timoth'; Female: 'Deborah'; Family: 'White'),
    (Male: 'Ronal'; Female: 'Stephanie'; Family: 'Harris'),
    (Male: 'Jaso'; Female: 'Rebecca'; Family: 'Sanchez'),
    (Male: 'Georg'; Female: 'Sharon'; Family: 'Clark'),
    (Male: 'Edwar'; Female: 'Laura'; Family: 'Ramirez'),
    (Male: 'Jeffre'; Female: 'Cynthia'; Family: 'Lewis'),
    (Male: 'Rya'; Female: 'Amy'; Family: 'Robinson'),
    (Male: 'Jaco'; Female: 'Kathleen'; Family: 'Walker'),
    (Male: 'Nichola'; Female: 'Angela'; Family: 'Young'),
    (Male: 'Gar'; Female: 'Dorothy'; Family: 'Allen'),
    (Male: 'Eri'; Female: 'Shirley'; Family: 'King'),
    (Male: 'Jonatha'; Female: 'Emma'; Family: 'Wright'),
    (Male: 'Stephe'; Female: 'Brenda'; Family: 'Scott'),
    (Male: 'Larr'; Female: 'Nicole'; Family: 'Torres'),
    (Male: 'Justi'; Female: 'Pamela'; Family: 'Nguyen'),
    (Male: 'Benjami'; Female: 'Samantha'; Family: 'Hill'),
    (Male: 'Scot'; Female: 'Anna'; Family: 'Flores'),
    (Male: 'Brando'; Female: 'Katherine'; Family: 'Green'),
    (Male: 'Samue'; Female: 'Christine'; Family: 'Adams'),
    (Male: 'Gregor'; Female: 'Debra'; Family: 'Nelson'),
    (Male: 'Alexande'; Female: 'Rachel'; Family: 'Baker'),
    (Male: 'Patric'; Female: 'Olivia'; Family: 'Hall'),
    (Male: 'Fran'; Female: 'Carolyn'; Family: 'Rivera'),
    (Male: 'Jac'; Female: 'Maria'; Family: 'Campbell'),
    (Male: 'Raymon'; Female: 'Janet'; Family: 'Mitchell'),
    (Male: 'Denni'; Female: 'Heather'; Family: 'Carter'),
    (Male: 'Tyle'; Female: 'Diane'; Family: 'Roberts'),
    (Male: 'Aaro'; Female: 'Catherine'; Family: 'Gomez'),
    (Male: 'Jerr'; Female: 'Julie'; Family: 'Phillips'),
    (Male: 'Jos'; Female: 'Victoria'; Family: 'Evans'),
    (Male: 'Natha'; Female: 'Helen'; Family: 'Turner'),
    (Male: 'Ada'; Female: 'Joyce'; Family: 'Diaz'),
    (Male: 'Henr'; Female: 'Lauren'; Family: 'Parker'),
    (Male: 'Zachar'; Female: 'Kelly'; Family: 'Cruz'),
    (Male: 'Dougla'; Female: 'Christina'; Family: 'Edwards'),
    (Male: 'Pete'; Female: 'Joan'; Family: 'Collins'),
    (Male: 'Noa'; Female: 'Judith'; Family: 'Reyes'),
    (Male: 'Kyl'; Female: 'Ruth'; Family: 'Stewart'),
    (Male: 'Etha'; Female: 'Hannah'; Family: 'Morris'),
    (Male: 'Christia'; Female: 'Evelyn'; Family: 'Morales'),
    (Male: 'Jerem'; Female: 'Andrea'; Family: 'Murphy'),
    (Male: 'Keit'; Female: 'Virginia'; Family: 'Cook'),
    (Male: 'Austi'; Female: 'Megan'; Family: 'Rogers'),
    (Male: 'Sea'; Female: 'Cheryl'; Family: 'Gutierrez'),
    (Male: 'Roge'; Female: 'Jacqueline'; Family: 'Ortiz'),
    (Male: 'Terr'; Female: 'Madison'; Family: 'Morgan'),
    (Male: 'Walte'; Female: 'Sophia'; Family: 'Cooper'),
    (Male: 'Dyla'; Female: 'Abigail'; Family: 'Peterson'),
    (Male: 'Geral'; Female: 'Teresa'; Family: 'Bailey'),
    (Male: 'Car'; Female: 'Isabella'; Family: 'Reed'),
    (Male: 'Jorda'; Female: 'Sara'; Family: 'Kelly'),
    (Male: 'Brya'; Female: 'Janice'; Family: 'Howard'),
    (Male: 'Gabrie'; Female: 'Martha'; Family: 'Ramos'),
    (Male: 'Jess'; Female: 'Gloria'; Family: 'Kim'),
    (Male: 'Harol'; Female: 'Kathryn'; Family: 'Cox'),
    (Male: 'Lawrenc'; Female: 'Ann'; Family: 'Ward'),
    (Male: 'Loga'; Female: 'Charlotte'; Family: 'Richardson'),
    (Male: 'Arthu'; Female: 'Judy'; Family: 'Watson'),
    (Male: 'Bruc'; Female: 'Amber'; Family: 'Brooks'),
    (Male: 'Bill'; Female: 'Julia'; Family: 'Chavez'),
    (Male: 'Elija'; Female: 'Grace'; Family: 'Wood'),
    (Male: 'Jo'; Female: 'Denise'; Family: 'James'),
    (Male: 'Ala'; Female: 'Danielle'; Family: 'Bennet'),
    (Male: 'Jua'; Female: 'Natalie'; Family: 'Gray'),
    (Male: 'Lia'; Female: 'Alice'; Family: 'Mendoza'),
    (Male: 'Willi'; Female: 'Marilyn'; Family: 'Ruiz'),
    (Male: 'Maso'; Female: 'Diana'; Family: 'Hughes'),
    (Male: 'Alber'; Female: 'Beverly'; Family: 'Price'),
    (Male: 'Rand'; Female: 'Jean'; Family: 'Alvarez'),
    (Male: 'Wayn'; Female: 'Brittany'; Family: 'Castillo'),
    (Male: 'Vincen'; Female: 'Theresa'; Family: 'Sanders'),
    (Male: 'Luca'; Female: 'Frances'; Family: 'Patel'),
    (Male: 'Cale'; Female: 'Kayla'; Family: 'Myers'),
    (Male: 'Luk'; Female: 'Alexis'; Family: 'Long'),
    (Male: 'Bobb'; Female: 'Tiffany'; Family: 'Ross'),
    (Male: 'Isaa'; Female: 'Lori'; Family: 'Foster'),
    (Male: 'Bradle'; Female: 'Kathy'; Family: 'Jimenez'));

function NewName: string;
begin
  if Random(2) = 0 then
    Result  := HundredNames[Random(100)].Male
  else
    Result  := HundredNames[Random(100)].Female;
  Result  := Result + ' ' + HundredNames[Random(100)].Family;
end;

end.
