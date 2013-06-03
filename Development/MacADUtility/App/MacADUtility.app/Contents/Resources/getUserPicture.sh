#!/bin/bash
#set -x
###############################################################################################
# 		NAME: 			geUserPicture.sh
#
# 		DESCRIPTION:  	This script looks up the URL of the user picture
#						Downloads it and converts it for use in AppleScript
#               
# 		LOCATION: 		Mac AD Utility Script --> /Library/Genentech/Centrify/.scripts
#		USAGE:			checkADZone.sh -h
###############################################################################################
#		HISTORY:
#						- created by Zack Smith (zsmith@318.com) 	10/28/2010
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

showUsage(){
	printf "%s\n\t" "USAGE:"
	printf "%s\n\t" 
	printf "%s\n\t" " OUTPUT:"
	printf "%s\n\t" " -v | # Turn on verbose output"
	printf "\033[%s;%s;%sm%s\033[0m\n\t" "1" "44" "37" " -c | # Turn on colorized output"
	printf "\033[0m"
	printf "%s\n\t" " -l | # Get Local User Picture"
	printf "%s\n\t" " -r | # Get Remote (LDAP) User Picture"

	printf "%s\n\t" " -u | # Username (local or remote )"
#	printf "%s\n\t" " -D | # Turn on debug (all function's name will be displayed at runtime)."

	printf "%s\n\t" " OTHER TASKS:"
#	printf "%s\n\t" " -f | </path/to/$SCRIPT_NAME.conf>	# Read configuration from a conf file."
	printf "%s\n\t" " -w | </path/to/save/directory>	# Write picture(s) to this directory"
#	printf "%s\n\t" " -d | </path/to/save/dir>	# Validate users against directory: </LDAPv3/od.mycompany.com/>"
	printf "%s\n\t" " -h | # Print this usage message and quit"
	printf "%s\n\t"
	printf "%s\n\t" " EXAMPLE SYNTAX:"
	printf "%s\n\t" " sudo $0 -r -w /tmp -u zacharrs"
	printf "%s\n"
	return 0
}


if [ $# = 0 ] ; then
	showUsage
	FatalError "No arguments Given, but required for $ScriptName"
fi
	
# Check script options
StatusMSG "$ScriptName"  "Processing script $# options:$@"
while getopts clru:w:h SWITCH ; do
	case $SWITCH in
		l ) export EnableColor='YES' ;;
		l ) export UserType="Local" ;;
		r ) export UserType="Remote" ;;
		u ) export UserName="${OPTARG}" ;;
		w ) export SaveDirectory="${OPTARG}" ;;
		h ) showUsage ;;
		
	esac
done # END while

# Commands required by this script
declare -x awk="/usr/bin/awk"
declare -x ldapsearch="/usr/bin/ldapsearch"
declare -x sips="/usr/bin/sips"


extractLocalPicture(){
	setInstallPercentage $CurrentPercentage.10
	declare -x UserShortName="$1"
	StatusMSG $ScriptName "Extracting Local Image File, saving to $SaveDirectory/$UserShortName-Local.jpg"
	dscl . read /Users/$UserShortName JPEGPhoto | awk '{getline}END{print}'| xxd -r -p > "$SaveDirectory/$UserShortName-Local.jpg"
	setInstallPercentage $CurrentPercentage.50
	StatusMSG $ScriptName "Converting to Icon file $SaveDirectory/$UserShortName-Local.icns"
	sips -z 128 128 "$SaveDirectory/$UserShortName-Local.jpg" --out "$SaveDirectory/$UserShortName-Local.jpg"
	sips -s format icns "$SaveDirectory/$UserShortName-Local.jpg" --out "$SaveDirectory/$UserShortName-Local.icns"
	setInstallPercentage $CurrentPercentage.99
}

downloadGNEPhoto(){
	declare UnixId="$1"
	StatusMSG $ScriptName "Contacting server" uistatus
	setInstallPercentage $CurrentPercentage.10
	StatusMSG $ScriptName "Attempting download User Picture for $UnixId"
	curl "$UserPictureURL" -o "$SaveDirectory/$UnixId.jpg"
	setInstallPercentage $CurrentPercentage.50
	sips "$SaveDirectory/$UnixId.jpg" --out "$SaveDirectory/$UnixId.jpg" --resampleHeightWidth 128 128
	sips -s format icns "$SaveDirectory/$UnixId.jpg" --out "$SaveDirectory/$UnixId.icns"
	setInstallPercentage $CurrentPercentage.99
}


ldapAttribute(){
		declare -x UserShortName="$1" UserAttribute="$2"
		$ldapsearch -LLL -h "$LdapServer" -b "$LdapBase" -x "uid=$UserShortName" "$UserAttribute" | 
				$awk "/^$UserAttribute: /"'{print $NF;exit}'
}


begin
StatusMSG $ScriptName "Downloading user picture..." uiphase
setInstallPercentage 10.00
StatusMSG $ScriptName "Processing $UserType user" uistatus

if [ "$UserType" = "Remote" ] ; then
	export UserPictureURL="$(ldapAttribute "$UserName" 'gnePhotoID')"
	setInstallPercentage 50.00
	StatusMSG $ScriptName "Found $UserName PictureURL: $UserPictureURL"

	StatusMSG $ScriptName "Downloading : $UserPictureURL and converting..."

	downloadGNEPhoto "$UserName"
	setInstallPercentage 70.00
elif [ "$UserType" = "Local" ] ; then
	extractLocalPicture "$UserName"
fi

setInstallPercentage 80.00
die 0


