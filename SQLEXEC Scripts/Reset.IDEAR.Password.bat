@echo off
ECHO Reset IDEAR Password
set /p uname=Username:
set /p passwd=Password:
ECHO Setting Password for %uname%
ECHO Connecting to SQL Server
SQLCMD -S "D-DB92\DB92" -i resetidearpass.sql

PAUSE