#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			checkFileVault
# 		DESCRIPTION:  	This script checks to see if FileVault is encrypting
#              
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com)	04/25/2013
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

exec 2>>"$LogFile"

declare -x FileVaultStatus=`fdesetup status | awk '{print $3}'| awk -F. '{print $1}'`

StatusMSG $ScriptName "FileVault2 Encrypting Check" uiphase
StatusMSG $ScriptName "Checking if Macintosh HD is currently FileVault2 Encrypting..." uistatus
sleep 4

if [[ $FileVaultStatus == "Off" || $FileVaultStatus == "On" ]]; then
	StatusMSG $ScriptName "FileVault2 is Not Currently Encrypting." uistatus
	sleep 2
	exit 0
else
	StatusMSG $ScriptName "FileVault2 is Currently Encrypting. Exiting." uistatus
	sleep 2
	exit 1
fi		
