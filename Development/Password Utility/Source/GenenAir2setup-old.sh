#!/bin/bash
# set -x	# DEBUG. Display commands and their arguments as they are executed
# set -v	# VERBOSE. Display shell input lines as they are read.
# set -n	# EVALUATE. Check syntax of the script but dont execute
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"

#===============================================================================
#
#          FILE:  GenenAir2setup.sh
#
#         USAGE:  ./GenenAir2setup.sh [-u username] [-p password]
#
#   DESCRIPTION:  Properly configures a 10.5.x+ machine for GenenAir2. 
#
#          BUGS:  See below. 
#         NOTES:  Based on the following script: http://code.google.com/p/leopard-8021xconfig/
#                 Added support for Mac OS X 10.6.x
#       CREATOR:  Kevin Bernstein: berny@gene.com
#       COMPANY:  Genentech, Inc.
#       VERSION:  1.2.3
#       CREATED:  12/23/2008 10:31 PM
#  LAST REVISED:  11/18/2009 11:57 AM (Kevin Bernstein) 
#     CHANGELOG:
#			* AREK: Added KeyChainsPermsFix() to fix ownership of login.keychain - 
#			  caused issues saving new keys post-configuration
#			* AREK: Created a new directory (~/Library/Genentech) to move Preferences_backup.zip
#			  from the root of the drive to a less visible location
#			* AREK: Fixed the for-loops logic in RemoveOldGenenAir2_FromAirportPref, RemoveIncorrectNetworks,
#			  and RemoveOldGenenAir2_FromPrefs as they did not remove all networks on run
#			* AREK: Added Keychain key removal function for items that contain GenenAir1, GenenAir2, 
#			  GenenAir3, guestwlan, and pda-wlan (running the script did not clean out old keys 
#			  and would create a new one each time)
#			* AREK: Added GenenAir1, GenenAir3, guestwlan, pda-wlan into the com.apple.eap.profiles.plist 
#			  cleaning function (noticed these types of configurations affected functionality in the 
#			  field after the tool was run)
#			* AREK: Added port definition variable to support MacBook Air en0 Airport configurations
#			* 11/17 KEVIN: Updated MacBookAir variable to a faster, less impactful command. 
#			  Drive no longer spins up
#			* 11/17 KEVIN: Added a check for 10.6, adjusting power on/off scripts
#			* 11/17 KEVIN: Found a new way to create the keychain item. Implemented code
#			* 11/17 KEVIN: Update functions to power on/off. Changed path of GenenAir2Configured.done to
#			  a standard location that will show up in Casper
#			* 11/17 ZS:Removed reference to KeyChainsPermsFix function as it was missing
#			* 11/17 ZS:Removed echo's with StatusMSG logging function

#===============================================================================


declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

exec 2>>"$LogFile"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName"
	
StatusMSG $ScriptName "Processing options $@"
StatusMSG $ScriptName "Running as LOGNAME=$LOGNAME"
StatusMSG $ScriptName "Running as USER=$USER"

# Quickly define proper usage of this script
usage="GenenAir2setup.sh -u UNIXusername -p UNIXpassword"

# Parse the input options...
while getopts "u:p:o: h" CredInputs; do
	case $CredInputs in
		u ) UNIXuser="$OPTARG" ;;
		p ) UNIXpass="$OPTARG" ;;
		o ) NotUsed="$OPTARG" ;;
		h ) echo $usage
			exit 1;;
		* ) usage
			exit 1;;			
	esac
done

StatusMSG $ScriptName "Was passed Username: $UNIXuser"
#StatusMSG $ScriptName "Was passed Password: $UNIXpass"


# Commands used by this script
declare -x awk="/usr/bin/awk"
declare -x ps="/bin/ps"
declare -x PlistBuddy="/usr/libexec/PlistBuddy"
declare -x launchctl="/bin/launchctl"
declare -x ifconfig="/sbin/ifconfig"
declare -x mkdir=" /bin/mkdir"
declare -x defaults="/usr/bin/defaults"
declare -x uuidgen="/usr/bin/uuidgen"
declare -x security="/usr/bin/security"
declare -x sysctl="/usr/sbin/sysctl"
declare -x networksetup="/usr/sbin/networksetup"
declare -x profiles="/usr/bin/profiles"
declare -x rm="/bin/rm"
declare -x sudo="/usr/bin/sudo"
declare -x who="/usr/bin/who"

# Other
declare -x eapolclient="/System/Library/SystemConfiguration/EAPOLController.bundle/Contents/Resources/eapolclient"

# Custom Commands
declare -x mcedit="$RunDirectory/mcedit.py"
declare -x platformExpert="$RunDirectory/platformExpert"

# Paths used by this script
export Preferences="/Library/Preferences/SystemConfiguration/preferences.plist"

# The SSID Used by this script
export SSID="GenenAir2"
export SSID_REMOVE="GenenAir3"
# The security type (man networksetup)
export SECT="WPA2E"

# Get our profile name from our SSID ( do not single quote ).
declare -x Profile_Name="$SSID"
declare -x Profile_Template="$RunDirectory/$Profile_Name.mobileconfig"
declare -x Profile_Modified="/tmp/.$UNIXuser-$Profile_Name.mobileconfig"

# Added to support MacBook Air (en0 is default for Airport, not en1)
port="en1"
checkIfMBA="`sysctl hw.model |
						grep -o -m1 Air`"
if [[ "${#checkIfMBA}" -gt 0 ]]; then
	port="en0"
	StatusMSG $ScriptName "This is a MacBook Air - Wireless set to $port" uistatus
fi	

AirAddresswithColons=`$ifconfig $port |
					$awk '/ether/ { gsub(":", "\\\\:"); print $2 }'`
AirAddresswithColons2=`$ifconfig $port |
					$awk '/ether/ { gsub(":", "\\:"); print $2 }'`
					
export NETWORKUUID="$($uuidgen)"
StatusMSG $ScriptName "Generated NETWORKUUID: ($NETWORKUUID)"


# Generated a new EAP UUID
export EAPUUID="$($uuidgen)"
# Get the console users name
export CONSOLE_USER="$($who |
						$awk '/console/{print $1}')"
StatusMSG $ScriptName "Generated EAPUUID: ($EAPUUID)"

# Dynamically set the Leopard UUID for the ByHost file naming

# ZS: Added platformExpert a simple IOKit wrapper, this key is a string. Tested on 10.5+
# ZS: Adding redirection of standard error for this command
export LEOUUID="$("$platformExpert" IOPlatformUUID 2>&1)"

StatusMSG $ScriptName "Found IOPlatformUUID: ($LEOUUID)"

export EAPBindings="Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist"
# ZS: Removed ScriptDir var as it is redundant and not in user anywhere in the script

# AS: Added to support MacBook Air (en0 is default for Airport, not en1)
# KB: Adjusted so that it does not activate system profiler and thus the CD spinup
# KB: Added to check for 10.6
# ZS: Updated to use SystemVersion.plist rather then the loginwindow.plist
MacOSVer=`$defaults read /System/Library/CoreServices/SystemVersion ProductUserVisibleVersion |
																			$awk -F'.' '{print $1"."$2}'`
StatusMSG $ScriptName "Found MacOSVer: ($MacOSVer)"

LOCALUSER=`logname`
StatusMSG $ScriptName "Found LOCALUSER: ($LOCALUSER)"


# * * * * * * * * * * * * * * * D E F I N E  F U N C T I O N S * * * * * * * * * * * * * * * * * * * * * * 
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
AddPreferredWirelessNetwork() {
	if [ $MacOSVer == "10.5" ]; then
		StatusMSG $ScriptName "10.5 machines will have their preferred networks added via plist"
	else
		StatusMSG $ScriptName "Removing & Re-adding $SSID at index 0"
		$sudo -u root $networksetup -removepreferredwirelessnetwork "$port" "$SSID" >> "${LogFile:?}"
		$sudo -u root $networksetup -addpreferredwirelessnetworkatindex "$port" "$SSID" 0 "$SECT" >> "${LogFile:?}"
	fi
}


RemoveWirelessNetwork(){
	if [ $MacOSVer == "10.5" ]; then
		StatusMSG $ScriptName "10.5 machines will have their preferred networks added via plist"
	else
		StatusMSG $ScriptName "Removing $SSID_REMOVE"
		$sudo -u root $networksetup -removepreferredwirelessnetwork "$port" "$SSID_REMOVE" >> "${LogFile:?}"
		# Account was set SSID in my keychain but Airport for System so we try both
		$sudo -u root security delete-generic-password -D 'AirPort network password' -a "$SSID_REMOVE" -l "$SSID_REMOVE"
		$sudo -u root security delete-generic-password -D 'AirPort network password' -a "Airport" -l "$SSID_REMOVE"
		# Attempt to remove for users keychain
		if [ "${#CONSOLE_USER}" -gt 0 ] ; then
			$sudo -u "$CONSOLE_USER" security delete-generic-password -D 'AirPort network password' -a "$SSID_REMOVE" -l "$SSID_REMOVE"
			$sudo -u "$CONSOLE_USER" security delete-generic-password -D 'AirPort network password' -a "Airport" -l "$SSID_REMOVE"
		fi

	fi
}

PowerAirportOn() {
	StatusMSG $ScriptName "Turning Airport ON" uistatus
	if [[ $MacOSVer == "10.5" ]]; then
		$sudo -u root $networksetup -setairportpower on
		sleep 5
	else
		$sudo -u root $networksetup -setairportpower $port on
		#ifconfig $port up
	fi
}

PowerAirportOff() {
	StatusMSG $ScriptName "Turning Airport OFF" uistatus
	if [[ $MacOSVer == "10.5" ]]; then
		$sudo -u root $networksetup -setairportpower off
		sleep 5
	else
		$sudo -u root $networksetup -setairportpower $port off
		#ifconfig $port down
	fi
}

QuitSystemPreferences() {
	if [[ `ps aux | grep "System Preferences" | grep -v grep | awk {'print $2'}` != "" ]]; then
		StatusMSG $ScriptName "Quitting System Preferences" uistatus
		kill `ps aux | grep "System Preferences" | grep -v grep | awk {'print $2'}`
		while [[ `ps aux | grep "System Preferences" | grep -v grep | awk {'print $2'}` != "" ]]; do
			sleep 1
		done		
	fi
}

CopyPlistBuddy() {
	/bin/echo `/bin/date` \*\*\*\* Copying PlistBuddy to /usr/libexec/ \*\*\*\*
	if [[ ! -e /usr/libexec/PlistBuddy ]]; then
		ditto "$ScriptDir/PlistBuddy" /usr/libexec/PlistBuddy
		if [[ ! -e /usr/libexec/PlistBuddy ]]; then
			exit 5
		fi
	# else
	# 	echo "PlistBuddy is already installed"
	fi
}

CopyCerts() {
	if [[ `ls -1 /Library/Genentech/certs | wc -l` -lt 5 ]]; then
		/bin/echo `/bin/date` \*\*\*\* Copying Certs to /Library/Genentech/ \*\*\*\*
		mkdir -p /Library/Genentech
		ditto "$ScriptDir/certs/" /Library/Genentech/certs
	fi
}

CleanNetworksSettings() {
	StatusMSG $ScriptName "Cleaning out the CURRENT System-Level Config" uistatus
	theSets=(`$PlistBuddy -c "Print :Sets" $Preferences | egrep -a "= Dict {$" | sed -n '/^.\{45\}/p' | sed '/^.\{50\}/d' | awk {'print $1'}`)
	for eachSet in ${theSets[@]}; do
		theOldPreferredNetworks=(`$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks" $Preferences | egrep -a "Dict {$" | awk {'print $1'}`)
		for (( i = 0; i < ${#theOldPreferredNetworks[@]}; i++ )); do
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir1'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir2'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir3'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'guestwlan'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'pda-wlan'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:AirPort:PreferredNetworks:$i" $Preferences
			fi
		done	
		
		setInstallPercentage 20.00
		theNewPreferredNetworks=(`$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks" $Preferences | egrep -a "Dict {$" | awk {'print $1'}`)
		for (( i = 0; i < ${#theNewPreferredNetworks[@]}; i++ )); do
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir1'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir2'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'GenenAir3'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'guestwlan'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i" $Preferences
			fi
			if [[ `$PlistBuddy -c "Print Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i:SSID_STR" $Preferences | grep 'pda-wlan'` != "" ]]; then
					$PlistBuddy -c "Delete Sets:$eachSet:Network:Interface:$port:AirPort:PreferredNetworks:$i" $Preferences
			fi
		done	
	done
	
	setInstallPercentage 30.00
	theKnownNetworks=(`$PlistBuddy -c "Print :KnownNetworks" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | egrep -a "= Dict {$" | sed -n '/^.\{45\}/p' | sed '/^.\{50\}/d' | awk {'print $1'}`)
	for eachKnownNetwork in ${theKnownNetworks[@]}; do
		if [[ `$PlistBuddy -c "Print :KnownNetworks:$eachKnownNetwork:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir1'` != "" ]]; then
				$PlistBuddy -c "Delete :KnownNetworks:$eachKnownNetwork" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :KnownNetworks:$eachKnownNetwork:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir2'` != "" ]]; then
				$PlistBuddy -c "Delete :KnownNetworks:$eachKnownNetwork" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :KnownNetworks:$eachKnownNetwork:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir3'` != "" ]]; then
				$PlistBuddy -c "Delete :KnownNetworks:$eachKnownNetwork" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :KnownNetworks:$eachKnownNetwork:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'guestwlan'` != "" ]]; then
				$PlistBuddy -c "Delete :KnownNetworks:$eachKnownNetwork" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :KnownNetworks:$eachKnownNetwork:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'pda-wlan'` != "" ]]; then
				$PlistBuddy -c "Delete :KnownNetworks:$eachKnownNetwork" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
	done

	theRecentNetworks=(`$PlistBuddy -c "Print $port:RecentNetworks" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | egrep -a "Dict {$" | awk {'print $1'}`)
	for (( i = 0; i < ${#theRecentNetworks[@]}; i++ )); do
		if [[ `$PlistBuddy -c "Print :$port:RecentNetworks:$i:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir1'` != "" ]]; then
				$PlistBuddy -c "Delete :$port:RecentNetworks:$i" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :$port:RecentNetworks:$i:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir2'` != "" ]]; then
			$PlistBuddy -c "Delete :$port:RecentNetworks:$i" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :$port:RecentNetworks:$i:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'GenenAir3'` != "" ]]; then
			$PlistBuddy -c "Delete :$port:RecentNetworks:$i" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :$port:RecentNetworks:$i:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'guestwlan'` != "" ]]; then
			$PlistBuddy -c "Delete :$port:RecentNetworks:$i" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
		if [[ `$PlistBuddy -c "Print :$port:RecentNetworks:$i:SSID_STR" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | grep 'pda-wlan'` != "" ]]; then
			$PlistBuddy -c "Delete :$port:RecentNetworks:$i" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
		fi
	done
	setInstallPercentage 40.00
	# Verify that everything is cleared out 
	if [[ `cat /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist | egrep 'GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan'` != "" ]]; then
		echo " > Ooops! /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist still contains GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan!"
	else
		echo " > Looks like we successfully deleted GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan from /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist"
	fi
	if [[ `cat $Preferences | egrep 'GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan'` != "" ]]; then
		echo " > Ooops! $Preferences still contains GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan!"
	else
		echo " > Looks like we successfully deleted GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan from $Preferences"
	fi
}

CleanUserSettings() {
	StatusMSG $ScriptName "Cleaning out the CURRENT User-Level GenenAir2 Config" uistatus
	StatusMSG $ScriptName "`/bin/date` **** Starting on Cleaning User Settings ****"
	userList=(`/bin/ls /Users | /usr/bin/grep -E -v '(Shared|Desktop|^\.)'`)  #Get list of all user accounts on the computer
	#Complete for every user account in userList
	for userAccount in ${userList[@]}; do
		# Archive the User's settings...
		declare EAP_BINDING_PLIST="/Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.${LEOUUID:?}.plist"
		cd /Users/$userAccount/Library/Preferences/
		zip EAPProfile_backup /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		zip EAPBinding_backup "$EAP_BINDING_PLIST"
		if [ -f "$EAP_BINDING_PLIST" ] ; then
			rm "$EAP_BINDING_PLIST"
		fi
		rm /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist

	# 	# Cleaning the User's EAP settings...
	# 	/bin/echo `/bin/date` \*\*\*\* Cleaning the User EAPProfile Settings for $userAccount \*\*\*\*
	# 	EAPItems=`$PlistBuddy -c "Print :Profiles" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist | egrep -a "Dict {$" | sed '/^.\{11\}/d' | wc -l`
	# 	for (( i = 0; i < $EAPItems; i++ )); do
	# 		if [[ `$PlistBuddy -c "Print :Profiles:$i" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist | egrep 'GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan'` != "" ]]; then
	# 			$PlistBuddy -c "Delete :Profiles:$i" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
	# 		fi
	# 	done
	# 	/bin/echo `/bin/date` \*\*\*\* Cleaning the User EAPBindings Settings for $userAccount \*\*\*\*
	# 	# EAPBindingItems=(`defaults read /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID $AirAddresswithColons | egrep -a "Wireless Network"`)		# 
	# 	# EAPBindingItems=(`$PlistBuddy -c "Print :$AirAddresswithColons2" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist | egrep -a "Dict {$"`)
	# 	for (( i = 0; i < ${#EAPBindingItems[@]}; i++ )); do
	# 		if [[ `$PlistBuddy -c "Print :"$AirAddresswithColons2":$i:Wireless\ Network" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist | egrep 'GenenAir2|guestwlan|GenenAir1|GenenAir3|pda-wlan'` != "" ]]; then
	# 			$PlistBuddy -c "Delete :"$AirAddresswithColons2":$i" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
	# 		fi	
	# 	done
	done
}

CleanAllSettings() {
	CleanNetworkSettings
	CleanUserSettings
}


SetCorrectNetworkSystem() {
	StatusMSG $ScriptName "Creating the CORRECT System-Level GenenAir2 Config" uistatus
	$mkdir -p ~/Library/Genentech/
	StatusMSG $ScriptName "`/bin/date` **** Building the PreferredNetworks settings in $Preferences ****"
	zip Preferences_backup $Preferences # Archive the existing file...
	mv /Preferences_backup.zip "$HOME/Library/Genentech/"
   
	theSets=(`$PlistBuddy -c "Print :Sets" $Preferences | egrep -a "= Dict {$" |  sed -n '/^.\{45\}/p' | sed '/^.\{50\}/d' | awk {'print $1'}`)
	NUMtheSets=(`$PlistBuddy -c "Print :Sets" $Preferences | egrep -a "= Dict {$" |  sed -n '/^.\{45\}/p' | sed '/^.\{50\}/d' | awk {'print $1'} | wc -l`)
	for (( i = 0; i < ${#theSets[@]}; i++ )); do
		#Setup the Preferred Networks the Old way
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:AirPort:PreferredNetworks array" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:AirPort:PreferredNetworks:0 dict" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:AirPort:PreferredNetworks:0:SSID_STR string GenenAir2" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:AirPort:PreferredNetworks:0:SecurityType string WPA2 Enterprise" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:AirPort:PreferredNetworks:0:Unique\ Network\ ID string $NETWORKUUID" $Preferences
		#Setup the Preferred Networks the New way. Old and New should not interfere
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:$port:AirPort:PreferredNetworks array" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:$port:AirPort:PreferredNetworks:0 dict" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:$port:AirPort:PreferredNetworks:0:SSID_STR string GenenAir2" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:$port:AirPort:PreferredNetworks:0:SecurityType string WPA2 Enterprise" $Preferences
		$PlistBuddy -c "Add Sets:${theSets[$i]}:Network:Interface:$port:AirPort:PreferredNetworks:0:Unique\ Network\ ID string $NETWORKUUID" $Preferences
	done

	StatusMSG $ScriptName "`/bin/date` **** Starting on /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist ****"
	cd /Library/Preferences/SystemConfiguration/
	zip AirportPref_backup /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist     # Archive the existing file, just in case...
	$PlistBuddy -c "Add :KnownNetworks dict" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID dict" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:Remembered\ channels array" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:Remembered\ channels:0 integer 6" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:Remembered\ channels:0 integer 11" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:SSID_STR string GenenAir2" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:SecurityType string 802.1X\ WPA2 Enterprise" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :KnownNetworks:$NETWORKUUID:_timeStamp date `date`" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist

	$PlistBuddy -c "Add :$port dict" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :$port:RecentNetworks array" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :$port:RecentNetworks:0 dict" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :$port:RecentNetworks:0:SSID_STR string GenenAir2" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :$port:RecentNetworks:0:SecurityType string 802.1X\ WPA2 Enterprise" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	$PlistBuddy -c "Add :$port:RecentNetworks:0:Unique\ Network\ ID string $NETWORKUUID" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
}

PermsFix() {
	chown root:staff /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	chown root:staff $Preferences
	chmod 644 /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	chmod 644 $Preferences
	# Change ownership of login.keychain back to the user
	chown $USER:staff /Users/$USER/Library/Keychains/login.keychain
}

UserSettings() {
	StatusMSG $ScriptName "Creating the CORRECT User-Level GenenAir2 Config" uistatus
	StatusMSG $ScriptName "`/bin/date` **** Configuring User Settings ****"
	userList=(`/bin/ls /Users | /usr/bin/grep -E -v '(Shared|Desktop|^\.)'`)  #Get list of all user accounts on the computer
	#Complete for every user account in userList
	for userAccount in ${userList[@]}; do
		# Setting the User's EAP settings....
		StatusMSG $ScriptName "`/bin/date` **** Setting the User EAPProfile Settings for $userAccount ****"
		$PlistBuddy -c "Add :Profiles array" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0 dict" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:ConnectByDefault bool Yes" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:EAPClientConfiguration dict" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:EAPClientConfiguration:AcceptEAPTypes array" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:EAPClientConfiguration:AcceptEAPTypes:0 integer 25" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:EAPClientConfiguration:UserName string $UNIXuser" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:EAPClientConfiguration:UserPasswordKeychainItemID string $EAPUUID" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:UniqueIdentifier string $EAPUUID" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:UserDefinedName string GenenAir2-$UNIXuser" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		$PlistBuddy -c "Add :Profiles:0:Wireless\ Network string GenenAir2" /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist
		/usr/sbin/chown $userAccount:staff /Users/$userAccount/Library/Preferences/com.apple.eap.profiles.plist #Set the ownership of Library/Preferences/com.apple.eap.profiles.plist
		
		StatusMSG $ScriptName "`/bin/date` **** Setting the User EAPBindings Settings for $userAccount ****"
		$PlistBuddy -c "Add :"$AirAddresswithColons" array" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
		$PlistBuddy -c "Add :"$AirAddresswithColons":0 dict" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
		$PlistBuddy -c "Add :"$AirAddresswithColons":0:UniqueIdentifier string $EAPUUID" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
		$PlistBuddy -c "Add :"$AirAddresswithColons":0:Wireless\ Network string GenenAir2" /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
		/usr/sbin/chown $userAccount:staff /Users/$userAccount/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist		#Set the ownership of Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
	done
}
CertImport() {
	/bin/echo `/bin/date` \*\*\*\* Importing the *.gene.com certificate \*\*\*\*
	SYSTEMKEYCHAIN="/Library/Keychains/System.keychain"
	CERTDIR="/Library/Genentech/certs"

	## REMOVED AS I WILL BE EXPLICITING INSTALLING THE DIR AND FILES
	mkdir -p /Library/Genentech/certs    # is the CertDir present?  If not, let's create it
	# is the CertDir empty?  If not, let's go get it	
	# TODO: find the syntax to download the contents of a directory, wo specifying the file name specifically
	# if [[ `ls -1 $CERTDIR/*.pem` == "" ]]; then
	# 	curl -O "http://tao.gene.com/dna.pem"
	# fi

	# is the System keychain present?  If not, let's create it
	# more of a security measure. It should be there in most cases
	if [[ ! -f "$SYSTEMKEYCHAIN" ]]; then
		`/usr/sbin/systemkeychain -C`
	fi

	# make sure default system identities are in the system keychain
	certtool C com.apple.systemdefault u P >/dev/null 2>&1
	certtool C com.apple.kerberos.kdc u P >/dev/null 2>&1

	# get list of .pem files from $CERTDIR
	if [[ -d $CERTDIR ]]; then
		for c in `ls -1 $CERTDIR/*.pem`; do
			security add-trusted-cert -d -r trustAsRoot -p eap -k ${SYSTEMKEYCHAIN} $c 	
		done
	fi
}

SetAirportSettings() {
	StatusMSG $ScriptName "Setting the CORRECT Airport Settings" uistatus
	StatusMSG $ScriptName "`/bin/date` **** Setting Airport Prompt setting ****"
	CurrentSet=`$defaults read /Library/Preferences/SystemConfiguration/preferences CurrentSet | awk '{gsub(/\//,":");print}'`	# Set the CurrentSet to the Currently selected Network Location
	$PlistBuddy -c "Delete $CurrentSet:Network:Interface:$port:AirPort:JoinModeFallback" "$Preferences" 	# Remove any previous entry.
	$PlistBuddy -c "Add $CurrentSet:Network:Interface:$port:AirPort:JoinModeFallback array" "$Preferences" 	
	$PlistBuddy -c "Add $CurrentSet:Network:Interface:$port:AirPort:JoinModeFallback:0 string DoNothing" "$Preferences" 	# Set Airport to not ask for new networks
}

CreateKeyChain() {
	# ZS added quotes around password and paths
	# DEBUG: Added to echo password command, disable in final version.
	# ZS: Fixed syntax issue with 10.5
	# DEBUG code
	#set -x
	if [[ $MacOSVer == "10.5" ]]; then
		StatusMSG $ScriptName "Found Leopard (10.5) install"
		# Checking to see if this even does anything.
		$security add-generic-password -a $UNIXuser -p "$UNIXpass" -s $EAPUUID "/Users/$LOCALUSER/Library/Keychains/login.keychain"
	else
		StatusMSG $ScriptName "Found (10.6+) install"
		if [ -f "$eapolclient" ] ; then
			$security add-generic-password -a $UNIXuser -w "$UNIXpass" -s $EAPUUID -D "Internet Connect" -l "GenenAir2-$UNIXuser" -j "Created by the GenenAir2 wireless utility" -T /System/Library/CoreServices/SystemUIServer.app -T '/Applications/System Preferences.app' -T group://AirPort -T "$eapolclient" "/Users/$LOCALUSER/Library/Keychains/login.keychain"
		else
			$security add-generic-password -a $UNIXuser -w "$UNIXpass" -s $EAPUUID -D "Internet Connect" -l "GenenAir2-$UNIXuser" -j "Created by the GenenAir2 wireless utility" -T /System/Library/CoreServices/SystemUIServer.app -T '/Applications/System Preferences.app' -T group://AirPort "/Users/$LOCALUSER/Library/Keychains/login.keychain"
		fi
	fi
	# DEBUG code
	#set +x
}

#DEBUG ONLY
CheckDirectories() {
	open /Library/Preferences/SystemConfiguration
	open /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
	open $Preferences
	open /Users/$LOCALUSER/Library/Preferences/com.apple.eap.profiles.plist
	open /Users/$LOCALUSER/Library/Preferences/ByHost/com.apple.eap.bindings.$LEOUUID.plist
}

ProfileInstall() {
	#set -x
	# Get the Login Window PID
	declare -xi LOGIN_WINDOW_PID="$($ps -axww |
							$awk '/loginwindo[w]/{print $1}')"
	# Sanity check if its empty ( i.e. command line install?)
	StatusMSG $ScriptName "Found Loginwindow PID: $LOGIN_WINDOW_PID"
	if [ $LOGIN_WINDOW_PID -eq 0 ] ; then
			FatalError "Error finding loginwindow process ID"
	else
		# Check for profile in bundle
		if [ -f "$Profile_Template" ] ;then
			StatusMSG $ScriptName "Found Wireless Profile: $Profile_Template"
			StatusMSG $ScriptName "Modifying template with user's credentials "

			$mcedit -u "$UNIXuser" -p "$UNIXpass" -f "$Profile_Template" -w "$Profile_Modified" >> "${LogFile:?}"
			if [ -f "$Profile_Modified" ] ; then
				StatusMSG $ScriptName "Importing profile: $Profile_Modified"
				if [ "${#CONSOLE_USER}" -gt 0 ] ; then
					#$sudo -u root $profiles -I -v -f -F "$Profile_Modified" >> "${LogFile:?}" #&&
					$sudo -u $CONSOLE_USER $profiles -I -v -f -F "$Profile_Modified" >> "${LogFile:?}" &&
									$rm "${Profile_Modified:?}" >> "${LogFile:?}"
				else
					FatalError "No console user is present"
				fi
			else
				FatalError "Missing modfied template: $Profile_Modified"
			fi
		else
			FatalError "Missing wireless template: $Profile_Template"
		fi
	fi
	set +x
}

#* * * * * * * * * * * * * * * * E N D   D E F I N E   F U N C T I O N S * * * * * * * * * * * * * * * * * 
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


# * * * * * * * * * * * * * * * R U N  F U N C T I O N S * * * * * * * * * * * * * * * * * * * * * * * * *
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
StatusMSG $ScriptName "`/bin/date` **** Starting the GenenAir2 Setup functions ****"
setInstallPercentage 10.00
QuitSystemPreferences
PowerAirportOff
if [ $MacOSVer == "10.7" ]; then
	StatusMSG $ScriptName "Found Lion (10.7) install"
	ProfileInstall
else
	CleanNetworksSettings
	CleanUserSettings
	SetCorrectNetworkSystem
	setInstallPercentage 50.00
	UserSettings
	PermsFix
	setInstallPercentage 60.00	
	SetAirportSettings
	setInstallPercentage 70.00
	CreateKeyChain
	setInstallPercentage 80.00
fi
# Add the preferred network on 10.6+ and higher before we turn the network back on.
AddPreferredWirelessNetwork
# ZS Added GenenAir3 Removal
RemoveWirelessNetwork
CreateKeyChain
#KeyChainsPermsFix
touch "/tmp/GenenAir2Setup.done"
mkdir -p /Users/$USER/Library/Receipts/
touch /Users/$USER/Library/Receipts/GenenAir2.Configured

PowerAirportOn
StatusMSG $ScriptName "`/bin/date` **** Ending the functions ****"

declare -x PreferencesOld="$Preferences.old"
if [ -f "$PreferencesOld" ] ; then
	$rm "$PreferencesOld"
	# Remove the auto-created .old file for cleanliness sake, as we have an archive already
fi
setInstallPercentage 90.00
# Replaced remove com.gene bridge files with die , that does that automatically
die 0



#* * * * * * * * * * * * * * * *    E N D    R U N   F U N C T I O N S   * * * * * * * * * * * * * * * * * 
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

