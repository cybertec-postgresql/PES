unit frmInstall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.StrUtils, PythonVersions,
  Console, dxGDIPlusClasses, Vcl.ComCtrls, Vcl.ExtActns, System.Actions, Vcl.ActnList, SynEdit,
  SynMemo, SynEditHighlighter, SynHighlighterJSON;

type
  TfmInstall = class(TForm)
    btnNext: TButton;
    btnBack: TButton;
    Panel1: TPanel;
    imgHeader: TImage;
    pcWizard: TPageControl;
    tabPython: TTabSheet;
    btnInstall: TButton;
    mmInfo: TMemo;
    ActionList1: TActionList;
    acBack: TPreviousTab;
    acNext: TNextTab;
    tabNodes: TTabSheet;
    mmDBNodes: TMemo;
    Label1: TLabel;
    mmEctdNodes: TMemo;
    Label2: TLabel;
    Button1: TButton;
    acFinish: TAction;
    TabSheet1: TTabSheet;
    SynMemo1: TSynMemo;
    SynJSONSyn1: TSynJSONSyn;
    procedure UpdateInfo(Sender: TObject);
    procedure acFinishUpdate(Sender: TObject);
  private
  public
    { Public declarations }
  end;

var
  fmInstall: TfmInstall;

const
  PYTHON_VERSION: string = '3.7.5';

implementation

{$R *.dfm}

procedure TfmInstall.acFinishUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := pcWizard.ActivePageIndex = pcWizard.PageCount - 1;
end;

procedure TfmInstall.UpdateInfo(Sender: TObject);
var
    v:  TPythonVersion;
    vv: TPythonVersions;
begin
  mmInfo.Clear;
  mmInfo.Lines.Add('Default Python version in system:');
  mmInfo.Lines.Add('---------------------------------');
  mmInfo.Lines.Add(GetDosOutput('python.exe -c "import sys; print(sys.version)" '));
  mmInfo.Lines.Add('');
  mmInfo.Lines.Add('Installed Python versions in system:');
  mmInfo.Lines.Add('---------------------------------');
  vv := GetRegisteredPythonVersions();
  if Length(vv) > 0 then
    btnInstall.Caption := ifthen(Length(vv) > 0, 'Upgrade Python', 'Install Python');

  for v in vv do
  with mmInfo.Lines do
  begin
    btnInstall.Enabled := btnInstall.Enabled and (CompareVersions(v.Version, PYTHON_VERSION) > 0);
    Add(Format('Name: %s', [v.DisplayName]));
    Add(Format('Installation: %s', [v.InstallPath]));
    Add(Format('Executable: %s', [v.PythonExecutable]));
    Add('');
  end;

end;

end.
