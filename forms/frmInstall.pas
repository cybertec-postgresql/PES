unit frmInstall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.StrUtils, PythonVersions,
  Console, template, Vcl.ComCtrls, Vcl.ExtActns, System.Actions, Vcl.ActnList,
  SynEdit, uTetherModule,
  SynEditHighlighter, SynHighlighterJSON, Winapi.ShlObj, IPPeerClient,
  IPPeerServer, System.Tether.Manager, System.Tether.AppProfile,
  SynEditCodeFolding, VirtualTrees, Vcl.Imaging.jpeg;

type
  TfmInstall = class(TForm)
    btnNext: TButton;
    btnBack: TButton;
    pnlNavigation: TPanel;
    imgHeader: TImage;
    pcWizard: TPageControl;
    tabPython: TTabSheet;
    btnInstall: TButton;
    mmInfo: TMemo;
    alActions: TActionList;
    acBack: TPreviousTab;
    acNext: TNextTab;
    tabNodes: TTabSheet;
    Button1: TButton;
    acFinish: TAction;
    TabSheet1: TTabSheet;
    SynJSONSyn1: TSynJSONSyn;
    edClusterName: TEdit;
    lbClusterName: TLabel;
    lbNodes: TLabel;
    tabPostgres: TTabSheet;
    lbBinDir: TLabel;
    Label1: TLabel;
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
    tabVIPManager: TTabSheet;
    Label7: TLabel;
    edVIPKey: TEdit;
    edVIPMask: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    edVIPInterface: TEdit;
    edVIP: TEdit;
    Label10: TLabel;
    chkEnableVIP: TCheckBox;
    acVIP: TAction;
    tsTethering: TTabSheet;
    mmRemoteManagers: TMemo;
    btnConnect: TButton;
    acGetConfig: TAction;
    SynEdit1: TSynEdit;
    vstNodes: TVirtualStringTree;
    edBinDir: TEdit;
    edDataDir: TEdit;
    btnAddNode: TButton;
    btnDeleteNode: TButton;
    acDeleteNode: TAction;
    btnGenerateConfigs: TButton;
    btnLoadConfig: TButton;
    btnSync: TButton;
    tmCheckConnection: TTimer;
    procedure UpdatePythonInfo(Sender: TObject);
    procedure acFinishUpdate(Sender: TObject);
    procedure btnGenerateConfigsClick(Sender: TObject);
    procedure btnLoadConfigClick(Sender: TObject);
    procedure acVIPCheck(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure acGetConfigExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure vstNodesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure btnAddNodeClick(Sender: TObject);
    procedure vstNodesGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure vstNodesNewText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; NewText: string);
    procedure vstNodesFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstNodesNodeClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure btnDeleteNodeClick(Sender: TObject);
    procedure acDeleteNodeUpdate(Sender: TObject);
    procedure edVIPChange(Sender: TObject);
    procedure edClusterChange(Sender: TObject);
    procedure btnSyncClick(Sender: TObject);
    procedure OnResourceReceived(const Sender: TObject; const AResource: TRemoteResource);
    procedure tmCheckConnectionTimer(Sender: TObject);
    procedure acVIPUpdate(Sender: TObject);
  private
    Cluster: TCluster;
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

procedure TfmInstall.acDeleteNodeUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := vstNodes.SelectedCount > 0;
end;

procedure TfmInstall.acFinishUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := pcWizard.ActivePageIndex = pcWizard.PageCount - 1;
end;

procedure TfmInstall.acGetConfigExecute(Sender: TObject);
begin
  btnGenerateConfigsClick(nil);
end;

procedure TfmInstall.acVIPCheck(Sender: TObject);
begin
  Cluster.VIPManager.Enabled := chkEnableVIP.Checked;
end;

procedure TfmInstall.acVIPUpdate(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to tabVIPManager.ControlCount - 1 do
    if tabVIPManager.Controls[i] is TLabel then
      with TLabel(tabVIPManager.Controls[i]) do
      begin
        Enabled := chkEnableVIP.Checked;
        if Assigned(FocusControl) then
          FocusControl.Enabled := Enabled;
      end;
end;

procedure TfmInstall.btnAddNodeClick(Sender: TObject);
begin
  vstNodes.AddChild(nil, TNode.Create(Cluster));
end;

procedure TfmInstall.btnDeleteNodeClick(Sender: TObject);
begin
  vstNodes.DeleteSelectedNodes();
end;

procedure TfmInstall.btnConnectClick(Sender: TObject);
begin
  dmTether.Connect();
end;

procedure TfmInstall.btnGenerateConfigsClick(Sender: TObject);
begin
  IOUtils.TDirectory.CreateDirectory(Cluster.Name);
  Cluster.SaveToFile(Cluster.Name + '\cluster.txt');
end;

procedure TfmInstall.btnLoadConfigClick(Sender: TObject);
begin
  vstNodes.Clear; //this will destroy nodes in cluster
  Cluster.VIPManager.Free;
  try
    Cluster.LoadFromFile('pgcluster\cluster.txt');
    InvalidateCluster(Cluster);
  except
    vstNodes.Clear;
  end;
end;

procedure TfmInstall.btnSyncClick(Sender: TObject);
var
  ss: TStringStream;
begin
  ss := TStringStream.Create;
  try
    Cluster.SaveToStream(ss);
    ss.Position := 0;
    dmTether.SendStream(ss);
  finally
    ss.Free;
  end;
end;

procedure TfmInstall.edClusterChange(Sender: TObject);
begin
  Cluster.Name := edClusterName.Text;
  Cluster.PostgresDir := edBinDir.Text;
  Cluster.DataDir := edDataDir.Text;
  Cluster.ReplicationRole := edReplicationRole.Text;
  Cluster.ReplicationPassword := edReplicationPassword.Text;
  Cluster.SuperUser := edSuperuserRole.Text;
  Cluster.SuperUserPassword := edSuperuserPassword.Text;
  Cluster.EtcdClusterToken := edClusterToken.Text;
  Cluster.Existing := False;
  Cluster.PostgresParameters := '';
end;

procedure TfmInstall.edVIPChange(Sender: TObject);
begin
  Cluster.VIPManager.IP := edVIP.Text;
  Cluster.VIPManager.Mask := edVIPMask.Text;
  Cluster.VIPManager.InterfaceName := edVIPInterface.Text;
  Cluster.VIPManager.Key := edVIPKey.Text;
end;

procedure TfmInstall.FormCreate(Sender: TObject);
begin
  Cluster := TCluster.Create(Self);
  dmTether.TetheringAppProfile.OnResourceReceived := OnResourceReceived;
end;

procedure TfmInstall.InvalidateCluster(ACluster: TCluster);
var
  i: Integer;
begin
  edClusterName.Text := ACluster.Name;
  edBinDir.Text := ACluster.PostgresDir;
  edDataDir.Text := ACluster.DataDir;
  edReplicationRole.Text := ACluster.ReplicationRole;
  edReplicationPassword.Text := ACluster.ReplicationPassword;
  edSuperuserRole.Text := ACluster.SuperUser;
  edSuperuserPassword.Text := ACluster.SuperUserPassword;
  edClusterToken.Text := ACluster.EtcdClusterToken;

  chkEnableVIP.Checked := False;

  vstNodes.BeginUpdate;
  try
    for i := 0 to ACluster.ComponentCount - 1 do
      if ACluster.Components[i] is TNode then
        vstNodes.AddChild(nil, ACluster.Components[i])
      else
      begin
        chkEnableVIP.Checked := True;
        edVIP.Text := TVIPManager(ACluster.Components[i]).IP;
        edVIPMask.Text := TVIPManager(ACluster.Components[i]).Mask;
      end;
  finally
    vstNodes.EndUpdate;
  end;

end;

procedure TfmInstall.OnResourceReceived(const Sender: TObject;
  const AResource: TRemoteResource);
begin
  if AResource.Hint <> dmTether.ResourceName then
    Exit;
  vstNodes.Clear; // this will destroy nodes in cluster
  Cluster.VIPManager.Free;
  try
    Cluster.LoadFromStream(AResource.Value.AsStream);
    InvalidateCluster(Cluster);
  except
    vstNodes.Clear;
  end;
end;

procedure TfmInstall.tmCheckConnectionTimer(Sender: TObject);
var
  AManager: TTetheringManagerInfo;
begin
  if not dmTether.IsConnected() then
  begin
    mmRemoteManagers.Lines.Text := 'You are not connected';
    Exit;
  end;
  mmRemoteManagers.Lines.BeginUpdate;
  try
    mmRemoteManagers.Lines.Clear;
    for AManager in dmTether.TetherManager.RemoteManagers do
      mmRemoteManagers.Lines.Append(' - ' + AManager.ConnectionString);
  finally
    mmRemoteManagers.Lines.EndUpdate;
  end;
end;

procedure TfmInstall.UpdatePythonInfo(Sender: TObject);
var
  v: TPythonVersion;
  vv: TPythonVersions;
begin
  mmInfo.Clear;
  mmInfo.Lines.Add('Default Python version in system:');
  mmInfo.Lines.Add('---------------------------------');
  mmInfo.Lines.Add
    (GetDosOutput('python.exe -c "import sys; print(sys.version)" '));
  mmInfo.Lines.Add('');
  mmInfo.Lines.Add('Installed Python versions in system:');
  mmInfo.Lines.Add('---------------------------------');
  vv := GetRegisteredPythonVersions();
  if Length(vv) > 0 then
    btnInstall.Caption := ifthen(Length(vv) > 0, 'Upgrade Python',
      'Install Python');

  for v in vv do
    with mmInfo.Lines do
    begin
      btnInstall.Enabled := btnInstall.Enabled and
        (CompareVersions(v.Version, PYTHON_VERSION) > 0);
      Add(Format('Name: %s', [v.DisplayName]));
      Add(Format('Installation: %s', [v.InstallPath]));
      Add(Format('Executable: %s', [v.PythonExecutable]));
      Add('');
    end;

end;

procedure TfmInstall.vstNodesFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  AData: pointer;
begin
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then
    Exit;
  FreeAndNil(TObject(AData^));
end;

procedure TfmInstall.vstNodesGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNode);
end;

procedure TfmInstall.vstNodesGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  AnObj: TObject;
  AData: pointer;
begin
  // Column is -1 if the header is hidden or no columns are defined
  if Column < 0 then
    Exit;
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then
    Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    with TNode(AnObj) do
      case Column of
        0: CellText := IP;
        1: CellText := ifthen(HasDatabase, '✔', '❌');
        2: CellText := ifthen(HasEtcd, '✔', '❌');
        3: CellText := ifthen(NoFailover, '✔', '❌');
      end;
end;

procedure TfmInstall.vstNodesNewText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; NewText: string);
var
  AnObj: TObject;
  AData: pointer;
begin
  // Column is -1 if the header is hidden or no columns are defined
  if Column < 0 then
    Exit;
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then
    Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    with TNode(AnObj) do
      case Column of
        0:
          IP := NewText;
      end;
end;

procedure TfmInstall.vstNodesNodeClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
var
  AnObj: TObject;
  AData: pointer;
begin
  AData := Sender.GetNodeData(HitInfo.HitNode);
  if not Assigned(AData) then
    Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    with TNode(AnObj) do
      case HitInfo.HitColumn of
        1:
          HasDatabase := not HasDatabase;
        2:
          HasEtcd := not HasEtcd;
        3:
          NoFailover := not NoFailover;
      end;
end;

{ TNode }

end.
