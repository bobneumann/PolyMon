-- =============================================
-- Script: Update DB 1.63 to 1.64
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.64 fixes the real root cause found via mt7060's DbSetup.log
--          (shipped in v1.63): Invoke-Sqlcmd on mt7060's SqlServer module
--          version doesn't support -TrustServerCertificate (added for
--          SQL Server 2022-era encryption-by-default changes) - the param
--          was passed unconditionally, throwing "A parameter cannot be
--          found that matches parameter name 'TrustServerCertificate'."
--          Now detected once via Get-Command and only passed if supported.
--          Also fixed a real PowerShell parsing bug exposed by that crash's
--          fallback path: "$ServerInstance?" in a double-quoted string is
--          parsed as variable name "ServerInstance?" (the ? is NOT treated
--          as a separate literal character) - confirmed via direct local
--          testing. No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.64
GO
