#!/bin/bash
#set -x
# ABOVE: Uncomment to turn on debug
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"
###############################################################################################
# 		NAME: 			changeKeychainPassword.sh
#
# 		DESCRIPTION:  	This script attempts to update the KeyChain password for the user to  
#               		match their Genentech password; If unsuccessful - it moves the
#						login keychain to /Library/gInstall/MacADUtility/username.login.keychain.backup
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
	FatalError "No arguments Given, but required for $ScriptName"

declare -x Username="$1"
declare -x OldPass="$2"
declare -x NewPass="$3"
declare -x NewUserName="$4"

begin
StatusMSG $ScriptName "Updating Keychain..." uiphase &&
	setInstallPercentage 10.00		

# Commands used by this script
declare -x mv="/bin/mv"
declare -x chown="/usr/sbin/chown"
declare -x security="/usr/bin/security"
declare -x LoginKeychain="/Users/$Username/Library/Keychains/login.keychain"

if [ ! -e ${LoginKeychain:?} ]; then
	StatusMSG $FUNCNAME "Keychain $LoginKeychain does not exist; no action needed."
else
	setInstallPercentage 50.00		
	StatusMSG $FUNCNAME "Attempting to update login.keychain password to match the users Genentech password"
	$security 'set-keychain-password' -o "$OldPass" -p "$NewPass" "${LoginKeychain:?}" ||
		$mv "${LoginKeychain:?}" "/Library/Genentech/Centrify/$Username.login.keychain.backup"			

	if [ -f ${LoginKeychain:?} ]; then
		StatusMSG $FUNCNAME "Successfully updated login.keychain password to match the users Genentech password"
		$chown "$NewUserName:admin" "$LoginKeychain" &&
			StatusMSG $FUNCNAME "Successfully updated ownership of login.keychain to $NewUserName:admin"
	else
		StatusMSG $FUNCNAME "Failed updating keychain password.  Moved KeyChain to /Library/Genentech/Centrify/$Username.login.keychain.backup"	
	fi
	setInstallPercentage 70.00
fi
setInstallPercentage 80.00		

die 0
