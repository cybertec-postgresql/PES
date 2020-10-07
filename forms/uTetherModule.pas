unit uTetherModule;

interface

uses
  System.SysUtils, System.Classes, IPPeerClient, IPPeerServer, System.Tether.Manager,
  System.Tether.AppProfile, Vcl.ExtCtrls;

type
  TdmTether = class(TDataModule)
    TetherManager: TTetheringManager;
    TetheringAppProfile: TTetheringAppProfile;
    procedure TetherManagerRequestManagerPassword(const Sender: TObject;
      const ARemoteIdentifier: string; var Password: string);
    procedure TetherManagerPairedFromLocal(const Sender: TObject;
      const AManagerInfo: TTetheringManagerInfo);
  public
    OnConnect: TNotifyEvent;
    procedure Connect();
    procedure SendStream(AStream: TStream);
    procedure SendText(AText: string);
    function IsConnected(): boolean;
    function GetConnectionString(): string;
    function GetPairedConnectionStrings(): TArray<string>;
    const ResourceName: string = 'cluster';
  end;

var
  dmTether: TdmTether;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmTether.Connect();
begin
  TetherManager.AutoConnect;
end;

type
  THackAdapter =  class(TTetheringAdapter);

function TdmTether.GetConnectionString: string;
begin
  if TetherManager.Adapters.Count < 1 then Exit;
  Result := THackAdapter(TetherManager.Adapters[0]).FAdapterConnectionString.Replace('$', ':');
end;

function TdmTether.GetPairedConnectionStrings: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, TetherManager.PairedManagers.Count);
  for I := 0 to TetherManager.PairedManagers.Count - 1 do
    Result[I] := TetherManager.PairedManagers[I].ConnectionString.Replace('$', ':');
end;

function TdmTether.IsConnected: boolean;
begin
  Result := TetherManager.RemoteProfiles.Count > 0;
end;

procedure TdmTether.TetherManagerPairedFromLocal(const Sender: TObject;
  const AManagerInfo: TTetheringManagerInfo);
begin
  TetherManager.AutoConnect();
  if Assigned(OnConnect) then
    OnConnect(TetherManager);
end;

procedure TdmTether.TetherManagerRequestManagerPassword(const Sender: TObject;
  const ARemoteIdentifier: string; var Password: string);
begin
  Password := TetherManager.Password;
end;

procedure TdmTether.SendStream(AStream: TStream);
var
  AProfile: TTetheringProfileInfo;
begin
  AStream.Position := 0;
  for AProfile in TetherManager.RemoteProfiles do
  begin
    TetheringAppProfile.SendStream(AProfile, ResourceName, AStream)
  end;
end;

procedure TdmTether.SendText(AText: string);
var
  AProfile: TTetheringProfileInfo;
begin
  for AProfile in TetherManager.RemoteProfiles do
  begin
    TetheringAppProfile.SendString(AProfile, ResourceName, AText)
  end;
end;

end.
