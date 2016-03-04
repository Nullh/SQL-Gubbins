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
	VALUES (N'71039999')       --<--<--
DECLARE @id nvarchar(max)
DECLARE @pass nvarchar(max)
SET @id = (SELECT id FROM ##temp)
SET @pass = N'Calico(72hj'     --<--<--

PRINT 'Creating user '+@id

EXEC('CREATE LOGIN ['+@id+'] 
	WITH PASSWORD=N'''+@pass+''', 
	DEFAULT_DATABASE=[master], 
	CHECK_EXPIRATION=OFF, 
	CHECK_POLICY=OFF')
GO

USE [ss_fwprod]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Live'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
GO
USE [ss_fwuatest]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Test'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
GO

DROP TABLE ##temp
