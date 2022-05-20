unit uman;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls;

type
  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuOpen: TMenuItem;
    mnuExport: TMenuItem;
    mnuSep1: TMenuItem;
    mnuExit: TMenuItem;
    scrollBox1: TScrollBox;
    previewImage: TImage;
    statusMain: TStatusBar;
    dlgSave: TSaveDialog;
    dlgOpenImage: TOpenDialog;
    procedure mnuOpenClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure mnuExportClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  portableimage;

{$R *.dfm}

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
        MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      end;
    end;
  end;
end;

end.
