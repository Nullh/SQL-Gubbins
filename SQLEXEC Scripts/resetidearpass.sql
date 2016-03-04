------------------------------------------
-- Create IDEAR User                      --
-- Don't forget to change the details! --
------------------------------------------
/*
Account created and password sent to user.
*/

USE [master]
GO

DECLARE @id nvarchar(max)
DECLARE @pass nvarchar(max)
SET @id = '$(uname)'
SET @pass = '$(passwd)'     --<--<--

PRINT 'Changing password for '+@id+'...'

EXEC('ALTER LOGIN ['+@id+'] 
	WITH PASSWORD=N'''+@pass+'''')
GO
PRINT 'Password changed'