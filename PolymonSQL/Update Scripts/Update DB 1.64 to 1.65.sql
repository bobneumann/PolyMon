-- =============================================
-- Script: Update DB 1.64 to 1.65
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.65 fixes a real config bug Bob hit on a real install: the
--          Executive service ended up pointed at the placeholder
--          Data Source=.\SQLEXPRESS;Initial Catalog=PolyMon instead of the
--          instance/database actually entered in the installer wizard.
--          Root cause: [Files] had a separate "onlyifdoesntexist" copy of
--          the checked-in placeholder .config, which runs during ssInstall -
--          BEFORE ssPostInstall's WriteConfigIfAbsent. On every fresh
--          install that placeholder landed first, so WriteConfigIfAbsent
--          then found a file already present (the one this same install run
--          had just created) and silently preserved the wrong values instead
--          of writing the real ones. Removed the redundant Inno-level copy;
--          WriteConfigIfAbsent is now the sole source of truth. No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.65
GO
