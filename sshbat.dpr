program sshbat;

uses
  Vcl.Forms,
  main in 'main.pas' {FrmMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'SSH Batcher';
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
