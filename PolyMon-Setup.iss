; PolyMon-Setup.iss
; InnoSetup script for PolyMon — fresh install, upgrade, and repair
;
; Prerequisites:
;   1. Run Build-PolyMonPackage.ps1 to populate PolyMonInstall\
;   2. Compile with: iscc.exe PolyMon-Setup.iss
;
; The installer expects the staging folder layout produced by
; Build-PolyMonPackage.ps1 in the same directory as this .iss file.

#define MyAppName "PolyMon"
#define MyAppVersion "1.50"
#define MyAppPublisher "Bob Neumann"
#define MyAppURL "https://github.com/bneumann/polymon"
#define StagingDir "PolyMonInstall"

[Setup]
AppId={{B7E3F2A1-8C4D-4F5E-9A1B-2D3C4E5F6A7B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={commonpf}\PolyMon
DefaultGroupName=PolyMon
AllowNoIcons=yes
OutputDir=Output
OutputBaseFilename=PolyMon-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
UninstallDisplayIcon={app}\PolyMon Manager\PolyMonManager.exe
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=6.1sp1
SetupIconFile=PolyMonManager\Resources\PolyMon.ico
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; =====================================================================
; Files
; =====================================================================
[Files]
; --- PolyMon Manager ---
Source: "{#StagingDir}\PolyMon Manager\PolyMonManager.exe";          DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\PolyMon.dll";                 DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\PolyMonNotifier.dll";         DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericMonitor.dll";          DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericMonitorEditor.dll";    DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericXMLEditor.dll";        DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\ZedGraph.dll";                DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Interop.MSScriptControl.dll"; DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\AlertRecap_Email.xsl";       DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\AlertRecap_Web.xsl";         DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Heartbeat_Email.xsl";        DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Notify.wav";                  DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\PolyMonManager.exe.config";   DestDir: "{app}\PolyMon Manager"; Flags: onlyifdoesntexist

; Manager optional files (included if present in staging)
Source: "{#StagingDir}\PolyMon Manager\polymon.chm";                 DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#StagingDir}\PolyMon Manager\PolyMonLicense.pdf";          DestDir: "{app}\PolyMon Manager"; Flags: ignoreversion skipifsourcedoesntexist

; --- Monitor DLLs (Manager\Monitors) ---
Source: "{#StagingDir}\PolyMon Manager\Monitors\CPUMonitor.dll";             DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\DiskMonitor.dll";            DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\FileMonitor.dll";            DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PerfMonitor.dll";            DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PingMonitor.dll";            DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PowerShellMonitor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\ServiceMonitor.dll";         DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMPMonitor.dll";            DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMP.dll";                   DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SQLMonitor.dll";             DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\TCPPortMonitor.dll";         DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLMonitor.dll";             DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLXMLMonitor.dll";          DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\WMIMonitor.dll";             DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\NRSPortalMonitor.dll";       DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion

; --- Monitor Editor DLLs ---
Source: "{#StagingDir}\PolyMon Manager\Monitors\CPUMonitorEditor.dll";       DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\DiskMonitorEditor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\FileMonitorEditor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PerfMonitorEditor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PingMonitorEditor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PowerShellMonitorEditor.dll"; DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\ServiceMonitorEditor.dll";   DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMPMonitorEditor.dll";      DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\TCPPortMonitorEditor.dll";   DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLMonitorEditor.dll";       DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLXMLMonitorEditor.dll";    DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\WMIMonitorEditor.dll";       DestDir: "{app}\PolyMon Manager\Monitors"; Flags: ignoreversion

; --- PolyMon Executive ---
Source: "{#StagingDir}\PolyMon Executive\PolyMonExecutive.exe";              DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PolyMon.dll";                       DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PolyMonNotifier.dll";               DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\GenericMonitor.dll";                DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\Interop.MSScriptControl.dll";       DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\AlertRecap_Email.xsl";             DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\AlertRecap_Web.xsl";               DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\Heartbeat_Email.xsl";              DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PolyMonExecutive.exe.config";       DestDir: "{app}\PolyMon Executive"; Flags: onlyifdoesntexist

; Executive Monitor DLLs
Source: "{#StagingDir}\PolyMon Executive\CPUMonitor.dll";                    DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\DiskMonitor.dll";                   DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\FileMonitor.dll";                   DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PerfMonitor.dll";                   DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PingMonitor.dll";                   DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\PowerShellMonitor.dll";             DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\ServiceMonitor.dll";                DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\SNMPMonitor.dll";                   DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\SNMP.dll";                          DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\SQLMonitor.dll";                    DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\TCPPortMonitor.dll";                DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\URLMonitor.dll";                    DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\URLXMLMonitor.dll";                 DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\WMIMonitor.dll";                    DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Executive\NRSPortalMonitor.dll";              DestDir: "{app}\PolyMon Executive"; Flags: ignoreversion

; --- SQL Scripts ---
Source: "{#StagingDir}\SQL\DB Version 1.30.sql";              DestDir: "{app}\SQL"; Flags: ignoreversion
Source: "{#StagingDir}\SQL\Update DB 1.00 to 1.10.sql";      DestDir: "{app}\SQL"; Flags: ignoreversion
Source: "{#StagingDir}\SQL\Update DB 1.10 to 1.30.sql";      DestDir: "{app}\SQL"; Flags: ignoreversion
Source: "{#StagingDir}\SQL\Update DB 1.30 to 1.40.sql";      DestDir: "{app}\SQL"; Flags: ignoreversion
Source: "{#StagingDir}\SQL\Update DB 1.40 to 1.50.sql";      DestDir: "{app}\SQL"; Flags: ignoreversion
Source: "{#StagingDir}\SQL\TSData-Extend.sql";                DestDir: "{app}\SQL"; Flags: ignoreversion

; --- PowerShell Modules ---
; Installed to the system-wide PS modules path so all users/services can import them.
; onlyifdoesntexist preserves user-customized modules on upgrade.
Source: "PSModules\SSH-Sessions\SSH-Sessions.psd1";         DestDir: "{commonpf}\WindowsPowerShell\Modules\SSH-Sessions"; Flags: onlyifdoesntexist
Source: "PSModules\SSH-Sessions\SSH-Sessions.psm1";         DestDir: "{commonpf}\WindowsPowerShell\Modules\SSH-Sessions"; Flags: onlyifdoesntexist
Source: "PSModules\SSH-Sessions\Renci.SshNet35.dll";        DestDir: "{commonpf}\WindowsPowerShell\Modules\SSH-Sessions"; Flags: onlyifdoesntexist
Source: "PSModules\SQL_Server_Overview\SQL_Server_Overview.psd1";   DestDir: "{commonpf}\WindowsPowerShell\Modules\SQL_Server_Overview"; Flags: onlyifdoesntexist
Source: "PSModules\SQL_Server_Overview\SQL_Server_Overview.psm1";   DestDir: "{commonpf}\WindowsPowerShell\Modules\SQL_Server_Overview"; Flags: onlyifdoesntexist
Source: "PSModules\SQL_Server_Overview2\SQL_Server_Overview.psd1";  DestDir: "{commonpf}\WindowsPowerShell\Modules\SQL_Server_Overview2"; Flags: onlyifdoesntexist
Source: "PSModules\SQL_Server_Overview2\SQL_Server_Overview2.psm1"; DestDir: "{commonpf}\WindowsPowerShell\Modules\SQL_Server_Overview2"; Flags: onlyifdoesntexist

; --- Utility Scripts ---
Source: "{#StagingDir}\Install-PolyMon.ps1";      DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\Uninstall-PolyMon.ps1";    DestDir: "{app}"; Flags: ignoreversion

; =====================================================================
; Icons (Start Menu)
; =====================================================================
[Icons]
Name: "{group}\PolyMon Manager";     Filename: "{app}\PolyMon Manager\PolyMonManager.exe"
Name: "{group}\Uninstall PolyMon";   Filename: "{uninstallexe}"

; =====================================================================
; Post-install: register and start the service
; =====================================================================
[Run]
Filename: "{code:GetInstallUtilPath}"; Parameters: """{app}\PolyMon Executive\PolyMonExecutive.exe"""; \
    StatusMsg: "Installing PolyMon Executive service..."; Flags: runhidden waituntilterminated; \
    Check: InstallUtilExists
Filename: "net.exe"; Parameters: "start PolyMonExecutive"; \
    StatusMsg: "Starting PolyMon Executive service..."; Flags: runhidden waituntilterminated; \
    Check: InstallUtilExists

; =====================================================================
; Uninstall: stop and remove the service
; =====================================================================
[UninstallRun]
Filename: "net.exe"; Parameters: "stop PolyMonExecutive"; \
    Flags: runhidden waituntilterminated; RunOnceId: "StopService"
Filename: "{code:GetInstallUtilPath}"; Parameters: "/u ""{app}\PolyMon Executive\PolyMonExecutive.exe"""; \
    Flags: runhidden waituntilterminated; RunOnceId: "UninstallService"; \
    Check: InstallUtilExists

; =====================================================================
; Pascal Script — service management, InstallUtil, DB setup prompt
; =====================================================================
[Code]

// --- InstallUtil detection ---

function GetInstallUtilPath(Param: String): String;
var
  Path64, Path32: String;
begin
  Path64 := ExpandConstant('{win}') + '\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe';
  Path32 := ExpandConstant('{win}') + '\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe';
  if FileExists(Path64) then
    Result := Path64
  else if FileExists(Path32) then
    Result := Path32
  else
    Result := '';
end;

function InstallUtilExists: Boolean;
begin
  Result := GetInstallUtilPath('') <> '';
end;

// --- Service helper: check if service exists ---

function ServiceExists(ServiceName: String): Boolean;
var
  ResultCode: Integer;
begin
  // sc query returns 0 if service exists, nonzero otherwise
  Result := Exec('sc.exe', 'query ' + ServiceName, '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
            and (ResultCode = 0);
end;

// --- PrepareToInstall: stop & uninstall existing service for upgrade ---

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
  InstallUtilPath: String;
  ExePath: String;
begin
  Result := '';
  NeedsRestart := False;

  if ServiceExists('PolyMonExecutive') then
  begin
    // Stop the service (ignore errors — it may already be stopped)
    Exec('net.exe', 'stop PolyMonExecutive', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // Uninstall the old service via InstallUtil
    InstallUtilPath := GetInstallUtilPath('');
    if InstallUtilPath <> '' then
    begin
      ExePath := ExpandConstant('{app}') + '\PolyMon Executive\PolyMonExecutive.exe';
      if FileExists(ExePath) then
        Exec(InstallUtilPath, '/u "' + ExePath + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;

// --- Database setup wizard page ---

var
  DbPage: TInputQueryWizardPage;
  DbSetupCheckBox: TNewCheckBox;

procedure InitializeWizard;
begin
  // Add a custom page after the install dir page for DB settings
  DbPage := CreateInputQueryPage(wpSelectDir,
    'Database Configuration',
    'Configure the PolyMon database connection.',
    'Enter SQL Server details below. If you do not want to run database setup,' +
    ' uncheck the box and click Next.');

  DbPage.Add('SQL Server instance:', False);
  DbPage.Add('Database name:', False);
  DbPage.Values[0] := '.\SQLEXPRESS';
  DbPage.Values[1] := 'PolyMon';

  DbSetupCheckBox := TNewCheckBox.Create(DbPage);
  DbSetupCheckBox.Parent := DbPage.Surface;
  DbSetupCheckBox.Caption := 'Run database setup/upgrade after install';
  DbSetupCheckBox.Checked := True;
  DbSetupCheckBox.Left := 0;
  DbSetupCheckBox.Top := DbPage.Edits[1].Top + DbPage.Edits[1].Height + ScaleY(16);
  DbSetupCheckBox.Width := DbPage.SurfaceWidth;
end;

// --- Post-install: run database setup if user opted in ---

procedure RunDatabaseSetup;
var
  SqlInstance, DbName, SqlCmd, ScriptsDir: String;
  ResultCode: Integer;
  CurrentVersion: AnsiString;
  VersionFile: String;
begin
  SqlInstance := DbPage.Values[0];
  DbName := DbPage.Values[1];

  ScriptsDir := ExpandConstant('{app}') + '\SQL';
  VersionFile := ExpandConstant('{tmp}') + '\polymon_dbver.txt';

  // Detect current DB version
  SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName
            + ' -Q "SET NOCOUNT ON; SELECT CAST(SettingValue AS varchar(10)) FROM SysSettings WHERE SettingName=''DBVersion''" -h -1 -W'
            + ' -o "' + VersionFile + '"';
  Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  CurrentVersion := '';
  if LoadStringFromFile(VersionFile, CurrentVersion) then
    CurrentVersion := Trim(CurrentVersion);

  // If no database found, offer to create it
  if (CurrentVersion = '') or (ResultCode <> 0) then
  begin
    if MsgBox('Database "' + DbName + '" not found or empty.' + #13#10
              + 'Create a new PolyMon database?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -Q "CREATE DATABASE [' + DbName + ']"';
      Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\DB Version 1.30.sql"';
      Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      CurrentVersion := '1.30';
      MsgBox('Database created at version 1.30. Applying upgrades...', mbInformation, MB_OK);
    end
    else
      Exit;
  end;

  // Apply upgrade scripts in sequence
  if (CurrentVersion = '1.00') or (CurrentVersion = '1.0') then
  begin
    SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\Update DB 1.00 to 1.10.sql"';
    Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    CurrentVersion := '1.10';
  end;

  if (CurrentVersion = '1.10') or (CurrentVersion = '1.1') then
  begin
    SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\Update DB 1.10 to 1.30.sql"';
    Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    CurrentVersion := '1.30';
  end;

  if (CurrentVersion = '1.30') or (CurrentVersion = '1.3') then
  begin
    SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\Update DB 1.30 to 1.40.sql"';
    Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    CurrentVersion := '1.40';
  end;

  if (CurrentVersion = '1.40') or (CurrentVersion = '1.4') then
  begin
    SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\Update DB 1.40 to 1.50.sql"';
    Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    CurrentVersion := '1.50';
  end;

  // Always run TSData-Extend (safe to re-run)
  SqlCmd := 'sqlcmd -S ' + SqlInstance + ' -d ' + DbName + ' -i "' + ScriptsDir + '\TSData-Extend.sql"';
  Exec('cmd.exe', '/c ' + SqlCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  if CurrentVersion = '1.50' then
    MsgBox('Database is up to date at version 1.50.', mbInformation, MB_OK)
  else
    MsgBox('Database upgrade completed. Current version: ' + String(CurrentVersion) + #13#10
           + 'Check the SQL scripts in ' + ScriptsDir + ' if further action is needed.',
           mbInformation, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if DbSetupCheckBox.Checked then
      RunDatabaseSetup;
  end;
end;
