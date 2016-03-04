@echo off
ECHO DROPPING FWi User
set /p uname=Username:
ECHO Dropping FWi user %uname%
PAUSE
ECHO Connecting to SQL Server
SQLCMD -S "D-DB91\DB91" -i dropfwiuser.sql

PAUSE