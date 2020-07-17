unit frmInstall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.StrUtils, PythonVersions,
  Console, template, Vcl.ComCtrls, Vcl.ExtActns, System.Actions, Vcl.ActnList, SynEdit,
  SynMemo, SynEditHighlighter, SynHighlighterJSON, Winapi.ShlObj, cxShellCommon, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxCustomData, cxStyles,
  cxTL, cxTextEdit, cxCheckBox, cxTLdxBarBuiltInMenu, cxInplaceContainer, cxMaskEdit,
  cxDropDownEdit, cxShellComboBox, dxGDIPlusClasses;

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
    Button1: TButton;
    acFinish: TAction;
    TabSheet1: TTabSheet;
    SynMemo1: TSynMemo;
    SynJSONSyn1: TSynJSONSyn;
    tlNodes: TcxTreeList;
    tlcHost: TcxTreeListColumn;
    tlcDatabase: TcxTreeListColumn;
    tlcEtcd: TcxTreeListColumn;
    tlcFailover: TcxTreeListColumn;
    edClusterName: TEdit;
    lbClusterName: TLabel;
    lbNodes: TLabel;
    tlcName: TcxTreeListColumn;
    tabPostgres: TTabSheet;
    lbBinDir: TLabel;
    cbBinDir: TcxShellComboBox;
    Label1: TLabel;
    cbDataDir: TcxShellComboBox;
    btnGenerateConfigs: TButton;
    Label2: TLabel;
    edReplicationRole: TEdit;
    Label3: TLabel;
    edReplicationPassword: TEdit;
    Label4: TLabel;
    edSuperuserRole: TEdit;
    Label5: TLabel;
    edSuperuserPassword: TEdit;
    Label6: TLabel;
    edClusterToken: TEdit;
    btnLoadConfig: TButton;
    procedure UpdateInfo(Sender: TObject);
    procedure acFinishUpdate(Sender: TObject);
    procedure tlcEtcdPropertiesValidate(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure tlNodesNodeChanged(Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
      AColumn: TcxTreeListColumn);
    procedure btnGenerateConfigsClick(Sender: TObject);
    procedure btnLoadConfigClick(Sender: TObject);
  private
  public
    procedure InvalidateCluster(ACluster: TCluster);
  end;



var
  fmInstall: TfmInstall;


const
  PYTHON_VERSION: string = '3.7.5';

implementation

uses Math, IOUtils;

{$R *.dfm}

procedure TfmInstall.acFinishUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := pcWizard.ActivePageIndex = pcWizard.PageCount - 1;
end;

procedure TfmInstall.btnGenerateConfigsClick(Sender: TObject);
var
  Cluster: TCluster;
  Node: TNode;
  N: TcxTreeListNode;
  I: Integer;
begin
  Cluster := TCluster.Create(Self);
  try
    Cluster.Name := edClusterName.Text;
    Cluster.PostgresDir := cbBinDir.Path;
    Cluster.DataDir := cbDataDir.Path;
    Cluster.ReplicationRole := edReplicationRole.Text;
    Cluster.ReplicationPassword := edReplicationPassword.Text;
    Cluster.SuperUser := edSuperuserRole.Text;
    Cluster.SuperUserPassword := edSuperuserPassword.Text;
    Cluster.EtcdClusterToken := edClusterToken.Text;
    Cluster.Existing := False;
    Cluster.PostgresParameters := '';
    for I := 0 to tlNodes.AbsoluteCount-1 do
    begin
      N := tlNodes.AbsoluteItems[I];
      Node := TNode.Create(Cluster);
      Node.Name := N.Texts[tlcName.ItemIndex];
      Node.IP := N.Texts[tlcHost.ItemIndex];
      Node.HasDatabase := N.Values[tlcDatabase.ItemIndex] = True;
      Node.HasEtcd := N.Values[tlcEtcd.ItemIndex] = True;
      Node.NoFailover := N.Values[tlcFailover.ItemIndex] = False;
      //Cluster.Nodes.Add(Node);
    end;
    IOutils.TDirectory.CreateDirectory(Cluster.ClusterName);
    Cluster.SaveToFile(Cluster.ClusterName+'\cluster.txt');
  finally
    Cluster.Free;
  end;
end;

procedure TfmInstall.btnLoadConfigClick(Sender: TObject);
var
  Cluster: TCluster;
begin
  Cluster := TCluster.Create(Self);
  try
    Cluster.LoadFromFile('pgcluster\cluster.txt');
    InvalidateCluster(Cluster);
  finally
    Cluster.Free;
  end;
end;

procedure TfmInstall.InvalidateCluster(ACluster: TCluster);
var
  I: Integer;
  N: TNode;
begin
  edClusterName.Text := ACluster.ClusterName;
  cbBinDir.Path := ACluster.PostgresDir;
  cbDataDir.Path := ACluster.DataDir;
  edReplicationRole.Text := ACluster.ReplicationRole;
  edReplicationPassword.Text := ACluster.ReplicationPassword;
  edSuperuserRole.Text := ACluster.SuperUser;
  edSuperuserPassword.Text := ACluster.SuperUserPassword;
  edClusterToken.Text := ACluster.EtcdClusterToken;
  // False := Cluster.Existing;
  // '' := Cluster.PostgresParameters;
  tlNodes.BeginUpdate;
  tlNodes.Clear;
  try
    for I := 0 to ACluster.ComponentCount - 1 do
      with tlNodes.Add do
      begin
        N := ACluster.Components[I] as TNode;
        Texts[tlcName.ItemIndex] := N.Name;
        Texts[tlcHost.ItemIndex] := N.IP;
        Values[tlcDatabase.ItemIndex] := N.HasDatabase;
        Values[tlcEtcd.ItemIndex] := N.HasEtcd;
        Values[tlcFailover.ItemIndex] := not N.NoFailover;
      end;
  finally
    tlNodes.EndUpdate;
  end;

end;

procedure TfmInstall.tlcEtcdPropertiesValidate(Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to tlNodes.Count - 1 do
  begin
    if tlNodes.Items[I].Values[tlcEtcd.ItemIndex] = True then
      inc(N)
  end;
  Error := N in [1,3,5,7];
  ErrorText := Format('Etcd cluster size %d not supported, use odd number of nodes up to 7', [N+1]);
end;

procedure TfmInstall.tlNodesNodeChanged(Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
  AColumn: TcxTreeListColumn);
var
  I: Integer;
begin
  for I := tlcDatabase.ItemIndex to tlcFailover.ItemIndex do
    if ANode.Values[I] = Null then
      ANode.Values[I] := True;
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

{ TNode }


end.
