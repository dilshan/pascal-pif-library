program nativepif;

uses
  Vcl.Forms,
  uman in 'uman.pas' {frmMain},
  portableimage in '..\..\src\portableimage.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Native PIF Viewer';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
