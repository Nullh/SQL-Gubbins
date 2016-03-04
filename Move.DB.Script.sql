USE [master]
GO

DECLARE @dbname nvarchar(MAX)
DECLARE @newdatadrive nvarchar(1)
DECLARE @newlogdrive nvarchar(1)
DECLARE @newpath nvarchar(MAX)
DECLARE @fileidno int
DECLARE @query nvarchar(MAX)
DECLARE @assist nvarchar(MAX)
SET @assist = CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+N'Now move the following files:'+CHAR(13)+CHAR(10)

---    SET THESE!    ---
SET @dbname = N'DBName'
SET @newdatadrive = N'X'
SET @newlogdrive = N'Y'
------------------------

-- Switch on if the db name is valid
IF EXISTS(SELECT name FROM sys.databases WHERE name = @dbname)
BEGIN
	PRINT N'Commands run:'+CHAR(13)+CHAR(10)
	-- Get file information for database
	DECLARE @filetable TABLE
	(
		file_id int,
		type_desc nvarchar(10),
		name nvarchar(MAX),
		physical_name nvarchar(MAX)
	)
	SET @query = N'SELECT file_id, type_desc, name, physical_name FROM ['+@dbname+N'].sys.database_files'
	INSERT INTO @filetable EXEC sp_executesql @query

	-- Restrict database
	SET @query = N'ALTER DATABASE ['+@dbname+N'] SET  RESTRICTED_USER WITH ROLLBACK IMMEDIATE'
	PRINT @query
	EXEC sp_executesql @query

	-- Alter file paths
	SET @fileidno = (SELECT MIN(file_id) FROM @filetable)
	WHILE @fileidno <= (SELECT MAX(file_id) FROM @filetable)
	BEGIN
		IF (SELECT type_desc FROM @filetable WHERE file_id = @fileidno) = N'LOG'
		BEGIN
			SET @newpath = @newlogdrive+SUBSTRING((SELECT physical_name FROM @filetable WHERE file_id = @fileidno), 2,
				LEN((SELECT physical_name FROM @filetable WHERE file_id = @fileidno))-1)
		END
		ELSE
		BEGIN 
			SET @newpath = @newdatadrive+SUBSTRING((SELECT physical_name FROM @filetable WHERE file_id = @fileidno), 2,
				LEN((SELECT physical_name FROM @filetable WHERE file_id = @fileidno))-1)
		END		
		
		SET @query = N'ALTER DATABASE ['+@dbname+N'] MODIFY FILE (NAME= '+
			(SELECT name FROM @filetable WHERE file_id = @fileidno)+
			N', FILENAME='''+@newpath+''')'
		PRINT @query
		EXEC sp_executesql @query
		
		SET @assist = @assist+(SELECT physical_name FROM @filetable WHERE file_id = @fileidno)+' to '+@newpath+CHAR(13)+CHAR(10)
		SET @fileidno = @fileidno + 1
	END

	-- Set database offline
	SET @query = N'ALTER DATABASE ['+@dbname+N'] SET OFFLINE'
	PRINT @query
	EXEC sp_executesql @query
	
	SET @assist = @assist+N'Then run the online script.'
	PRINT @assist
END
ELSE
PRINT N'Database name does not exist'