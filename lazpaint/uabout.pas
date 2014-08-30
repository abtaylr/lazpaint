unit UAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, uscaledpi, BGRATextFX, BGRAGradients,
  LazPaintType;

type

  { TFAbout }

  TFAbout = class(TForm)
    Button_Donate: TBitBtn;
    Image_Title: TImage;
    Label_Authors: TLabel;
    Label_HomePage: TLabel;
    Label_AuthorsValue: TLabel;
    LabelUrl: TLabel;
    Label_Libraries: TLabel;
    Label_LibrariesValue: TLabel;
    Label_Licence: TLabel;
    Label_OpenSource: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Timer1: TTimer;
    procedure Button_DonateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LabelUrlClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    FInstance: TLazPaintCustomInstance;
    titleStartTime: TDateTime;
    frameNumber: integer;
    fx: TBGRATextEffect;
    shader: TPhongShading;
    angle: single;
    procedure RenderTitle;
  public
    { public declarations }
  end;

procedure ShowAboutDlg(AInstance: TLazPaintCustomInstance; {%H-}AText: string);

implementation

uses LCLIntf, BGRABitmap, BGRABitmapTypes;

procedure ShowAboutDlg(AInstance: TLazPaintCustomInstance; {%H-}AText: string);
var
  About: TFAbout;
begin
  About := nil;
  try
    About:= TFAbout.create(nil);
    About.FInstance := AInstance;
    About.ShowModal;
  except
    on ex:Exception do
      AInstance.ShowError('ShowAboutDlg',ex.Message);
  end;
  About.Free;
end;

{ TFAbout }

procedure TFAbout.LabelUrlClick(Sender: TObject);
begin
  OpenURL(LabelUrl.Caption);
end;

procedure TFAbout.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := false;
  angle += 2*Pi/180;
  RenderTitle;
  Timer1.Enabled := true;
end;

procedure TFAbout.RenderTitle;
var bmp: TBGRABitmap;
begin
  shader.LightPosition := Point(round((cos(angle)+1)/2*Image_Title.Width),round((sin(angle)+1)*Image_Title.height));
  inc(frameNumber);
  bmp := TBGRABitmap.Create(Image_Title.Width,Image_Title.Height,ColorToRGB(clBtnFace));

  fx.DrawShaded(bmp,bmp.Width div 2,0, shader, 2,
    MergeBGRA(ColorToBGRA(ColorToRGB(clBtnFace)),ColorToBGRA(ColorToRGB(clWindowText))),
    taCenter, false);

  bmp.Draw(Image_Title.Picture.Bitmap.Canvas,0,0,true);
  bmp.Free;
  Image_Title.Refresh;
end;

procedure TFAbout.FormShow(Sender: TObject);
begin
  titleStartTime := Now;
  RenderTitle;
  Timer1.Enabled := true;
end;

procedure TFAbout.FormHide(Sender: TObject);
begin
  Timer1.Enabled := false;
end;

procedure TFAbout.FormCreate(Sender: TObject);
var bmp: TBitmap;
    titlefont: TFont;
begin
  ScaleDPI(Self,OriginalDPI);

  Self.DoubleBuffered:=True;

  bmp := TBitmap.Create;
  bmp.Width := Image_Title.Width;
  bmp.Height := Image_Title.Height;
  bmp.PixelFormat := pf24bit;
  Image_Title.Picture.Bitmap := Bmp;
  bmp.Free;
  FrameNumber := 0;

  titlefont := TFont.Create;
  titlefont.Height := Image_Title.Height;
  titlefont.Name := 'Arial';
  titlefont.Style := [fsBold];
  fx := TBGRATextEffect.Create('LazPaint ' + LazPaintCurrentVersion,titlefont,True);
  titlefont.Free;
  shader := TPhongShading.Create;
end;

procedure TFAbout.Button_DonateClick(Sender: TObject);
begin
  FInstance.Donate;
end;

procedure TFAbout.FormDestroy(Sender: TObject);
begin
  fx.Free;
  shader.Free;
end;

{$R *.lfm}

end.

