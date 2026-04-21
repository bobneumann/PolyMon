-- =============================================
-- Script: Update DB 1.55 to 1.56
-- Feature: Monitor run logging toggle
--          MonitorRunLog: enable/disable monitor_run.log in executive (default 1 = on)
-- =============================================
set nocount on
GO

ALTER TABLE SysSettings ADD MonitorRunLog bit NOT NULL DEFAULT 1
GO

ALTER PROCEDURE [dbo].[polymon_sel_SysSettings]
AS

set nocount on

select
	Name,
	IsEnabled,
	ServiceServer,
	MainTimerInterval,
	UseInternalSMTP,
	SMTPFromName,
	SMTPFromAddress,
	ExtSMTPServer,
	ExtSMTPPort,
	ExtSMTPUserID,
	ExtSMTPPwd,
	ExtSMTPUseSSL,
	PushService,
	PushServerURL,
	PushToken,
	Notes,
	EmailRelayKey,
	GraphDefaultStatusFreq,
	GraphDefaultUptime,
	MonitorConcurrency,
	MonitorTimeoutPct,
	MonitorRunLog,
	DBVersion,
	RetentionMaxMonthsRaw,
	RetentionMaxMonthsDaily,
	RetentionMaxMonthsWeekly,
	RetentionMaxMonthsMonthly
from SysSettings
GO

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
@PushToken varchar(255) = NULL,
@Notes varchar(max) = NULL,
@EmailRelayKey varchar(255) = NULL,
@GraphDefaultStatusFreq bit = 1,
@GraphDefaultUptime bit = 1,
@MonitorConcurrency int = 10,
@MonitorTimeoutPct int = 80,
@MonitorRunLog bit = 1
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
		PushToken=@PushToken,
		Notes=@Notes,
		EmailRelayKey=@EmailRelayKey,
		GraphDefaultStatusFreq=@GraphDefaultStatusFreq,
		GraphDefaultUptime=@GraphDefaultUptime,
		MonitorConcurrency=@MonitorConcurrency,
		MonitorTimeoutPct=@MonitorTimeoutPct,
		MonitorRunLog=@MonitorRunLog
end
else
begin
	insert into SysSettings (Name, IsEnabled, ServiceServer, MainTimerInterval, UseInternalSMTP, SMTPFromName, SMTPFromAddress,
				ExtSMTPServer, ExtSMTPPort, ExtSMTPUserID, ExtSMTPPwd, ExtSMTPUseSSL,
				PushService, PushServerURL, PushToken, Notes, EmailRelayKey,
				GraphDefaultStatusFreq, GraphDefaultUptime,
				MonitorConcurrency, MonitorTimeoutPct, MonitorRunLog)
	values(@Name, @IsEnabled, @ServiceServer, @MainTimerInterval, @UseInternalSMTP, @SMTPFromName, @SMTPFromAddress,
				@ExtSMTPServer, @ExtSMTPPort, @ExtSMTPUserID, @ExtSMTPPwd, @ExtSMTPUseSSL,
				@PushService, @PushServerURL, @PushToken, @Notes, @EmailRelayKey,
				@GraphDefaultStatusFreq, @GraphDefaultUptime,
				@MonitorConcurrency, @MonitorTimeoutPct, @MonitorRunLog)
end
GO

-- Update DB version
UPDATE SysSettings SET DBVersion = 1.56
GO
