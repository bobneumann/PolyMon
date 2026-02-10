-- =============================================
-- Script Template Update DB 1.30 to 1.40
-- Adds MonitorHistory table, modifies AuditUpdateDT trigger,
-- and creates polymon_RevertMonitor stored procedure.
-- Also migrates Monitor.MonitorXML from deprecated text to
-- varchar(max) so the trigger can access it via deleted/inserted.
-- =============================================
set nocount on
GO

-- Migrate Monitor.MonitorXML from text to varchar(max)
-- (text is deprecated and cannot be read in trigger pseudo-tables)
ALTER TABLE [dbo].[Monitor] ALTER COLUMN [MonitorXML] varchar(max) NOT NULL
GO

-- MonitorHistory table
CREATE TABLE [dbo].[MonitorHistory](
    [HistoryID]     int IDENTITY(1,1) PRIMARY KEY,
    [MonitorID]     int NOT NULL,
    [Name]          varchar(50) NOT NULL,
    [MonitorTypeID] int NOT NULL,
    [MonitorXML]    varchar(max) NOT NULL,
    [SavedAt]       datetime NOT NULL DEFAULT(GETDATE()),
    [RevisionNum]   int NOT NULL DEFAULT(1)
)
GO

CREATE INDEX IX_MonitorHistory_MonitorID ON MonitorHistory(MonitorID, RevisionNum DESC)
GO

-- Modify existing AuditUpdateDT trigger to also capture history
ALTER TRIGGER [dbo].[AuditUpdateDT] ON [dbo].[Monitor]
FOR UPDATE
AS
BEGIN
    -- Original behavior: update audit timestamp
    UPDATE Monitor SET AuditUpdateDT = GETDATE()
    WHERE MonitorID IN (SELECT MonitorID FROM deleted)

    -- New: capture previous state in history
    INSERT INTO MonitorHistory (MonitorID, Name, MonitorTypeID, MonitorXML, RevisionNum)
    SELECT d.MonitorID, d.Name, d.MonitorTypeID, d.MonitorXML,
           ISNULL((SELECT MAX(RevisionNum) FROM MonitorHistory
                   WHERE MonitorID = d.MonitorID), 0) + 1
    FROM deleted d

    -- Prune: keep only last 10 revisions per monitor
    DELETE h FROM MonitorHistory h
    INNER JOIN deleted d ON h.MonitorID = d.MonitorID
    WHERE h.HistoryID NOT IN (
        SELECT TOP 10 HistoryID FROM MonitorHistory
        WHERE MonitorID = d.MonitorID ORDER BY RevisionNum DESC
    )
END
GO

-- Stored procedure for revert
CREATE PROCEDURE [dbo].[polymon_RevertMonitor]
    @MonitorID int,
    @Result int OUTPUT
AS
BEGIN
    SET @Result = -1
    DECLARE @HistoryID int

    SELECT TOP 1 @HistoryID = HistoryID
    FROM MonitorHistory WHERE MonitorID = @MonitorID
    ORDER BY RevisionNum DESC

    IF @HistoryID IS NULL BEGIN
        SET @Result = -2  -- no history available
        RETURN
    END

    UPDATE Monitor
    SET Name = h.Name, MonitorTypeID = h.MonitorTypeID, MonitorXML = h.MonitorXML
    FROM Monitor m INNER JOIN MonitorHistory h ON h.HistoryID = @HistoryID
    WHERE m.MonitorID = @MonitorID

    -- Delete consumed history row (the UPDATE above will fire the
    -- trigger, capturing current state as a new history row)
    DELETE FROM MonitorHistory WHERE HistoryID = @HistoryID
    SET @Result = 0
END
GO


--Set Database Version --
update SysSettings
set DBVersion = '1.40'
GO
