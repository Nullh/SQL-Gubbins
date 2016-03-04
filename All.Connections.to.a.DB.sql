---------------------------------------------------
--   -=|View connections to a DB|=-              --
-- View all connections to a specified database  --
-- - [Neil Holmes](http://red-alliance.org)      --
-- N.B. Don't forget to change the DBName value! --
---------------------------------------------------

USE master
GO

DECLARE @DBName VARCHAR(50) 
SET @DBName = 'ENVS_Bridges'

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

SELECT * FROM #sp_who2
WHERE DBName = @DBName

DROP TABLE #sp_who2