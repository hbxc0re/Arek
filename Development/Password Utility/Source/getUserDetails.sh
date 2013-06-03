#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			geUserPicture.sh
#
# 		DESCRIPTION:  	This script looks up the URL of the user picture
#						Downloads it and converts it for use in AppleScript
#               
#		USAGE:			geUserPicture.sh
###############################################################################################
#		HISTORY:
#						- created by Zack Smith (zsmith@318.com) 	10/28/2010
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

showUsage(){
	printf "%s\n\t" "USAGE:"
	printf "%s\n\t" 
	printf "%s\n\t" " OUTPUT:"
	printf "%s\n\t" " -u | # Get Picture URL"
	printf "%s\n\t"
	printf "%s\n\t" " EXAMPLE SYNTAX:"
	printf "%s\n\t" " sudo $0 -u smithz"
	printf "%s\n"
	return 0
}


if [ $# = 0 ] ; then
	showUsage
	FatalError "No arguments Given, but required for $ScriptName"
fi
	
# Check script options
while getopts clru:w:h SWITCH ; do
	case $SWITCH in
		u ) export UserName="${OPTARG}" ;;
		h ) showUsage ;;
		
	esac
done # END while

# Commands required by this script
declare -x awk="/usr/bin/awk"
declare -x ldapsearch="/usr/bin/ldapsearch"

ldapAttribute(){
		declare -x UserShortName="$1" UserAttribute="$2"
		$ldapsearch -LLL -h "$LdapServer" -b "$LdapBase" -x "uid=$UserShortName" "$UserAttribute" | 
				$awk "/^$UserAttribute: /"'{print $NF;exit}'
}
# activeDirectoryLookUp
export UserPictureURL="$(ldapAttribute "$UserName" 'gnePhotoID')"
if [ ${#UserPictureURL} -gt 0 ]; then
	printf "<result>%s</result>" "$UserPictureURL"
else
	export UserUID="$(ldapAttribute "$UserName" 'uid')"
	if [ "$UserUID" == "$UserName" ]; then
		StatusMSG $ScriptName "User has no picture but appears to be valid user"

		printf "<result>%s</result>" "http://gwiz.gene.com/cgi-bin/mt/mt-static/support/plugins/genentechthemepack/images/people-placeholder-thumb.gif"
	else
		StatusMSG $ScriptName "User is not valid"
		printf "<result>%s</result>" 'invalid'
	fi
fi
exit 0

