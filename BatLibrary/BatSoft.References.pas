unit BatSoft.References;

interface

uses
  Generics.Collections, RTTI, BatSoft.Classes;

type
  TState = (Available, Unknown, InUse);

  PReferenceRecord = ^TReferenceRecord;
  TReferenceRecord = record
  public
    Obj: TObject;
    RefCount: integer;
    State: TState;
    Next: PReferenceRecord;
  end;

  //NOTE:
  //  Really ReferenceOnOnHeap<T> and ReferenceOnStackOrGlobal<T> ought to be a
  //  single type called Reference<T>. But because I don't know how to determine
  //  whether an address (specifically, the location of fRefRec) is on the stack
  //  or is a global variable (on the heap), thereby making it a root ref, or
  //  whether it is otherwise on the heap, thereby making it a NOT root ref, I
  //  have resorted to breaking it into two distinct types.
  //  Until there is a way to determine that, it is up to the programmer to
  //  ensure that the correct type is used depending on where it is located.

  ReferenceOnOnHeap<T: class> = record
  private
    fRefRec: PReferenceRecord;
    function  GetObj: T;
    class function  IsRootRef(const P: Pointer): Boolean; static; inline;
  public
    class operator  Initialize(out Dest: ReferenceOnOnHeap<T>);
    class operator  Finalize(var Dest: ReferenceOnOnHeap<T>);
    class operator  Assign(var Dest: ReferenceOnOnHeap<T>; const [ref] Src: ReferenceOnOnHeap<T>); inline;
    class function  New(const Obj: T): ReferenceOnOnHeap<T>; static; inline;
    property  Obj: T read GetObj;
  end;

  ReferenceOnStackOrGlobal<T: class> = record
  private
    fRefRec: PReferenceRecord;
    function  GetObj: T;
    class function  IsRootRef(const P: Pointer): Boolean; static; inline;
  public
    class operator  Initialize(out Dest: ReferenceOnStackOrGlobal<T>);
    class operator  Finalize(var Dest: ReferenceOnStackOrGlobal<T>);
    class operator  Assign(var Dest: ReferenceOnStackOrGlobal<T>; const [ref] Src: ReferenceOnStackOrGlobal<T>); inline;
    class function  New(const Obj: T): ReferenceOnStackOrGlobal<T>; static; inline;
    property  Obj: T read GetObj;
  end;

  ReferenceGC = class
  private const
    RefRecArraySize  = 128;
  private type
    //  Classes and their reference fields

    TRefRecArray = array [0..RefRecArraySize - 1] of TReferenceRecord;
    PRefRecArray = ^TRefRecArray;

    TRefRecArrays = class(TBinaryList<PRefRecArray>)
    private
      fFree, fUsed: PReferenceRecord;
      function  CreateArray: PRefRecArray;
      procedure FreeArray(var RefRecArray: PRefRecArray);
    public
      function  Obtain: PReferenceRecord;
      procedure Release(var RefRec: PReferenceRecord);
      procedure Pack;
    end;

  private
    //  Reference records
    class var _RefRecArrays: TRefRecArrays;
    class var _ClassFields: TDictionary<TClass, TArray<TRttiField>>;
    class function  ObtainClassFields(const AClass: TClass): TArray<TRttiField>;
  private
    class function  ObtainRefRec(const Obj: TObject): PReferenceRecord;
  private
    class constructor Create;
    class destructor  Destroy;
  public
    class procedure Collect;
  end;

implementation

var
  RTTICtx: TRttiContext;

{ ReferenceOnOnHeap<T> }

class operator ReferenceOnOnHeap<T>.Assign(var Dest: ReferenceOnOnHeap<T>; const [ref] Src: ReferenceOnOnHeap<T>);
begin
  //  Decrement ref count
  if  IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
  //  Update ReferenceOnStack
  Dest.fRefRec := Src.fRefRec;
  //  Increment ref count
  if  IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
end;

function ReferenceOnOnHeap<T>.GetObj: T;
begin
  if  Assigned(fRefRec) then
    Result  := T(fRefRec.Obj)
  else
    Result  := nil
end;

class operator ReferenceOnOnHeap<T>.Finalize(var Dest: ReferenceOnOnHeap<T>);
begin
  if IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
end;

class operator ReferenceOnOnHeap<T>.Initialize(out Dest: ReferenceOnOnHeap<T>);
begin
  Dest.fRefRec  := nil;
end;

class function ReferenceOnOnHeap<T>.IsRootRef(const P: Pointer): Boolean;
begin
  //  True iff P is local or global variable
  Result  := False
end;

class function ReferenceOnOnHeap<T>.New(const Obj: T): ReferenceOnOnHeap<T>;
begin
  Result.fRefRec  := ReferenceGC.ObtainRefRec(Obj);
end;

{ ReferenceOnStackOrGlobal<T> }

class operator ReferenceOnStackOrGlobal<T>.Assign(var Dest: ReferenceOnStackOrGlobal<T>; const [ref] Src: ReferenceOnStackOrGlobal<T>);
begin
  //  Decrement ref count
  if  IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
  //  Update ReferenceOnStack
  Dest.fRefRec := Src.fRefRec;
  //  Increment ref count
  if  IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
end;

function ReferenceOnStackOrGlobal<T>.GetObj: T;
begin
  if  Assigned(fRefRec) then
    Result  := T(fRefRec.Obj)
  else
    Result  := nil
end;

class operator ReferenceOnStackOrGlobal<T>.Finalize(var Dest: ReferenceOnStackOrGlobal<T>);
begin
  if IsRootRef(Dest.fRefRec) and Assigned(Dest.fRefRec)  then
    dec(Dest.fRefRec.RefCount);
end;

class operator ReferenceOnStackOrGlobal<T>.Initialize(out Dest: ReferenceOnStackOrGlobal<T>);
begin
  Dest.fRefRec  := nil;
end;

class function ReferenceOnStackOrGlobal<T>.IsRootRef(const P: Pointer): Boolean;
begin
  //  True iff P is local or global variable
  Result  := True
end;

class function ReferenceOnStackOrGlobal<T>.New(const Obj: T): ReferenceOnStackOrGlobal<T>;
begin
  Result.fRefRec  := ReferenceGC.ObtainRefRec(Obj);
end;

{ ReferenceGC.TRefRecArrays }

function  ReferenceGC.TRefRecArrays.CreateArray: PRefRecArray;
begin
  GetMem(Result, SizeOf(TRefRecArray));
  FillChar(Result^, SizeOf(TRefRecArray), 0);
  Add(Result);
end;

procedure ReferenceGC.TRefRecArrays.FreeArray(var RefRecArray: PRefRecArray);
begin
  FreeMem(RefRecArray);
end;

function  ReferenceGC.TRefRecArrays.Obtain: PReferenceRecord;
begin
  if  Assigned(fFree) then
    begin
      Result  := fFree;
      fFree   := fFree.Next;
    end
  else
    Result  := @(CreateArray[0])
end;

procedure ReferenceGC.TRefRecArrays.Pack;
var
  iRefRecArr, iRefRec: integer;
  Used: Boolean;
begin
  fFree := nil;
  for iRefRecArr := Count - 1 downto 0 do
    begin
      Used  := False;
      //
      for iRefRec := 0 to RefRecArraySize - 1 do
        if  Self[iRefRecArr][iRefRec].State = TState.Available  then
          begin
            Self[iRefRecArr][iRefRec].Next  := fFree;
            fFree := @Self[iRefRecArr][iRefRec];
          end
        else
          Used  := True;
      //
      if  not Used  then
        Delete(iRefRecArr);
    end;
end;

procedure ReferenceGC.TRefRecArrays.Release(var RefRec: PReferenceRecord);
begin

end;

{ ReferenceGC }

class procedure ReferenceGC.Collect;
var
  Queue: TQueue<PReferenceRecord>;
  Unqueued: TList<PReferenceRecord>;
  CurrRefRec, NewRefRec: PReferenceRecord;
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  _Used, _Free: TList<PReferenceRecord>;
begin
  Queue     := TQueue<PReferenceRecord>.Create;
  Unqueued  := TList<PReferenceRecord>.Create;
  _Used         := TList<PReferenceRecord>.Create;
  _Free         := TList<PReferenceRecord>.Create;
  try
    //  Separate root referenced from not root referenced
    for CurrRefRec in _Used do
      if Boolean(CurrRefRec.RefCount) then
        begin
          CurrRefRec.State  := InUse;
          Queue.Enqueue(CurrRefRec);
        end
      else
        begin
          CurrRefRec.State  := Unknown;
          Unqueued.Add(CurrRefRec);
        end;
    //  Run through queue, adding indrectly referenced
    while Queue.Count > 0 do
      begin
        CurrRefRec  := Queue.Dequeue;
        Fields      := ObtainClassFields(CurrRefRec.Obj.ClassType);
        for Field in Fields do
          begin
            NewRefRec := Pointer(Field.GetValue(CurrRefRec.Obj).AsInteger);
            if Assigned(NewRefRec) and (NewRefRec.State = Unknown) then
              begin
                NewRefRec.State := InUse;
                Queue.Enqueue(CurrRefRec);
              end;
          end;
      end;
    //  Free unreferenced objects
    for CurrRefRec in Unqueued do
      if CurrRefRec.State = Unknown then
        begin
          CurrRefRec.Obj.Free;
          CurrRefRec.State  := Available;
          _Free.Add(CurrRefRec);
          _Used.Remove(CurrRefRec);
        end;
    //  Tidy up
  finally
    _Used.Free;
    _Free.Free;
    Queue.Free;
    Unqueued.Free;
  end;
end;

class constructor ReferenceGC.Create;
begin
  _ClassFields  := TDictionary<TClass, TArray<TRttiField>>.Create;
  _RefRecArrays := TRefRecArrays.Create;
end;

class destructor ReferenceGC.Destroy;
begin
  _RefRecArrays.Free;
  _ClassFields.Free;
end;

class function ReferenceGC.ObtainClassFields(const AClass: TClass): TArray<TRttiField>;
var
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  List: TList<TRttiField>;
begin
  if not _ClassFields.TryGetValue(AClass, Result) then
    begin
      //  Find class fields
      Fields  := RTTICtx.GetType(AClass).AsInstance.GetDeclaredFields;
      //  Filter in only reference fields
      List  := TList<TRttiField>.Create;
      try
        for Field in Fields do
          if True then
            List.Add(Field);
        if  List.Count = 0  then
          Result  := nil
        else
          Result  := List.ToArray;
      finally
        List.Free;
      end;
      //  Add to dictionary
      _ClassFields.Add(AClass, Result);
    end;
end;

class function ReferenceGC.ObtainRefRec(const Obj: TObject): PReferenceRecord;
begin
  //  Ensure we have available reference records to draw from
  Result  := _RefRecArrays.Obtain;
  //  Initialise reference record
  Result.RefCount := 1;
  Result.Obj      := Obj;
  Result.State    := Unknown;
end;

initialization
  RTTICtx := TRttiContext.Create;

finalization
  ReferenceGC.Collect;
  RTTICtx.Free;

end.
