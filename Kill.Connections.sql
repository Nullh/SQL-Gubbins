---------------------------------------------------
--   -=|Kill Connections|=-                      --
-- Kills all connections to a specified database --
-- - [Neil Holmes](http://red-alliance.org)      --
-- N.B. Don't forget to change the DBName value! --
---------------------------------------------------

USE master
GO

DECLARE @DBName VARCHAR(50) 
SET @DBName = 'Test'

CREATE TABLE #sp_who2
(SPID INT, 
Status VARCHAR(1000) NULL, 
Login SYSNAME NULL, 
HostName SYSNAME NULL, 
BlkBy SYSNAME NULL, 
DBName SYSNAME NULL, 
Command VARCHAR(1000) NULL, 
CPUTime INT NULL, 
DiskIO INT NULL, 
LastBatch VARCHAR(1000) NULL, 
ProgramName VARCHAR(1000) NULL, 
SPID2 INT,
REQUESTID INT)

INSERT INTO #sp_who2
EXEC sp_who2

DECLARE whoCursor CURSOR FOR 
SELECT SPID, [Login]
FROM #sp_who2
WHERE DBName = @DBName

DECLARE @spid INT
DECLARE @login VARCHAR(100)
DECLARE @killstring VARCHAR(100)

OPEN whoCursor
FETCH NEXT FROM whoCursor INTO @spid, @login

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @killstring = 'KILL ' + CAST(@spid AS VARCHAR(5)) + ';'
	PRINT 'Running ' + @killstring + ' for user ' + @login
	EXEC(@killstring)
	FETCH NEXT FROM whoCursor INTO @spid
END

CLOSE whoCursor
DEALLOCATE whoCursor

DROP TABLE #sp_who2
GO

