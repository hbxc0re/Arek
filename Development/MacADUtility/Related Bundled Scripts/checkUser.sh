#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			checkUser
# 		DESCRIPTION:  	This script attempts to update the KeyChain password for the user to  
#               		match their domain password; If unsuccessful - it moves the
#						login keychain to /Users/Shared/username.login.keychain.backup
#              
#		USAGE:			changeKeychainPassword.sh <username> <old password> <new password>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/15/2013
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

begin

if $id ${UserName:?} >/dev/null ; then
    declare -xi IsLocalUser="$($dscl . -search /Users RecordName "$UserName" |
                                $awk '{seen++}END{print seen}')"
	StatusMSG $FUNCNAME "Found $UserName is a valid account"
else
    StatusMSG $FUNCNAME  "User ($UserName) does not seem to be valid account name"
	declare -xi IsLocalUser=0
fi

if [ "$IsLocalUser" -ge 1 ] ; then
	StatusMSG $FUNCNAME  "Found $UserName is a local account"
	declare -x IsGENEDomainUser="$($dscl . -read /Users/$UserName AuthenticationAuthority |
					grep -o -m1 gene.com)"
	if [ "$IsGENEDomainUser" == "gene.com" ] ; then
		StatusMSG $FUNCNAME  "User ($UserName) is already a GNE AD cached account"
		die 1
	else
        	StatusMSG $FUNCNAME  "User ($UserName) is NOT a GNE AD cached account"
		die 0
	fi
	
	declare -x IsROCHEDomainUser="$($dscl . -read /Users/$UserName AuthenticationAuthority |
					grep -o -m1 roche.com)"
	if [ "$IsROCHEDomainUser" == "roche.com" ] ; then
		StatusMSG $FUNCNAME  "User ($UserName) is already a Roche AD cached account"
		die 1
	else
        	StatusMSG $FUNCNAME  "User ($UserName) is NOT a Roche AD cached account"
		die 0
	fi
else
	StatusMSG $FUNCNAME  "User ($UserName) is not a local account name"
	die 0
fi
