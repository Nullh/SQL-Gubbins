----------------------------------------
-- Reset FWi Password                 --
-- Hardly necessary, but saves typing --
----------------------------------------
/*
Password reset and sent to user.
*/
--- TRIBAL DB92/FRAMEWORKI DB91 ---

USE [master]
GO
ALTER LOGIN [] WITH PASSWORD = ''
