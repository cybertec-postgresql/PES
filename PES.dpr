program PES;

uses
  Vcl.Forms,
  frmInstall in 'forms\frmInstall.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
