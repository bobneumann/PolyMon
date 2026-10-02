-- =============================================
-- Script: Update DB 1.62 to 1.63
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.63 adds diagnostic logging to Install-PolyMon.ps1 (every run
--          now writes a full transcript to DbSetup.log next to the script,
--          since the installer runs it hidden with zero output capture -
--          confirmed blocking real diagnosis across v1.61/v1.62) and widens
--          sqlcmd.exe detection to also check Program Files (x86), where
--          SQL Server command-line tools commonly install even on 64-bit
--          Windows. No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.63
GO
