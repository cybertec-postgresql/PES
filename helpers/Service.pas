unit Service;

interface

function ServiceStart(sMachine, sService : string) : Boolean;

implementation

uses Winapi.Windows, System.SysUtils, Winapi.WinSvc;

function ServiceStart(sMachine, sService : string) : Boolean;
var
  schSCManager,
  schService : SC_HANDLE;
  ssStatus : TServiceStatus;
  dwWaitTime: Cardinal;
  args: PWideChar;
begin
  // Get a handle to the SCM database.
  schSCManager := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_CONNECT);
  if (schSCManager = 0) then RaiseLastOSError;
  try
    // Get a handle to the service.
    schService := OpenService(schSCManager, PChar(sService), SERVICE_START or SERVICE_QUERY_STATUS);
    if (schService = 0) then RaiseLastOSError;
    try
      // Check the status in case the service is not stopped.
      if not QueryServiceStatus(schService, ssStatus) then
      begin
        if (ERROR_SERVICE_NOT_ACTIVE <> GetLastError()) then RaiseLastOSError;
        ssStatus.dwCurrentState := SERVICE_STOPPED;
      end;

      // Check if the service is already running
      if (ssStatus.dwCurrentState <> SERVICE_STOPPED) and (ssStatus.dwCurrentState <> SERVICE_STOP_PENDING) then
      begin
        Result := True;
        Exit;
      end;

      // Wait for the service to stop before attempting to start it.
      while (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) do
      begin
        // Do not wait longer than the wait hint. A good interval is
        // one-tenth of the wait hint but not less than 1 second
        // and not more than 10 seconds.

        dwWaitTime := ssStatus.dwWaitHint div 10;

        if (dwWaitTime < 1000) then
          dwWaitTime := 1000
        else if (dwWaitTime > 10000) then
          dwWaitTime := 10000;

        Sleep(dwWaitTime);

        // Check the status until the service is no longer stop pending.

        if not QueryServiceStatus(schService, ssStatus) then
        begin
          if (ERROR_SERVICE_NOT_ACTIVE <> GetLastError()) then RaiseLastOSError;
          Break;
        end;
      end;

      // Attempt to start the service.

      // NOTE: if you use a version of Delphi that incorrectly declares
      // StartService() with a 'var' lpServiceArgVectors parameter, you
      // can't pass a nil value directly in the 3rd parameter, you would
      // have to pass it indirectly as either PPChar(nil)^ or PChar(nil^)
      args := nil;
      if not StartService(schService, 0, args) then RaiseLastOSError;
      // Check the status until the service is no longer start pending.

      if not QueryServiceStatus(schService, ssStatus) then
      begin
        if (ERROR_SERVICE_NOT_ACTIVE <> GetLastError()) then RaiseLastOSError;
        ssStatus.dwCurrentState := SERVICE_STOPPED;
      end;

      while (ssStatus.dwCurrentState = SERVICE_START_PENDING) do
      begin
        // Do not wait longer than the wait hint. A good interval is
        // one-tenth the wait hint, but no less than 1 second and no
        // more than 10 seconds.

        dwWaitTime := ssStatus.dwWaitHint div 10;

        if (dwWaitTime < 1000) then
          dwWaitTime := 1000
        else if (dwWaitTime > 10000) then
          dwWaitTime := 10000;

        Sleep(dwWaitTime);

        // Check the status again.

        if not QueryServiceStatus(schService, ssStatus) then
        begin
          if (ERROR_SERVICE_NOT_ACTIVE <> GetLastError()) then RaiseLastOSError;
          ssStatus.dwCurrentState := SERVICE_STOPPED;
          Break;
        end;
      end;

      // Determine whether the service is running.

      Result := (ssStatus.dwCurrentState = SERVICE_RUNNING);
    finally
      CloseServiceHandle(schService);
    end;
  finally
    CloseServiceHandle(schSCManager);
  end;
end;

end.
