#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			createMacTempUser.sh
#
# 		DESCRIPTION:  	This script creates the macaduser temp user account
#               
#		USAGE:			createMacTempUser.sh <password>
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

PassWord="$1"

# GUID Code and rem others
declare -x awk="/usr/bin/awk"
declare -x cp="/bin/cp"
declare -x chown="/usr/sbin/chown"
declare -x dscl="/usr/bin/dscl"
declare -x defaults="/usr/bin/defaults"
declare -x uuidgen="/usr/bin/uuidgen"
declare -x id="/usr/bin/id"
declare -x mkdir="/bin/mkdir"

declare -x TMP_USER="macaduser"

CreateTempUser(){
	
	# Rename HD to Macintosh HD for later adfixid tasks
	diskutil rename / Macintosh\ HD &&
		StatusMSG $FUNCNAME "Renamed HD to Macintosh HD."
	
	# Generate a new GUID as to not conflict with the old user
	export NewUserGUID="`$uuidgen`"
	
	# ABOVE: This really does not do much but can be left in the script
	StatusMSG $FUNCNAME "Hiding users under 500 from the login window"
	
	$defaults write /Library/Preferences/com.apple.loginwindow Hide500Users - bool 

    # Create new hidden backup user
	if ! $id macauthtmp 2>/dev/null ; then
		$dscl . -create /Users/$TMP_USER
		$dscl . -create /Users/$TMP_USER RealName "backup"
		$dscl . -create /Users/$TMP_USER UniqueID 505 # ${OrginalUID:-"501"} 
		$dscl . -create /Users/$TMP_USER NFSHomeDirectory /tmp/$TMP_USER
		$dscl . -create /Users/$TMP_USER PrimaryGroupID 80
		$dscl . -create /Users/$TMP_USER GeneratedUID $NewUserGUID
		$dscl . -passwd /Users/$TMP_USER "$PassWord"
		$dscl . -merge /Groups/admin GroupMembership $TMP_USER
		FlushCache
	else
		StatusMSG $FUNCNAME "macaduser user already exists"
		$dscl . -delete /Users/$TMP_USER
		$dscl . -create /Users/$TMP_USER
		$dscl . -create /Users/$TMP_USER RealName "backup"
		$dscl . -create /Users/$TMP_USER UniqueID 505 # ${OrginalUID:-"501"} 
		$dscl . -create /Users/$TMP_USER NFSHomeDirectory /tmp/$TMP_USER
		$dscl . -create /Users/$TMP_USER PrimaryGroupID 80
		$dscl . -create /Users/$TMP_USER GeneratedUID $NewUserGUID
		$dscl . -passwd /Users/$TMP_USER "$PassWord"
		$dscl . -merge /Groups/admin GroupMembership $TMP_USER
		FlushCache
	fi

	
	# This step ensures that Centrify has left the domain and is uninstalled
	if $id $TMP_USER ; then

        if [ -e /usr/share/centrifydc/bin/centrifydc ]; then
            adleave --force
            /usr/share/centrifydc/bin/uninstall.sh -n -e
        fi

        if [ -e /usr/share/centrifydc/bin/centrifydc ]; then
            die 1
        else
            die 0
        fi
       
	fi
}

begin
CreateTempUser
die 0
