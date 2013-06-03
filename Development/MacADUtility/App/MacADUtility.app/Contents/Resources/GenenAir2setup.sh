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
#   DESCRIPTION:  Properly configures a 10.7.x+ machine for GenenAir2. 
#
#          BUGS:  See below. 
#         NOTES:  Based on the following script: http://code.google.com/p/leopard-8021xconfig/
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

# Custom Commands
declare -x mcedit="$RunDirectory/mcedit.py"
declare -x platformExpert="$RunDirectory/platformExpert"

# The SSID Used by this script
export SSID="GenenAir2"
# The security type (man networksetup)
export SECT="WPA2E"

# Get our profile name from our SSID ( do not single quote ).
declare -x Profile_Name="$SSID"
declare -x Profile_Template="$RunDirectory/$Profile_Name.mobileconfig"
declare -x Profile_Modified="/tmp/.$UNIXuser-$Profile_Name.mobileconfig"

MacOSVer=`$defaults read /System/Library/CoreServices/SystemVersion ProductUserVisibleVersion |
																			$awk -F'.' '{print $1"."$2}'`
StatusMSG $ScriptName "Found MacOSVer: ($MacOSVer)"



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


ProfileInstall() {
	set -x
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
					$sudo -u 'root' $profiles -I -v -f -F "$Profile_Modified" >> "${LogFile:?}" &&
									$rm "${Profile_Modified:?}" >> "${LogFile:?}"
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
StatusMSG $ScriptName "`/bin/date` **** Starting the GenenAir2 Mini Setup functions ****"
setInstallPercentage 10.00
#PowerAirportOff
if [ $MacOSVer == "10.7" || $MacOSVer == "10.8" ]; then
	StatusMSG $ScriptName "Installing GenenAir2 Wireless Profile"
	ProfileInstall
else
	exit 0
fi
# Add the preferred network on 10.6+ and higher before we turn the network back on.
AddPreferredWirelessNetwork
StatusMSG $ScriptName "`/bin/date` **** Ending the functions ****"

setInstallPercentage 90.00
die 0
#* * * * * * * * * * * * * * * *    E N D    R U N   F U N C T I O N S   * * * * * * * * * * * * * * * * * 
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

