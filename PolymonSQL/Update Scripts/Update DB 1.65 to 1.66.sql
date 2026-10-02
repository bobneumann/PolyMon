-- =============================================
-- Script: Update DB 1.65 to 1.66
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.66 syncs PolyMonManager and PolyMonExecutive's
--          AssemblyVersion/AssemblyFileVersion (AssemblyInfo.vb) to the
--          current installer version - both had been hardcoded at "1.5.5"
--          for years, completely disconnected from the real shipped
--          version, making the About box permanently stale. This axis is
--          now part of the same coupled-versioning policy as DBVersion
--          (see PolyMon-Setup.iss). No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.66
GO
