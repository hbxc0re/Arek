#!/bin/bash

# inventoryUpdate.sh
# PasswordUtility
#
# Created by Zack Smith on 3/14/12.
# Copyright 2012 318. All rights reserved.

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

# Check for a conf file in the same directory
if [ -f "$RunDirectory/.macauth.conf" ] ; then
	source "$RunDirectory/.macauth.conf"
else
	printf "%s\n" "Configuration file required for this script is missing !($RunDirectory/.macauth.conf)"
	exit 1
fi

source "$RunDirectory/common.sh"
exec 2>>"$LogFile"


[ "$EUID" != 0 ] && 
	printf "%s\n" "This script requires root access!" && exit 1

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"

declare -x jamf="/usr/sbin/jamf"

# Parse the input options...
while getopts "u:p:o:l: h" CredInputs; do
	case $CredInputs in
		u ) export ADUser="$OPTARG" ;;
		l ) export LocalUser="$OPTARG" ;;
		p ) export NewPass="$OPTARG" ;;
		o ) export OldPass="$OPTARG" ;;
		h ) showUsage
			exit 1;;		
	esac
done

begin
# If shortname is different from userid - migrate home directory to match userid and update group id and ownership
begin
StatusMSG $ScriptName "Updating Inventory..." uiphase
StatusMSG $ScriptName "This process may take several minutes..." uistatus

$jamf recon >>"$LogFile"

die 0
