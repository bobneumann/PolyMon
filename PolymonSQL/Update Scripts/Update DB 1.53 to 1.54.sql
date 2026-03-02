-- =============================================
-- Script: Update DB 1.53 to 1.54
-- Feature: Maintenance Mode
--          Allows a monitor to be temporarily silenced for N minutes.
--          Sets IsEnabled=0 and stores expiry time in MaintenanceUntil.
--          Executive re-enables automatically when time expires.
-- =============================================
set nocount on
GO

-- Add MaintenanceUntil column to Monitor (nullable datetime UTC)
ALTER TABLE [dbo].[Monitor] ADD [MaintenanceUntil] datetime NULL
GO

-- Set maintenance mode: disable monitor for N minutes
CREATE PROCEDURE [dbo].[polymon_upd_SetMaintenanceMode]
    @MonitorID int,
    @Minutes   int   -- pass 0 to cancel immediately
AS
set nocount on
if @Minutes <= 0
    UPDATE Monitor SET IsEnabled=0, MaintenanceUntil=NULL WHERE MonitorID=@MonitorID
else
    UPDATE Monitor SET IsEnabled=0, MaintenanceUntil=DATEADD(minute, @Minutes, GETUTCDATE()) WHERE MonitorID=@MonitorID
GO

-- Called by Executive each tick: re-enables monitors whose maintenance window has passed
CREATE PROCEDURE [dbo].[polymon_upd_ExpireMaintenanceMode]
AS
set nocount on
UPDATE Monitor SET IsEnabled=1, MaintenanceUntil=NULL
WHERE MaintenanceUntil IS NOT NULL AND GETUTCDATE() >= MaintenanceUntil
GO

-- Alter polymon_sel_AllCurrentStatus to include MaintenanceUntil
ALTER PROCEDURE [dbo].[polymon_sel_AllCurrentStatus]
AS
BEGIN
    SET NOCOUNT ON;
    select Monitor.MonitorID,
        Monitor.Name,
        MonitorType.Name as MonitorType,
        coalesce(MCS.EventDT,getdate()) as EventDT,
        coalesce(MCS.StatusID, 0) as StatusID,
        coalesce(LookupEventStatus.Status, 'Unknown') as Status,
        coalesce(MCS.StatusMessage, 'Unknown') as StatusMessage,
        coalesce(MCS.LifetimePercUptime,0) as LifetimePercUptime,
        Monitor.IsEnabled,
        coalesce(MCS.StatusStartDT, getdate()) as StatusStartDT,
        coalesce(MCS.StatusEndDT, getdate()) as StatusEndDT,
        coalesce(MCS.TimeElapsedSecs,0) as TimeElapsedSecs,
        coalesce(MCS.TimeElapsedTxt,'') as TimeElapsedTxt,
        Monitor.MaintenanceUntil
    from Monitor with(NOLOCK)
        left outer join MonitorCurrentStatus MCS with(NOLOCK) on Monitor.MonitorID=MCS.MonitorID
        left outer join MonitorType with(NOLOCK) on Monitor.MonitorTypeID=MonitorType.MonitorTypeID
        left outer join LookupEventStatus with(NOLOCK) on MCS.StatusID=LookupEventStatus.StatusID
    order by Monitor.Name
END
GO

-- Update DB version
update SysSettings set DBVersion = '1.54'
GO
