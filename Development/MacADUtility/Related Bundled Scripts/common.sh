#!/bin/bash
# set -xv
###############################################################################################
# 		NAME: 			common.sh
#
# 		DESCRIPTION:  	This script contains all the common functions used by MacADUtility 
#               
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 					10/14/2010
#						- modified by Arek Sokol (arek@gene.com)					04/24/2013
###############################################################################################
# Sanity Check that we are running as root user


export RunDirectory="${0%/*}"

# Shared Commands Used in functions and child scripts
export awk="/usr/bin/awk"
export date="/bin/date"
export defaults="/usr/bin/defaults"
export dsexport="/usr/bin/dsexport"
export dsimport="/usr/bin/dsimport"
export dscl="/usr/bin/dscl"
export cat="/bin/cat"
export cp="/bin/cp"
export chflags="/usr/bin/chflags"
export chown="/usr/sbin/chown"
export chmod="/bin/chmod"
export rm="/bin/rm"
export tee="/usr/bin/tee"
export find="/usr/bin/find"
export id="/usr/bin/id"
export ifconfig="/sbin/ifconfig"
export ioreg="/usr/sbin/ioreg"
export sw_vers="/usr/bin/sw_vers"
export dsmemberutil="/usr/bin/dsmemberutil"
export dscacheutil="/usr/bin/dscacheutil"
export dscl="/usr/bin/dscl"
export rm="/bin/rm"
export mkdir='/bin/mkdir'
export mv="/bin/mv"
export ln="/bin/ln"
export touch="/usr/bin/touch"
export installer="/usr/sbin/installer"
export killall="/usr/bin/killall"

# Bundle application
export platformExpert="$RunDirectory/platformExpert"

# Check our configuration directory is present
[ -d  /Library/gInstall/MacADUtility/ ] ||
		/bin/mkdir -p /Library/gInstall/MacADUtility/
		
# Check our log directory is present
[ -d /Library/Logs/gInstall/ ] ||
		/bin/mkdir -p /Library/Logs/gInstall/
		

# Determine OS version
export OsVersion=`$sw_vers -productVersion | $awk -F"." '{print $2;exit}'`

# Update for Apple Serial number change in 2010
export LastSixSN="$($ioreg -l |
	$awk -F'\"' '
	/IOPlatformSerialNumber/{
	if (length($4) == 12)
	  print substr($4,7,12)
	else 
	   print substr($4,6,11)
	}')"

export PLATFORM_UUID="$("$platformExpert" IOPlatformUUID 2>&1)"
# Added Check for invalid Serial Number
if [ "${#LastSixSN}" -gt 6 ] ; then
	export LastSixSN=$($ifconfig "en0" ether  2>/dev/null |
	$awk 'BEGIN { FS="ether " }
	/^\tether /{
	ether=toupper($2)
	# Convert MAC addess to uppercase
	gsub(/:/,"",ether)
	ether=substr(ether,7,12)
	# Truncate to 6 Characters
	gsub(" ","",ether)
	# Remove any white space
	print ether }
	END { exit 0 }')
fi

# Generates log status message
StatusMSG(){ 
declare FunctionName="$1" StatusMessage="$2" MessageType="$3" CustomDelay="$4"
# Set the Date Per Function Call
declare DATE="$($date)"
declare format='%s\n'

case "${MessageType:-"progress"}" in
	uiphase ) \
		printf "%s\n" "$StatusMessage" > "$InstallPhaseTxt" ;
		sleep ${CustomDelay:=1} ;;
	uistatus ) \
		printf "%s\n" "$StatusMessage" > "$InstallProgressTxt" ;
		sleep ${CustomDelay:=1} ;;
	progress) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# Used for general progress messages, always viewable

	notice) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# Notifications of non-fatal errors , always viewable

	error) \
		printf $format $NOTBOLD $REDBG $YELLOWFG "---> $ScriptName:($FunctionName) - $StatusMessage"  ;;
		

	verbose) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# All verbose output

	header) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# Function and section headers for the script

	passed) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# Sanity checks and "good" information
	*) \
		printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
		# Used for general progress messages, always viewable
esac
return 0
} # END StatusMSG()

setInstallPercentage(){
	declare InstallPercentage="$1"
	echo "$InstallPercentage" >> "$InstallProgressFile"
	export CurrentPercentage="$InstallPercentage"
}
# Logs fatal errors and exits
deleteBridgeFiles(){
	$rm "$InstallProgressTxt" &>/dev/null
	$rm "$InstallPhaseTxt" &>/dev/null
	$rm "$InstallProgressFile" &>/dev/null
}

begin(){
	StatusMSG $FUNCNAME "BEGINNING: $ScriptName - $ProjectName" header
	deleteBridgeFiles
}

die(){
	StatusMSG $FUNCNAME "END: $ScriptName - $ProjectName" header
	setInstallPercentage 99.00
	StatusMSG $FUNCNAME "Step Complete" uistatus 0.5
	deleteBridgeFiles
	unset CurrentPercentage
	exec 2>&- # Reset the error redirects
	exit $1
}

FatalError() {
	StatusMSG $FUNCNAME "BEGIN: Beginning $ScriptName:$FUNCNAME"
	declare ErrorMessage="$1"
	StatusMSG $FUNCNAME "$ErrorMessage" error
	exit 1
}

checkSystemVersion() {
        StatusMSG $FUNCNAME "END: $ScriptName - $ProjectName" header
        declare -x defaults="$defaults:="/usr/bin/defaults"}"
        declare -x SYSTEM_VERSION="/System/Library/CoreServices/SystemVersion.plist"
        declare -x OSVER="$("$defaults" read "${SYSTEM_VERSION%.plist}" ProductVersion )"
        case "${OSVER:?}" in
                10.0* | 10.1* | 10.2* | 10.3* | 10.4*) \
                        FatalError $FUNCNAME "OS version: $OSVER is too old." ;;
                10.5*) \
                        StatusMSG $FUNCNAME "CHECK_OS: OS check: $OS successful!";
                        export OsVersion="5"; return 0 ;;

                10.6*) \
                        StatusMSG $FUNCNAME "CHECK_OS: OS check: $OS successful!";
                        export OsVersion="6"; return 0 ;;

                10.7*) \
                        StatusMSG $FUNCNAME "CHECK_OS: OS check: $OS successful!";
                        export OsVersion="7"; return 0 ;;
                *) \
                        FatalError $FUNCNAME "Unsupported OS:$OS unknown error";;
	esac
	return 1
} # END checkSystemVersion()

FixUserPermissions() {
	StatusMSG $FUNCNAME "BEGIN: Beginning $ScriptName:$FUNCNAME"
	declare UserName=$1
	
	StatusMSG $FUNCNAME "Ensuring There are No Locked Files in /Users/$UserName"
	
	StatusMSG $FUNCNAME "Unlocking Locked Files from /Users/$UserName" uistatus
	
	$chflags -R nouchg "/Users/$UserName"
	
	StatusMSG $FUNCNAME "BEGIN: Processing /Users/$UserName"
	
	declare -i UserNumber="$($dscl . -read "/Users/$UserName" UniqueID |
								$awk '/UniqueID/{print $NF;exit}')"

	declare -i UserNumberSearch="$(id -u "$UserName")"
									
	# Error on the side of the local directory if there is a conflict
	if [ "$UserNumber" -eq "0" ] ; then
		StatusMSG $FUNCNAME "User $UserName (correctly) Does Not Exist in Local Directory"
	elif [ "$UserNumber" != "$UserNumberSearch" ] ; then
		StatusMSG $FUNCNAME "User $UserName Shows UID of $UserNumberSearch in Search Path"
		StatusMSG $FUNCNAME "but Shows UID of $UserNumber in Local Directory"
		FatalError "FAILED - Change Ownership of Contents in /Users/$UserName UID Conflict"
		StatusMSG $FUNCNAME "Updating Ownership on /Users/$UserName" uistatus
		chown -R "$UserNumberSearch" "/Users/$UserName"
	fi
	StatusMSG $FUNCNAME "Updating Ownership on /Users/$UserName" uistatus
	chown -R "$UserName:admin" "/Users/$UserName" ||
		FatalError "FAILED - to change ownership of contents in /Users/$UserName"	

	StatusMSG $FUNCNAME "SUCCESS - changed ownership of contents in /Users/$UserName"
		
	# Update user ownership for contents in /Applications and /Library
	#/usr/share/centrifydc/bin/adfixid --commit /Volumes/Macintosh\ HD  ||
	#	FatalError "FAILED - command exited with error to run adfixid on /Applications and /Library"
	#StatusMSG $FUNCNAME "SUCCESS - updated ownership for contents of Macintosh HD"

	
}

disableLionState(){
  StatusMSG $FUNCNAME "Disabling Lion System State Save"
  declare LOGIN_PLIST="/Users/$NewUser/Library/Preferences/com.apple.loginwindow.plist"
  declare LOGIN_PLIST_UUID="/Users/$NewUser/Library/Preferences/ByHost/com.apple.loginwindow.${PLATFORM_UUID:?}.plist"
  
  if [ -f "$LOGIN_PLIST" ] ; then
	  $defaults delete "${LOGIN_PLIST%%.plist}" AutoOpenedWindowDictionary
  else
    StatusMSG $FUNCNAME "LOGIN_PLIST:$LOGIN_PLIST not found"
  fi
  if [ -f "$LOGIN_PLIST_UUID" ] ; then
	$defaults delete "${LOGIN_PLIST_UUID%%.plist}" TALAppsToRelaunchAtLogin
  else
     StatusMSG $FUNCNAME "LOGIN_PLIST_UUID:$LOGIN_PLIST_UUID not found"
     $mv "/Users/$NewUser/Library/Preferences/ByHost/com.apple.loginwindow"* /tmp/
  fi 
	declare STATE_DIR="/Users/$NewUser/Library/Saved Application State"
	if [ -d "$STATE_DIR" ] ; then
	  declare DISABLED_STATE_DIR="/Users/$NewUser/Library/Saved Application State Disabled"
	  $mkdir "$DISABLED_STATE_DIR" 2>/dev/null
	  $mv "$STATE_DIR"/com.gene.* "$DISABLED_STATE_DIR/" 2>/dev/null
	fi
}

FixHDOwnership(){
	StatusMSG $FUNCNAME "BEGIN: Beginning $ScriptName:$FUNCNAME"
	# Parameters passed to the function
	declare OldUser="$1" NewUser="$2" OldUID="$3"
	StatusMSG $FUNCNAME "Finding Files Owned by $OldUser" uiphase
	StatusMSG $FUNCNAME "Starting HD Search for old files owned by ${OldUser}($OldUID)"
	# Touch a file so we know to revert this change
	$touch /Library/Caches/.fixperms
	# Capture the Start Time
	declare -xi ADFixIDTimeStart="$SECONDS"
	# Exclude /Volumes Directory ( does not affect / ) and /Users as we chown that
	# Use the Null for find and xargs to allow spaces in path names
	# UPDATED: Reworked the following to not traverse into the /Volumes directory
	OLDIFS="$IFS"
	declare -a FILES=(/*)
	StatusMSG $FUNCNAME "Found ${#FILES[@]} paths at /"
	# This logic does not work above 100 items, but that is unlikely
	declare -i TICK_MARK="$((100 / ${#FILES[@]}))"
	IFS=$'\n'
	for (( N = 0 ; N <=${#FILES[@]}; N++ )) ; do
		if [ ${PROGRESS:-0} -eq 0 ] ; then
			# Start the progress bar a little early for the first folder 
			declare -i PROGRESS="$TICK_MARK"
			setInstallPercentage $PROGRESS.00
		else
			declare -i PROGRESS="$((${PROGRESS:-0} + $TICK_MARK))"
		fi
		declare FOLDER="${FILES[$N]}"
		# Skip over symlinks
		[ -L "$FOLDER" ] && continue
		# Run Through the exlcuded list
		if  [ "$FOLDER" != '/Volumes' ] &&
			[ "$FOLDER" != '/System' ] &&
			[ "$FOLDER" != '/Network' ] &&
			[ "$FOLDER" != '/Recycled' ] &&
			[ "$FOLDER" != '/cores' ] &&
			[ "$FOLDER" != '/dev' ] &&
			[ "$FOLDER" != '/net' ] &&
			[ "$FOLDER" != '/private' ]
		then
			StatusMSG $FUNCNAME "Processing: $FOLDER" uistatus
			$find "$FOLDER" \
			-not -path "/Users/${OldUser:="Missing"}/*" \
			-not -path "/Users/${NewUser:="Missing"}/*" \
			-not -path "/dev*" \
			-not -path "/net*" \
			-not -path "/private/var/tmp*" \
			-not -path "/private/var/run*" \
			-not -path "/private/var/folders*" \
			-not -path "/Library/Genentech*" \
			-not -path "/Volumes*" -user "${OldUID:="$OldUser"}" \
			-print0 | xargs -0 chown "${NewUser:?}"
			setInstallPercentage $PROGRESS.00
		fi
	done
	IFS="$OLDIFS"
	# added -not to /Library* from -path /Library/Genentech; removed -not -path "/Library/Logs/Genentech*"
	# ZS: Added current cache directories
	# Added optional item for disk permissions reset
	if [ "$RepairDiskPermissions" = 'YES' ] ; then
		diskutil repairpermissions /
	fi
	declare -i ADFixIDTime="$(( $SECONDS - ${ADFixIDTimeStart:?} ))"
	# Define our seconds constants
	declare -xi Day=86400 Hour=3600 Min=60
		
	if [ "${ADFixIDTime:-0}" -gt 0 ] ; then
		declare -i TimeHuman="$ADFixIDTime"
		if [ "${ADFixIDTime:-0}" -gt 1 ] ; then
			declare    TimeUnit="Seconds"
		else
			declare    TimeUnit="Second"
		fi
		if [ "${ADFixIDTime:-0}" -gt  "${Day:?}" ] ; then
			declare    TimeUnit="Days"
			declare -i TimeHuman="$(printf %.0f $((${ADFixIDTime:-0} / 86400 )))"

		elif [ "${ADFixIDTime:-0}" -gt "${Hour:?}" ] ; then
			declare    TimeUnit="Hours"
			declare -i TimeHuman="$(printf %.0f $((${ADFixIDTime:-0} / 3600 )))"

		elif [ "${ADFixIDTime:-0}" -gt "${Min:?}" ] ; then
			declare    TimeUnit="Minutes"
			declare -i TimeHuman="$(printf %.0f $((${ADFixIDTime:-0} / 60 )))"
		fi
		StatusMSG $FUNCNAME "Took $TimeHuman $TimeUnit to Run" notice
	fi
  disableLionState
	StatusMSG $FUNCNAME "END: Finished $ScriptName:$FUNCNAME" header
}


FileOwnershipUpdate(){
	StatusMSG $FUNCNAME "BEGIN: Beginning $ScriptName:$FUNCNAME" header
	StatusMSG $FUNCNAME "Updating Home Paths..." uiphase
	# Parameters passed to the function
	declare OldUser="$1" NewUser="$2"  OldUID="$3"
	# Commands used by this function
	declare dscl="/usr/bin/dscl"
	declare rm="/bin/rm"
	declare mv="/bin/mv"
	declare ln="/bin/ln"
	
	if [ "${NewUser:?}" != "${OldUser:?}" ]; then
		# If shortname is changed - add to admin group
		$dscl . -merge /Groups/admin GroupMembership "$NewUser"
		StatusMSG $FUNCNAME "added $NewUser to /Groups/admin"
		
		# Checks to see if symbolic link - if so, delete
		StatusMSG $FUNCNAME "Deleting stale symlink: /Users/$NewUser"
		$rm "/Users/$NewUser" 2>/dev/null
		
		StatusMSG $FUNCNAME "Deleting stale symlink: /Users/$OldUser"
		$rm "/Users/$OldUser" 2>/dev/null
		
		# Verified that the home directory exists
		[ -d "/Users/$OldUser" ] ||
			FatalError "FAILED - path to /Users/$OldUser does not exist."
		
		# Migrate user directory from old shortname to new
		  
		$mv -v "/Users/$OldUser/" "/Users/$NewUser/" ||
			FatalError "FAILED - to migrate user directory from /Users/$OldUser to /Users/$NewUser"
		StatusMSG $FUNCNAME "successfully migrated /Users/$OldUser to /Users/$NewUser"
		
		# Insert simlink from old shortname to the new
		$ln -s "/Users/$NewUser" "/Users/$OldUser" ||
			StatusMSG $FUNCNAME "FAILED - to create symlink for /Users/$NewUser to /Users/$OldUser"
		StatusMSG $FUNCNAME "inserted simlink to point /Users/$OldUser --> /Users/$NewUser"
		
		# Run function to fix user permissions
		FixUserPermissions "$NewUser"
				
	else
		# Run function to fix user permissions
		FixUserPermissions "$NewUser"
	fi
	StatusMSG $FUNCNAME "END: Completed $ScriptName:$FUNCNAME" header
}

# Used when needing to ask user to logout (revertChanges.sh)
logOutUser(){
	osascript <<EOF
tell application "System Events"
	log out
end tell
EOF
	return 0
} # END showUIDialog()

# Flush the DirectoryService/opendirectoryd Cache
FlushCache(){
	StatusMSG $FUNCNAME "Flushing Caches" uistatus
	$dscacheutil -flushcache
	$dsmemberutil flushcache
}



jamfRecon(){
	StatusMSG "$FUNCNAME" "Updating Inventory..." uistatus
	if [ ! -x "$jamf" ] ; then
		StatusMSG "$FUNCNAME" "Jamf Binary is Missing! ($jamf)" error
		return 1
	fi
	$jamf recon >> "$LogFile" ||
		StatusMSG "$FUNCNAME" "Recon may have failed." error
	return 0
}

