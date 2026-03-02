-- =============================================
-- Script: Update DB 1.54 to 1.55
-- Feature: Parallel monitor execution settings
--          MonitorConcurrency: max monitors running simultaneously (default 10)
--          MonitorTimeoutPct:  monitor timeout as % of main cycle interval (default 80)
-- =============================================
set nocount on
GO

-- Add execution settings columns to SysSettings
ALTER TABLE SysSettings ADD MonitorConcurrency int NOT NULL DEFAULT 10
GO
ALTER TABLE SysSettings ADD MonitorTimeoutPct int NOT NULL DEFAULT 80
GO

-- Alter polymon_sel_SysSettings to include new columns
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
	DBVersion,
	RetentionMaxMonthsRaw,
	RetentionMaxMonthsDaily,
	RetentionMaxMonthsWeekly,
	RetentionMaxMonthsMonthly
from SysSettings
GO

-- Alter polymon_hyb_SaveSysSettings to include new columns
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
@MonitorTimeoutPct int = 80
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
		MonitorTimeoutPct=@MonitorTimeoutPct
end
else
begin
	insert into SysSettings (Name, IsEnabled, ServiceServer, MainTimerInterval, UseInternalSMTP, SMTPFromName, SMTPFromAddress,
				ExtSMTPServer, ExtSMTPPort, ExtSMTPUserID, ExtSMTPPwd, ExtSMTPUseSSL,
				PushService, PushServerURL, PushToken, Notes, EmailRelayKey,
				GraphDefaultStatusFreq, GraphDefaultUptime,
				MonitorConcurrency, MonitorTimeoutPct)
	values(@Name, @IsEnabled, @ServiceServer, @MainTimerInterval, @UseInternalSMTP, @SMTPFromName, @SMTPFromAddress,
				@ExtSMTPServer, @ExtSMTPPort, @ExtSMTPUserID, @ExtSMTPPwd, @ExtSMTPUseSSL,
				@PushService, @PushServerURL, @PushToken, @Notes, @EmailRelayKey,
				@GraphDefaultStatusFreq, @GraphDefaultUptime,
				@MonitorConcurrency, @MonitorTimeoutPct)
end
GO

--Set Database Version --
update SysSettings
set DBVersion = '1.55'
GO
