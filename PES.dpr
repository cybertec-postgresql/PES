program PES;

uses
  Vcl.Forms,
  frmInstall in 'forms\frmInstall.pas' {fmInstall},
  console in 'helpers\console.pas',
  template in 'templates\template.pas',
  uTetherModule in 'forms\uTetherModule.pas' {dmTether: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdmTether, dmTether);
  Application.CreateForm(TfmInstall, fmInstall);
  Application.Run;
end.
