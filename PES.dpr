program PES;

uses
  Vcl.Forms,
  frmInstall in 'forms\frmInstall.pas' {fmInstall},
  PythonVersions in 'python4delphi\PythonForDelphi\Components\Sources\Core\PythonVersions.pas',
  PythonEngine in 'python4delphi\PythonForDelphi\Components\Sources\Core\PythonEngine.pas',
  MethodCallBack in 'python4delphi\PythonForDelphi\Components\Sources\Core\MethodCallBack.pas',
  console in 'helpers\console.pas',
  template in 'templates\template.pas',
  VirtualTrees in 'virtualtreeview\Source\VirtualTrees.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmInstall, fmInstall);
  Application.Run;
end.
