#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			restoreAccount.sh
#
# 		DESCRIPTION:  	This script recreates a local user with current username and password if caching account fails
#               
#		USAGE:			restoreAccount.sh <password> <username> <olduid>
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

[ "$EUID" != 0 ] && 
	printf "%s\n" "This script requires root access!" && exit 1

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"

declare -x PassWord="$1"
declare -x Username="$2"
declare -x UID="$3"


declare -x awk="/usr/bin/awk"
declare -x cp="/bin/cp"
declare -x chown="/usr/sbin/chown"
declare -x dscl="/usr/bin/dscl"
declare -x defaults="/usr/bin/defaults"
declare -x uuidgen="/usr/bin/uuidgen"
declare -x id="/usr/bin/id"
declare -x mkdir="/bin/mkdir"



restoreUser(){
	
	# Generate a new GUID as to not conflict with the old user
	export NewUserGUID="`$uuidgen`"

    # Create new hidden backup user
	if ! $id $Username 2>/dev/null ; then
		StatusMSG $FUNCNAME "$Username Is Being Re-Created."
		$dscl . -create /Users/$Username
		$dscl . -create /Users/$Username RealName $Username
		$dscl . -create /Users/$Username UniqueID $UID
		$dscl . -create /Users/$Username NFSHomeDirectory /Users/$Username
		$dscl . -create /Users/$Username PrimaryGroupID 80
		$dscl . -create /Users/$Username GeneratedUID $NewUserGUID
		$dscl . -passwd /Users/$Username "$PassWord"
		$dscl . -merge /Groups/admin GroupMembership $Username
		FlushCache
	else
		
		StatusMSG $FUNCNAME "$Username Already Partially Exists."
		$dscl . -delete /Users/$Username
		$dscl . -create /Users/$Username
		$dscl . -create /Users/$Username RealName $Username
		$dscl . -create /Users/$Username UniqueID $UID
		$dscl . -create /Users/$Username NFSHomeDirectory /Users/$Username
		$dscl . -create /Users/$Username PrimaryGroupID 80
		$dscl . -create /Users/$Username GeneratedUID $NewUserGUID
		$dscl . -passwd /Users/$Username "$PassWord"
		$dscl . -merge /Groups/admin GroupMembership $Username	
		
	fi

}

begin
restoreUser
die 0
