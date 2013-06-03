#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			checkUser
# 		DESCRIPTION:  	This script attempts to update the KeyChain password for the user to  
#               		match their Genentech password; If unsuccessful - it moves the
#						login keychain to /Library/Genentech/Centrify/username.login.keychain.backup
#               
# 		LOCATION: 		Mac AD Utility Script --> /Library/Genentech/Centrify/.scripts
#		USAGE:			changeKeychainPassword.sh <username> <old password> <new password>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	10/14/2010
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

exec 2>>"$LogFile"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"


declare UserName="$1"

# Commands Required by this Script
declare -x awk="/usr/bin/awk"
declare -x dscl="/usr/bin/dscl"
declare -x id="/usr/bin/id"
declare -x CentrifyUser="$($dscl . -read /Users/$UserName AuthenticationAuthority | grep -m1 -o "Centrify")"
echo $IsCentrifyUser
	if [ "$CentrifyUser" == "Centrify" ] ; then
		StatusMSG $FUNCNAME  "User ($UserName) is a Centrify cached account"
		exit 0
	else
        	StatusMSG $FUNCNAME  "User ($UserName) is not a Centrify cached account"
		exit 1
	fi
