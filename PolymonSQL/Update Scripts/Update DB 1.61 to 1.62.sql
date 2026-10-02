-- =============================================
-- Script: Update DB 1.61 to 1.62
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.62 fixes two installer/packaging bugs found while testing v1.61
--          on mt7060: Build-PolyMonPackage.ps1 was silently dropping newly
--          added "Update DB X to Y.sql" scripts from the shipped installer
--          (hardcoded manifest, now auto-discovered), and Install-PolyMon.ps1
--          hung/threw under -NonInteractive when no SQL command-line tool was
--          found (now fails fast with a clear message instead). No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.62
GO
