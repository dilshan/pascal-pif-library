unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, ComCtrls;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    mnuSep1: TMenuItem;
    mnuExport: TMenuItem;
    mnuExit: TMenuItem;
    mnuFile: TMenuItem;
    mnuOpen: TMenuItem;
    mneMain: TMainMenu;
    dlgOpenImage: TOpenDialog;
    previewImage: TImage;
    dlgSave: TSaveDialog;
    scrollBox1: TScrollBox;
    statusMain: TStatusBar;
    procedure FormResize(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuExportClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  portableimage;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.mnuOpenClick(Sender: TObject);
var
  tempPIF: TPortableImageFile;
begin
  if(dlgOpenImage.Execute) then
  begin
    try
      tempPIF := TPortableImageFile.Create(dlgOpenImage.FileName);
      previewImage.Picture.Bitmap := tempPIF.Image;
      statusMain.Panels[0].Text := 'Format: ' + tempPIF.FormatName;
      statusMain.Panels[1].Text := IntToStr(previewImage.Picture.Bitmap.Width) + ' × ' + IntToStr(previewImage.Picture.Bitmap.Height);
      statusMain.Panels[2].Text := ExtractFileName(dlgOpenImage.FileName);

      mnuExport.Enabled := Assigned(previewImage.Picture.Bitmap);
      FormResize(Sender);
    except
      on E: Exception do
      begin
        MessageDlg(Application.Title, E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      end;
    end;
  end;
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.mnuExportClick(Sender: TObject);
begin
  dlgSave.FileName := '';
  if(Assigned(previewImage.Picture.Bitmap) and (dlgSave.Execute)) then
  begin
    previewImage.Picture.SaveToFile(dlgSave.FileName);
  end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
var
  leftPos, topPos: Integer;
begin
  leftPos := (scrollBox1.Width - previewImage.Width) div 2;
  if(leftPos < 0) then
  begin
    leftPos := 0;
  end;

  topPos := (scrollBox1.Height - previewImage.Height) div 2;
  if(topPos < 0) then
  begin
    topPos := 0;
  end;

  previewImage.Top := topPos;
  previewImage.Left := leftPos;
end;

end.

