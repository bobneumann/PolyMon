-- =============================================
-- Script: Update DB 1.66 to 1.67
-- Feature: NONE - pure version-number alignment, no schema change.
--          v1.67 fixes a real destructive bug Bob hit: ssInstall
--          unconditionally stops+deletes any existing PolyMon Executive
--          service to free its file locks before copying new binaries, but
--          ssPostInstall only reinstalled it if the Tasks checkbox was
--          checked - so an upgrade on a machine that already had Executive
--          running, with the box left unchecked (its default state), tore
--          the service down with no restore. Now an existing service is
--          always preserved across an upgrade regardless of checkbox/
--          /MANAGERONLY state; those only gate ADDING Executive to a
--          machine that didn't already have it. No DDL here.
-- =============================================
set nocount on
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.67
GO
