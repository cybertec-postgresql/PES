unit template;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.StrUtils,
  System.Generics.Collections;

type
  TCluster = class;

  TNode = class(TPersistent)
  private
    FIP: string;
    FHasEtcd: boolean;
    FNoFailover: boolean;
    FHasDatabase: boolean;
    FListenAddress: string;
    FName: string;
    FOwner: TCluster;
    function GetEtcdConnectUrl: string;
    function GetEtcdListenClientUrls: string;
    function GetEtcdListenPeerUrls: string;
    function GetDCSConfig(): string;
    function GetBootstrapConfig(): string;
  public
    constructor Create(Owner: TCluster);
    function GetEtcdConfig(): string;
    function GetPatroniConfig(): string;
    function GetPatroniCtlConfig(): string;
  published
    property Name: string read FName write FName;
    property IP: string read FIP write FIP;
    property HasDatabase: boolean read FHasDatabase write FHasDatabase;
    property HasEtcd: boolean read FHasEtcd write FHasEtcd;
    property NoFailover: boolean read FNoFailover write FNoFailover;
  end;


  TCluster = class(TPersistent)
  private
    FNodes: TObjectList<TNode>;
    FPostgresDir: string;
    FDataDir: string;
    FReplicationRole: string;
    FReplicationPassword: string;
    FSuperUser: string;
    FSuperUserPassword: string;
    FEtcdClusterToken: string;
    FClusterName: string;
    FExisting: boolean;
    FPostgresParameters: string;
    procedure SetEtcdClusterToken(const Value: string);
    procedure SetReplicationPassword(const Value: string);
    procedure SetSuperUserPassword(const Value: string);
    procedure SetClusterName(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;
    function GetEtcdInitialCluster: string;
    function GetEtcdHostListPatroni: string;
  published
    property Nodes: TObjectList<TNode> read FNodes;
    property ClusterName: string read FClusterName write SetClusterName;
    property PostgresDir: string read FPostgresDir write FPostgresDir;
    property DataDir: string read FDataDir write FDataDir;
    property ReplicationRole: string read FReplicationRole write FReplicationRole;
    property ReplicationPassword: string read FReplicationPassword write SetReplicationPassword;
    property SuperUser: string read FSuperUser write FSuperUser;
    property SuperUserPassword: string read FSuperUserPassword write SetSuperUserPassword;
    property EtcdClusterToken: string read FEtcdClusterToken write SetEtcdClusterToken;
    property Existing: boolean read FExisting write FExisting;
    property PostgresParameters: string read FPostgresParameters write FPostgresParameters;
  end;

implementation

uses IOUtils;

function RandomPassword(const Len: integer = 12): string;
var
  I: Integer;
begin
  for I := 1 to Len do
    Result := Result + Chr(ord('a') + Random(26));
end;

{ TSettings }

constructor TCluster.Create;
begin
  FNodes := TObjectList<TNode>.Create();
  FSuperUser := 'postgres';
  FSuperUserPassword := RandomPassword();
  FReplicationRole := 'replicator';
  FReplicationPassword := RandomPassword();
  FEtcdClusterToken := RandomPassword();
end;

destructor TCluster.Destroy;
begin
  FNodes.Free;
  inherited;
end;

function TCluster.GetEtcdHostListPatroni: string;
var SL: TStrings;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    for I := 0 to FNodes.Count - 1 do
      if FNodes[I].HasEtcd then
        SL.Append(FNodes[I].FIP + ':2379');
    Result := SL.CommaText;
  finally
    SL.Free;
  end;
end;

function TCluster.GetEtcdInitialCluster: string;
var
  i, n: integer;
begin
  if FNodes.Count = 0 then
    raise Exception.Create('Etcd cluster is empty. Add Etcd nodes to cluster');
  n := 0;
  for I := 0 to FNodes.Count - 1 do
    if FNodes[I].HasEtcd then
    begin
      Result := Result + Format('%s=%s,', [FNodes[I].Name, FNodes[I].GetEtcdConnectUrl()]);
      inc(n);
    end;
  if n mod 2 = 0 then
    raise Exception.CreateFmt('Etcd cluster size %d not supported.'+
        'Use odd number of nodes up to 7', [n])
  else
    Result.Remove(Length(Result)-1);
end;

procedure TCluster.SetClusterName(const Value: string);
begin
  if Value = '' then raise Exception.Create('Cluster name cannot be empty!');
  FClusterName := Value;
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

constructor TNode.Create(Owner: TCluster);
begin
  if not Assigned(Owner) then
    raise Exception.Create('Node owner cannot be nil');
  FListenAddress := '0.0.0.0';
end;

function TNode.GetBootstrapConfig: string;
begin
  if FOwner.Existing then Exit;
  Result := TFile.ReadAllText('patroni_bootstrap.template', TEncoding.UTF8);
end;

function TNode.GetDCSConfig: string;
begin
  Result := 'etcd:'#13#10#9'hosts: ' + FOwner.GetEtcdHostListPatroni();
end;

function TNode.GetEtcdConfig: string;
begin
  if not FHasDatabase then Exit;
  Result := TFile.ReadAllText('etcd.template', TEncoding.UTF8);
  Result := ReplaceStr(Result, '{nodename}', FName);
  Result := ReplaceStr(Result, '{etcd_listen_peer_urls}', GetEtcdListenPeerUrls);
  Result := ReplaceStr(Result, '{etcd_listen_client_urls}', GetEtcdListenClientUrls);
  Result := ReplaceStr(Result, '{etcd_connect_url}', GetEtcdConnectUrl);
  Result := ReplaceStr(Result, '{cluster.etcd_initial_cluster}', FOwner.GetEtcdInitialCluster);
  Result := ReplaceStr(Result, '{cluster.etcd_cluster_token}', FOwner.EtcdClusterToken);
  Result := ReplaceStr(Result, '{connect_address}', FIP);
end;

function TNode.GetEtcdConnectUrl: string;
begin
  if not FHasEtcd then raise Exception.Create('Node doesn''n has etcd member');
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
  Result := ReplaceStr(Result, '{cluster.clustername}', FOwner.ClusterName);
  Result := ReplaceStr(Result, '{nodename}', FName);
  Result := ReplaceStr(Result, '{listen_address}', FListenAddress);
  Result := ReplaceStr(Result, '{connect_address}', FIP);
  Result := ReplaceStr(Result, '{dcsconfig}', GetDCSConfig);
  Result := ReplaceStr(Result, '{bootstrap_config}', GetBootstrapConfig);
  Result := ReplaceStr(Result, '{data_dir}', FOwner.DataDir);
  Result := ReplaceStr(Result, '{bin_dir}', FOwner.PostgresDir);
  Result := ReplaceStr(Result, '{cluster.replication_user}', FOwner.ReplicationRole);
  Result := ReplaceStr(Result, '{cluster.replication_pw}', FOwner.ReplicationPassword);
  Result := ReplaceStr(Result, '{cluster.superuser_user}', FOwner.SuperUser);
  Result := ReplaceStr(Result, '{cluster.superuser_pw}', FOwner.SuperUserPassword);
  Result := ReplaceStr(Result, '{postgresql_parameters}', FOwner.PostgresParameters);
  Result := ReplaceStr(Result, '{nofailover_tag}', FNoFailover.ToString(True));
end;

function TNode.GetPatroniCtlConfig: string;
begin
  if not FHasDatabase then Exit;
  Result := TFile.ReadAllText('patroni_ctl.template', TEncoding.UTF8);
  Result := ReplaceStr(Result, '{etcd_address}', 'localhost:2379');
  Result := ReplaceStr(Result, '{cluster.clustername}', FOwner.ClusterName);
end;

end.
