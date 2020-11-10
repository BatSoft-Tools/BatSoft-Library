unit BatSoft.WebImage;
//  Copyright: Peter Thönell (BatSoft)
//  Feel free to use this in your projects, both commercial and personal.
//  This is donation-ware, so if you feel you are getting value out of it, please visit:
//  http://batsoft.com.au/batsoft-library-delphi/

interface

uses
  FMX.Objects;

type
  TWebImage = class(TImage)
  private
    fURL: string;
    procedure SetURL(const Value: string);
    procedure FetchImage(URL: string);
  public
    procedure Clear;
  published
    property  URL: string read fURL write SetURL;
  end;

procedure Register;

implementation

uses
  System.Classes, System.UITypes, IdHTTP;

procedure Register;
begin
  RegisterComponents('BatSoft', [TWebImage]);
end;

{ TWebImage }

procedure TWebImage.Clear;
begin
  Bitmap.Clear(TAlphaColorRec.White);
end;

procedure TWebImage.FetchImage(URL: string);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      HTTP: TIdHTTP;
      Stream: TMemoryStream;
    begin
      HTTP  := TIdHTTP.Create(nil);
      try
        Stream  := TMemoryStream.Create;
        try
          try
            HTTP.Get(URL, Stream);
            Stream.Position := 0;
            TThread.Synchronize(nil, procedure begin Bitmap.LoadFromStream(Stream); end);
          except
            TThread.Synchronize(nil, procedure begin Clear; end);
          end;
        finally
          Stream.Free;
        end;
      finally
        HTTP.Free;
      end;
    end
    ).Start;
end;

procedure TWebImage.SetURL(const Value: string);
begin
  fURL := Value;
  if fURL = '' then
    Clear
  else
    FetchImage(fURL);
end;

end.
