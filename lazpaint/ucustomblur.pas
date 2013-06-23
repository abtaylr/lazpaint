unit ucustomblur; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ExtDlgs,  bgrabitmap, LazPaintType, uscaledpi, uresourcestrings;

type

  { TFCustomBlur }

  TFCustomBlur = class(TForm)
    Button_LoadMask: TButton;
    Button_EditMask: TButton;
    Button_OK: TButton;
    Button_Cancel: TButton;
    btnLoadMask: TButton;
    Image1: TImage;
    OpenPictureDialog1: TOpenPictureDialog;
    procedure Button_EditMaskClick(Sender: TObject);
    procedure Button_LoadMaskClick(Sender: TObject);
    procedure Button_OKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadMask(filename: string);
  private
    subConfig: TStringStream;
    FLazPaintInstance: TLazPaintCustomInstance;
    procedure GenerateDefaultMask;
    procedure SetLazPaintInstance(const AValue: TLazPaintCustomInstance);
  public
    sourceLayer, filteredLayer : TBGRABitmap;
    function ShowDlg(ALayer:TBGRABitmap; out AFilteredLayer: TBGRABitmap): boolean;
    property LazPaintInstance: TLazPaintCustomInstance read FLazPaintInstance write SetLazPaintInstance;
  end;

implementation

uses umac,BGRABitmapTypes;

{ TFCustomBlur }

procedure TFCustomBlur.FormCreate(Sender: TObject);
begin
  ScaleDPI(Self,OriginalDPI);

  CheckOKCancelBtns(Button_OK,Button_Cancel);
  filteredLayer := nil;
  subConfig := TStringStream.Create('[Tool]'+LineEnding+
    'ForeColor=FFFFFFFF'+LineEnding+
    'BackColor=000000FF'+LineEnding+
    'PenWidth=1');
end;

procedure TFCustomBlur.FormDestroy(Sender: TObject);
begin
  subConfig.Free;
end;

procedure TFCustomBlur.LoadMask(filename: string);
var loadedImg, grayscale: TBGRABitmap;
    bmp: TBitmap;
begin
  loadedImg := TBGRABitmap.Create(UTF8ToSys( filename ));
  grayscale := loadedImg.FilterGrayscale as TBGRABitmap;
  loadedImg.Free;

  bmp := grayscale.MakeBitmapCopy(clBlack);
  grayscale.free;
  Image1.Picture.Assign(bmp);
  bmp.Free;
end;

procedure TFCustomBlur.GenerateDefaultMask;
var bmp: TBitmap;
    defaultMask: TBGRABitmap;
begin
  defaultMask := TBGRABitmap.Create(11,11);
  defaultMask.GradientFill(0,0,11,11,BGRAWhite,BGRABlack,gtRadial,pointf(5,5),pointf(-0.5,5),dmSet);
  bmp := defaultMask.MakeBitmapCopy(clBlack);
  defaultMask.Free;
  Image1.Picture.Assign(bmp);
  bmp.Free;
end;

procedure TFCustomBlur.SetLazPaintInstance(const AValue: TLazPaintCustomInstance);
var
  defaultMaskFilename: String;
begin
  FLazPaintInstance := AValue;
  defaultMaskFilename := LazPaintInstance.Config.DefaultCustomBlurMask;
  if (defaultMaskFilename = '') or not FileExists(defaultMaskFilename) then
    GenerateDefaultMask else
  begin
    try
      LoadMask(defaultMaskFilename);
    except
      on ex: Exception do
      begin
        LazPaintInstance.Config.SetDefaultCustomBlurMask('');
        GenerateDefaultMask;
      end;
    end;
  end;
end;

function TFCustomBlur.ShowDlg(ALayer: TBGRABitmap; out AFilteredLayer: TBGRABitmap): boolean;
begin
  AFilteredLayer := nil;
  result := false;
  sourceLayer := ALayer;
  filteredLayer := nil;
  result:= (showmodal = mrOk);
  AFilteredLayer := filteredLayer;
end;

procedure TFCustomBlur.Button_LoadMaskClick(Sender: TObject);
var filename: string;
begin
  if not OpenPictureDialog1.Execute then exit;
  try
    filename := OpenPictureDialog1.FileName;
    LoadMask(filename);
    LazPaintInstance.Config.SetDefaultCustomBlurMask(filename);
  except
    on ex:Exception do
    begin
      MessageDlg(ex.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TFCustomBlur.Button_EditMaskClick(Sender: TObject);
var bgraBmp: TBGRABitmap;
    bmpCopy: TBitmap;
begin
  bgraBmp := TBGRABitmap.Create(Image1.Picture.Width,Image1.Picture.Height);
  bgraBmp.Canvas.Draw(0,0,image1.picture.bitmap);
  bgraBmp.AlphaFill(255);
  LazPaintInstance.EditBitmap(bgraBmp,subConfig,rsEditMask);
  BGRAReplace(bgraBmp,bgraBmp.FilterGrayscale);
  bmpCopy := bgraBmp.MakeBitmapCopy(clBlack);
  Image1.Picture.Assign(bmpCopy);
  bmpCopy.Free;
  bgraBmp.Free;
end;

procedure TFCustomBlur.Button_OKClick(Sender: TObject);
var mask: TBGRABitmap;
begin
    if (sourceLayer <> nil) then
    begin
      mask := TBGRABitmap.Create(Image1.Picture.Width,Image1.Picture.Height);
      mask.Canvas.Draw(0,0,image1.picture.bitmap);
      mask.AlphaFill(255);
      filteredLayer := sourceLayer.FilterCustomBlur(mask) as TBGRABitmap;
      mask.Free;
      ModalResult := mrOK;
    end else
      ModalResult := mrCancel;
end;

initialization
  {$I ucustomblur.lrs}

end.
