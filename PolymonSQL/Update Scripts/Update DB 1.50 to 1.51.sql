-- =============================================
-- Script: Update DB 1.50 to 1.51
-- Feature: Notes field on SysSettings for push notification config notes
-- =============================================
set nocount on
GO

-- Add Notes column to SysSettings
ALTER TABLE SysSettings ADD Notes varchar(max) NULL
GO

-- Alter polymon_hyb_SaveSysSettings to include Notes parameter
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
@Notes varchar(max) = NULL
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
		Notes=@Notes
end
else
begin
	insert into SysSettings (Name, IsEnabled, ServiceServer, MainTimerInterval, UseInternalSMTP, SMTPFromName, SMTPFromAddress,
				ExtSMTPServer, ExtSMTPPort, ExtSMTPUserID, ExtSMTPPwd, ExtSMTPUseSSL,
				PushService, PushServerURL, PushToken, Notes)
	values(@Name, @IsEnabled, @ServiceServer, @MainTimerInterval, @UseInternalSMTP, @SMTPFromName, @SMTPFromAddress,
				@ExtSMTPServer, @ExtSMTPPort, @ExtSMTPUserID, @ExtSMTPPwd, @ExtSMTPUseSSL,
				@PushService, @PushServerURL, @PushToken, @Notes)
end
GO


--Set Database Version --
update SysSettings
set DBVersion = '1.51'
GO
