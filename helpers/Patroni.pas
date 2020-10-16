unit Patroni;

interface

function PatroniGet(): string;

implementation

uses
  SysUtils, HTTPApp, IdHTTP, Json, REST.Json;

function httpGet(const url: string): string;
var
  http: TIdHTTP;
  tmpJson: TJsonValue;
begin
  http := TIdHTTP.Create;
  try
    tmpJson := TJsonObject.ParseJSONValue(http.Get(url));
    try
      Result := TJson.Format(tmpJson);
    finally
      tmpJson.Free;
    end;
  finally
    http.Free;
  end;
end;

function PatroniGet(): string;
begin
  Result := httpGet('http://localhost:8008/patroni');
end;

end.
