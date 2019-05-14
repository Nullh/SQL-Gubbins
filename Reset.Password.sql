----------------------------------------
-- Reset FWi Password                 --
-- Hardly necessary, but saves typing --
----------------------------------------
/*
Password reset and sent to user.
*/

USE [master]
GO
ALTER LOGIN [] WITH PASSWORD = ''
