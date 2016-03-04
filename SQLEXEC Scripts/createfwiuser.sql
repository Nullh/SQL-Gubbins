------------------------------------------
-- Create FWi User                      --
-- Don't forget to change the details! --
------------------------------------------
/*
Account created and password sent to user.
*/

USE [master]
GO

CREATE TABLE ##temp
	(id nvarchar(max))
INSERT INTO ##temp
	VALUES ('$(uname)')     --<--<--
DECLARE @id nvarchar(max)
DECLARE @pass nvarchar(max)
SET @id = (SELECT id FROM ##temp)
SET @pass = '$(passwd)'     --<--<--

PRINT 'Creating login '+@id+'...'

EXEC('CREATE LOGIN ['+@id+'] 
	WITH PASSWORD=N'''+@pass+''', 
	DEFAULT_DATABASE=[master], 
	CHECK_EXPIRATION=OFF, 
	CHECK_POLICY=OFF')
GO
PRINT 'Login created'
USE [ss_fwprod]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Live'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
GO
PRINT 'Live user created'
USE [ss_fwuatest]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Test'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
GO
PRINT 'Test user created'
DROP TABLE ##temp
PRINT 'User set up complete'