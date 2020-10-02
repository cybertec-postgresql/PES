unit template;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.StrUtils,
  System.Generics.Collections, System.Net.Socket;

type
  TCluster = class;

  TVIPManager = class(TComponent)
  private
    FIP: string;
    FMask: string;
    FInterfaceName: string;
    FKey: string;
    FNodeName: string;
    FEndPoints: string;
    FEnabled: boolean;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IP: string read FIP write FIP;
    property Mask: string read FMask write FMask;
    property InterfaceName: string read FInterfaceName write FInterfaceName;
    property Key: string read FKey write FKey;
    property NodeName: string read FNodeName write FNodeName;
    property EndPoints: string read FEndPoints write FEndPoints;
    property Enabled: boolean read FEnabled write FEnabled;
  end;

  TNode = class(TComponent)
  private
    FIP: string;
    FHasEtcd: boolean;
    FNoFailover: boolean;
    FHasDatabase: boolean;
    FListenAddress: string;
    function GetEtcdConnectUrl: string;
    function GetEtcdListenClientUrls: string;
    function GetEtcdListenPeerUrls: string;
    function GetDCSConfig(): string;
    function GetBootstrapConfig(): string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetEtcdConfig(): string;
    function GetPatroniConfig(): string;
    function GetPatroniCtlConfig(): string;
  published
    property IP: string read FIP write FIP;
    property HasDatabase: boolean read FHasDatabase write FHasDatabase;
    property HasEtcd: boolean read FHasEtcd write FHasEtcd;
    property NoFailover: boolean read FNoFailover write FNoFailover;
  end;

  TCluster = class(TComponent)
  private
    FPostgresDir: string;
    FDataDir: string;
    FReplicationRole: string;
    FReplicationPassword: string;
    FSuperUser: string;
    FSuperUserPassword: string;
    FEtcdClusterToken: string;
    FExisting: boolean;
    FPostgresParameters: string;
    FVIPManager: TVIPManager;
    procedure SetEtcdClusterToken(const Value: string);
    procedure SetReplicationPassword(const Value: string);
    procedure SetSuperUserPassword(const Value: string);
    function GetNode(Index: Integer): TNode;
    function GetNodeCount: integer;
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetEtcdInitialCluster: string;
    function GetEtcdHostListPatroni: string;
    function GetEtcdNodeCount: integer;
    procedure SaveToStream(AStream: TStream);
    procedure SaveToFile(AFileName: string);
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromFile(AFileName: string);
    property Nodes[Index: Integer]: TNode read GetNode;
    property NodeCount: integer read GetNodeCount;
  published
    property DataDir: string read FDataDir write FDataDir;
    property EtcdClusterToken: string read FEtcdClusterToken write SetEtcdClusterToken;
    property Existing: boolean read FExisting write FExisting;
    property PostgresDir: string read FPostgresDir write FPostgresDir;
    property PostgresParameters: string read FPostgresParameters write FPostgresParameters;
    property ReplicationPassword: string read FReplicationPassword write SetReplicationPassword;
    property ReplicationRole: string read FReplicationRole write FReplicationRole;
    property SuperUser: string read FSuperUser write FSuperUser;
    property SuperUserPassword: string read FSuperUserPassword write SetSuperUserPassword;
    property VIPManager: TVIPManager read FVIPManager;
  end;

implementation

uses IOUtils, Winapi.WinSock2;

function RandomPassword(const Len: Integer = 12): string;
var
  I: Integer;
begin
  for I := 1 to Len do
    Result := Result + Chr(ord('a') + Random(26));
end;

{ TSettings }

constructor TCluster.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Name := 'pgcluster'; { do not localize }
  FVIPManager := TVIPManager.Create(Self);
  FVIPManager.FreeNotification(Self);
  FSuperUser := 'postgres';
  FReplicationRole := 'replicator';
end;

destructor TCluster.Destroy;
begin
  inherited;
end;

function TCluster.GetEtcdHostListPatroni: string;
var
  SL: TStrings;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    for I := 0 to ComponentCount - 1 do
      if Nodes[I].HasEtcd then
        SL.Append(Nodes[I].FIP + ':2379');
    Result := SL.CommaText;
  finally
    SL.Free;
  end;
end;

function TCluster.GetEtcdInitialCluster: string;
var
  I, n: Integer;
begin
  if ComponentCount = 0 then
    raise Exception.Create('Etcd cluster is empty. Add Etcd nodes to cluster');
  n := 0;
  for I := 0 to ComponentCount - 1 do
    if Nodes[I].HasEtcd then
    begin
      Result := Result + Format('%s=%s,',
        [Nodes[I].Name, Nodes[I].GetEtcdConnectUrl()]);
      inc(n);
    end;
  if n mod 2 = 0 then
    raise Exception.CreateFmt('Etcd cluster size %d not supported.' +
      'Use odd number of nodes up to 7', [n])
  else
    Result.Remove(Length(Result) - 1);
end;

function TCluster.GetEtcdNodeCount: integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ComponentCount - 1 do
    if Nodes[I].HasEtcd then
      inc(Result);
end;

function TCluster.GetNode(Index: Integer): TNode;
begin
  Result := Components[Index] as TNode;
end;

function TCluster.GetNodeCount: integer;
begin
  Result := ComponentCount;
end;

procedure TCluster.SetEtcdClusterToken(const Value: string);
begin
  FEtcdClusterToken := ifthen(Value = '', RandomPassword(), Value)
end;

procedure TCluster.SetReplicationPassword(const Value: string);
begin
  FReplicationPassword := ifthen(Value = '', RandomPassword(), Value)
end;

procedure TCluster.SetSuperUserPassword(const Value: string);
begin
  FSuperUserPassword := ifthen(Value = '', RandomPassword(), Value)
end;

{ TNode }

constructor TNode.Create(AOwner: TComponent);
begin
  if not Assigned(AOwner) then
    raise Exception.Create('Node owner cannot be nil');
  inherited Create(AOwner as TCluster);
  FIP := '127.0.0.1';
  FHasEtcd := True;
  FHasDatabase := True;
  FListenAddress := '0.0.0.0';
  SetSubComponent(True);
end;

function TNode.GetBootstrapConfig: string;
begin
  if TCluster(Owner).Existing then
    Exit;
  Result := TFile.ReadAllText('patroni_bootstrap.template', TEncoding.UTF8);
end;

function TNode.GetDCSConfig: string;
begin
  Result := 'etcd:'#13#10#9'hosts: ' + TCluster(Owner).GetEtcdHostListPatroni();
end;

function TNode.GetEtcdConfig: string;
begin
  if not FHasDatabase then
    Exit;
  Result := TFile.ReadAllText('etcd.template', TEncoding.UTF8);
  Result := ReplaceStr(Result, '{nodename}', Name);
  Result := ReplaceStr(Result, '{etcd_listen_peer_urls}',
    GetEtcdListenPeerUrls);
  Result := ReplaceStr(Result, '{etcd_listen_client_urls}',
    GetEtcdListenClientUrls);
  Result := ReplaceStr(Result, '{etcd_connect_url}', GetEtcdConnectUrl);
  Result := ReplaceStr(Result, '{cluster.etcd_initial_cluster}',
    TCluster(Owner).GetEtcdInitialCluster);
  Result := ReplaceStr(Result, '{cluster.etcd_cluster_token}',
    TCluster(Owner).EtcdClusterToken);
  Result := ReplaceStr(Result, '{connect_address}', FIP);
end;

function TNode.GetEtcdConnectUrl: string;
begin
  if not FHasEtcd then
    raise Exception.Create('Node doesn''n has etcd member');
  Result := 'http://' + FIP + ':2380';
end;

function TNode.GetEtcdListenClientUrls: string;
begin
  if FListenAddress = '0.0.0.0' then
    Result := 'http://0.0.0.0:2379'
  else
    Result := Format('http://%s:2379,http://localhost:2379', [FListenAddress])
end;

function TNode.GetEtcdListenPeerUrls: string;
begin
  if FListenAddress = '0.0.0.0' then
    Result := 'http://0.0.0.0:2380'
  else
    Result := Format('http://%s:2380,http://localhost:2380', [FListenAddress])
end;

function TNode.GetPatroniConfig: string;
begin
  if not FHasDatabase then Exit;
  Result := TFile.ReadAllText('patroni.template', TEncoding.UTF8);
  Result := ReplaceStr(Result, '{cluster.clustername}', TCluster(Owner).Name);
  Result := ReplaceStr(Result, '{nodename}', Name);
  Result := ReplaceStr(Result, '{listen_address}', FListenAddress);
  Result := ReplaceStr(Result, '{connect_address}', FIP);
  Result := ReplaceStr(Result, '{dcsconfig}', GetDCSConfig);
  Result := ReplaceStr(Result, '{bootstrap_config}', GetBootstrapConfig);
  Result := ReplaceStr(Result, '{data_dir}', TCluster(Owner).DataDir);
  Result := ReplaceStr(Result, '{bin_dir}', TCluster(Owner).PostgresDir);
  Result := ReplaceStr(Result, '{cluster.replication_user}', TCluster(Owner).ReplicationRole);
  Result := ReplaceStr(Result, '{cluster.replication_pw}', TCluster(Owner).ReplicationPassword);
  Result := ReplaceStr(Result, '{cluster.superuser_user}', TCluster(Owner).SuperUser);
  Result := ReplaceStr(Result, '{cluster.superuser_pw}', TCluster(Owner).SuperUserPassword);
  Result := ReplaceStr(Result, '{postgresql_parameters}', TCluster(Owner).PostgresParameters);
  Result := ReplaceStr(Result, '{nofailover_tag}', FNoFailover.ToString(True));
end;

function TNode.GetPatroniCtlConfig: string;
begin
  if not FHasDatabase then Exit;
  Result := TFile.ReadAllText('patroni_ctl.template', TEncoding.UTF8);
  Result := ReplaceStr(Result, '{etcd_address}', 'localhost:2379');
  Result := ReplaceStr(Result, '{cluster.clustername}', TCluster(Owner).Name);
end;

procedure TCluster.LoadFromFile(AFileName: string);
var
  StrStream: TStringStream;
begin
  StrStream := TStringStream.Create(TFile.ReadAllText(AFileName));
  try
    LoadFromStream(StrStream);
  finally
    StrStream.Free;
  end;
end;

procedure TCluster.LoadFromStream(AStream: TStream);
var
  BinStream: TMemoryStream;
begin
  if not Assigned(AStream) then raise Exception.Create('Stream object cannot be nil');
  BinStream := TMemoryStream.Create;
  try
    ObjectTextToBinary(AStream, BinStream);
    BinStream.Seek(0, soFromBeginning);
    BinStream.ReadComponent(Self);
  finally
    BinStream.Free;
  end;
end;

procedure TCluster.SaveToStream(AStream: TStream);
var
  BinStream: TMemoryStream;
begin
  if not Assigned(AStream) then raise Exception.Create('Stream object cannot be nil');
  BinStream := TMemoryStream.Create;
  try
    BinStream.WriteComponent(Self);
    BinStream.Seek(0, soFromBeginning);
    ObjectBinaryToText(BinStream, AStream);
  finally
    BinStream.Free
  end;
end;

procedure TCluster.SaveToFile(AFileName: string);
var
  StrStream: TStringStream;
begin
    StrStream := TStringStream.Create();
    try
      SaveToStream(StrStream);
      StrStream.Seek(0, soFromBeginning);
      StrStream.SaveToFile(AFileName);
    finally
      StrStream.Free;
    end;
end;

procedure TCluster.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  AComponent: TComponent;
begin
  if @Proc = nil then
    raise Exception.CreateFmt('Parameter %s cannot be nil', ['Proc']);
  for AComponent in Self do
    if (AComponent is TNode) and (AComponent.Owner = Root) then
      Proc(AComponent);
end;

{ TVIPManager }

constructor TVIPManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Name := 'VIPManager';  { do not localize }
  SetSubComponent(True);
end;


//procedure TVIPManager.SetVirtualIP(const Value: string);
//begin
//  FVirtualIP := TIPAddress.LookupAddress(Value);
//  if (FVirtualIP.Addr.S_addr = INADDR_NONE) or
//    (FVirtualIP.Addr.S_addr = INADDR_ANY) then
//  begin
//    FVirtualIP := TIPAddress.LookupName(Value);
//    if FVirtualIP.Addr.S_addr = INADDR_ANY then
//      raise Exception.Create('Incorrect IP or domain name value');
//  end;
//end;

initialization

RegisterClasses([TCluster, TNode, TVIPManager]);

end.
