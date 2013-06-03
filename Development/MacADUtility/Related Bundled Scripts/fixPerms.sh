#!/bin/bash
#set -x
###############################################################################################
# 		NAME: 			fixPerms
# 		DESCRIPTION:  	This script attempts fix user permissions on the machine
#					
#		USAGE:			fixPerms.sh <olduser> <new user> <old user UID>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	10/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/15/2013
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

exec 2>>"$LogFile"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"

LoggedInUserFix="$1"
UserNameFix="$2"
OldUIDFix="$3"

begin
# No Progress Bars here as the functions do most of that work
StatusMSG $ScriptName "Updating Permissions..." uiphase

StatusMSG $ScriptName "Updating Home Folder Ownership..." uiphase
FileOwnershipUpdate "$LoggedInUserFix" "$UserNameFix" "$OldUIDFix" &&

StatusMSG $ScriptName "Fixing Volume File Ownership..." uiphase
# Run the find command to search for all files on the HD owned by the old UID
FixHDOwnership "$LoggedInUserFix" "$UserNameFix" "$OldUIDFix" &&
die 0