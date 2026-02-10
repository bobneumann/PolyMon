<#
.SYNOPSIS
   Checks the most common statuses of SQL server health:  Backups, integrity checks, drive and database freespace
.DESCRIPTION
   Hostname is the only required parameter
      .PARAMETER HostName
            Enter the hostname
      .PARAMETER Instance_Name
            Enter the instance name if not default
      .PARAMETER check_sql_version_yes_or_no
            Do you wish to monitor/report the SQL Server Version?
    .PARAMETER sql_version_warn_or_fail
            If the version is too low, Do you wish to report it as a "Warning" or a "Failure"?
      .PARAMETER check_full_daily_backup_yes_or_no
            Do you wish to monitor/report the state of SQL Agent full daily backup jobs?
    .PARAMETER daily_backup_job_name
            Enter the name of the SQL Agent Job that runs Full daily backups.  (wildcards ok *backup*)
    .PARAMETER full_daily_backup_warn_or_fail
            If a full daily backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER full_daily_backup_interval_DAYS
            What is the maximum number of days SINCE the last successful full daily backup job?
      .PARAMETER check_full_weekly_backup_yes_or_no
            Do you wish to monitor/report the state of SQL Agent full weekly backup jobs?
    .PARAMETER weekly_backup_job_name
            Enter the name of the SQL Agent Job that runs Full weekly backups.  (wildcards ok *backup*)
    .PARAMETER full_weekly_backup_warn_or_fail
            If a full weekly backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER full_weekly_backup_interval_DAYS
            What is the maximum number of days SINCE the last successful full weekly backup job?      
      .PARAMETER check_translog_backup_yes_or_no
            Do you wish to monitor/report the state of SQL Agent Transaction Log backup jobs?
    .PARAMETER translog_job_name
            Enter the name of the SQL Agent Job that runs transaction log backups.  (wildcards ok *translog*)
    .PARAMETER translog_backup_warn_or_fail
            If a Transaction Log Backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER translog_interval_MINUTES
            What is the maximum number of minutes SINCE the last successful Transaction Log backup job?
      .PARAMETER Check_integrity_jobs_yes_or_no
            Do you wish to monitor/report the state of SQL Agent integritying jobs?
    .PARAMETER integrity_job_name
            Enter the name of the SQL Agent Job that runs integrity checks.  (wildcards ok *integrity*)
    .PARAMETER integrity_jobs_warn_or_fail
            If an integritying job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER integrity_jobs_interval_DAYS
            What is the maximum number of days SINCE the last successful SQL Agent integritying job?
      .PARAMETER check_logfile_ratio_yes_or_no
            Do you wish to monitor/report the state of database logfile sizes?
    .PARAMETER logfile_ratio_warn_or_fail
            If a database logfile size discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER logfile_ratio_alert_PCT
            What is the minimum logfile to database size ratio to indicate a discrepancy?
      .PARAMETER check_for_dbs_on_c_drive
            Do you wish to monitor/report the existence of databases on C: drive?
      .PARAMETER check_db_freespace_yes_or_no
            Do you wish to monitor/report the state of free space within db datafiles?
    .PARAMETER db_freespace_warning_PCT
            What is the minimum db datafile freespace percentage to trigger a "Warning"?
    .PARAMETER db_freespace_failure_PCT
            What is the minimum db datafile freespace percentage to trigger a "Failure"?
      .PARAMETER check_db_recoverymodel_yes_or_no
            Do you wish to monitor/report the state of free space within db datafiles?
      .PARAMETER db_recoverymodel_warn_or_fail
            If a database Recovery Model discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
      .PARAMETER Approved_Simple_dbs                
            Enter the list of databases that are known to have the "Simple" recovery model in this format: -Approved_Simple_dbs "db1","db2","db3"
      .PARAMETER check_hd_freespace_yes_or_no
            Do you wish to monitor/report the state of hard drive free space on the SQL server?
    .PARAMETER hd_freespace_warning_PCT
            What is the minimum hard drive freespace percentage to trigger a "Warning"?
    .PARAMETER hd_freespace_failure_PCT
            What is the minimum hard drive freespace percentage to trigger a "Failure"?
      .PARAMETER check_exhaustive_backup_yes_or_no
            Do you wish to exhaustively check all databases and confirm that each has been recently backed up?
    .PARAMETER exhaustive_backup_warn_or_fail
            If an exhaustive backup discrepancy is found, Do you wish to report it as a "Warning" or a "Failure"?
    .PARAMETER exhaustive_backup_interval_DAYS
            What is the maximum number of days SINCE the last backup?
    .PARAMETER exhaustive_backup_check_ignore
            Enter the names of any databases to be ignored for exhaustive backup checks in this format: -exhaustive_backup_check_ignore "db1","db2","db3"
    .PARAMETER check_for_db_usercount
            Do you wish to record a counter for total count of SQL user connections?
      .PARAMETER check_for_Full_backup_duration
            Do you wish to record the duration (in minutes) of the last UserDB Full Backup Job?
      .PARAMETER displayverbose
            What level of messages/counters do you wish to display? (0 = no counters, 1 = counters only, 2= counters and full messages)
.EXAMPLE
   <An example of using the script>
#>
###############################
##  SQL Overview Monitor - Revision 1.00 ##
###############################
function SQL_Overview{
   
    param([Parameter(Mandatory=$true)][string] $HostName,
          [Parameter()][string] $Instance_Name = "default",
          [Parameter()][string] $check_sql_version_yes_or_no = "no",
              [Parameter()][string] $sql_version_warn_or_fail = "Warn",
              [Parameter()][string] $check_full_daily_backup_yes_or_no = "Yes", #               Do you wish to monitor/report the state of SQL Agent full daily backup jobs?
              [Parameter()][string] $daily_backup_job_name = "DBA Daily Full Backup*",#                          Enter the name of the SQL Agent Job that runs Full daily backups.  (wildcards ok *backup*)
          [Parameter()][string] $full_daily_backup_warn_or_fail = "Warn", #                    If a full daily backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
          [Parameter()][int] $full_daily_backup_interval_DAYS = 1,  #                    What is the maximum number of days SINCE the last successful full daily backup job?
              [Parameter()][string] $check_full_weekly_backup_yes_or_no = "No" ,#         Do you wish to monitor/report the state of SQL Agent full weekly backup jobs?
              [Parameter()][string] $weekly_backup_job_name = "XXX*",#       Enter the name of the SQL Agent Job that runs Full weekly backups.  (wildcards ok *backup*)
          [Parameter()][string] $full_weekly_backup_warn_or_fail = "Warn" ,#                   If a full weekly backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
          [Parameter()][int] $full_weekly_backup_interval_DAYS = 7 , #                   What is the maximum number of days SINCE the last successful full weekly backup job? 
              [Parameter()][string] $check_translog_backup_yes_or_no = "no", #                  Do you wish to monitor/report the state of SQL Agent Transaction Log backup jobs?
              [Parameter()][string] $translog_job_name = "BackupUser.Logs*",#                  Enter the name of the SQL Agent Job that runs transaction log backups.  (wildcards ok *translog*)
              [Parameter()][string] $translog_backup_warn_or_fail = "Warn" ,#                        If a Transaction Log Backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
          [Parameter()][int] $translog_interval_MINUTES = 242, #                         What is the maximum number of minutes SINCE the last successful Transaction Log backup job?
          [Parameter()][string] $Check_integrity_jobs_yes_or_no = "Yes", #                Do you wish to monitor/report the state of SQL Agent integritying jobs?
              [Parameter()][string] $integrity_job_name = "DBA Integrity*",#                   Enter the name of the SQL Agent Job that runs integrity checks.  (wildcards ok *integrity*)
              [Parameter()][string] $integrity_jobs_warn_or_fail = "Warn" ,#                   If an integritying job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
          [Parameter()][int] $integrity_jobs_interval_DAYS = 14 , #                      What is the maximum number of days SINCE the last successful SQL Agent integritying job?
          [Parameter()][string] $check_logfile_ratio_yes_or_no = "Yes", #                 Do you wish to monitor/report the state of database logfile sizes?
              [Parameter()][string] $logfile_ratio_warn_or_fail = "Warn", #                    If a database logfile size discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
              [Parameter()][int] $logfile_ratio_alert_PCT = 50 ,#                        What is the minimum logfile to database size ratio to indicate a discrepancy?
              [Parameter()][string] $check_for_dbs_on_c_drive = "No" ,#                         Do you wish to monitor/report the existence of databases on C: drive?
          [Parameter()][string] $check_db_freespace_yes_or_no = "No" ,#                   Do you wish to monitor/report the state of free space within db datafiles?
          [Parameter()][int] $db_freespace_warning_PCT = 10 ,#                           What is the minimum db datafile freespace percentage to trigger a "Warning"?
              [Parameter()][int] $db_freespace_failure_PCT = 5 ,#                        What is the minimum db datafile freespace percentage to trigger a "Failure"?
          [Parameter()][string] $check_db_recoverymodel_yes_or_no = "No" ,#               Do you wish to monitor/report the state of the Recovery Model within db datafiles?          
              [Parameter()][string] $check_db_recoverymodel_warn_or_fail = "Warn", #      If a database Recovery Model discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
          [Parameter()][string[]] $Approved_Simple_dbs = @("xxx","x") , #                Enter the list of databases that are known to have the "Simple" recovery model in this format: $Approved_Simple_dbs ="db1","db2","db3"
              [Parameter()][string] $check_hd_freespace_yes_or_no = "Yes" ,#              Do you wish to monitor/report the state of hard drive free space on the SQL server?
          [Parameter()][int] $hd_freespace_warning_PCT = 10 ,#                           What is the minimum hard drive freespace percentage to trigger a "Warning"?
          [Parameter()][int] $hd_freespace_failure_PCT = 5 ,#                            What is the minimum hard drive freespace percentage to trigger a "Failure"?
              [Parameter()][string] $check_exhaustive_backup_yes_or_no = "yes",#                Do you wish to exhaustively check all databases and confirm that each has been recently backed up?
              [Parameter()][string] $exhaustive_backup_warn_or_fail = "Warn",#                       If an exhaustive backup discrepancy is found, Do you wish to report it as a "Warning" or a "Failure"?
              [Parameter()][int] $exhaustive_backup_interval_DAYS = 30,#                       What is the maximum number of days SINCE the last backup?
          [Parameter()][string] $exhaustive_backup_check_ignore = "xxx",#                      Enter the names of any databases to be ignored for exhaustive backup checks in this format: $exhaustive_backup_check_ignore ="db1","db2","db3"
          [Parameter()][string] $check_for_db_usercount = "Yes",#                  Do you wish to record a counter for total count of SQL user connections?
              [Parameter()][string] $check_for_Full_backup_duration = "Yes",#              Do you wish to record the duration (in minutes) of the last UserDB Full Backup Job?
              [Parameter()][int] $displayverbose = 0 #
         )


# $HostName = "phcma203" ; #                    Enter the hostname
# $Instance_Name = "default" ;#                       Enter the instance name if not default

# $check_sql_version_yes_or_no = "No" ;#              Do you wish to monitor/report the SQL Server Version?
    # $sql_version_warn_or_fail = "Warn" ;#                      If the version is too low, Do you wish to report it as a "Warning" or a "Failure"?
      
# $check_full_daily_backup_yes_or_no = "Yes" ;#                   Do you wish to monitor/report the state of SQL Agent full daily backup jobs?
    # $daily_backup_job_name = "DBA Daily Full Backup*";#                          Enter the name of the SQL Agent Job that runs Full daily backups.  (wildcards ok *backup*)
    # $full_daily_backup_warn_or_fail = "Warn" ;#                      If a full daily backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    # $full_daily_backup_interval_DAYS = 1 ; #                   What is the maximum number of days SINCE the last successful full daily backup job?
      
# $check_full_weekly_backup_yes_or_no = "No" ;#             Do you wish to monitor/report the state of SQL Agent full weekly backup jobs?
    # $weekly_backup_job_name = "DBA Weekly Full Backup*";#      Enter the name of the SQL Agent Job that runs Full weekly backups.  (wildcards ok *backup*)
    # $full_weekly_backup_warn_or_fail = "Warn" ;#                     If a full weekly backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    # $full_weekly_backup_interval_DAYS = 7 ; #                  What is the maximum number of days SINCE the last successful full weekly backup job? 
      
# $check_translog_backup_yes_or_no = "yes" ;#               Do you wish to monitor/report the state of SQL Agent Transaction Log backup jobs?
    # $translog_job_name = "BackupUser.Logs*";#                  Enter the name of the SQL Agent Job that runs transaction log backups.  (wildcards ok *translog*)
    # $translog_backup_warn_or_fail = "Warn" ;#                        If a Transaction Log Backup job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    # $translog_interval_MINUTES = 242 ;#                        What is the maximum number of minutes SINCE the last successful Transaction Log backup job?
      
# $Check_integrity_jobs_yes_or_no = "Yes" ;#                Do you wish to monitor/report the state of SQL Agent integritying jobs?
    # $integrity_job_name = "Integrity*";#                       Enter the name of the SQL Agent Job that runs integrity checks.  (wildcards ok *integrity*)
    # $integrity_jobs_warn_or_fail = "Warn" ;#                   If an integritying job discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    # $integrity_jobs_interval_DAYS = 60 ; #                     What is the maximum number of days SINCE the last successful SQL Agent integritying job?
      
# $check_logfile_ratio_yes_or_no = "No" ;#                  Do you wish to monitor/report the state of database logfile sizes?
    # $logfile_ratio_warn_or_fail = "Warn" ;#                    If a database logfile size discrepancy if found, Do you wish to report it as a "Warning" or a "Failure"?
    # $logfile_ratio_alert_PCT = 50 ;#                           What is the minimum logfile to database size ratio to indicate a discrepancy?
      
# $check_for_dbs_on_c_drive = "No" ;#                       Do you wish to monitor/report the existence of databases on C: drive?

# $check_db_freespace_yes_or_no = "No" ;#                   Do you wish to monitor/report the state of free space within db datafiles?
    # $db_freespace_warning_PCT = 8 ;#                           What is the minimum db datafile freespace percentage to trigger a "Warning"?
    # $db_freespace_failure_PCT = 2 ;#                           What is the minimum db datafile freespace percentage to trigger a "Failure"?
      
# $check_hd_freespace_yes_or_no = "Yes" ;#                  Do you wish to monitor/report the state of hard drive free space on the SQL server?
    # $hd_freespace_warning_PCT = 11 ;#                          What is the minimum hard drive freespace percentage to trigger a "Warning"?
    # $hd_freespace_failure_PCT = 2 ;#                           What is the minimum hard drive freespace percentage to trigger a "Failure"?
      
# $check_exhaustive_backup_yes_or_no = "yes";#              Do you wish to exhaustively check all databases and confirm that each has been recently backed up?
    # $exhaustive_backup_warn_or_fail = "Warn";#                       If an exhaustive backup discrepancy is found, Do you wish to report it as a "Warning" or a "Failure"?
    # $exhaustive_backup_interval_DAYS = 30; #                   What is the maximum number of days SINCE the last backup?
    # $exhaustive_backup_check_ignore ="xxx";#                   Enter the names of any databases to be ignored for exhaustive backup checks in this format: $exhaustive_backup_check_ignore ="db1","db2","db3"
   
# $check_for_db_usercount = "Yes";#                  Do you wish to record a counter for total count of SQL user connections?
# $check_for_Full_backup_duration = "Yes";#                  Do you wish to record the duration (in minutes) of the last UserDB Full Backup Job?

##############################################
# Establish General Variables
##############################################
if($Counters){[DOUBLE]$polymon = 1;$Status.StatusText = ""} else {[DOUBLE]$polymon = 0}
#$displayverbose = 0

$errlvl="OK"
if ($polymon -eq 1) {$Status.StatusText = ""}
if ($Instance_Name -eq "default")
      {$instance = "$HostName"}
else
      {$instance = "$HostName\$Instance_Name"}
$instance = $instance.toupper()
$sysdbs = "master","model","msdb","tempdb","northwind"
$sqlversion = ""
$SQL_2005_min_build_nbr = 4912
$SQL_2008_R2_min_build_nbr = 2418
$SQL_2008_min_build_nbr = 5500
$min_versions = "8.00.4035","9.00.4035","10.0.4064.0"
$full_daily_backupdisplaytext = ", Full Daily Backups OK"
$full_weekly_backupdisplaytext = ", Full Weekly Backups OK"
$transbackupdisplaytext = ", Trans Logs OK"
$integrityjobdisplaytext = ", Integrity Checks OK"
$exhaustive_backupdisplaytext = ", No Un-Backed-Up Databases"
$dblowfreespacedisplaytext = ""
$dbhighlogratiodisplaytext = ""
$dbcdrivedisplaytext = ""
$dbdrivefreedisplaytext = ""
$counter = @()
$counter += ,@('Declare', 0)
$totalconnectedusers = 0
$fullbuduration = 0
$usercountdisplaytext = ""
$fullbudisplaytext = ""
if ($check_translog_backup_yes_or_no -eq "Yes"){$check_db_recoverymodel_yes_or_no = "Yes"}


[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
# Create an SMO connection to the instance
$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance
$dbs = $s.Databases


##############################################
## Discover SQL Job Information
##############################################
$jobsserver = $s.JobServer
$jobs = $jobsserver.Jobs
$fulldailybackupjobexist = 0
$fullweeklybackupjobexist = 0
$full_daily_backupstatus = 0
$exhaustive_backupstatus = 0
$full_weekly_backupstatus = 0
$translogjobexist = 0
$translogjobstatus = 0
$integrityjobexist = 0
$integrityjobstatus = 0
$check_full_daily_backup_target_time = [datetime]::Now.AddDays(-$full_daily_backup_interval_DAYS)
$check_full_weekly_backup_target_time = [datetime]::Now.AddDays(-$full_weekly_backup_interval_DAYS)
$trans_log_target_time = [datetime]::Now.AddMinutes(-$translog_interval_MINUTES)
$Integrity_target_time = [datetime]::Now.AddDays(-$integrity_jobs_interval_DAYS)
$exhaustive_backup_interval_DAYS_target_time = [datetime]::Now.AddDays(-$exhaustive_backup_interval_DAYS)
$exhaustive_backup_new_db_target_time = [datetime]::Now.AddDays(-2)
$exhaustivebackupexceptions = @()
$fulldailybackupJobs = @()
$fullweeklybackupJobs = @()
$translogJobs = @()
$integrityJobs = @()

# Function to turn the Duration from EnumHistory() bigint into useable time value
Function Convert-Duration {
      param ([int]$sec)
      if ($sec -gt 9999) {$hh = [int][Math]::Truncate($sec/10000); $sec = $sec - ($hh*10000)}
            else {$hh = 0}
      if ($sec -gt 99) {$mm = [int][Math]::Truncate($sec/100); $sec = $sec - ($mm*100)}
            else {$mm = 0}
      $dur = ([double]("{0:D2}" -f $hh)*60)+[double]("{0:D2}" -f $mm)+[math]::Round([double](("{0:D2}" -f $sec)/60), 2)
   if ([double]("{0:D2}" -f $mm) -ge 1){$dur = [math]::Round($dur,0)}
    $dur
      }



foreach ($job in $jobs)
{
      if (($job.name -like $daily_backup_job_name) -and ($job.name -notlike $translog_job_name)-and ($job.name -notlike $weekly_backup_job_name))
      {
                                 $fulldailybackupjobexist = 1           
                                if ($job.CurrentRunStatus -ne "Executing"){
            if (($job.LastRunOutcome -ne "Succeeded") -or ($job.LastRunDate -lt $check_full_daily_backup_target_time))
            {
                  $full_daily_backupstatus += 1
            }
            $fulldailybackupjobs += """"+$job.name+""" "+$job.LastRunOutcome+" on "+$job.LastRunDate+" "
#find duration of last UserDB full backup
 foreach($entry in $job.EnumHistory())
    { if ($entry[9] -eq $job.LastRunDate -and $entry[4] -eq '(Job outcome)'-and $entry[7] -eq $job.name -and $entry[7] -match "User")
    {

   # $jobduration = Convert-Duration ($entry[10])
                                                          $fullbudurationlabel = ($entry[7]+' job duration (minutes)')
                                                          $fullbuduration = [DOUBLE](Convert-Duration ($entry[10]))
 #   $Counter += ,@(($entry[7]+' job duration (minutes)'), [DOUBLE]$jobduration)
#if ($check_for_Full_backup_duration -eq "Yes") {$fullbudisplaytext = ", "+[string]$fullbuduration+" minutes for UserDBs full backup "} else {$fullbudisplaytext = "" };$Counter += ,@($fullbudurationlabel,$fullbuduration)
    }}


      }}
      if (($job.name -like $weekly_backup_job_name) -and ($job.name -notlike $translog_job_name)-and ($job.name -notlike $daily_backup_job_name))
      {
            $fullweeklybackupjobexist = 1
            if ($job.CurrentRunStatus -ne "Executing"){
            if (($job.LastRunOutcome -ne "Succeeded") -or ($job.LastRunDate -lt $check_full_weekly_backup_target_time))
            {
                  $full_weekly_backupstatus += 1
            }
            $fullweeklybackupjobs += """"+$job.name+""" "+$job.LastRunOutcome+" on "+$job.LastRunDate+" "
      }}
if ($job.name -like $translog_job_name)
      {     $translogjobexist = 1
            if ($job.CurrentRunStatus -ne "Executing"){
        if (($job.LastRunOutcome -ne "Succeeded") -or ($job.LastRunDate -lt $trans_log_target_time))
                  {$translogjobstatus += 1}
            $translogJobs += """"+$job.name+""" "+$job.LastRunOutcome+" on "+$job.LastRunDate+" "
            }}
      
if ($job.name -like $integrity_job_name)
      {     $integrityjobexist = 1
    if ($job.CurrentRunStatus -ne "Executing"){
            if (($job.LastRunOutcome -ne "Succeeded") -or ($job.LastRunDate -lt $Integrity_target_time))
                  {$integrityjobstatus += 1}
            $integrityJobs += """"+$job.name+""" "+$job.LastRunOutcome+" on "+$job.LastRunDate+" "
            }}
}
##############################################
## Are Full Daily Backups Running/Up to date?
##############################################
if ($check_full_daily_backup_yes_or_no -eq "Yes")
      {     if (($fulldailybackupjobexist -ne 1) -or ($full_daily_backupstatus -ne 0))
                  {     If ($fulldailybackupjobexist -ne 1)
                              {$full_daily_backupdisplaytext = ", Full Daily Backups Job not Found (search value = "+$daily_backup_job_name+". (Use the -daily_backup_job_name parameter to specify a different job name) " ; $Counter += ,@('Full Daily Backups Job not Found', 1) }
                        else
                              {$full_daily_backupdisplaytext = ", Full Daily Backups Failed or Out of Date: " +$fulldailybackupjobs ;     $Counter += ,@('Full Daily Backups Failed or Out of Date', 1)}
                        if ($errlvl -ne "fail"){$errlvl = $full_daily_backup_warn_or_fail}      }
            else
                  {     If ($displayverbose -eq 1)    {$full_daily_backupdisplaytext = "Full Daily Backups OK: "+$fulldailybackupjobs ; $Counter += ,@('Full Daily Backups OK',1)}  }     }
      else {$full_daily_backupdisplaytext = ""}
      

##############################################
## Are Full Weekly Backups Running/Up to date?
##############################################
if ($check_full_weekly_backup_yes_or_no -eq "Yes")
      {     if (($fullweeklybackupjobexist -ne 1) -or ($full_weekly_backupstatus -ne 0))
                  {     If ($fullweeklybackupjobexist -ne 1)
                              {$full_weekly_backupdisplaytext = ", Full Weekly Backups Job not Found (search value = "+$weekly_backup_job_name+". (Use the -weekly_backup_job_name parameter to specify a different job name) "  ; $Counter += ,@('Full Weekly Backups Job not Found', 1) }
                        else
                              {$full_weekly_backupdisplaytext = ", Full Weekly Backups Failed or Out of Date: " +$fullweeklybackupjobs ;  $Counter += ,@('Full Weekly Backups Failed or Out of Date', 1)}
                        if ($errlvl -ne "fail"){$errlvl = $full_weekly_backup_warn_or_fail}     }
            else
                  {     If ($displayverbose -eq 1)    {$full_weekly_backupdisplaytext = "Full Weekly Backups OK: "+$fullweeklybackupjobs ; $Counter += ,@('Full Weekly Backups OK',1)}    }     }
      else {$full_weekly_backupdisplaytext = ""}      
      
      
      

##############################################
## Are Translog Backups Running/Up to date?
##############################################
if ($check_translog_backup_yes_or_no -eq "Yes")
      {     if (($translogjobexist -ne 1) -or ($translogjobstatus -ne 0))
                  {     if ($translogjobexist -ne 1)
                              {$transbackupdisplaytext = ", Trans Logs Job not Found (search value = "+$translog_job_name+". (Use the -translog_job_name parameter to specify a different job name) "  ;    $Counter += ,@('Trans Logs Job not Found', 1)}
                        else
                              {$transbackupdisplaytext = ", Trans Logs Failed or Out of Date: " +$translogJobs ; $Counter += ,@('Trans Logs Failed or Out of Date', 1)}
                        if ($errlvl -ne "fail"){$errlvl = $translog_backup_warn_or_fail}  }
                  else
                        {     If ($displayverbose -eq 1)    {$transbackupdisplaytext = "TransLog Backup OK: "+$translogJobs    ; $Counter += ,@('TransLog Backups OK',1)}     }     }
      else {$transbackupdisplaytext = ""}

##############################################
## Are integritying Jobs succeeding?
##############################################
if ($Check_integrity_jobs_yes_or_no -eq "Yes")
      {     if (($integrityjobexist -ne 1) -or ($integrityjobstatus -ne 0))
                  {
                        if ($integrityjobexist -ne 1)
                              {$integrityjobdisplaytext = ", Integrity Checks Job not Found (search value = "+$integrity_job_name+". (Use the -integrity_job_name parameter to specify a different job name) " ;$Counter += ,@('Integrity Checks Job not Found', 1)}
                        else
                              {$integrityjobdisplaytext = ", Integrity Checks Failed or Out of Date: " +$IntegrityJobs ; $Counter += ,@('Integrity Checks Failed or Out of Date', 1)}
                              if ($errlvl -ne "fail"){$errlvl = $integrity_jobs_warn_or_fail}   }
            else
                  {If ($displayverbose -eq 1){  $integrityjobdisplaytext = ", Integrity Jobs OK: "+$IntegrityJobs;$Counter += ,@('Integrity Checks OK', 1)} }     }
      else {$integrityjobdisplaytext = ""}
##############################################
## Enumerate Database-Specific information
##############################################
$dblowfreespacealert = ", DB Freespace OK"
$dbRecoveryModelalert = ", DB RecoveryModel OK"
$dbhighlogratioalert = ", Log Ratios OK"
$hdfreespacealert = ", HD Freespace OK"
$dbcdrivealert = ", No DB's on C: Drive"
$dblowfreespacedisplaytext = ""
$dbhighlogratiodisplaytext = ""
$dbcdrivedisplaytext = ""
$dbSpaceRatiostatus =0
$dbrecoverymodelstatus =0
$dblogRatiostatus =0
$HDFreespacestatus = 0
$CDriveDBstatus = 0
foreach ($db in $dbs)
{     if (($db.mirroringstatus -notmatch "Synchronized") -and ($db.status -notmatch "Offline"))
      {
       if ($check_exhaustive_backup_yes_or_no -eq "yes")
    {
       if (($db.name -ne "tempdb") -and ($exhaustive_backup_check_ignore -notmatch $db.name -eq "false") -and ($db.createdate -lt $exhaustive_backup_new_db_target_time))
        {
            if ($db.lastbackupdate -lt $exhaustive_backup_interval_DAYS_target_time)
                {
                    $exhaustive_backupstatus += 1
                    $exhaustivebackupexceptions += $db.name}}}
        else {$exhaustive_backupdisplaytext = ""}

     
      $dblocation = ($db.primaryfilepath).split(":")
      $dbdrive = $dblocation[0]+":"
      $name = $db.name
      $logfiles = $db.LogFiles
      $recoverymodel = $db.RecoveryModel
      $totallogsize = 0
    $totalconnectedusers += $s.GetActiveDBConnectionCount($name)
      foreach ($log in $logfiles) {$logsize = $log.size/1KB;$logsize = [math]::Round($logsize, 2);    $totallogsize += $logsize}
      $dbSpaceRatio = [math]::Round(([math]::Round(($db.SpaceAvailable/1KB), 2)/[math]::Round($db.Size, 2)),2)*100
      $dbLogRatio = [math]::Round(([math]::Round($totallogsize, 2)/[math]::Round($db.Size, 2)),2)*100

      ####################################
      #Evaluate/alert Freespace
      ####################################
      if ($check_db_freespace_yes_or_no -eq "Yes")
      {     if (($dbSpaceRatio -lt ($db_freespace_warning_pct)) -and ($sysdbs -notcontains $db.name))  
                  {     $Counter += ,@(('% DB FreeSpace on: '+$db.name), $dbSpaceRatio)
                        $dbSpaceRatiostatus += 1
                        if ($dblowfreespacealert -eq ", DB Freespace OK" )
                              {$dblowfreespacealert = ", DB Freespace Alert: "+$db.name + ":("+$dbSpaceRatio+"%)"}
                        else
                              {$dblowfreespacealert = $dblowfreespacealert +" "+$db.name + ":("+$dbSpaceRatio+"%)"}
                        if ($dbSpaceRatio -lt ($db_freespace_failure_pct))
                              {$errlvl = "fail"}
                        else
                              {if ($errlvl -ne "fail"){$errlvl = "warn"}      }     }
        else
                  {      if (($displayverbose -eq 1) -and ($dbSpaceRatiostatus -eq 0))
                  {     $Counter += ,@(('% DB FreeSpace on:  '+$db.name), $dbSpaceRatio)
                              if ($dblowfreespacealert -eq ", DB Freespace OK" )
                                    {$dblowfreespacealert = ", DB Freespace OK: "+$db.name + ":("+$dbSpaceRatio+"% free)"}
                      else
                                    {$dblowfreespacealert = $dblowfreespacealert +" "+$db.name + ":("+$dbSpaceRatio+"% free)"}
                        }     }     }
      ####################################
      #Evaluate/alert RecoveryModel
      ####################################
      if ($check_db_RecoveryModel_yes_or_no -eq "Yes")
      {     
    if (("Full" -notcontains $RecoveryModel ) -and ($sysdbs -notcontains $db.name) -and ($Approved_Simple_dbs -notcontains $db.name))
                  {
            $Counter += ,@(('Simple Recovery Model Found on: '+$db.name), 1)
                        $dbRecoveryModelstatus += 1
                        if ($dbRecoveryModelalert -eq ", DB RecoveryModel OK" )
                              {$dbRecoveryModelalert = ", DB RecoveryModel Alert: "+$db.name + ":("+$RecoveryModel+")"}
                        else
                              {$dbRecoveryModelalert = $dbRecoveryModelalert +" "+$db.name + ":("+$RecoveryModel+")"}
                        
                        if ($errlvl -ne "fail"){$errlvl = $check_db_recoverymodel_warn_or_fail}
                  }
        else
                  {      if (($displayverbose -eq 1) -and ($dbRecoveryModelstatus -eq 0))
                  {     if ($dbRecoveryModelalert -eq ", DB RecoveryModel OK" )
                                    {$dbRecoveryModelalert = ", DB RecoveryModel OK: "+$db.name + ":("+$RecoveryModel+")"}
                      else
                                    {$dbRecoveryModelalert = $dbRecoveryModelalert +" "+$db.name + ":("+$RecoveryModel+")"}
                        }     }     }
      ##############################################
      #Are log file sizes out of whack?
      ##############################################
      if ($check_logfile_ratio_yes_or_no -eq "Yes")
      {     if ($dbLogRatio -gt ($logfile_ratio_alert_pct)  -and ($sysdbs -notcontains $db.name)  )
                  {     $dblogRatiostatus += 1
                        $Counter += ,@(('Ratio(%) of Logfile size to DB size on '+$db.name), $dbLogRatio)
                if ($dbhighlogratioalert -like "*Log Ratios OK*" )
                              {$dbhighlogratioalert = ", Log Size alert: "+$db.name + " Log Ratio:"+$dbLogRatio+"%("+$totallogsize+" mb)"}
                        else
                              { $dbhighlogratioalert = $dbhighlogratioalert +" "+$db.name + " Log Ratio:"+$dbLogRatio+"%("+$totallogsize+" mb)"}
                        if ($errlvl -ne "fail"){$errlvl = $logfile_ratio_warn_or_fail}
                  }
            else
            {    if (($displayverbose -eq 1) -and ($dblogRatiostatus -eq 0))
                      {
                              $Counter += ,@(('Ratio(%) of Logfile size to DB size on '+$db.name), $dbLogRatio)
                              if ($dbhighlogratioalert -eq ", Log Ratios OK" )
                                    {$dbhighlogratioalert = ", Log Ratios OK: "+$db.name + " Log Ratio:"+$dbLogRatio+"%("+$totallogsize+"mb)"}
                              else
                                    {$dbhighlogratioalert = $dbhighlogratioalert +", "+$db.name + " Log Ratio:"+$dbLogRatio+"%("+$totallogsize+"mb)"}
                        }    }      }
      ##############################################
      ## Do the drives have adequate freespace?
      ##############################################
      if ($check_hd_freespace_yes_or_no -eq "Yes")
      {
      $drives = Get-WmiObject -ComputerName $HostName Win32_LogicalDisk -ErrorAction SilentlyContinue -ErrorVariable $wmierror | Where-Object {$_.DriveType -eq 3}
      Trap [SystemException] { continue   }
      if (!$drives) {$errlvl = "fail"
                  $hdfreespacealert = ", Drive Freespace alert: Drives not returned from WMI: "}

      if ($drives) {
      foreach($drive in $drives)
      {
        if ($drive.size -gt 0)
        {
            $size1 = $drive.size / 1GB
            $size = "{0:N2}" -f $size1
            $free1 = $drive.freespace / 1GB
            $free = "{0:N2}" -f $free1
            $ID = $drive.DeviceID
            $drivefreeraw = [math]::Round(($free1 / $size1 * 100), 2)
            $drivefreeformatted = "{0:N2}" -f $drivefreeraw

                  if ($id -like $dbdrive)
                  {
                if ($drivefreeraw -lt $hd_freespace_warning_pct)
                        {
                              $Counter += ,@(('% Freespace on Drive: '+$ID), [double]$drivefreeraw)
                  if ($hdfreespacealert -like "*HD Freespace OK*")
                              {
                       
                              $hdfreespacealert = ", Drive Freespace alert: " +$drivefreeformatted+"% freespace on "+$dbdrive
                              if ($drivefreeraw -lt $hd_freespace_failure_pct)
                                    {
                                          $errlvl = "fail"
                                          #" errlvl 9: "+$errlvl
                                    }
                              else
                                    {
                                          if ($errlvl -ne "fail"){$errlvl = "warn"}
                                          #" errlvl 10: "+$errlvl
                                    }
                              }
                              else
                              {
                     If ($hdfreespacealert -notmatch $dbdrive)
                                     {
                                    $hdfreespacealert = $hdfreespacealert+", "+$drivefreeformatted+"% freespace on "+$dbdrive
                                    if ($drivefreeraw -lt $hd_freespace_failure_pct)
                                          {
                                                $errlvl = "fail"
                                                #" errlvl 11: "+$errlvl
                                          }
                                    else
                                          {
                                                if ($errlvl -ne "fail"){$errlvl = "warn"}
                                                #" errlvl 12: "+$errlvl
                                          }
                                    }
                              }
                        }
                if (($displayverbose -eq 1)-and ($HDFreespacestatus -eq 0))
                              {
                              $Counter += ,@(('% Freespace on Drive: '+$ID), [double]$drivefreeraw)
                              if ($hdfreespacealert -eq ", HD Freespace OK")
                                    {
                                    $hdfreespacealert = ", HD Freespace OK: " +$drivefreeformatted+"% freespace on "+$dbdrive
                                    }
                                    else
                                    {
                                     If ($hdfreespacealert -notmatch $dbdrive)
                                          {
                                          $hdfreespacealert = $hdfreespacealert+", "+$drivefreeformatted+"% freespace on "+$dbdrive
                                          }
                                    }
                              }
                        }                       
                  }
            }
      } }
      
      ##############################################
      ## Are there databases located on C: drive?
      ##############################################
      if ($check_for_dbs_on_c_drive -eq "Yes")
            {     $dblocation = ($db.primaryfilepath).split(":")
                  $dbdrive = $dblocation[0]
                  if ($dbdrive -eq "C")
                        {     $CDriveDBstatus += 1
                              $dbcdrivealert = " Databases found on C: Drive"
                              $Counter += ,@('Databases found on C: Drive', 1)
                              if ($errlvl -ne "fail"){$errlvl = $check_dbs_on_c_drive_warn_or_fail}
                              #" errlvl 13: "+$errlvl
                              }
                  else
                        {     if (($displayverbose -eq 1)-and ($CDriveDBstatus -eq 0)){$dbcdrivealert = ", No Databases found on C: Drive" ; $Counter += ,@('Databases found on C: Drive', 0)}  }
            }
      }
      
}
##############################################
## What SQL Version?
##############################################
$version = $s.VersionString
if ($check_sql_version_yes_or_no -eq "Yes")
{
      $TextVersion = "Unknown version"
      $versiontotext = $s.VersionString -split ".", 0, "simplematch"
      # $versiontotext[0]  #10
      # $versiontotext[1]  #50
      # $versiontotext[2]  #2500
      # $versiontotext[3]  #0
      $versionerror = 1
      if (    ($versiontotext[0] -eq 9 -and $versiontotext[2] -ge $SQL_2005_min_build_nbr) -or ($versiontotext[0] -eq 10 -and $versiontotext[1] -eq 50 -and $versiontotext[2] -ge $SQL_2008_R2_min_build_nbr) -or ($versiontotext[0] -eq 10 -and $versiontotext[1] -eq 0 -and $versiontotext[2] -ge $SQL_2008_min_build_nbr) )
                  {$versionerror = 0}
      switch -exact ($s.VersionMajor)     
    {
        "7" {$TextVersion = "SQL Server 7"}
        "8" {$TextVersion = "SQL Server 2000"}
        "9" {switch -exact ($s.VersionString)                           
                              {
                                    "9.00.5292.00" {$TextVersion = "SQL 2005 SP4 + Q2494123"}
                                    "9.00.5266.00" {$TextVersion = "SQL 2005 + SP4 Cumulative Update 3"}
                                    "9.00.5254.00" {$TextVersion = "SQL 2005 + SP4 Cumulative Update 1"}
                                    "9.00.5057.00" {$TextVersion = "SQL 2005 SP4 + KB2494120"}
                                    "9.00.5000.00" {$TextVersion = "SQL 2005 + SP4 RTM"}
                                    "9.00.4912.00" {$TextVersion = "SQL 2005 + SP4 CTP"}
                                    "9.00.4340.00" {$TextVersion = "SQL 2005 SP3 + Q2494112"}
                                    "9.00.4325.00" {$TextVersion = "SQL 2005 SP3+Q2438344 (Cumulative HF15)"}
                                    "9.00.4315.00" {$TextVersion = "SQL 2005 SP3+Q2438344 (Cumulative HF13)"}
                                    "9.00.4311.00" {$TextVersion = "SQL 2005 SP3+Q2345449 (Cumulative HF12)"}
                                    "9.00.4309.00" {$TextVersion = "SQL 2005 SP3+Q2258854 (Cumulative HF11)"}
                                    "9.00.4305.00" {$TextVersion = "SQL 2005 SP3+Q983329 (Cumulative HF10)"}
                                    "9.00.4294.00" {$TextVersion = "SQL 2005 SP3+Q980176 (Cumulative HF9)"}
                                    "9.00.4285.00" {$TextVersion = "SQL 2005 SP3+Q978915 (Cumulative HF8)"}
                                    "9.00.4278.00" {$TextVersion = "SQL 2005 SP3+Q978791"}
                                    "9.00.4273.00" {$TextVersion = "SQL 2005 SP3+Q976951 (Cumulative HF7)"}
                                    "9.00.4266.00" {$TextVersion = "SQL 2005 SP3+Q974648 (Cumulative HF6)"}
                                    "9.00.4230.00" {$TextVersion = "SQL 2005 SP3+Q972511 (Cumulative HF5)"}
                                    "9.00.4226.00" {$TextVersion = "SQL 2005 SP3+Q970279 (Cumulative HF4)"}
                                    "9.00.4224.00" {$TextVersion = "SQL 2005 + Q971409"}
                                    "9.00.4220.00" {$TextVersion = "SQL 2005 SP3+Q967909 (Cumulative HF3)"}
                                    "9.00.4216.00" {$TextVersion = "SQL 2005 SP3+Q967101"}
                                    "9.00.4211.00" {$TextVersion = "SQL 2005 SP3+Q961930 (Cumulative HF2)"}
                                    "9.00.4207.00" {$TextVersion = "SQL 2005 SP3+Q959195 (Cumulative HF1)"}
                                    "9.00.4053.00" {$TextVersion = "SQL 2005+SP3 (Q970892)"}
                                    "9.00.4035.00" {$TextVersion = "SQL 2005+SP3 (Q955706)"}
                                    "9.00.3356.00" {$TextVersion = "SQL 2005 SP2 + Cumulative Update 17"}
                                    "9.00.3355.00" {$TextVersion = "SQL 2005 SP2+Q216793 (Cumulative HF16)"}
                                    "9.00.3330.00" {$TextVersion = "SQL 2005 SP2+Q972510 (Cumulative HF15)"}
                                    "9.00.3328.00" {$TextVersion = "SQL 2005 SP2+Q970278 (Cumulative HF14)"}
                                    "9.00.3327.00" {$TextVersion = "SQL 2005 SP2+Q948567 / 961648"}
                                    "9.00.3325.00" {$TextVersion = "SQL 2005 SP2+Q967908 (Cumulative HF 13)"}
                                    "9.00.3320.00" {$TextVersion = "SQL 2005 SP2+Q969142"}
                                    "9.00.3318.00" {$TextVersion = "SQL 2005 SP2+Q967199"}
                                    "9.00.3315.00" {$TextVersion = "SQL 2005 SP2 (Cumulative HF12, available via request.)"}
                                    "9.00.3310.00" {$TextVersion = "SQL 2005 SP2+Q960090"}
                                    "9.00.3303.00" {$TextVersion = "SQL 2005 SP2+Q962209"}
                                    "9.00.3302.00" {$TextVersion = "SQL 2005 SP2+Q961479 / 961648"}
                                    "9.00.3301.00" {$TextVersion = "SQL 2005 SP2+Q958735 (Cumulative HF11, avail. via request.)"}
                                    "9.00.3295.00" {$TextVersion = "SQL 2005 SP2+Q959132"}
                                    "9.00.3294.00" {$TextVersion = "SQL 2005 SP2+Q956854 (Cumulative HF10, avail. via request.)"}
                                    "9.00.3291.00" {$TextVersion = "SQL 2005 SP2+Q956889"}
                                    "9.00.3289.00" {$TextVersion = "SQL 2005 SP2+Q937137"}
                                    "9.00.3282.00" {$TextVersion = "SQL 2005 SP2+Q953752 / 953607 (Cumulative HF9, avail. via request or by clicking here.)"}
                                    "9.00.3261.00" {$TextVersion = "SQL 2005 SP2+Q955754"}
                                    "9.00.3260.00" {$TextVersion = "SQL 2005 SP2+Q954950"}
                                    "9.00.3259.00" {$TextVersion = "SQL 2005 SP2+Q954669 / 954831"}
                                    "9.00.3257.00" {$TextVersion = "SQL 2005 SP2+Q951217 (Cumulative HF8, avail. via request.)"}
                                    "9.00.3253.00" {$TextVersion = "SQL 2005 SP2+Q954054"}
                                    "9.00.3244.00" {$TextVersion = "SQL 2005 SP2+Q952330"}
                                    "9.00.3242.00" {$TextVersion = "SQL 2005 SP2+Q951190"}
                                    "9.00.3240.00" {$TextVersion = "SQL 2005 SP2+Q951204"}
                                    "9.00.3239.00" {$TextVersion = "SQL 2005 SP2+Q949095 (Cumulative HF7, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3235.00" {$TextVersion = "SQL 2005 SP2+Q950189"}
                                    "9.00.3233.00" {$TextVersion = "SQL 2005 (QFE) SP2+Q941203 / 948108"}
                                    "9.00.3232.00" {$TextVersion = "SQL 2005 SP2+Q949959"}
                                    "9.00.3231.00" {$TextVersion = "SQL 2005 SP2+Q949687/949595"}
                                    "9.00.3230.00" {$TextVersion = "SQL 2005 SP2+Q949199"}
                                    "9.00.3228.00" {$TextVersion = "SQL 2005 SP2+Q946608 (Cumulative HF6, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3224.00" {$TextVersion = "SQL 2005 SP2+Q947463"}
                                    "9.00.3222.00" {$TextVersion = "SQL 2005 SP2+Q945640 / 945641 / 947196 / 947197"}
                                    "9.00.3221.00" {$TextVersion = "SQL 2005 SP2+Q942908 / 945442 / 945443 / 945916 / 944358 "}
                                    "9.00.3215.00" {$TextVersion = "SQL 2005 SP2+Q941450 (Cumulative HF5, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3209.00" {$TextVersion = "SQL 2005 SP2 (KB N/A, SQLHF Bug #50002118)"}
                                    "9.00.3208.00" {$TextVersion = "SQL 2005 SP2+Q944902"}
                                    "9.00.3206.00" {$TextVersion = "SQL 2005 SP2+Q944677"}
                                    "9.00.3205.00" {$TextVersion = "SQL 2005 SP2 (KB N/A, SQLHF Bug #50001708/50001999)"}
                                    "9.00.3203.00" {$TextVersion = "SQL 2005 SP2 (KB N/A, SQLHF Bug #50001951/50001993/50001997/50001998/50002000)"}  
                                    "9.00.3200.00" {$TextVersion = "SQL 2005 SP2+Q941450 (Cumulative HF4, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3195.00" {$TextVersion = "SQL 2005 SP2 (KB N/A, SQLHF Bug #50001812)"}  
                                    "9.00.3194.00" {$TextVersion = "SQL 2005 SP2+Q940933"}
                                    "9.00.3186.00" {$TextVersion = "SQL 2005 SP2+Q939562 (Cumulative HF3, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3182.00" {$TextVersion = "SQL 2005 SP2+Q940128"}
                                    "9.00.3180.00" {$TextVersion = "SQL 2005 SP2+Q939942"}
                                    "9.00.3179.00" {$TextVersion = "SQL 2005 SP2+Q938243"}
                                    "9.00.3178.00" {$TextVersion = "SQL 2005 SP2 (KB N/A, SQLHF Bug #50001193/5001352)"}
                                    "9.00.3177.00" {$TextVersion = "SQL 2005 SP2+Q939563 / 939285"}
                                    "9.00.3175.00" {$TextVersion = "SQL 2005 SP2+Q936305 /938825 (Cumulative HF2, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3171.00" {$TextVersion = "SQL 2005 SP2+Q937745"}
                                    "9.00.3169.00" {$TextVersion = "SQL 2005 SP2+Q937041/937033"}
                                    "9.00.3166.00" {$TextVersion = "SQL 2005 SP2+Q936185 / 934734"}
                                    "9.00.3162.00" {$TextVersion = "SQL 2005 SP2+Q932610/935360/935922"}
                                    "9.00.3161.00" {$TextVersion = "SQL 2005 SP2+Q935356/933724(Cumulative HF1, avail. via PSS only - must supply KBID of issue to resolve in your request)"}
                                    "9.00.3159.00" {$TextVersion = "SQL 2005 SP2+Q934459"}
                                    "9.00.3156.00" {$TextVersion = "SQL 2005 SP2+Q934226"}
                                    "9.00.3155.00" {$TextVersion = "SQL 2005 SP2+Q933549 / 933766/933808/933724/932115/933499"}
                                    "9.00.3154.00" {$TextVersion = "SQL 2005 SP2+Q934106 / 934109 / 934188"}
                                    "9.00.3153.00" {$TextVersion = "SQL 2005 SP2+Q933564"}
                                    "9.00.3152.00" {$TextVersion = "SQL 2005 SP2+Q933097 (Cumulative HF1)"}
                                    "9.00.3080.00" {$TextVersion = "SQL 2005 SP2+Q970895"}
                                    "9.00.3077.00" {$TextVersion = "SQL 2005 SP2+Q960089"}
                                    "9.00.3073.00" {$TextVersion = "SQL 2005 SP2+Q954606 (GDR)"}
                                    "9.00.3068.00" {$TextVersion = "SQL 2005 (GDR) SP2+Q941203 / 948109"}
                                    "9.00.3054.00" {$TextVersion = "SQL 2005 SP2+Q934458"}
                                    "9.00.3050.00" {$TextVersion = "SQL 2005 SP2+Q933508"}
                                    "9.00.3043.00" {$TextVersion = "SQL 2005 SP2+Q933508 (use this if SP2 was applied prior to 3/8)"}
                                    "9.00.3042.00" {$TextVersion = "SQL 2005 'Fixed' SP2 (use this if SP2 was NOT applied yet - orig. RTM removed)"}
                                    "9.00.3033.00" {$TextVersion = "SQL 2005 SP2 CTP (December) - Fix List"}
                                    "9.00.3027.00" {$TextVersion = "SQL 2005 SP2 CTP (November)"}
                                    "9.00.3026.00" {$TextVersion = "SQL 2005 SP1+Q929376"}
                                    "9.00.2249.00" {$TextVersion = "SQL 2005 SP1+Q948344"}
                                    "9.00.2245.00" {$TextVersion = "SQL 2005 SP1+Q933573"}
                                    "9.00.2243.00" {$TextVersion = "SQL 2005 SP1+Q944968"}
                                    "9.00.2242.00" {$TextVersion = "SQL 2005 SP1+Q943389/943388"}
                                    "9.00.2239.00" {$TextVersion = "SQL 2005 SP1+Q940961"}
                                    "9.00.2237.00" {$TextVersion = "SQL 2005 SP1+Q940719"}
                                    "9.00.2236.00" {$TextVersion = "SQL 2005 SP1+Q940287 / 940286"}
                                    "9.00.2234.00" {$TextVersion = "SQL 2005 SP1+Q937343"}
                                    "9.00.2233.00" {$TextVersion = "SQL 2005 SP1+Q933499/937545"}
                                    "9.00.2232.00" {$TextVersion = "SQL 2005 SP1+Q937277"}
                                    "9.00.2231.00" {$TextVersion = "SQL 2005 SP1+Q934812"}
                                    "9.00.2230.00" {$TextVersion = "SQL 2005 SP1+Q936179"}
                                    "9.00.2229.00" {$TextVersion = "SQL 2005 SP1+Q935446"}
                                    "9.00.2227.00" {$TextVersion = "SQL 2005 SP1+Q934066/933265"}
                                    "9.00.2226.00" {$TextVersion = "SQL 2005 SP1+Q933762/934065934065"}
                                    "9.00.2224.00" {$TextVersion = "SQL 2005 SP1+Q932990 / 933519"}
                                    "9.00.2223.00" {$TextVersion = "SQL 2005 SP1+Q932393"}
                                    "9.00.2221.00" {$TextVersion = "SQL 2005 SP1+Q931593"}
                                    "9.00.2219.00" {$TextVersion = "SQL 2005 SP1+Q931329 / 932115"}
                                    "9.00.2218.00" {$TextVersion = "SQL 2005 SP1+Q931843 / 931843"}
                                    "9.00.2216.00" {$TextVersion = "SQL 2005 SP1+Q931821"}
                                    "9.00.2215.00" {$TextVersion = "SQL 2005 SP1+Q931666"}
                                    "9.00.2214.00" {$TextVersion = "SQL 2005 SP1+Q929240 / 930505 / 930775"}
                                    "9.00.2211.00" {$TextVersion = "SQL 2005 SP1+Q930283 / 930284"}
                                    "9.00.2209.00" {$TextVersion = "SQL 2005 SP1+Q929278"}
                                    "9.00.2208.00" {$TextVersion = "SQL 2005 SP1+Q929179 / 929404"}
                                    "9.00.2207.00" {$TextVersion = "SQL 2005 SP1+Q928394 / 928372 / 928789"}
                                    "9.00.2206.00" {$TextVersion = "SQL 2005 SP1+Q928539 / 928083 / 928537"}
                                    "9.00.2202.00" {$TextVersion = "SQL 2005 SP1+Q927643"}
                                    "9.00.2201.00" {$TextVersion = "SQL 2005 SP1+Q927289"}
                                    "9.00.2198.00" {$TextVersion = "SQL 2005 SP1+Q926773 / 926611 / 924808 / 925277 / 926612 / 924807 / 924686"}
                                    "9.00.2196.00" {$TextVersion = "SQL 2005 SP1+Q926285/926335/926024"}
                                    "9.00.2195.00" {$TextVersion = "SQL 2005 SP1+Q926240"}
                                    "9.00.2194.00" {$TextVersion = "SQL 2005 SP1+Q925744"}
                                    "9.00.2192.00" {$TextVersion = "SQL 2005 SP1+Q924954/925335"}
                                    "9.00.2191.00" {$TextVersion = "SQL 2005 SP1+Q925135"}
                                    "9.00.2190.00" {$TextVersion = "SQL 2005 SP1+Q925227"}
                                    "9.00.2189.00" {$TextVersion = "SQL 2005 SP1+Q925153"}
                                    "9.00.2187.00" {$TextVersion = "SQL 2005 SP1+Q923849"}
                                    "9.00.2183.00" {$TextVersion = "SQL 2005 SP1+Q929404 / 924291"}
                                    "9.00.2181.00" {$TextVersion = "SQL 2005 SP1+Q923624/923605"}
                                    "9.00.2176.00" {$TextVersion = "SQL 2005 SP1+Q923296 / 922594"}
                                    "9.00.2175.00" {$TextVersion = "SQL 2005 SP1+Q922578 /922438 / 921536 / 922579 / 920794"}
                                    "9.00.2174.00" {$TextVersion = "SQL 2005 SP1+Q922063"}
                                    "9.00.2167.00" {$TextVersion = "SQL 2005 SP1+Q920974/921295"}
                                    "9.00.2164.00" {$TextVersion = "SQL 2005 SP1+Q919636 / 918832/919775"}
                                    "9.00.2156.00" {$TextVersion = "SQL 2005 SP1+Q919611"}
                                    "9.00.2153.00" {$TextVersion = "SQL 2005 SP1+builds 1531-40 (See Q919224 before applying!)"}
                                    "9.00.2050.00" {$TextVersion = "SQL 2005 SP1+.NET Vulnerability fix"}
                                    "9.00.2047.00" {$TextVersion = "SQL 2005 SP1 RTM"}
                                    "9.00.2040.00" {$TextVersion = "SQL 2005 SP1 CTP"}
                                    "9.00.2029.00" {$TextVersion = "SQL 2005 SP1 Beta"}
                                    "9.00.1561.00" {$TextVersion = "SQL 2005 RTM+Q932556"}
                                    "9.00.1558.00" {$TextVersion = "SQL 2005 RTM+Q926493"}
                                    "9.00.1554.00" {$TextVersion = "SQL 2005 RTM+Q926292"}
                                    "9.00.1551.00" {$TextVersion = "SQL 2005 RTM+Q922804"}
                                    "9.00.1550.00" {$TextVersion = "SQL 2005 RTM+Q917887/921106"}
                                    "9.00.1547.00" {$TextVersion = "SQL 2005 RTM+Q918276"}
                                    "9.00.1545.00" {$TextVersion = "SQL 2005 RTM+Q917905/919193"}
                                    "9.00.1541.00" {$TextVersion = "SQL 2005 RTM+Q917888/917971"}
                                    "9.00.1539.00" {$TextVersion = "SQL 2005 RTM+Q917738"}
                                    "9.00.1538.00" {$TextVersion = "SQL 2005 RTM+Q917824"}
                                    "9.00.1536.00" {$TextVersion = "SQL 2005 RTM+Q917016"}
                                    "9.00.1534.00" {$TextVersion = "SQL 2005 RTM+Q916706"}
                                    "9.00.1533.00" {$TextVersion = "SQL 2005 RTM+Q916086"}
                                    "9.00.1532.00" {$TextVersion = "SQL 2005 RTM+Q916046"}
                                    "9.00.1531.00" {$TextVersion = "SQL 2005 RTM+Q915918"}
                                    "9.00.1528.00" {$TextVersion = "SQL 2005 RTM+Q915112 / 915306 / 915307/ 915308"}
                                    "9.00.1519.00" {$TextVersion = "SQL 2005 RTM+Q913494"}
                                    "9.00.1518.00" {$TextVersion = "SQL 2005 RTM+Q912472/913371/913941"}
                                    "9.00.1514.00" {$TextVersion = "SQL 2005 RTM+Q912471"}
                                    "9.00.1503.00" {$TextVersion = "SQL 2005 RTM+Q911662"}
                                    "9.00.1502.00" {$TextVersion = "SQL 2005 RTM+Q915793"}
                                    "9.00.1500.00" {$TextVersion = "SQL 2005 RTM+Q910416"}
                                    "9.00.1406.00" {$TextVersion = "SQL 2005 RTM+Q932557"}
                                    "9.00.1399.00" {$TextVersion = "SQL 2005 RTM"}
                                    "9.00.1314.00" {$TextVersion = "SQL 2005 September CTP Release"}
                                    "9.00.1187.00" {$TextVersion = "SQL 2005 June CTP Release"}
                                    "9.00.1116.00" {$TextVersion = "SQL 2005 April CTP Release"}
                                    "9.00.1090.00" {$TextVersion = "SQL 2005 March CTP Release (may list as Feb.)"}
                                    "9.00.981.00" {$TextVersion = "SQL 2005 December CTP Release 2005 N/A 981"}
                                    "9.00.951.00" {$TextVersion = "SQL 2005 October CTP Release"}
                                    "9.00.917.00" {$TextVersion = "SQL 2005 Internal build (?)"}
                                    "9.00.852.00" {$TextVersion = "SQL 2005 Beta 2"}
                                    "9.00.849.00" {$TextVersion = "SQL 2005 Internal build (?)"}
                                    "9.00.844.00" {$TextVersion = "SQL 2005 Internal build (?)"}
                                    "9.00.836.00" {$TextVersion = "SQL 2005 Express Ed. Tech Preview"}
                                    "9.00.823.00" {$TextVersion = "SQL 2005 Internal build (IDW4)"}
                                    "9.00.790.00" {$TextVersion = "SQL 2005 Internal build (IDW3)"}
                                    "9.00.767.00" {$TextVersion = "SQL 2005 Internal build (IDW2)"}
                                    "9.00.747.00" {$TextVersion = "SQL 2005 Internal build (IDW)"}
                                    "9.00.645.00" {$TextVersion = "SQL 2005 MS Internal (?)"}
                                    "9.00.608.00" {$TextVersion = "SQL 2005 Beta 1"}
            }
            }
        "10" {
                        switch -exact ($s.VersionString)                      
                              {
                                    "10.50.2789.0" {$TextVersion = "SQL 2008 R2 SP1 + Cumulative Update 3"}
                                    "10.50.2772.0" {$TextVersion = "SQL 2008 R2 SP1 + Cumulative Update 2"}
                                    "10.50.2769.0" {$TextVersion = "SQL 2008 R2 SP1 + Cumulative Update 1"}
                                    "10.50.2500.0" {$TextVersion = "SQL 2008 R2 + SP1"}
                                    "10.50.2418.0" {$TextVersion = "SQL 2008 R2 + SP1 CTP"}
                                    "10.50.1804.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 9"}
                                    "10.50.1797.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 8"}
                                    "10.50.1790.0" {$TextVersion = "SQL 2008 R2 + Q2494086790"}
                                    "10.50.1777.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 7"}
                                    "10.50.1765.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 6"}
                                    "10.50.1753.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 5"}
                                    "10.50.1746.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 4"}
                                    "10.50.1734.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 3"}
                                    "10.50.1720.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 2"}
                                    "10.50.1702.0" {$TextVersion = "SQL 2008 R2 + Cumulative Update 1"}
                                    "10.50.1600.1" {$TextVersion = "SQL 2008 R2 RTM"}
                                    "10.50.1450.3" {$TextVersion = "SQL 2008 R2 RC" }
                                    "10.0.5500.0" {$TextVersion = "SQL 2008 + Service Pack 3"}
                                    "10.0.4321.0" {$TextVersion = "SQL 2008 SP2 + Cumulative Update 6"}
                                    "10.0.4316.0" {$TextVersion = "SQL 2008 SP2 + Cumulative Update 5"}
                                    "10.0.4311.0" {$TextVersion = "SQL 2008 SP2 + Q2494094"}
                                    "10.0.4285.0"ersion = "SQL 2008 + Cumulative Update 4 for SP2"}
                                    "10.0.4279.0" {$TextVersion = "SQL 2008 + Cumulative Update 3 for SP2"}
                                    "10.0.4272.0" {$TextVersion = "SQL 2008 + Cumulative Update 2 for SP2"}
                                    "10.0.4266.0" {$TextVersion = "SQL 2008 + Cumulative Update 1 for SP2"}
                                    "10.0.4064.0" {$TextVersion = "SQL 2008 SP2 + Q2494089"}
                                    "10.0.4000.0" {$TextVersion = "SQL 2008 + Service Pack 2"}
                                    "10.0.2850.0" {$TextVersion = "SQL 2008 + Cumulative Update 16 for SP1"}
                                    "10.0.2847.0" {$TextVersion = "SQL 2008 + Cumulative Update 15 for SP1"}
                                    "10.0.2841.0" {$TextVersion = "SQL 2008 SP1 + Q2494100"}
                                    "10.0.2821.0" {$TextVersion = "SQL 2008 + Cumulative Update 14 for SP1"}
                                    "10.0.2816.0" {$TextVersion = "SQL 2008 + Cumulative Update 13 for SP1"}
                                    "10.0.2808.0" {$TextVersion = "SQL 2008 + Cumulative Update 12 for SP1"}
                                    "10.0.2804.0" {$TextVersion = "SQL 2008 + Q2413738"}
                                    "10.0.2799.0" {$TextVersion = "SQL 2008 + Cumulative Update 10 for SP1"}
                                    "10.0.2789.0" {$TextVersion = "SQL 2008 + Cumulative Update 9 for SP1"}
                                    "10.0.2775.0" {$TextVersion = "SQL 2008 + Cumulative Update 8 for SP1"}
                                    "10.0.2766.0" {$TextVersion = "SQL 2008 + Cumulative Update 7 for SP1"}
                                    "10.0.2760.0" {$TextVersion = "SQL 2008 + Q978839"}
                                    "10.0.2758.0" {$TextVersion = "SQL 2008 SP1 + Q978791"}
                                    "10.0.2757.0" {$TextVersion = "SQL 2008 + Cumulative Update 6 for SP1"}
                                    "10.0.2746.0" {$TextVersion = "SQL 2008 + Cumulative Update 5 for SP1"}
                                    "10.0.2740.0" {$TextVersion = "SQL 2008 + Q976761"}
                                    "10.0.2734.0" {$TextVersion = "SQL 2008 + Cumulative Update 4 for SP1"}
                                    "10.0.2723.0" {$TextVersion = "SQL 2008 + Cumulative Update 3 for SP1"}
                                    "10.0.2714.0" {$TextVersion = "SQL 2008 + Cumulative Update 2 for SP1"}
                                    "10.0.2712.0" {$TextVersion = "SQL 2008 + Q970507"}
                                    "10.0.2710.0" {$TextVersion = "SQL 2008 + Cumulative Update 1 for SP1"}
                                    "10.0.2531.0" {$TextVersion = "SQL 2008 + Service Pack 1"}
                                    "10.0.1835.0" {$TextVersion = "SQL 2008 + Cumulative Update 10"}
                                    "10.0.1828.0" {$TextVersion = "SQL 2008 + Cumulative Update 9"}
                                    "10.0.1823.0" {$TextVersion = "SQL 2008 + Cumulative Update 8"}
                                    "10.0.1818.0" {$TextVersion = "SQL 2008 + Q973601"}
                                    "10.0.1812.0" {$TextVersion = "SQL 2008 + Cumulative Update 6"}
                                    "10.0.1806.0" {$TextVersion = "SQL 2008 + Cumulative Update 5"}
                                    "10.0.1798.0" {$TextVersion = "SQL 2008 + Cumulative Update 4"}
                                    "10.0.1787.0" {$TextVersion = "SQL 2008 + Cumulative Update 3"}
                                    "10.0.1779.0" {$TextVersion = "SQL 2008 + Q958186 (Cumulative HF2, available by request.)"}
                                    "10.0.1771.0" {$TextVersion = "SQL 2008 + Q958611"}
                                    "10.0.1763.0" {$TextVersion = "SQL 2008 + Q956717"}
                                    "10.0.1755.0" {$TextVersion = "SQL 2008 + Q957387"}
                                    "10.0.1750.0" {$TextVersion = "SQL 2008 + Q956718"}
                                    "10.0.1600.22.0" {$TextVersion = "SQL 2008 RTM"}
                                    "10.0.1300.13.0" {$TextVersion = "SQL 2008 February CTP"}
                                    "10.0.1049.14.0" {$TextVersion = "SQL 2008 July CTP (requires Virtual Server 2005 R2)"}
                                    "10.0.1019.17.0" {$TextVersion = "SQL 2008 June CTP"}
                              }
                        }

      }
            if ($versionerror -gt 0)
                  {if ($errlvl -ne "fail"){$errlvl = $sql_version_warn_or_fail}; $Counter += ,@(($TextVersion+' (Build Number: )'), [double]$versiontotext[2])    }
            else
                  {if ($displayverbose -eq 1) {$Counter += ,@(($TextVersion+' (Build Number: )'), [double]$versiontotext[2])} }
}
      ##############################################
      ## Are there Un-Backed-Up databases?
      ##############################################  
      if ($exhaustive_backupstatus -ne 0)
                  {
                  $exhaustive_backupdisplaytext = ", "+$exhaustivebackupexceptions+" not Backed up in the last " +$exhaustive_backup_interval_DAYS+" days " ;     $Counter += ,@('Number of Un-Backed-Up databases: ', $exhaustive_backupstatus)
                  if ($errlvl -ne "fail"){$errlvl = $exhaustive_backup_warn_or_fail}      }     
      else
                  {     If ($displayverbose -eq 1)    {$exhaustive_backupdisplaytext = "No Un-Backed-Up databases " ; $Counter += ,@('Number of Un-Backed-Up databases: ',0)} }     
if ($check_sql_version_yes_or_no -eq "Yes"){$sqlversion = ", "+$TextVersion+": ("+$version+")"} else {$sqlversion = ""}
if ($check_db_freespace_yes_or_no -eq "Yes"){$dblowfreespacedisplaytext = $dblowfreespacealert} else {$dblowfreespacedisplaytext = ""}
if ($check_db_recoverymodel_yes_or_no -eq "Yes"){$dbrecoverymodeldisplaytext = $dbrecoverymodelalert} else {$dbrecoverymodeldisplaytext = ""}
if ($check_hd_freespace_yes_or_no -eq "Yes"){$dbdrivefreedisplaytext = $hdfreespacealert} else {$dbdrivefreedisplaytext = ""}
if ($check_logfile_ratio_yes_or_no -eq "Yes"){$dbhighlogratiodisplaytext = $dbhighlogratioalert} else {$dbhighlogratiodisplaytext = ""}
if ($check_for_dbs_on_c_drive -eq "Yes"){$dbcdrivedisplaytext = $dbcdrivealert} else {$dbcdrivedisplaytext = ""}
if ($check_for_db_usercount -eq "Yes") {$usercountdisplaytext = ", "+[string]$totalconnectedusers+" total connections "} else {$usercountdisplaytext = "" };$Counter += ,@('Total Conections: ',$totalconnectedusers)
if ($check_for_Full_backup_duration -eq "Yes") {$fullbudisplaytext = ", "+[string]$fullbuduration+" minutes for UserDBs full backup "} else {$fullbudisplaytext = "" };$Counter += ,@($fullbudurationlabel,$fullbuduration)
if ($polymon -eq 1){if ($errlvl -eq "warn") {$Status.StatusID=2} elseif ($errlvl -eq "fail") {$Status.StatusID=3} else {$Status.StatusID=1}}

$displaymessageraw = "   "+$sqlversion+$full_daily_backupdisplaytext+$full_weekly_backupdisplaytext+$transbackupdisplaytext+$integrityjobdisplaytext+$Exhaustive_backupdisplaytext+$dblowfreespacedisplaytext+$dbrecoverymodeldisplaytext+$dbhighlogratiodisplaytext+$dbcdrivedisplaytext+$dbdrivefreedisplaytext+$usercountdisplaytext+$fullbudisplaytext
$displaymessage = $displaymessageraw -replace "   ,", ""

if ($polymon -eq 1){$Status.StatusText=$displaymessage}
if ($polymon -eq 0) {$errlvl+" "+$displaymessage}

if (($counter.length) -gt 1){  $counter = $counter | select -uniq;foreach ($count in $counter){ If ($polymon -eq 1){  If ($count[0] -ne 'declare'){  $Counters.Add($count[0],$count[1])  }  }   }   } 


}
#endregion Originating script: 'H:\My Docs\PM_SQL_Overview.ps1'
