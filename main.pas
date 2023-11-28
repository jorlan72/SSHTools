unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.AppEvnts, iphcore, iphsshell, Vcl.Imaging.jpeg;

type
  TFrmMain = class(TForm)
    PanelTop: TPanel;
    GroupBoxActions: TGroupBox;
    PanelHosts: TPanel;
    GroupBoxHosts: TGroupBox;
    GroupBoxConfiguration: TGroupBox;
    GroupBoxFailedHosts: TGroupBox;
    GroupBoxLog: TGroupBox;
    Splitter1: TSplitter;
    MemoHosts: TMemo;
    MemoConfiguration: TMemo;
    MemoFailedHosts: TMemo;
    Log: TMemo;
    GroupBoxParameters: TGroupBox;
    ButtonStart: TButton;
    ButtonStop: TButton;
    ButtonExit: TButton;
    EditLoginDelay: TEdit;
    EditLineSendDelay: TEdit;
    EditLogoffDelay: TEdit;
    LabelLogin: TLabel;
    LabelLineSend: TLabel;
    LabelLogoff: TLabel;
    StatusBar: TStatusBar;
    ApplicationEvents: TApplicationEvents;
    sshclient: TiphSShell;
    LogFeedback: TCheckBox;
    ButtonClearLists: TButton;
    procedure ApplicationEventsHint(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure ButtonExitClick(Sender: TObject);
    procedure sshclientSSHServerAuthentication(Sender: TObject; HostKey: string;
      const Fingerprint, KeyAlgorithm, CertSubject, CertIssuer, Status: string;
      var Accept: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure sshclientStdout(Sender: TObject; Text: string);
    procedure sshclientStderr(Sender: TObject; Text: string);
    procedure ButtonClearListsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  StopJob : boolean;
  JobRunning : boolean;

implementation

{$R *.dfm}


Procedure HangOn(const time:integer);
var
 counter : integer;
 i : integer;
begin
 counter := time div 1000;
 counter := counter * 10;
  for i := 0 to counter do begin
    sleep(100);
    application.ProcessMessages;
  end;
end;

Procedure LogAddText(const Logtekst: string);
begin
frmmain.Log.Lines.Add(timetostr(now) + ' - ' + Logtekst);
end;

Procedure LogClear;
begin
frmmain.log.Lines.Clear;
frmmain.log.Update;
end;

Procedure LogAddSpace;
begin
frmmain.log.Lines.add(' ');
end;

Procedure LogDate;
begin
frmmain.Log.lines.add(datetostr(now));
end;

Procedure DoSSHHost(const host:string);
var
 i : integer;
begin
if stopjob = true then exit;
  try
    begin
    frmmain.sshclient.SSHUser := frmmain.memoconfiguration.lines.Strings[0];
    frmmain.sshclient.SSHPassword := frmmain.memoconfiguration.lines.Strings[1];
    logaddtext('Logging into host : ' + host);
    frmmain.sshclient.SSHLogon(host,22);
    HangOn(strtoint(frmmain.editlogindelay.text));
    frmmain.sshclient.doevents;
    logaddtext('Processing configuration lines.');
    if stopjob = true then exit;
     for i := 2 to frmmain.MemoConfiguration.Lines.Count -1 do begin
       if stopjob = true then exit;
       frmmain.sshclient.command := frmmain.MemoConfiguration.Lines.Strings[i];
       HangOn(strtoint(frmmain.EditLineSendDelay.Text));
       frmmain.sshclient.doevents;
     end;
    logaddtext('All configuration lines sent.');
    HangOn(strtoint(frmmain.EditLogoffDelay.Text));
    frmmain.sshclient.SSHLogoff;
    frmmain.sshclient.doevents;
    logaddtext('Logged out of host : ' + host);
    logaddspace;
    end;
  except
      on E: Exception do begin
      logaddtext('Could not connect to host : ' + host);
      logaddtext('The following error occured:');
      frmmain.MemoFailedHosts.Lines.Add(host);
      logaddtext(e.Message);
      logaddspace;
      E.CleanupInstance;
      end;
  end;
end;

procedure TFrmMain.ApplicationEventsHint(Sender: TObject);
begin
statusbar.SimpleText := application.Hint;
end;

procedure TFrmMain.ButtonClearListsClick(Sender: TObject);
begin
 memohosts.Clear;
 memoconfiguration.Clear;
 memofailedhosts.Clear;
 log.Clear;
end;

procedure TFrmMain.ButtonExitClick(Sender: TObject);
begin
if jobrunning then begin
   if MessageDlg('Would you like to cancel the running job and exit the application?',
    mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then  begin
    halt(1);
    end;
end;
halt(1);
end;

procedure TFrmMain.ButtonStartClick(Sender: TObject);
var
 i : integer;
begin
jobrunning := true;
LogClear;
memofailedhosts.Lines.Clear;
Logdate;
LogAddText('Starting SSH Batcher Job');
LogAddText('Delay parameters in use : ' + editlogindelay.Text + ', ' + editlinesenddelay.Text + ', ' + editlogoffdelay.Text);
buttonStop.Enabled := true;
LogAddText('Stop Running Job button enabled');
Logaddspace;
if memohosts.Lines.Count = 0 then begin
 showmessage('You need to have some hosts to work with.' +  sLineBreak +  sLineBreak + 'Dude! come on...');
 LogAddText('No hosts to work with in hosts list. User was told what terrible mistake this is.');
 buttonStop.Enabled := true;
 LogAddText('Stop Running Job button disabled');
 Logaddspace;
 LogAddText('Job ended. In fact, nothing was done. Start over');
 jobrunning := false;
 exit;
end;
if memoconfiguration.Lines.Count = 0 then begin
 showmessage('You need to have some configuration to work with.' +  sLineBreak +  sLineBreak + 'Dude! come on...');
 LogAddText('No configuration lines to work with. User was told what terrible mistake this is.');
 buttonStop.Enabled := true;
 LogAddText('Stop Running Job button disabled');
 Logaddspace;
 LogAddText('Job ended. In fact, nothing was done. Start over.');
 jobrunning := false;
 exit;
end;
 for i := 0 to memohosts.Lines.Count -1 do begin
   if stopjob = true then begin
     Logaddspace;
     LogAddText('Job canceled');
     buttonStop.Enabled := false;
     stopjob := false;
     LogAddText('Stop Running Job button disabled');
     jobrunning := false;
     LogAddText('Job ended before it was complete. Interrupted by user.');
     exit;
   end;
   LogAddText('Processing ' + inttostr(i + 1) + ' of ' + inttostr(memohosts.Lines.Count));
   LogAddText('*************************************');
   DoSSHHost(memohosts.Lines.Strings[i]);
 end;
Logaddspace;
buttonStop.Enabled := false;
stopjob := false;
LogAddText('Stop Running Job button disabled');
jobrunning := false;
LogAddText('Job completed.');
LogAddText(inttostr(memofailedhosts.Lines.Count) + ' hosts failed. Review the Failed Hosts list');
end;

procedure TFrmMain.ButtonStopClick(Sender: TObject);
begin
 if MessageDlg('Would you like to cancel the running job?',
    mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then  begin
    stopjob := true;
    LogAddText('Job will now terminate at the wish of the user. Pushing last command. Please hold...');
    end;
end;

procedure TFrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 if jobrunning then begin
   if MessageDlg('Would you like to cancel the running job and exit the application?',
    mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrNo then  canclose := false
 end;
end;

procedure TFrmMain.sshclientSSHServerAuthentication(Sender: TObject;
  HostKey: string; const Fingerprint, KeyAlgorithm, CertSubject, CertIssuer,
  Status: string; var Accept: Boolean);
begin
accept := true;
end;

procedure TFrmMain.sshclientStderr(Sender: TObject; Text: string);
begin
 if logfeedback.Checked then begin
 log.Text := log.Text + Text;
 log.SelStart := Length(log.Text);
 SendMessage(log.Handle,EM_SCROLLCARET,0,0);
 end;
end;

procedure TFrmMain.sshclientStdout(Sender: TObject; Text: string);
begin
 if logfeedback.Checked then begin
 log.Text := log.Text + Text;
 log.SelStart := Length(log.Text);
 SendMessage(log.Handle,EM_SCROLLCARET,0,0);
 end;
end;

end.
