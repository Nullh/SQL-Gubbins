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
	VALUES (N'71039999')     --<--<--
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Deleting user '+@id

USE [ss_fwdevelopment]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Dev'
	EXEC ('drop schema ['+@id+']')
	PRINT 'Dropping '+@id+' user from Dev'
	EXEC ('drop user ['+@id+']')
GO
USE [ss_fwuatest]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Test'
	EXEC ('drop schema ['+@id+']')
	PRINT 'Dropping '+@id+' user from Test'
	EXEC ('drop user ['+@id+']')
GO
USE [ss_fwprod]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping '+@id+' schema from Live'
	EXEC ('drop schema ['+@id+']')
	PRINT 'Dropping '+@id+' user from Live'
	EXEC ('drop user ['+@id+']')
GO
USE [master]
GO
	DECLARE @id nvarchar(max)
	SET @id = (SELECT id FROM ##temp)
	PRINT 'Dropping login '+@id
	EXEC ('drop login ['+@id+']')
GO
DROP TABLE ##temp