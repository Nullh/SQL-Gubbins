DECLARE @logfile nvarchar(max)
SET @logfile = (SELECT REVERSE(SUBSTRING(REVERSE(path),CHARINDEX('\',REVERSE(path)),LEN(path)))+'log.trc' FROM sys.traces WHERE path LIKE '%\MSSQL\Log\log%.trc')

SELECT te.name, t.DatabaseName, t.FileName, t.StartTime, t.ApplicatioNname
FROM fn_trace_gettable(@logfile, NULL) AS t
INNER JOIN sys.trace_events AS te ON t.EventClass = te.trace_event_id
WHERE te.name LIKE '%Auto Grow'
ORDER BY StartTime ASC