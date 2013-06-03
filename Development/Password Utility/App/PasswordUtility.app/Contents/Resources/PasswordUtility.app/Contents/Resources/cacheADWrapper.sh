#!/bin/bash
# set -x	# DEBUG. Display commands and their arguments as they are executed
# set -v	# VERBOSE. Display shell input lines as they are read.
# set -n	# EVALUATE. Check syntax of the script but dont execute
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"

# Simple wrapper for the except script
declare -x id="/usr/bin/id"
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


declare -x dscl="/usr/bin/dscl"

begin

# ZS Added dscl authonly check to make sure we don't hang on the expect
if $dscl /Search -authonly "$UNIXuser" "$UNIXpass" ; then
	StatusMSG $ScriptName "Attempting to Cache Credentials" uistatus
	"$RunDirectory/cacheAD.sh" "$UNIXuser" "$UNIXpass"
else
  declare -ix UniqueID="$($id -u $UNIXuser)"
  # Catch Local Users
  if [ $UniqueID -lt 1000 ] ; then
    StatusMSG $ScriptName "Updating Local User $UNIXuser " uistatus
    # ZS Added code to update local account password for pre Mac AD Utility users
    $dscl . -passwd /Users/$UNIXuser "$UNIXpass"
    if $dscl . -authonly $UNIXuser "$UNIXpass" ; then
          StatusMSG $ScriptName "Successfully Updated Local Password" uistatus
    else
          StatusMSG $ScriptName "Updating Local Password Failed"
    fi
  else
	 StatusMSG $ScriptName "$UNIXuser uidNumber is too high ($UniqueID) to be a local account"
  fi
fi
die 0
