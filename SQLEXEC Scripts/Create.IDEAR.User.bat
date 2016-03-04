@echo off
ECHO Creating new IDEAR User
set /p uname=Username:
set /p passwd=Password:
ECHO Creating new FWi user %uname%
ECHO Connecting to SQL Server
SQLCMD -S "D-DB92\DB92" -i createidearuser.sql

PAUSE