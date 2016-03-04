@echo off
ECHO Reset FWi Password
set /p uname=Username:
set /p passwd=Password:
ECHO Setting Password for %uname%
ECHO Connecting to SQL Server
SQLCMD -S "D-DB91\DB91" -i resetfwipass.sql

PAUSE