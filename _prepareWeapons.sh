#!/bin/bash

echo Enter the name of project:

read projectName

echo Preparing weapons for project $projectName

echo Creating folders for project $projectName
mkdir ~/$projectName
mkdir ~/$projectName/nmap
mkdir ~/$projectName/kerberosTickets
mkdir ~/$projectName/lsassDump
mkdir ~/$projectName/sharphoundOutput
mkdir ~/$projectName/webServer

echo Unzipping rockyou.txt wordlist
sudo gunzip /usr/share/wordlists/rockyou.txt.gz

echo Done!
