USE master;
GO
ALTER DATABASE msdb
MODIFY FILE (NAME = MSDBData, FILENAME = '<new path>\MSDBData.mdf');
GO
ALTER DATABASE msdb
MODIFY FILE (NAME = MSDBLog, FILENAME = '<new path>\MSDBLog.ldf');
GO

ALTER DATABASE model
MODIFY FILE (NAME = modeldev, FILENAME = '<new path>\model.mdf');
GO
ALTER DATABASE model
MODIFY FILE (NAME = modellog, FILENAME = '<new path>\modellog.ldf');
GO

ALTER DATABASE tempdb
MODIFY FILE (NAME = tempdev, FILENAME = '<new path>\tempdb.mdf');
GO
ALTER DATABASE tempdb
MODIFY FILE (NAME = templog, FILENAME = '<new path>\templog.ldf');
GO

-- FOR RECOVERY FROM MISSING SYSTEM DBs
-- D:\Program Files\Microsoft SQL Server\MSSQL11.ECCQA\MSSQL\Binn
-- SQLServr.exe -s ECCQA -f -e\\SVM-HV01\SQL_ECCQ_SQLSystemDB\MSSQL11.ECCQA\MSSQL\Log\ERRORLOG -d<new path>\master.mdf -l<new path>\mastlog.ldf -T7806 -T3608 -T3609