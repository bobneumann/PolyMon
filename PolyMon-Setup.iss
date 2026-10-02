; PolyMon-Setup.iss
; ============================================================================
; Single idempotent installer for the full PolyMon stack:
;   - PolyMon Manager (WinForms GUI)
;   - PolyMon Executive (Windows service)
;   - SQL Server database (create-if-absent, then version-gated upgrade)
;
; Responsibility split (Option A):
;   * Inno owns FILES, the SERVICE, shortcuts, and the Add/Remove Programs
;     entry — everything that must be tracked for a clean uninstall, and the
;     one thing only a real packager can do: embed the payload in the .exe.
;   * Install-PolyMon.ps1 -DbOnly owns the DATABASE (create + version-gated
;     upgrade chain). Single source of truth for the SQL logic; not duplicated
;     here in Pascal.
;
; Idempotent: safe to run repeatedly. A stable AppId makes re-runs an in-place
; upgrade/repair. The service is stopped + deleted before files are copied
; (no locked DLLs) and re-installed afterward. Config files are preserved on
; upgrade so connection strings survive.
;
; Build:
;   1. .\Build-PolyMonPackage.ps1 -Build      (stages files into PolyMonInstall\)
;   2. iscc.exe PolyMon-Setup.iss             (-> Output\PolyMon-Setup.exe)
; ============================================================================

#define MyAppName "PolyMon"
; Policy (effective v1.61 onward, decided 2026-10-02): this and
; SysSettings.DBVersion are COUPLED - every release bump here gets a matching
; DB version bump, even on releases with no real schema change. For a
; no-schema release, add a trivial "Update DB X.XX to Y.YY.sql" to
; PolymonSQL\Update Scripts\ containing only "UPDATE SysSettings SET
; DBVersion = Y.YY" (plus the standard header comment), and append the new
; version to Install-PolyMon.ps1's $VersionChain array (-DbOnly's upgrade
; chain is computed from that single ordered list, not a hand-maintained
; switch - see the comment there). Keeps the exact-equality
; Sys.DBVersion = mDBVersion check in frmMain.vb/PolyMonExecutive.vb simple -
; no compatibility-range logic needed.
; v1.59/v1.60 predate this policy (DB tops out at 1.58 for both, not
; retroactively fixed). v1.61 was the first release under it. v1.62-v1.65
; were a rapid bugfix sequence from testing the real compiled installer on
; mt7060 for the first time (see git log for full detail on each): a
; hardcoded SQL-script manifest silently dropping new migration scripts, a
; NonInteractive crash with no SQL tool found, zero diagnostic output on
; failure (fixed by {app}\DbSetup.log), an Invoke-Sqlcmd parameter mismatch
; on an older SqlServer module, a "$Var?" string-interpolation parsing bug,
; and finally the Executive service silently picking up a placeholder
; config instead of the wizard's entered values (an Inno-level
; "onlyifdoesntexist" config copy raced ahead of WriteConfigIfAbsent on
; every fresh install).
#define MyAppVersion "1.65"
#define MyAppPublisher "Bob Neumann"
#define StagingDir "PolyMonInstall"
#define ServiceName "PolyMonExecutive"

[Setup]
; A STABLE AppId is what turns a re-run into an upgrade instead of a parallel
; install. NEVER change this GUID across releases.
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
UninstallDisplayIcon={app}\PolyMon Manager\PolyMonManager.exe
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=6.1sp1
SetupIconFile=PolyMonManager\Resources\PolyMon.ico
DisableProgramGroupPage=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: desktopicon; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"
; Unchecked by default - installing/starting Executive is an opt-in, confirmed
; action (see ssPostInstall), not something that happens just by running this
; installer. Only the ONE machine meant to run monitoring centrally should
; ever have this checked - every instance hardcodes ExecutiveID=1, so a
; second one means duplicate monitor cycles against the same database.
Name: installExecutive; Description: "Install and start the PolyMon Executive monitoring service on THIS machine"; GroupDescription: "PolyMon Executive (monitoring service):"; Flags: unchecked

; ============================================================================
; Files — Inno embeds and tracks all of these (clean uninstall).
; Layout under {app} mirrors what Install-PolyMon.ps1 expects as its package
; dir, so the -DbOnly call finds SQL\ next to the script.
; ============================================================================
[Files]
; ---- Manager (GUI) ----
Source: "{#StagingDir}\PolyMon Manager\*"; DestDir: "{app}\PolyMon Manager"; \
    Excludes: "*.config"; Flags: ignoreversion recursesubdirs createallsubdirs
; Manager config is written ONLY by WriteConfigIfAbsent in ssPostInstall (see
; below), using the user's actual entered SQL instance/database - NOT copied
; here. An earlier version also had an Inno-level "onlyifdoesntexist" copy of
; the checked-in placeholder config (Data Source=.\SQLEXPRESS;Initial
; Catalog=PolyMon) as a belt-and-suspenders fallback - but [Files] copying
; happens during ssInstall, BEFORE ssPostInstall runs WriteConfigIfAbsent, so
; on every fresh install that placeholder landed FIRST and WriteConfigIfAbsent
; then found a file already present (the one this very install run had just
; created) and silently skipped writing the real values. Confirmed 2026-10-02:
; a real install pointed Executive at the placeholder .\SQLEXPRESS/PolyMon
; instead of the instance/database actually entered in the wizard. Removed -
; WriteConfigIfAbsent is now the sole source of truth for config creation.

; ---- Executive (service) ----
Source: "{#StagingDir}\PolyMon Executive\*"; DestDir: "{app}\PolyMon Executive"; \
    Excludes: "*.config"; Flags: ignoreversion recursesubdirs createallsubdirs
; Executive config: same story as Manager above - written only by
; WriteConfigIfAbsent in ssPostInstall, not copied here.

; ---- PowerShell modules ----
Source: "{#StagingDir}\PSModules\*"; DestDir: "{app}\PSModules"; \
    Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

; ---- SQL scripts (needed by the -DbOnly PS call; kept for reference too) ----
Source: "{#StagingDir}\SQL\*"; DestDir: "{app}\SQL"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- Installer scripts (Install for -DbOnly, Uninstall for reference) ----
Source: "{#StagingDir}\Install-PolyMon.ps1";   DestDir: "{app}"; Flags: ignoreversion
Source: "{#StagingDir}\Uninstall-PolyMon.ps1"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\PolyMon Manager";   Filename: "{app}\PolyMon Manager\PolyMonManager.exe"; WorkingDir: "{app}\PolyMon Manager"
Name: "{commondesktop}\PolyMon";   Filename: "{app}\PolyMon Manager\PolyMonManager.exe"; WorkingDir: "{app}\PolyMon Manager"; Tasks: desktopicon
Name: "{group}\Uninstall PolyMon"; Filename: "{uninstallexe}"

; ============================================================================
; Uninstall — stop + remove the service cleanly (Inno removes the files).
; ============================================================================
[UninstallRun]
Filename: "{sys}\sc.exe"; Parameters: "stop {#ServiceName}";   Flags: runhidden; RunOnceId: "StopPolyMonSvc"
Filename: "{sys}\sc.exe"; Parameters: "delete {#ServiceName}"; Flags: runhidden; RunOnceId: "DeletePolyMonSvc"

; ============================================================================
; Pascal Script — service lifecycle, config writing, and DB delegation.
; ============================================================================
[Code]

var
  SqlPage: TInputQueryWizardPage;
  DbSetupPage: TInputOptionWizardPage;

// ---- service helpers -------------------------------------------------------

function ServiceExists(const Name: String): Boolean;
var
  RC: Integer;
begin
  Result := Exec(ExpandConstant('{sys}\sc.exe'), 'query ' + Name, '',
    SW_HIDE, ewWaitUntilTerminated, RC) and (RC = 0);
end;

function FindInstallUtil(): String;
begin
  Result := ExpandConstant('{win}\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe');
  if not FileExists(Result) then
    Result := ExpandConstant('{win}\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe');
end;

procedure StopAndDeleteService(const Name: String);
var
  RC: Integer;
begin
  Exec(ExpandConstant('{sys}\sc.exe'), 'stop ' + Name, '', SW_HIDE, ewWaitUntilTerminated, RC);
  Sleep(2000);  // let the SCM release the executable before files are overwritten
  Exec(ExpandConstant('{sys}\sc.exe'), 'delete ' + Name, '', SW_HIDE, ewWaitUntilTerminated, RC);
  Sleep(1000);
end;
// ---- /MANAGERONLY support ---------------------------------------------------
// For coworkers upgrading their own desktop Manager GUI - no SQL/DB prompts,
// no automatic DB setup, and critically, does NOT install/start the
// PolyMonExecutive service (that would otherwise happen unconditionally on
// every machine the installer runs on, which is wrong for a per-user client
// upgrade - the service belongs on one central server, not every desktop).
// Combine with standard Inno switches for a fully unattended run, e.g.:
//   PolyMon-Setup.exe /MANAGERONLY /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
// UPGRADES ONLY - the config file must already exist. On a machine with no
// prior install, the SQL page is still skipped but PolyMonManager.exe.config
// gets written with the placeholder ".\SQLEXPRESS"/"PolyMon" defaults (since
// WriteConfigIfAbsent only no-ops when the file already exists) - wrong for
// a fresh install. Don't use this switch for first-time installs.

function HasCmdLineSwitch(const Switch: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to ParamCount do
    if CompareText(ParamStr(i), Switch) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

function IsManagerOnlyMode(): Boolean;
begin
  Result := HasCmdLineSwitch('/MANAGERONLY');
end;


// ---- wizard pages ----------------------------------------------------------

procedure InitializeWizard;
begin
  SqlPage := CreateInputQueryPage(wpSelectDir,
    'SQL Server Connection',
    'Where is the PolyMon database hosted?',
    'Enter the SQL Server instance and database name. Windows authentication is used.');
  SqlPage.Add('SQL Server instance (e.g. SERVER\SQLEXPRESS):', False);
  SqlPage.Add('Database name:', False);
  SqlPage.Values[0] := '.\SQLEXPRESS';
  SqlPage.Values[1] := 'PolyMon';

  DbSetupPage := CreateInputOptionPage(SqlPage.ID,
    'Database Setup',
    'What should the installer do with the database?',
    'The installer can create the database if it does not exist and apply any '
    + 'schema updates needed to reach the current version. Choose "Skip" if you '
    + 'manage the database yourself.',
    True, False);
  DbSetupPage.Add('Create and/or upgrade the database automatically (recommended)');
  DbSetupPage.Add('Skip database setup (I will run the SQL scripts myself)');
  DbSetupPage.SelectedValueIndex := 0;

  if IsManagerOnlyMode() then
    DbSetupPage.SelectedValueIndex := 1;  // force "skip" even though the page is hidden
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if IsManagerOnlyMode() and ((PageID = SqlPage.ID) or (PageID = DbSetupPage.ID)) then
    Result := True;
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

// ---- config writers (only when absent; preserves on upgrade) ---------------

procedure WriteConfigIfAbsent(const Path, Xml: String);
begin
  if not FileExists(Path) then
    SaveStringToFile(Path, Xml, False);
end;

procedure WriteConfigs(const Instance, Db: String);
var
  MgrXml, ExecXml: String;
begin
  MgrXml :=
    '<?xml version="1.0" encoding="utf-8"?>' + #13#10 +
    '<configuration>' + #13#10 +
    '  <appSettings>' + #13#10 +
    '    <add key="SQLConn" value="Data Source=' + Instance +
         ';Initial Catalog=' + Db + ';Integrated Security=SSPI;"/>' + #13#10 +
    '  </appSettings>' + #13#10 +
    '  <startup>' + #13#10 +
    '    <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.8"/>' + #13#10 +
    '  </startup>' + #13#10 +
    '</configuration>' + #13#10;
  WriteConfigIfAbsent(ExpandConstant('{app}\PolyMon Manager\PolyMonManager.exe.config'), MgrXml);

  ExecXml :=
    '<?xml version="1.0" encoding="utf-8"?>' + #13#10 +
    '<configuration>' + #13#10 +
    '  <appSettings>' + #13#10 +
    '    <add key="SQLConn" value="Data Source=' + Instance +
         ';Initial Catalog=' + Db + ';Integrated Security=SSPI;"/>' + #13#10 +
    '    <add key="ExecutiveID" value="1"/>' + #13#10 +
    '  </appSettings>' + #13#10 +
    '  <startup>' + #13#10 +
    '    <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.8"/>' + #13#10 +
    '  </startup>' + #13#10 +
    '</configuration>' + #13#10;
  WriteConfigIfAbsent(ExpandConstant('{app}\PolyMon Executive\PolyMonExecutive.exe.config'), ExecXml);
end;

// ---- database delegation ---------------------------------------------------
// Calls the (single-source-of-truth) PS installer in -DbOnly mode. Returns
// True on success. On any failure, the caller shows manual instructions.

function RunDatabaseSetup(const Instance, Db: String): Boolean;
var
  RC: Integer;
  PsArgs: String;
begin
  PsArgs :=
    '-NoProfile -ExecutionPolicy Bypass -File "' +
      ExpandConstant('{app}\Install-PolyMon.ps1') + '" ' +
    '-DbOnly -NonInteractive ' +
    '-SqlInstance "' + Instance + '" ' +
    '-DatabaseName "' + Db + '" ' +
    '-InstallDir "' + ExpandConstant('{app}') + '"';

  Result := Exec('powershell.exe', PsArgs, '', SW_HIDE, ewWaitUntilTerminated, RC)
            and (RC = 0);
end;

// ---- service install -------------------------------------------------------

procedure InstallAndStartService();
var
  InstallUtil, ExePath: String;
  RC: Integer;
begin
  InstallUtil := FindInstallUtil();
  ExePath := ExpandConstant('{app}\PolyMon Executive\PolyMonExecutive.exe');

  if not FileExists(InstallUtil) then
  begin
    MsgBox('.NET Framework 4.x InstallUtil.exe was not found, so the PolyMon '
      + 'Executive service could not be registered. Install .NET Framework 4.8 '
      + 'and re-run this installer.', mbError, MB_OK);
    Exit;
  end;

  if Exec(InstallUtil, '"' + ExePath + '"', '', SW_HIDE, ewWaitUntilTerminated, RC)
     and (RC = 0) then
  begin
    Exec(ExpandConstant('{sys}\sc.exe'), 'config {#ServiceName} start= auto', '',
      SW_HIDE, ewWaitUntilTerminated, RC);
    Exec(ExpandConstant('{sys}\sc.exe'), 'start {#ServiceName}', '',
      SW_HIDE, ewWaitUntilTerminated, RC);
  end
  else
    MsgBox('The PolyMon Executive service could not be registered (InstallUtil '
      + 'exit code ' + IntToStr(RC) + '). You can register it later by running '
      + 'InstallUtil against {app}\PolyMon Executive\PolyMonExecutive.exe.',
      mbError, MB_OK);
end;

// ---- lifecycle -------------------------------------------------------------

procedure CurStepChanged(CurStep: TSetupStep);
var
  Instance, Db: String;
begin
  case CurStep of
    ssInstall:
      // BEFORE copying files: stop + remove the existing service so its
      // .exe/.dll are not locked. Safe whether or not it exists.
      if ServiceExists('{#ServiceName}') then
        StopAndDeleteService('{#ServiceName}');

    ssPostInstall:
      begin
        Instance := Trim(SqlPage.Values[0]);
        Db := Trim(SqlPage.Values[1]);
        if Db = '' then Db := 'PolyMon';

        WriteConfigs(Instance, Db);

        // Database (delegated). Option 0 = automatic.
        if DbSetupPage.SelectedValueIndex = 0 then
        begin
          if not RunDatabaseSetup(Instance, Db) then
            MsgBox('Automatic database setup did not complete. See '
              + ExpandConstant('{app}\DbSetup.log')
              + ' for the exact error, or set up the database manually:' + #13#10#13#10
              + '  1. Create the database if needed: CREATE DATABASE [' + Db + ']' + #13#10
              + '  2. If new, run: {app}\SQL\DB Version 1.30.sql' + #13#10
              + '  3. Run the "Update DB x.xx to y.yy.sql" scripts in {app}\SQL '
              + 'in order, up to the newest.' + #13#10
              + '  4. Run: {app}\SQL\TSData-Extend.sql' + #13#10#13#10
              + 'Then start the PolyMon Executive service.',
              mbInformation, MB_OK);
        end;

        // Executive install requires BOTH the opt-in checkbox AND an
        // explicit confirmation - never happens just by running the
        // installer. /MANAGERONLY always skips it regardless of the
        // checkbox state (that mode is for desktop-only client upgrades).
        if (not IsManagerOnlyMode()) and WizardIsTaskSelected('installExecutive') then
        begin
          if MsgBox('Install and start the PolyMon Executive monitoring service on THIS machine?'
            + #13#10#13#10
            + 'Only do this on the single machine meant to run monitoring centrally. '
            + 'Every Executive instance uses ExecutiveID=1 - installing it on more than '
            + 'one machine means duplicate monitor cycles and duplicate writes against '
            + 'the same production database.'
            + #13#10#13#10 + 'Are you sure this is the right machine?',
            mbConfirmation, MB_YESNO) = IDYES then
            InstallAndStartService();
        end;
      end;
  end;
end;
