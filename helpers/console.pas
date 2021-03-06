unit Console;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes;

function GetDosOutput(CommandLine: string; Work: string = ''): string;
function GetPSOutput(CommandLine: string; Work: string = ''): string;

implementation

function GetConsoleOutput(Console, CommandLine: string; Work: string = ''): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..8192] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: PChar;
  Handle: Boolean;
begin
  Result := '';
  with SA do begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    if Work = '' then WorkDir := nil else WorkDir := PChar(Work);
    Handle := CreateProcess(nil, PChar(Console + CommandLine),
                            nil, nil, True, 0, nil,
                            WorkDir, SI, PI);
    CloseHandle(StdOutPipeWrite);
    if Handle then
      try
        repeat
          WasOK := ReadFile(StdOutPipeRead, Buffer, 8192, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            Result := Result + AdjustLineBreaks(string(Buffer), tlbsCRLF);
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end
    else
      RaiseLastOSError;
  finally
    CloseHandle(StdOutPipeRead);
  end;
  Result := Trim(Result);
end;

function GetDosOutput(CommandLine: string; Work: string = ''): string;
begin
  Result := GetConsoleOutput('cmd.exe /C ', CommandLine, Work);
end;

function GetPSOutput(CommandLine: string; Work: string = ''): string;
begin
  Result := GetConsoleOutput('powershell -Command ', CommandLine, Work);
end;

end.
