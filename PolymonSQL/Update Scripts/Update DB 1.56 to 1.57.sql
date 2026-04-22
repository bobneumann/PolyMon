-- =============================================
-- Script: Update DB 1.56 to 1.57
-- Feature: SQL-based monitor run logging + cycle watchdog
--          MonitorRunLog table records each monitor execution start/end.
--          EndDT IS NULL means the monitor never finished (hung).
--          CycleTimeout = 1 means the full monitor cycle exceeded its deadline.
-- =============================================
set nocount on
GO

CREATE TABLE MonitorRunLog (
    RunID       int IDENTITY(1,1) PRIMARY KEY,
    MonitorID   int NOT NULL,
    MonitorName varchar(255) NOT NULL,
    StartDT     datetime NOT NULL DEFAULT GETDATE(),
    EndDT       datetime NULL,
    CycleTimeout bit NOT NULL DEFAULT 0
)
GO

CREATE PROCEDURE [dbo].[polymon_ins_MonitorRunStart]
    @MonitorID   int,
    @MonitorName varchar(255),
    @RunID       int OUTPUT
AS
set nocount on
INSERT INTO MonitorRunLog (MonitorID, MonitorName, StartDT)
VALUES (@MonitorID, @MonitorName, GETDATE())
SET @RunID = SCOPE_IDENTITY()
GO

CREATE PROCEDURE [dbo].[polymon_upd_MonitorRunEnd]
    @RunID int
AS
set nocount on
UPDATE MonitorRunLog SET EndDT = GETDATE() WHERE RunID = @RunID
GO

CREATE PROCEDURE [dbo].[polymon_ins_MonitorCycleTimeout]
AS
set nocount on
INSERT INTO MonitorRunLog (MonitorID, MonitorName, StartDT, CycleTimeout)
VALUES (0, '[CYCLE TIMEOUT]', GETDATE(), 1)
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.57
GO
