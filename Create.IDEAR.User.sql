------------------------------------------
-- Create Tribal User                      --
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
	VALUES (N'71033624')       --<--<--
DECLARE @id nvarchar(max)
DECLARE @pass nvarchar(max)
SET @id = (SELECT id FROM ##temp)
SET @pass = N'Burning&62'     --<--<--

PRINT 'Creating user '+@id

EXEC('CREATE LOGIN ['+@id+'] 
	WITH PASSWORD=N'''+@pass+''', 
	DEFAULT_DATABASE=[master], 
	CHECK_EXPIRATION=OFF, 
	CHECK_POLICY=OFF')
GO

USE [EDUC_IDR_IDEAR]
GO
DECLARE @id nvarchar(max)
SET @id = (SELECT id FROM ##temp)
PRINT 'Creating user '+@id+' in Idear'
EXEC ('CREATE USER ['+@id+'] FOR LOGIN ['+@id+']')
EXEC sp_addrolemember N'FOUNDATION', @id
EXEC sp_addrolemember N'IDEAR', @id
GO
GO
GO

DROP TABLE ##temp
