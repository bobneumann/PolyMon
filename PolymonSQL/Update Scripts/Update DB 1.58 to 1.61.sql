-- =============================================
-- Script: Update DB 1.58 to 1.61
-- Feature: NONE - this is a pure version-number alignment, no schema change.
--          v1.59/v1.60 were installer-only releases (bug fixes to the
--          installer itself) and did not bump DBVersion at the time,
--          leaving the DB chain at 1.58 while the installer moved on.
--          Policy from here forward (documented in PolyMon-Setup.iss):
--          installer version and DBVersion stay coupled - every release
--          gets a matching DB version bump, even one like this with no
--          actual schema delta. Jumps straight to 1.61 to match the
--          installer, skipping the unused 1.59/1.60 numbers at the DB level.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.61
GO
