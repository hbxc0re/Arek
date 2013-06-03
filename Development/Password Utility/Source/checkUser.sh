#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			checkUser
# 		DESCRIPTION:  	This script checks if a current user is a Centrify User
#               
# 		LOCATION: 		/Applications/Utities/PasswordUtility.app/Contents/Resources/
#		USAGE:			checkUser
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	10/14/2010
#						- modified by Zack Smith (zsmith@318.com)	11/27/2011
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

# Parse the input options...

# Commands Required by this Script
declare -x awk="/usr/bin/awk"
declare -x dscl="/usr/bin/dscl"
declare -x id="/usr/bin/id"
declare -x who="/usr/bin/who"

export UserName="$($who |
						$awk '/console/{print $1}')"
						
						
if $id ${UserName:?} &>/dev/null ; then
    declare -xi IsLocalUser="$($dscl . -search /Users RecordName "$UserName" 2>/dev/null|
                                $awk '{seen++}END{print seen}')"
else
	declare -xi IsLocalUser=0
fi

if [ "$IsLocalUser" -ge 1 ] ; then
	declare -xi IsCentrifyUser="$($dscl . -read /Users/$UserName AuthenticationAuthority 2>/dev/null|
					$awk -F';' '/Centrify/{seen++}END{print seen}')"
	if [ "$IsCentrifyUser" -ge 1 ] ; then
		# If we ARE an account print the username
		printf "%s" "$UserName"
	else
		printf "%s" ""
		exit 0
	fi
else
	printf "%s" ""
	exit 0
fi
