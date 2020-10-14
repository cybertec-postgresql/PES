program PES;

uses
  Vcl.Forms,
  frmInstall in 'forms\frmInstall.pas' {fmInstall},
  uTetherModule in 'forms\uTetherModule.pas' {dmTether: TDataModule},
  Cluster in 'helpers\Cluster.pas',
  Console in 'helpers\Console.pas',
  Service in 'helpers\Service.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdmTether, dmTether);
  Application.CreateForm(TfmInstall, fmInstall);
  Application.Run;
end.
