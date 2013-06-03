#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			migrateAccount.sh
#
# 		DESCRIPTION:  	This script adds users to privileged users list on machine and migrates 
#               		the local user account to use AD for authentication
#               
#		USAGE:			migrateAccount.sh <Genentech UNIXID> <Mac shortname>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/16/2013
###############################################################################################
# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"


# Sanity Checks

[ $# = 0 ] &&
	FatalError "No Arguments Given but Required for $ScriptName"

[ "$EUID" != 0 ] && 
	printf "%s\n" "This Script Requires Root Access!" && exit 1

# Positional parameters passed to the script

UnixId="$1"
LocalUser="$2"

# Migrate local user account to use AD for authentication
ModifyLocalUser(){
	setInstallPercentage $CurrentPercentage.55
	# Get the local user's GUID
	[ ${#LocalUser} -eq 0 ] &&
		FatalError "Missing parameter LocalUser=($LocalUser)"

	setInstallPercentage $CurrentPercentage.70
	
		$dscl . -delete /Users/$LocalUser ||
			StatusMSG $FUNCNAME "FAILED - Unable to Delete Local User: $LocalUser"
		$dscacheutil -flushcache

	StatusMSG $FUNCNAME "SUCCESS - Deleted Local User: $LocalUser"
	setInstallPercentage $CurrentPercentage.90
	sleep 2
} # END ModifyLocalUser()

# If shortname is different from userid - migrate home directory to match userid and update group id and ownership
begin
StatusMSG $ScriptName "Migrating User Account..." uiphase
sleep 2
setInstallPercentage 10.00
sleep 2
setInstallPercentage 50.00
ModifyLocalUser
die 0
