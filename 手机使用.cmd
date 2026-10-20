@echo off
rem Pure-ASCII wrapper. Real logic lives in start-mobile.ps1.
rem Batch files are read using the ANSI codepage, so any non-ASCII
rem character here gets mangled and can even produce bogus commands.
rem PowerShell is used because IP discovery needs a pipeline, and cmd
rem would interpret the "|" inside a PowerShell command as its own pipe.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-mobile.ps1"
