-- =============================================
-- Script: Update DB 1.57 to 1.58
-- Feature: Scheduled Maintenance Mode
--          Lets a maintenance window be queued for a future start time,
--          instead of only "starting now for N minutes".
--          Executive activates the window (same as existing maintenance
--          mode: IsEnabled=0, MaintenanceUntil set) once the scheduled
--          start time arrives.
-- =============================================
set nocount on
GO

-- Add scheduled-maintenance columns to Monitor (nullable datetime UTC / int)
ALTER TABLE [dbo].[Monitor] ADD [ScheduledMaintenanceStart] datetime NULL
GO
ALTER TABLE [dbo].[Monitor] ADD [ScheduledMaintenanceMinutes] int NULL
GO

-- Queue (or cancel) a future maintenance window
-- Pass @StartUtc = NULL to cancel a pending schedule
CREATE PROCEDURE [dbo].[polymon_upd_ScheduleMaintenanceMode]
    @MonitorID int,
    @StartUtc  datetime = NULL,
    @Minutes   int = 0
AS
set nocount on
if @StartUtc IS NULL
    UPDATE Monitor SET ScheduledMaintenanceStart=NULL, ScheduledMaintenanceMinutes=NULL WHERE MonitorID=@MonitorID
else
    UPDATE Monitor SET ScheduledMaintenanceStart=@StartUtc, ScheduledMaintenanceMinutes=@Minutes WHERE MonitorID=@MonitorID
GO

-- Called by Executive each tick: activates any monitor whose scheduled window has arrived
-- Uses the scheduled start time (not "now") for MaintenanceUntil so a delayed tick doesn't
-- shorten the window.
CREATE PROCEDURE [dbo].[polymon_upd_ActivateScheduledMaintenance]
AS
set nocount on
UPDATE Monitor
SET IsEnabled=0,
    MaintenanceUntil=DATEADD(minute, ScheduledMaintenanceMinutes, ScheduledMaintenanceStart),
    ScheduledMaintenanceStart=NULL,
    ScheduledMaintenanceMinutes=NULL
WHERE ScheduledMaintenanceStart IS NOT NULL AND GETUTCDATE() >= ScheduledMaintenanceStart
GO

-- Alter polymon_sel_AllCurrentStatus to include the scheduled-maintenance columns
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
        Monitor.MaintenanceUntil,
        Monitor.ScheduledMaintenanceStart,
        Monitor.ScheduledMaintenanceMinutes
    from Monitor with(NOLOCK)
        left outer join MonitorCurrentStatus MCS with(NOLOCK) on Monitor.MonitorID=MCS.MonitorID
        left outer join MonitorType with(NOLOCK) on Monitor.MonitorTypeID=MonitorType.MonitorTypeID
        left outer join LookupEventStatus with(NOLOCK) on MCS.StatusID=LookupEventStatus.StatusID
    order by Monitor.Name
END
GO

-- Update DB version
update SysSettings set DBVersion = '1.58'
GO
