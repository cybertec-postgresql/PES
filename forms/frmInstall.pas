unit frmInstall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.ExtActns, System.Actions,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.StrUtils, PythonVersions, Console, template, Vcl.ComCtrls, Vcl.ActnList, uTetherModule,
  IPPeerClient, IPPeerServer, System.Tether.Manager, System.Tether.AppProfile, VirtualTrees,
  Vcl.Imaging.jpeg;

type
  TfmInstall = class(TForm)
    btnNext: TButton;
    btnBack: TButton;
    pnlNavigation: TPanel;
    imgHeader: TImage;
    pcWizard: TPageControl;
    tabPython: TTabSheet;
    mmPython: TMemo;
    alActions: TActionList;
    acBack: TPreviousTab;
    acNext: TNextTab;
    tabNodes: TTabSheet;
    ftnFinish: TButton;
    acFinish: TAction;
    tabConfigs: TTabSheet;
    edClusterName: TEdit;
    lbClusterName: TLabel;
    lbNodes: TLabel;
    tabPostgres: TTabSheet;
    lblBinDir: TLabel;
    lblDataDir: TLabel;
    lblReplicattionRole: TLabel;
    edReplicationRole: TEdit;
    lblReplicationPwd: TLabel;
    edReplicationPassword: TEdit;
    lblSuperuserRole: TLabel;
    edSuperuserRole: TEdit;
    lblSuperuserPwd: TLabel;
    edSuperuserPassword: TEdit;
    lblClusterToken: TLabel;
    edClusterToken: TEdit;
    tabVIPManager: TTabSheet;
    lblVIPKey: TLabel;
    edVIPKey: TEdit;
    edVIPMask: TEdit;
    lblVIPMask: TLabel;
    lblVIPInterface: TLabel;
    edVIPInterface: TEdit;
    edVIP: TEdit;
    lblVIP: TLabel;
    chkEnableVIP: TCheckBox;
    acVIP: TAction;
    tabTethering: TTabSheet;
    mmRemoteManagers: TMemo;
    btnConnect: TButton;
    vstNodes: TVirtualStringTree;
    edBinDir: TEdit;
    edDataDir: TEdit;
    btnAddNode: TButton;
    btnDeleteNode: TButton;
    acDeleteNode: TAction;
    btnSave: TButton;
    btnLoad: TButton;
    tmCheckConnection: TTimer;
    btnCheckPython: TButton;
    btnSync: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    lblStep: TLabel;
    btnAddTethered: TButton;
    acAddTethered: TAction;
    procedure acFinishUpdate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure acVIPCheck(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
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
    procedure btnSyncClick(Sender: TObject);
    procedure OnResourceReceived(const Sender: TObject; const AResource: TRemoteResource);
    procedure tmCheckConnectionTimer(Sender: TObject);
    procedure acVIPUpdate(Sender: TObject);
    procedure UpdateCluster(Sender: TObject);
    procedure btnCheckPythonClick(Sender: TObject);
    procedure acFinishExecute(Sender: TObject);
    procedure vstNodesKeyAction(Sender: TBaseVirtualTree; var CharCode: Word;
      var Shift: TShiftState; var DoDefault: Boolean);
    procedure btnNextClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure acAddTetheredUpdate(Sender: TObject);
    procedure acAddTetheredExecute(Sender: TObject);
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

uses Math, IOUtils, PythonEngine, PythonGUIInputOutput, FileCtrl;

{$R *.dfm}

procedure TfmInstall.acAddTetheredExecute(Sender: TObject);
var
  S: string;

  procedure AddNodeToTree(conn: string);
  var
    N: TNode;
  begin
      N := TNode.Create(Cluster);
      N.IP := conn.Split([':'])[0];
      vstNodes.AddChild(nil, N);
  end;

begin
  vstNodes.BeginUpdate;
  try
    vstNodes.Clear;
    AddNodeToTree(dmTether.GetConnectionString);
    for S in dmTether.GetPairedConnectionStrings do
      AddNodeToTree(S);
  finally
    vstNodes.EndUpdate;
  end;
end;

procedure TfmInstall.acAddTetheredUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := dmTether.TetherManager.PairedManagers.Count > 0;
end;

procedure TfmInstall.acDeleteNodeUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := vstNodes.SelectedCount > 0;
end;

procedure TfmInstall.acFinishExecute(Sender: TObject);
var
  i: Integer;
  ANode: TNode;
  ADir, ANodeDir: string;

  procedure WriteToFile(AFileName, AContent: string);
  begin
    if AContent = '' then
      Exit;
    TFile.WriteAllText(AFileName, AContent);
  end;

begin
  ADir := ExtractFilePath(Application.ExeName);
  if not FileCtrl.SelectDirectory('Select directory to save generated configs', '', ADir) then
    Exit;
  for i := 0 to Cluster.NodeCount - 1 do
  begin
    ANode := Cluster.Nodes[i];
    ANodeDir := TPath.Combine(ADir, ANode.Name);
    IOUtils.TDirectory.CreateDirectory(ANodeDir);
    WriteToFile(TPath.Combine(ANodeDir, 'patroni.yaml'), ANode.GetPatroniConfig);
    WriteToFile(TPath.Combine(ANodeDir, 'patronictl.yaml'), ANode.GetPatroniCtlConfig);
    WriteToFile(TPath.Combine(ANodeDir, 'etcd.yaml'), ANode.GetEtcdConfig);
    WriteToFile(TPath.Combine(ANodeDir, 'vipmanager.yaml'), ANode.GetVIPManagerConfig);
  end;
end;

procedure TfmInstall.acFinishUpdate(Sender: TObject);
begin
  lblStep.Caption := pcWizard.ActivePage.Caption;
  (Sender as TAction).Enabled := pcWizard.ActivePageIndex = pcWizard.PageCount - 1;
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
        if Assigned(FocusControl) then FocusControl.Enabled := Enabled;
      end;
end;

procedure TfmInstall.btnAddNodeClick(Sender: TObject);
begin
  vstNodes.AddChild(nil, TNode.Create(Cluster));
end;

procedure TfmInstall.btnBackClick(Sender: TObject);
begin
  pcWizard.SelectNextPage(False, False);
end;

procedure TfmInstall.btnDeleteNodeClick(Sender: TObject);
begin
  vstNodes.DeleteSelectedNodes();
end;

procedure TfmInstall.btnCheckPythonClick(Sender: TObject);
var
  pyEngine: TPythonEngine;
  pyGUI: TPythonGUIInputOutput;

  v: TPythonVersion;
  vv: TPythonVersions;
begin
  mmPython.Clear;
  mmPython.Lines.AddStrings([
    'Default Python version in system:',
    '---------------------------------',
    GetDosOutput('python.exe -c "import sys; print(sys.version)" '), '',
    'Installed Python versions in system:',
    '------------------------------------']);
  vv := GetRegisteredPythonVersions();
  if length(vv) = 0 then
  begin
    mmPython.Lines.Add('No installed Python found!');
    Exit;
  end;

  for v in vv do
    mmPython.Lines.AddStrings(['Name: '+ v.DisplayName,
        'Installation: ' + v.InstallPath,
        'Executable: ' + v.PythonExecutable, '']);

  pyEngine := TPythonEngine.Create(Self);
  pyGUI := TPythonGUIInputOutput.Create(Self);
  try
    pyGUI.Output := mmPython;
    pyGUI.RawOutput := False;
    pyGUI.UnicodeIO := True;
    mmPython.Lines.Add('Check Patroni packages installed:');
    mmPython.Lines.Add('---------------------------------');
    pyEngine.IO := pyGUI;
    pyEngine.FatalAbort := False;
    pyEngine.LoadDll;
    if pyEngine.Initialized then
      pyEngine.ExecString(AnsiString(TFile.ReadAllText('check_missing_pkgs.py')));
  finally
    FreeAndNil(pyEngine);
    FreeAndNil(pyGUI);
  end;
end;

procedure TfmInstall.btnConnectClick(Sender: TObject);
begin
  dmTether.Connect();
  tmCheckConnection.Enabled := True;
end;

procedure TfmInstall.btnSaveClick(Sender: TObject);
begin
  if not SaveDialog.Execute then Exit;
  Cluster.SaveToFile(SaveDialog.FileName);
end;

procedure TfmInstall.btnLoadClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;
  vstNodes.Clear; //this will destroy nodes in cluster
  try
    Cluster.LoadFromFile(OpenDialog.FileName);
    InvalidateCluster(Cluster);
  except
    vstNodes.Clear;
  end;
end;

procedure TfmInstall.btnNextClick(Sender: TObject);
begin
  pcWizard.SelectNextPage(True, False);
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

procedure TfmInstall.FormCreate(Sender: TObject);
begin
  Vcl.Dialogs.ForceCurrentDirectory := True;
  Cluster := TCluster.Create(Self);
  dmTether.TetheringAppProfile.OnResourceReceived := OnResourceReceived;
  dmTether.OnConnect := btnConnectClick;
  pcWizard.ActivePageIndex := 0;
  InvalidateCluster(Cluster);
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
  chkEnableVIP.Checked := ACluster.VIPManager.Enabled;
  vstNodes.BeginUpdate;
  try
    for i := 0 to ACluster.NodeCount - 1 do
      vstNodes.AddChild(nil, ACluster.Nodes[i])
  finally
    vstNodes.EndUpdate;
  end;
end;

procedure TfmInstall.OnResourceReceived(const Sender: TObject; const AResource: TRemoteResource);
begin
  if AResource.Hint <> dmTether.ResourceName then Exit;
  tmCheckConnection.Enabled := True;
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
  S: string;
const
  TAB: string = #9;
begin
  if pcWizard.ActivePage <> tabTethering then
    Exit;
  if not dmTether.IsConnected() then
  begin
    mmRemoteManagers.Lines.Text := 'You are not connected';
    Exit;
  end;
  mmRemoteManagers.Lines.BeginUpdate;
  try
    mmRemoteManagers.Lines.Clear;
    mmRemoteManagers.Lines.Add('Local instance:');
    mmRemoteManagers.Lines.Add(TAB + dmTether.GetConnectionString);
    mmRemoteManagers.Lines.Add('Paired instances:');
    for S in dmTether.GetPairedConnectionStrings do mmRemoteManagers.Lines.Add(TAB + S);
  finally
    mmRemoteManagers.Lines.EndUpdate;
  end;
end;

procedure TfmInstall.UpdateCluster;
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
  Cluster.VIPManager.IP := edVIP.Text;
  Cluster.VIPManager.Mask := edVIPMask.Text;
  Cluster.VIPManager.InterfaceName := edVIPInterface.Text;
  Cluster.VIPManager.Key := edVIPKey.Text;
end;

procedure TfmInstall.vstNodesFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  AData: pointer;
begin
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then Exit;
  FreeAndNil(TObject(AData^));
end;

procedure TfmInstall.vstNodesGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNode);
end;

procedure TfmInstall.vstNodesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
var
  AnObj: TObject;
  AData: pointer;
begin
  // Column is -1 if the header is hidden or no columns are defined
  if Column < 0 then Exit;
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    case Column of
      0: CellText := TNode(AnObj).IP;
      1: CellText := ifthen(TNode(AnObj).HasDatabase, '✔', '❌');
      2: CellText := ifthen(TNode(AnObj).HasEtcd, '✔', '❌');
      3: CellText := ifthen(TNode(AnObj).NoFailover, '✔', '❌');
      4: CellText := TNode(AnObj).Name;
    end;
end;

procedure TfmInstall.vstNodesKeyAction(Sender: TBaseVirtualTree; var CharCode: Word; var Shift: TShiftState;
  var DoDefault: Boolean);
var
  HI: THitInfo;
begin
  case CharCode of
    VK_RIGHT:
      CharCode := VK_TAB;
    VK_LEFT:
      begin
        CharCode := VK_TAB;
        Shift := [ssShift];
      end;
    VK_SPACE:
      begin
        HI.HitNode := vstNodes.GetFirstSelected();
        HI.HitColumn := vstNodes.FocusedColumn;
        vstNodesNodeClick(Sender, HI);
        vstNodes.InvalidateNode(HI.HitNode);
      end;
  end;
end;

procedure TfmInstall.vstNodesNewText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  NewText: string);
var
  AnObj: TObject;
  AData: pointer;
begin
  // Column is -1 if the header is hidden or no columns are defined
  if Column < 0 then Exit;
  AData := Sender.GetNodeData(Node);
  if not Assigned(AData) then Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    with TNode(AnObj) do
      case Column of
        0: IP := NewText;
        4: Name := NewText;
      end;
end;

procedure TfmInstall.vstNodesNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
var
  AnObj: TObject;
  AData: pointer;
begin
  AData := Sender.GetNodeData(HitInfo.HitNode);
  if not Assigned(AData) then Exit;
  AnObj := TObject(AData^);
  if Assigned(AnObj) and (AnObj is TNode) then
    with TNode(AnObj) do
      case HitInfo.HitColumn of
        1: HasDatabase := not HasDatabase;
        2: HasEtcd := not HasEtcd;
        3: NoFailover := not NoFailover;
      end;
end;

end.
