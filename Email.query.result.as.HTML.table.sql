declare @errcount int
declare @table varchar(MAX)

set @errcount = (select count(*) from report_logs
where line like '%error%'
and line not like '%_ERRORS%')

if @errcount > 0
begin
select 'Errors found, sending email'

set @table = N'Errors have been detected in the execution of Reports Repository on ss_fwprod.<br />
The details of the errors, taken from the Report_Logs table are below:<br /><br />' +
N'<table border="1">' +
	N'<tr><th>Timestamp</th><th>Step Name</th><th>Message</th><tr>' +
	CAST (( select td = time_stamp,	'',
					td = step,	'',
					td = line,	''
					from report_logs
					where line like '%error%'
					and line not like '%_ERRORS%'
					order by time_stamp asc
					FOR XML PATH('tr'), TYPE ) as nvarchar(MAX)) +
	N'</table>';

EXEC msdb.dbo.sp_send_dbmail
	@recipients = 'your@email.com',
	@body = @table,
	@body_format = 'HTML',
	@subject = 'Errors Detected in Reports Repository';

end
else
select 'No errors found'