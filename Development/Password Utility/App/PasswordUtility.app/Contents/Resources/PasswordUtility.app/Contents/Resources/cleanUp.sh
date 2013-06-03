#!/bin/bash
# set -x	# DEBUG. Display commands and their arguments as they are executed
# set -v	# VERBOSE. Display shell input lines as they are read.
# set -n	# EVALUATE. Check syntax of the script but dont execute
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName"

# Quickly define proper usage of this script
usage="$0 -u UNIXusername -p UNIXpassword"

# Parse the input options...
while getopts "u:p:o: h" CredInputs; do
	case $CredInputs in
		u ) UNIXuser="$OPTARG" ;;
		p ) UNIXpass="$OPTARG" ;;
		o ) NotUsed="$OPTARG" ;;
		h ) echo "$usage"
			exit 1;;		
	esac
done

declare -x mv="/bin/mv"

declare -x UserName="$(/usr/bin/who | /usr/bin/awk '/console/{print $1;exit}')"

begin
declare -x SAVED_STATE="/Users/$UserName/Library/Saved Application State/com.gene.PasswordUtility.savedState"

# Check to see if file exists and move it to the tmp directory
if [ -d "${SAVED_STATE:?}" ] ; then
	$mv "$SAVED_STATE" /private/tmp/
fi
die 0