-- =============================================
-- Script: Update DB 1.40 to 1.50
-- Bug Fix: polymon_ins_EvaluateEventAlertStatus transition detection
-- Feature: Push Notification support (ntfy / Pushover / Telegram)
-- =============================================
set nocount on
GO

-- =============================================
-- BUG FIX: polymon_ins_EvaluateEventAlertStatus
-- The proc was comparing current status against the LAST ALERTED
-- event's status instead of the PREVIOUS event's status.
-- This caused "Notify on failure" to not fire until the SECOND
-- consecutive failure when FailToOK alerts were disabled.
-- =============================================

ALTER PROCEDURE [dbo].[polymon_ins_EvaluateEventAlertStatus]
@CurrentEventID int

AS

/*
===================================================================
Procedure Name: polymon_ins_EvaluateEventAlertStatus
Purpose:  Generates alerts based on alert rules for a specific new event.
Notes:
	StatusIDs:
	0 = NA (never been polled or no prior event)
	1 = OK
	2 = Warning
	3 = Failure

	v1.50: Fixed transition detection to use previous EVENT status
	       instead of last ALERT status. This fixes the bug where
	       "Notify on failure" didn't fire until the second
	       consecutive failure when FailToOK alerts were disabled.
===================================================================
*/
set nocount on
set dateformat ymd

Declare @MonitorID int
Declare @CurrentStatusID tinyint
select @MonitorID=MonitorID, @CurrentStatusID=StatusID
from MonitorEvent
where EventID=@CurrentEventID


--Retrieve Alert rules for this monitor
Declare @EveryNewFailure bit
Declare @EveryFailToOK bit
Declare @EveryNewWarning bit
Declare @EveryWarnToOK bit
Declare @EveryNEvent int
Declare @EveryNFailures int
Declare @EveryNWarnings int

select
	@EveryNewFailure = AlertAfterEveryNewFailure,
	@EveryFailToOK = AlertAfterEveryFailToOK,
	@EveryNewWarning = AlertAfterEveryNewWarning,
	@EveryWarnToOK = AlertAfterEveryWarnToOK,
	@EveryNEvent = AlertAfterEveryNEvent,
	@EveryNFailures = AlertAfterEveryNFailures,
	@EveryNWarnings = AlertAfterEveryNWarnings
from MonitorAlertRule
where MonitorID = @MonitorID


--Determine last Alert EventID (still needed for "Every N" counting)
Declare @LastAlertEventID int
Declare @LastAlertEventDT as datetime

select top 1 @LastAlertEventID=EventID
from MonitorAlert
where MonitorID=@MonitorID
order by EventDT desc

if not(@LastAlertEventID is NULL)
	select @LastAlertEventDT = EventDT
	from MonitorEvent
	where EventID=@LastAlertEventID
else
	set @LastAlertEventDT = cast('1950-01-01' as datetime)

-- NEW: Get previous EVENT's status (correct for transition detection)
Declare @PrevEventStatusID tinyint
select top 1 @PrevEventStatusID = StatusID
from MonitorEvent
where MonitorID = @MonitorID and EventID <> @CurrentEventID
order by EventDT desc

if @PrevEventStatusID is NULL
	set @PrevEventStatusID = 0

Declare @IsAlerted bit
set @IsAlerted=0

--Alert After Every New Failure
if (@IsAlerted=0) and (@CurrentStatusID=3) and (@EveryNewFailure=1) and (@PrevEventStatusID<>3)
begin
	-- Alert New Failure
	print 'New Failure'
	exec polymon_ins_GenerateAlert @CurrentEventID
	set @IsAlerted=1
end

--Alert After Every Fail to OK
if (@IsAlerted=0) and (@CurrentStatusID=1) and (@EveryFailToOK=1) and (@PrevEventStatusID=3)
begin
	-- Alert Fail-->OK
	print 'Fail to OK'
	exec polymon_ins_GenerateAlert @CurrentEventID
	set @IsAlerted=1
end

--Alert After Every New Warning
if (@IsAlerted=0) and (@CurrentStatusID=2) and (@EveryNewWarning=1) and (@PrevEventStatusID<>2)
begin
	-- Alert New Warning
	print 'New Warning'
	exec polymon_ins_GenerateAlert @CurrentEventID
	set @IsAlerted=1
end

--Alert After Every Warn to OK
if (@IsAlerted=0) and (@CurrentStatusID=1) and (@EveryWarnToOK=1) and (@PrevEventStatusID=2)
begin
	-- Alert Warn-->OK
	print 'Warn to OK'
	exec polymon_ins_GenerateAlert @CurrentEventID
	set @IsAlerted=1
end

--Alert After Every N Event
if (@IsAlerted=0) and (@EveryNEvent>0)
begin
	--Count number of events since last alert
	Declare @NumEvents int
	select @NumEvents = count(EventID)
	from MonitorEvent
	where MonitorID=@MonitorID
	and EventID<>@CurrentEventID
	and EventDT > @LastAlertEventDT

	if @NumEvents>=@EveryNEvent
	begin
		-- Alert Every N Event(s)
		print 'Every N Event'
		select @NumEvents, @MonitorID, @CurrentEventID, @LastAlertEventDT
		exec polymon_ins_GenerateAlert @CurrentEventID
		set @IsAlerted=1
	end
end


Declare @RowCount int, @NumNonFails int, @NumNonWarns int
Declare @SQL nvarchar(4000)
create table #Events (EventID int, EventDT datetime, StatusID tinyint)

--Alert After Every N Failures
if (@IsAlerted=0) and (@EveryNFailures>0)
begin
	set @SQL= 'insert into #Events (EventID, EventDT, StatusID) '
		+ 'select top ' + cast(@EveryNFailures as varchar(10)) + ' EventID, EventDT, StatusID ' +
		' from MonitorEvent ' +
		' where MonitorID=' + cast(@MonitorID as varchar(10)) + ' ' +
		' and EventDT > ''' +  convert(varchar(50), @LastAlertEventDT,121) + ''' ' +
		' order by EventDT desc'

	execute sp_executesql @SQL
	print @SQL


	select @RowCount=count(*) from #Events
	select @NumNonFails = count(*)
	from #Events
	where StatusID <> 3

	select @RowCount, @NumNonFails, @MonitorID, @CurrentEventID, @LastAlertEventDT

	if (@RowCount>=@EveryNFailures) and (@NumNonFails=0)
	begin
		-- Alert after every N Fails
		print 'Every N Fail'
		exec polymon_ins_GenerateAlert @CurrentEventID
		set @IsAlerted=1
	end
end


--Alert After Every N Warnings
if (@IsAlerted=0) and (@EveryNWarnings>0)
begin
	set @SQL= 'insert into #Events (EventID, EventDT, StatusID) '
		+ 'select top ' + cast(@EveryNWarnings as varchar(10)) + ' EventID, EventDT, StatusID ' +
		' from MonitorEvent ' +
		' where MonitorID=' + cast(@MonitorID as varchar(10)) + ' ' +
		' and EventDT > ''' + convert(varchar(50), @LastAlertEventDT,121) + ''' ' +
		' order by EventDT desc'

	execute sp_executesql @SQL
	select @RowCount=count(*) from #Events
	select @NumNonFails = count(*)
	from #Events
	where StatusID <> 2

	if (@RowCount>=@EveryNFailures) and (@NumNonFails=0)
	begin
		-- Alert after every N Warnings
		print 'Every N Warning'
		exec polymon_ins_GenerateAlert @CurrentEventID
		set @IsAlerted=1
	end
end

drop table #Events
GO


-- =============================================
-- PUSH NOTIFICATION SUPPORT
-- =============================================

-- Add push notification columns to SysSettings
ALTER TABLE SysSettings ADD PushService varchar(20) NULL
GO
ALTER TABLE SysSettings ADD PushServerURL varchar(255) NULL
GO
ALTER TABLE SysSettings ADD PushToken varchar(255) NULL
GO

-- Add push address column to Operator
ALTER TABLE Operator ADD PushAddress varchar(255) NULL
GO


-- Alter polymon_hyb_SaveSysSettings to include push notification parameters
ALTER PROCEDURE [dbo].[polymon_hyb_SaveSysSettings]
@Name varchar(50),
@IsEnabled bit,
@ServiceServer varchar(255),
@MainTimerInterval int,
@UseInternalSMTP bit,
@SMTPFromName varchar(50),
@SMTPFromAddress varchar(255),
@ExtSMTPServer varchar(255) = NULL,
@ExtSMTPPort int = NULL,
@ExtSMTPUserID varchar(50) = NULL,
@ExtSMTPPwd varchar(50) = NULL,
@ExtSMTPUseSSL bit = NULL,
@PushService varchar(20) = NULL,
@PushServerURL varchar(255) = NULL,
@PushToken varchar(255) = NULL
AS

set nocount on

if exists(select * from SysSettings)
begin
	update SysSettings
	set Name=@Name,
		IsEnabled=@IsEnabled,
		ServiceServer=@ServiceServer,
		MainTimerInterval=@MainTimerInterval,
		UseInternalSMTP=@UseInternalSMTP,
		SMTPFromName=@SMTPFromName,
		SMTPFromAddress=@SMTPFromAddress,
		ExtSMTPServer=@ExtSMTPServer,
		ExtSMTPPort=@ExtSMTPPort,
		ExtSMTPUserID=@ExtSMTPUserID,
		ExtSMTPPwd=@ExtSMTPPwd,
		ExtSMTPUseSSL=@ExtSMTPUseSSL,
		PushService=@PushService,
		PushServerURL=@PushServerURL,
		PushToken=@PushToken
end
else
begin
	insert into SysSettings (IsEnabled, ServiceServer, MainTimerInterval, UseInternalSMTP, SMTPFromName, SMTPFromAddress,
				ExtSMTPServer, ExtSMTPPort, ExtSMTPUserID, ExtSMTPPwd, ExtSMTPUseSSL,
				PushService, PushServerURL, PushToken)
	values(@IsEnabled, @ServiceServer, @MainTimerInterval, @UseInternalSMTP, @SMTPFromName, @SMTPFromAddress,
				@ExtSMTPServer, @ExtSMTPPort, @ExtSMTPUserID, @ExtSMTPPwd, @ExtSMTPUseSSL,
				@PushService, @PushServerURL, @PushToken)
end
GO


-- Allow NULL email addresses (operators may use push-only)
ALTER TABLE [dbo].[Operator] ALTER COLUMN [EmailAddress] varchar(255) NULL
GO

-- Alter polymon_hyb_SaveOperator to include PushAddress parameter
ALTER PROCEDURE [dbo].[polymon_hyb_SaveOperator]
@OperatorID int output,
@Name nvarchar(255),
@IsEnabled bit,
@EmailAddress varchar(255),
@OfflineTimeStart char(5),
@OfflineTimeEnd char(5),
@IncludeMessageBody bit,
@QueuedNotify tinyint,
@SummaryNotify tinyint,
@SummaryNotifyOK bit,
@SummaryNotifyWarn bit,
@SummaryNotifyFail bit,
@SummaryNotifyTime char(5),
@PushAddress varchar(255) = NULL
AS

set nocount on

---If SummaryNotify has been set determine when next notification date time should be
Declare @NextDT datetime
Declare @NotifyTime int
Declare @CurrTime int

set dateformat ymd

set @NotifyTime =cast(replace(coalesce(@SummaryNotifyTime, '00:00'), ':', '') as int)
set @CurrTime =  cast(replace(convert(varchar(5), getdate(), 8), ':', '') as integer)

if @NotifyTime <= @CurrTime
	set @NextDT = cast(convert(varchar(10), dateadd(dd, 1, getdate()), 101) + ' ' + @SummaryNotifyTime as datetime)
else
	set @NextDT = cast(convert(varchar(10), getdate(), 101) + ' ' + @SummaryNotifyTime as datetime)


if @OperatorID is NULL
begin
	--Create new Operator Record
	insert into Operator (Name, IsEnabled, EmailAddress, OfflineTimeStart, OfflineTimeEnd, IncludeMessageBody, QueuedNotify, SummaryNotify, SummaryNotifyOK, SummaryNotifyWarn, SummaryNotifyFail, SummaryNotifyTime, SummaryNextNotifyDT, PushAddress)
	values (@Name, @IsEnabled, @EmailAddress, @OfflineTimeStart, @OfflineTimeEnd, @IncludeMessageBody, @QueuedNotify, @SummaryNotify, @SummaryNotifyOK, @SummaryNotifyWarn, @SummaryNotifyFail, @SummaryNotifyTime, @NextDT, @PushAddress)

	set @OperatorID=@@IDENTITY
end
else
begin
	--Update existing Operator Record
	if not(exists(select * from Operator where OperatorID=@OperatorID))
	begin
		--Invalid OperatorID
		raiserror('Specified OperatorID does not exist. Action aborted.', 16, 1)
	end
	else
	begin
		--Valid OperatorID
		update Operator
		set Name=@Name,
			IsEnabled=@IsEnabled,
			EmailAddress=@EmailAddress,
			OfflineTimeStart=@OfflineTimeStart,
			OfflineTimeEnd=@OfflineTimeEnd,
			IncludeMessageBody=@IncludeMessageBody,
			QueuedNotify=@QueuedNotify,
			SummaryNotify=@SummaryNotify,
			SummaryNotifyOK=@SummaryNotifyOK,
			SummaryNotifyWarn=@SummaryNotifyWarn,
			SummaryNotifyFail=@SummaryNotifyFail,
			SummaryNotifyTime=@SummaryNotifyTime,
			SummaryNextNotifyDT=@NextDT,
			PushAddress=@PushAddress
		where OperatorID=@OperatorID
	end
end
GO


-- Alter polymon_sel_PendingEmailAlerts to include PushAddress
ALTER PROCEDURE [dbo].[polymon_sel_PendingEmailAlerts]
@MaxCount int = 100
AS
BEGIN
	SET NOCOUNT ON;

SET ROWCOUNT @MaxCount

	select MonitorAlert.AlertID,
		Operator.OperatorID,
		Operator.Name,
		Operator.EmailAddress,
		Operator.IncludeMessageBody,
		Operator.PushAddress,
		MonitorAlert.MessageSubject,
		MonitorAlert.MessageBody
	from MonitorAlert with(NOLOCK)
		inner join OperatorAlert with(NOLOCK) on MonitorAlert.AlertID=OperatorAlert.AlertID
		inner join Operator with(NOLOCK) on OperatorAlert.OperatorID=Operator.OperatorID
	where OperatorAlert.IsSent=0
		and Operator.IsEnabled=1
		and OperatorAlert.IsQueued=0
	order by MonitorAlert.EventDT

SET ROWCOUNT 0
END
GO


-- Alter polymon_sel_QueuedEmailAlerts to include PushAddress
ALTER PROCEDURE [dbo].[polymon_sel_QueuedEmailAlerts]
@MaxCount int = 100
AS
BEGIN
	SET NOCOUNT ON;

SET ROWCOUNT @MaxCount

	select MonitorAlert.AlertID,
		Operator.OperatorID,
		Operator.Name,
		Operator.EmailAddress,
		Operator.IncludeMessageBody,
		Operator.PushAddress,
		MonitorAlert.MessageSubject,
		MonitorAlert.MessageBody
	from MonitorAlert with(NOLOCK)
		inner join OperatorAlert with(NOLOCK) on MonitorAlert.AlertID=OperatorAlert.AlertID
		inner join Operator with(NOLOCK) on OperatorAlert.OperatorID=Operator.OperatorID
	where OperatorAlert.IsSent=0
		and OperatorAlert.IsQueued=1
		and Operator.IsEnabled=1
		and Operator.QueuedNotify=1
		and dbo.fn_IsOfflineTime(Operator.OfflineTimeStart, Operator.OfflineTimeEnd, getdate())=0
	order by MonitorAlert.EventDT

SET ROWCOUNT 0
END
GO


--Set Database Version --
update SysSettings
set DBVersion = '1.50'
GO
