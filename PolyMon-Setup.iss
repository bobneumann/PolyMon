; PolyMon-Setup.iss
; InnoSetup script — installs PolyMon Manager (client) only.
; The database and Executive service are assumed to already be running on the server.
;
; Prerequisites:
;   1. Run Build-PolyMonPackage.ps1 to populate PolyMonInstall\
;   2. Compile with: iscc.exe PolyMon-Setup.iss -> Output\PolyMon-Setup.exe

#define MyAppName "PolyMon Manager"
#define MyAppVersion "1.55"
#define MyAppPublisher "Bob Neumann"
#define StagingDir "PolyMonInstall"

[Setup]
AppId={{B7E3F2A1-8C4D-4F5E-9A1B-2D3C4E5F6A7B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commonpf}\PolyMon
DefaultGroupName=PolyMon
AllowNoIcons=yes
OutputDir=Output
OutputBaseFilename=PolyMon-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
UninstallDisplayIcon={app}\PolyMonManager.exe
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
; Core Manager files
Source: "{#StagingDir}\PolyMon Manager\PolyMonManager.exe";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\PolyMon.dll";                 DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\PolyMonNotifier.dll";         DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericMonitor.dll";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericMonitorEditor.dll";    DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\GenericXMLEditor.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\ScottPlot.dll";               DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\ScottPlot.WinForms.dll";      DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\ZedGraph.dll";                DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#StagingDir}\PolyMon Manager\Interop.MSScriptControl.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\AlertRecap_Email.xsl";        DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\AlertRecap_Web.xsl";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Heartbeat_Email.xsl";         DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Notify.wav";                  DestDir: "{app}"; Flags: ignoreversion
; Config written by installer — only on fresh install, preserved on upgrade
Source: "{#StagingDir}\PolyMon Manager\PolyMonManager.exe.config";   DestDir: "{app}"; Flags: onlyifdoesntexist

; Monitor DLLs
Source: "{#StagingDir}\PolyMon Manager\Monitors\CPUMonitor.dll";              DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\DiskMonitor.dll";             DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\FileMonitor.dll";             DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PerfMonitor.dll";             DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PingMonitor.dll";             DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PowerShellMonitor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\ServiceMonitor.dll";          DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMPMonitor.dll";             DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMP.dll";                    DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SQLMonitor.dll";              DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SQLOverviewMonitor.dll";      DestDir: "{app}\Monitors"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#StagingDir}\PolyMon Manager\Monitors\TCPPortMonitor.dll";          DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLMonitor.dll";              DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLXMLMonitor.dll";           DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\WMIMonitor.dll";              DestDir: "{app}\Monitors"; Flags: ignoreversion

; Monitor Editor DLLs
Source: "{#StagingDir}\PolyMon Manager\Monitors\CPUMonitorEditor.dll";        DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\DiskMonitorEditor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\FileMonitorEditor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PerfMonitorEditor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PingMonitorEditor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\PowerShellMonitorEditor.dll"; DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\ServiceMonitorEditor.dll";    DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SNMPMonitorEditor.dll";       DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\SQLOverviewMonitorEditor.dll"; DestDir: "{app}\Monitors"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#StagingDir}\PolyMon Manager\Monitors\TCPPortMonitorEditor.dll";    DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLMonitorEditor.dll";        DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\URLXMLMonitorEditor.dll";     DestDir: "{app}\Monitors"; Flags: ignoreversion
Source: "{#StagingDir}\PolyMon Manager\Monitors\WMIMonitorEditor.dll";        DestDir: "{app}\Monitors"; Flags: ignoreversion

; =====================================================================
; Icons (Start Menu + Desktop)
; =====================================================================
[Icons]
Name: "{group}\PolyMon Manager";   Filename: "{app}\PolyMonManager.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\PolyMon";   Filename: "{app}\PolyMonManager.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{group}\Uninstall PolyMon"; Filename: "{uninstallexe}"

[Tasks]
Name: desktopicon; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

; =====================================================================
; Pascal Script — SQL connection string configuration
; =====================================================================
[Code]

var
  SqlPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  // Ask for the SQL Server instance so we can write the .config
  SqlPage := CreateInputQueryPage(wpSelectDir,
    'SQL Server Connection',
    'Enter the SQL Server instance where PolyMon database is hosted.',
    'Use the format: SERVER\INSTANCE  (e.g. PHCMS01\SQLEXPRESS)' + #13#10 +
    'For the default instance on a named server, just enter the server name.');

  SqlPage.Add('SQL Server instance:', False);
  SqlPage.Add('Database name:', False);
  SqlPage.Values[0] := '';
  SqlPage.Values[1] := 'PolyMon';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = SqlPage.ID) and (Trim(SqlPage.Values[0]) = '') then
  begin
    MsgBox('Please enter the SQL Server instance name.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure WriteConnectionConfig;
var
  ConfigPath, SqlInstance, DbName, ConfigXml: String;
begin
  SqlInstance := Trim(SqlPage.Values[0]);
  DbName      := Trim(SqlPage.Values[1]);
  if DbName = '' then DbName := 'PolyMon';

  ConfigPath := ExpandConstant('{app}') + '\PolyMonManager.exe.config';

  ConfigXml :=
    '<?xml version="1.0" encoding="utf-8"?>' + #13#10 +
    '<configuration>' + #13#10 +
    '  <appSettings>' + #13#10 +
    '    <add key="SQLConn" value="Data Source=' + SqlInstance +
         ';Initial Catalog=' + DbName + ';Integrated Security=SSPI;"/>' + #13#10 +
    '  </appSettings>' + #13#10 +
    '  <startup>' + #13#10 +
    '    <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.8"/>' + #13#10 +
    '  </startup>' + #13#10 +
    '</configuration>' + #13#10;

  SaveStringToFile(ConfigPath, ConfigXml, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    WriteConnectionConfig;
end;
