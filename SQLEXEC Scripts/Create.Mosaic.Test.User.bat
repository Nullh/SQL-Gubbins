@echo off
ECHO Creating new FWi User
set /p uname=Username:
set /p passwd=Password:
ECHO Creating new FWi user %uname%
ECHO Connecting to SQL Server
SQLCMD -S "D-DB-01" -i createmosaictestuser.sql

PAUSE