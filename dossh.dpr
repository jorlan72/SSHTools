program dossh;

uses
  Vcl.Forms,
  main in 'main.pas' {frmMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.Title := 'DoSSH';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
