#!/bin/bash
# set -x
# ABOVE: Uncomment to turn on debug
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"
###############################################################################################
# 		NAME: 			changeKeychainPassword.sh
#
# 		DESCRIPTION:  	This script attempts to update the KeyChain password for the user to  
#               		match their Genentech password; If unsuccessful - it moves the
#						login keychain to ~/Library/Genentech/username.login.keychain.backup
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
	FatalError "No arguments Given, but required for $ScriptName"
	
# Quickly define proper usage of this script
usage="$0 -u Username -p NewPass -o OldPass"

# Parse the input options...
while getopts "u:p:o:n: h" CredInputs; do
	case $CredInputs in
		u ) Username="$OPTARG" ;;
		n ) NewUserName="$OPTARG" ;;
		p ) NewPass="$OPTARG" ;;
		o ) OldPass="$OPTARG" ;;
		h ) echo $usage
			exit 1;;
		* ) usage
			exit 1;;			
	esac
done
if [ "${#NewUserName}" -eq 0 ]; then
	export NewUserName="$Username"
fi

setInstallPercentage 0.00	
begin
StatusMSG $ScriptName "Updating your Keychain password..." uiphase
setInstallPercentage 10.00		

# Commands used by this script
declare -x mv="/bin/mv"
declare -x chown="/usr/sbin/chown"
declare -x security="/usr/bin/security"
declare -x LoginKeychain="/Users/$Username/Library/Keychains/login.keychain"

if [ ! -e "$LoginKeychain" ]; then
	StatusMSG $FUNCNAME "Keychain $LoginKeychain does not exist - Skipping"
	setInstallPercentage 30.00
	StatusMSG $ScriptName "Login Keychain NOT FOUND; Skipping." uistatus
else
	setInstallPercentage 40.00
	StatusMSG $ScriptName "Login Keychain FOUND" uistatus		
	StatusMSG $FUNCNAME "Attempting to Update login.keychain password"
	StatusMSG $ScriptName "Updating Login Keychain To New Password" uistatus
	# ZS Add check for Passwords being the same on the system
	if [ "$OldPass" = "$NewPass" ] ; then
		StatusMSG $ScriptName "Old and New Passwords Match, No Action Necessary"
	else
		if $security 'set-keychain-password' -o "$OldPass" -p "$NewPass" "${LoginKeychain:?}" ; then
			StatusMSG $ScriptName "Keychain Updated Successfully"
			$security set-keychain-settings "$LoginKeychain" &&
				StatusMSG $ScriptName "Disabling Auto-Lock and Sleep Lock"
		else
			if $security 'set-keychain-password' -o "$NewPass" -p "$NewPass" "${LoginKeychain:?}" ; then
				StatusMSG $ScriptName "Keychain Updated Successfully"
				$security set-keychain-settings "$LoginKeychain" &&
					StatusMSG $ScriptName "Disabling Auto-Lock and Sleep Lock"
			else		
					
				StatusMSG $ScriptName "Updating User Keychain Failed, Creating New Keychain"
				$mv "${LoginKeychain:?}" "/Users/Shared/$Username.login.keychain.backup"
				$security create-keychain -p "$NewPass" "$LoginKeychain" &&
					StatusMSG $ScriptName "Created New Keychain: $LoginKeychain"
					$security default-keychain -s "$LoginKeychain" &&
					StatusMSG $ScriptName "Set $LoginKeychain as default"
					$security set-keychain-settings "$LoginKeychain" &&
					StatusMSG $ScriptName "Disabling Auto-Lock and Sleep Lock"
			fi	

		fi
		
	fi
	if [ -f "${LoginKeychain:?}" ]; then
		StatusMSG $FUNCNAME "Successfully Updated Login Keychain Password"
		$chown "$NewUserName:admin" "$LoginKeychain" &&
			StatusMSG $FUNCNAME "Successfully Updated Ownership to $NewUserName:admin"
			StatusMSG $ScriptName "Successfully Synchronized Login Keychain Password" uistatus
	else
		StatusMSG $FUNCNAME "Failed updating keychain password.  Moved KeyChain to /Users/Shared/$Username.login.keychain.backup"
		StatusMSG $ScriptName "Failed updating login Keychain password." uistatus
		# Added to warn on new Keychain password failures
		die 1	
	fi
	setInstallPercentage 70.00
fi
setInstallPercentage 90.00		

die 0