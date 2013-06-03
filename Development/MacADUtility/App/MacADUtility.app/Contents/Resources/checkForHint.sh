#!/bin/bash
# set -x
# ABOVE: Uncomment to turn on debug
###############################################################################################
# 		NAME: 			checkForHint.sh
#
# 		DESCRIPTION:  	Derives the users password hint if any, defines exit value    
#		SYNOPSIS:		./checkForHint.sh <username>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	10/11/09
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

# Redirect sterr to our logfile
exec 2>>"$LogFile"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"

declare -x LocalUser="$1"

declare -x dscl="/usr/bin/dscl"
declare -x sed="/usr/bin/sed"
declare -x id="/usr/bin/id"

dsclAuthenticationHint(){
	export  AuthenticationHint="$($dscl . -read "/Users/$LocalUser" AuthenticationHint |
															$sed '/AuthenticationHint/d')"
	if $id "$LocalUser" ; then
			StatusMSG $FUNCNAME "User:$LocalUser is a valid user"
	else
			StatusMSG $FUNCNAME "User:$LocalUser is NOT valid user"
			return 1
	fi														
	if [ "${#AuthenticationHint}" -gt 1 ] ; then
		StatusMSG $FUNCNAME "Found authentication hint ($AuthenticationHint) for user $LocalUser"
		return 0
	else
		StatusMSG $FUNCNAME "No authentication hint found for user $LocalUser"
		return 1
	fi
}

begin
dsclAuthenticationHint || die 1
die 0