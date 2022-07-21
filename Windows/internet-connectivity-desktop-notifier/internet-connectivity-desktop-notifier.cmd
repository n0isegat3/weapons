@echo off
Echo Starting internet-connectivity-desktop-notifier
Echo Jan Marek Cyber Rangers
timeout 5 > NUL
powershell.exe -executionpolicy unrestricted -sta -windowstyle hidden -file .\internet-connectivity-desktop-notifier.ps1 -balloontiptimeout 5 -testinterval 10