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
USE [ss_fwmosaic_with_docs]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Mosaic Test'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
EXEC ('sp_change_users_login ''update_one'','''+@id+''', '''+@id+'''')
GO
PRINT 'Test system user created'
GO

DROP TABLE ##temp
PRINT 'User set up complete'