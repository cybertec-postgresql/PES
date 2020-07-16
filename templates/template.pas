unit template;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.StrUtils,
  System.Generics.Collections;

type
  TNode = class(TPersistent)
  private
    FIP: string;
    FHasEtcd: boolean;
    FNoFailover: boolean;
    FHasDatabase: boolean;
    FListenAddress: string;
    FName: string;
  public
    constructor Create;
    function GetEtcdConnectUrl: string;
    function GetEtcdListenClientUrl: string;
    function GetEtcdListenPeerUrls: string;
  published
    property Name: string read FName write FName;
    property IP: string read FIP write FIP;
    property HasDatabase: boolean read FHasDatabase write FHasDatabase;
    property HasEtcd: boolean read FHasEtcd write FHasEtcd;
    property NoFailover: boolean read FNoFailover write FNoFailover;
  end;


  TSettings = class(TPersistent)
  private
    FNodes: TObjectList<TNode>;
    FPostgresDir: string;
    FDataDir: string;
    FReplicationRole: string;
    FReplicationPassword: string;
    FSuperUser: string;
    FSuperUserPassword: string;
    FEtcdClusterToken: string;
  public
    constructor Create;
    destructor Destroy; override;
    function GetEtcdInitialCluster: string;
  published
    property Nodes: TObjectList<TNode> read FNodes;
    property PostgresDir: string read FPostgresDir write FPostgresDir;
    property DataDir: string read FDataDir write FDataDir;
    property ReplicationRole: string read FReplicationRole write FReplicationRole;
    property ReplicationPassword: string read FReplicationPassword write FReplicationPassword;
    property SuperUser: string read FSuperUser write FSuperUser;
    property SuperUserPassword: string read FSuperUserPassword write FSuperUserPassword;
    property EtcdClusterToken: string read FEtcdClusterToken write FEtcdClusterToken;
  end;

implementation

function RandomPassword(const Len: integer = 12): string;
var
  I: Integer;
begin
  for I := 1 to Len do
    Result := Result + Chr(ord('a') + Random(26));
end;

{ TSettings }

constructor TSettings.Create;
begin
  FNodes := TObjectList<TNode>.Create();
  FSuperUser := 'postgres';
  FSuperUserPassword := RandomPassword();
  FReplicationRole := 'replicator';
  FReplicationPassword := RandomPassword();
  FEtcdClusterToken := RandomPassword();
end;

destructor TSettings.Destroy;
begin
  FNodes.Free;
  inherited;
end;

function TSettings.GetEtcdInitialCluster: string;
var
  i, n: integer;
begin
  if FNodes.Count = 0 then
    raise Exception.Create('Etcd cluster is empty. Add Etcd nodes to cluster');
  for I := 0 to FNodes.Count - 1 do
    if FNodes[I].HasEtcd then
    begin
      Result := Result + Format('%s=%s,', [FNodes[I].Name, FNodes[I].GetEtcdConnectUrl()]);
      inc(n);
    end;
  if n mod 2 = 0 then
    raise Exception.CreateFmt('Etcd cluster size %d not supported.'+
        'Use odd number of nodes up to 7')
  else
    Result.Remove(Length(Result)-1);
end;

{ TNode }

constructor TNode.Create;
begin
  FListenAddress := '0.0.0.0';
end;

function TNode.GetEtcdConnectUrl: string;
begin
  if not FHasEtcd then raise Exception.Create('Node doesn''n has etcd member');
  Result := 'http://' + FIP + ':2380';
end;

function TNode.GetEtcdListenClientUrl: string;
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

end.
