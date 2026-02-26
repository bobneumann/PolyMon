-- =============================================================
-- Import Production Monitors into Dev Database
-- Source: polymon_restored (upgraded to 1.50)
-- Target: PolyMon (dev, version 1.50)
--
-- All imported monitors are set to IsEnabled=0 (disabled)
-- so the dev executive won't try to poll production servers.
-- Enable individually as needed for testing.
-- =============================================================

USE PolyMon
GO

SET NOCOUNT ON
BEGIN TRANSACTION

BEGIN TRY

-- ---------------------------------------------------------
-- 1. Add missing MonitorType: SQL Overview Monitor (ID 14)
-- ---------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM MonitorType WHERE MonitorTypeID = 14)
BEGIN
    SET IDENTITY_INSERT MonitorType ON
    INSERT INTO MonitorType (MonitorTypeID, Name, MonitorAssembly, EditorAssembly, MonitorXMLTemplate)
    SELECT MonitorTypeID, Name, MonitorAssembly, EditorAssembly, MonitorXMLTemplate
    FROM polymon_restored.dbo.MonitorType
    WHERE MonitorTypeID = 14
    SET IDENTITY_INSERT MonitorType OFF
    PRINT 'Added MonitorType 14: SQL Overview Monitor'
END

-- ---------------------------------------------------------
-- 2. Import Operators (skip any that already exist by ID)
-- ---------------------------------------------------------
SET IDENTITY_INSERT Operator ON

INSERT INTO Operator (OperatorID, Name, IsEnabled, EmailAddress,
    OfflineTimeStart, OfflineTimeEnd, IncludeMessageBody,
    QueuedNotify, SummaryNotify, SummaryNotifyOK, SummaryNotifyWarn,
    SummaryNotifyFail, SummaryNotifyTime, SummaryNextNotifyDT, PushAddress)
SELECT o.OperatorID, o.Name, o.IsEnabled, o.EmailAddress,
    o.OfflineTimeStart, o.OfflineTimeEnd, o.IncludeMessageBody,
    o.QueuedNotify, o.SummaryNotify, o.SummaryNotifyOK, o.SummaryNotifyWarn,
    o.SummaryNotifyFail, o.SummaryNotifyTime, o.SummaryNextNotifyDT, o.PushAddress
FROM polymon_restored.dbo.Operator o
WHERE NOT EXISTS (SELECT 1 FROM PolyMon.dbo.Operator d WHERE d.OperatorID = o.OperatorID)

SET IDENTITY_INSERT Operator OFF
PRINT 'Imported Operators: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows'

-- ---------------------------------------------------------
-- 3. Delete existing dev test monitors (IDs 1-3) and their
--    related data, to avoid conflicts with prod imports
-- ---------------------------------------------------------
DELETE FROM MonitorOperator WHERE MonitorID IN (1, 2, 3)
DELETE FROM MonitorAlertRule WHERE MonitorID IN (1, 2, 3)
DELETE FROM MonitorAction WHERE MonitorID IN (1, 2, 3)
DELETE FROM MonitorCurrentStatus WHERE MonitorID IN (1, 2, 3)
DELETE FROM MonitorEvent WHERE MonitorID IN (1, 2, 3)
DELETE FROM MonitorEventCounter WHERE MonitorID IN (
    SELECT EventID FROM MonitorEvent WHERE MonitorID IN (1, 2, 3)
)
DELETE FROM DashboardGroupMonitorDefault WHERE MonitorID IN (1, 2, 3)
DELETE FROM Monitor WHERE MonitorID IN (1, 2, 3)
PRINT 'Removed existing dev monitors (IDs 1-3)'

-- ---------------------------------------------------------
-- 4. Import all Monitor definitions from prod
--    All set to IsEnabled = 0 (disabled)
-- ---------------------------------------------------------
SET IDENTITY_INSERT Monitor ON

INSERT INTO Monitor (MonitorID, Name, MonitorTypeID, MonitorXML,
    OfflineTime1Start, OfflineTime1End, OfflineTime2Start, OfflineTime2End,
    MessageSubjectTemplate, MessageBodyTemplate, TriggerMod,
    IsEnabled, ExecutiveID, AuditCreateDT, AuditUpdateDT)
SELECT MonitorID, Name, MonitorTypeID, CAST(MonitorXML AS VARCHAR(MAX)),
    OfflineTime1Start, OfflineTime1End, OfflineTime2Start, OfflineTime2End,
    MessageSubjectTemplate, MessageBodyTemplate, TriggerMod,
    0,  -- IsEnabled = disabled
    1,  -- ExecutiveID = local dev executive
    AuditCreateDT, AuditUpdateDT
FROM polymon_restored.dbo.Monitor

SET IDENTITY_INSERT Monitor OFF
PRINT 'Imported Monitors: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows'

-- ---------------------------------------------------------
-- 5. Import MonitorAlertRule (notification settings)
-- ---------------------------------------------------------
INSERT INTO MonitorAlertRule (MonitorID,
    AlertAfterEveryNEvent, AlertAfterEveryNewFailure, AlertAfterEveryNFailures,
    AlertAfterEveryFailToOK, AlertAfterEveryNewWarning, AlertAfterEveryNWarnings,
    AlertAfterEveryWarnToOK)
SELECT MonitorID,
    AlertAfterEveryNEvent, AlertAfterEveryNewFailure, AlertAfterEveryNFailures,
    AlertAfterEveryFailToOK, AlertAfterEveryNewWarning, AlertAfterEveryNWarnings,
    AlertAfterEveryWarnToOK
FROM polymon_restored.dbo.MonitorAlertRule

PRINT 'Imported MonitorAlertRule: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows'

-- ---------------------------------------------------------
-- 6. Import MonitorAction (trigger scripts)
-- ---------------------------------------------------------
INSERT INTO MonitorAction (MonitorID, TriggerTypeID, Script, IsEnabled, ScriptEngineID)
SELECT MonitorID, TriggerTypeID, Script, IsEnabled, ScriptEngineID
FROM polymon_restored.dbo.MonitorAction

PRINT 'Imported MonitorAction: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows'

-- ---------------------------------------------------------
-- 7. Import MonitorOperator (operator-to-monitor assignments)
-- ---------------------------------------------------------
INSERT INTO MonitorOperator (MonitorID, OperatorID)
SELECT MonitorID, OperatorID
FROM polymon_restored.dbo.MonitorOperator

PRINT 'Imported MonitorOperator: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows'

COMMIT TRANSACTION
PRINT ''
PRINT 'Import complete. All monitors imported as DISABLED.'
PRINT 'Enable monitors individually in PolyMon Manager as needed.'

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    PRINT 'ERROR: ' + ERROR_MESSAGE()
    PRINT 'Transaction rolled back. No changes were made.'
END CATCH
GO
