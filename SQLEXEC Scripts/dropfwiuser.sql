------------------------------------------
-- DROP FWi USER                        --
-- Don't forget to change the username! --
------------------------------------------
/*
SQL Account deleted.
*/

CREATE TABLE ##temp
	(id nvarchar(max))
INSERT INTO ##temp
	VALUES (N'$(uname)')     --<--<--
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Deleting user '+@id

USE [ss_fwdevelopment]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Dev'
	IF EXISTS(select name from sys.schemas
		where name = @id)
	BEGIN
		EXEC ('drop schema ['+@id+']')
	END
	ELSE
		PRINT 'No schema to drop'
	PRINT 'Dropping '+@id+' user from Dev'
	IF EXISTS(select name from sys.database_principals 
		where name LIKE @id)
	BEGIN
		EXEC ('drop user ['+@id+']')
	END
	ELSE
		PRINT 'No user to drop'
GO
USE [ss_fwuatest]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Test'
	IF EXISTS(select name from sys.schemas
		where name = @id)
	BEGIN
		EXEC ('drop schema ['+@id+']')
	END
	ELSE
		PRINT 'No schema to drop'
	PRINT 'Dropping '+@id+' user from Test'
	IF EXISTS(select name from sys.database_principals 
		where name LIKE @id)
	BEGIN
		EXEC ('drop user ['+@id+']')
	END
	ELSE
		PRINT 'No user to drop'
GO
USE [ss_fwprod]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Live'
	IF EXISTS(select name from sys.schemas
		where name = @id)
	BEGIN
		EXEC ('drop schema ['+@id+']')
	END
	ELSE
		PRINT 'No schema to drop'
	PRINT 'Dropping '+@id+' user from Live'
	IF EXISTS(select name from sys.database_principals 
		where name LIKE @id)
	BEGIN
		EXEC ('drop user ['+@id+']')
	END
	ELSE
		PRINT 'No user to drop'
GO
USE [master]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping login '+@id
	IF EXISTS(select name from master..syslogins 
	where name LIKE @id)
	BEGIN
		EXEC ('drop login ['+@id+']')
	END
	ELSE
		PRINT 'ERROR: Could not find login'
GO
DROP TABLE ##temp