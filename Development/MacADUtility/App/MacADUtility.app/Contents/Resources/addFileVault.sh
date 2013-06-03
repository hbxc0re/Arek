#!/bin/bash
# set -x
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"
###############################################################################################
# 		NAME: 			addFileVault.sh
#
# 		DESCRIPTION:  	This script adds a migrated user to FileVault2 enabled users 
#
#		SYNOPSIS:		addFileVault.sh <Username> <Password> <OldUsername>
###############################################################################################
#		HISTORY:
#						- 04/17/2013 -- created by Arek Sokol (arek@gene.com) 	
###############################################################################################
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

declare -x Username="$1"
declare -x Password="$2"
declare -x OldUser="$3"
declare -x FileVaultStatus=`fdesetup status | awk '{print $3}'| awk -F. '{print $1}'`
declare -x UserPlist="/tmp/.user.plist"

# Generates a user plist for automating the enabling of user into FileVault2
GenerateUserPlist(){

	StatusMSG $ScriptName "Generating User File to Import User for Access" uistatus
	sleep 1

	echo "<?xml version="1.0" encoding="UTF-8"?>" > $UserPlist
	echo "<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">" >> $UserPlist
	echo "<plist version="1.0">" >> $UserPlist
	echo "<dict>" >> $UserPlist
	echo "<key>Username</key>" >> $UserPlist
	echo "<string>$Username</string>" >> $UserPlist
	echo "<key>Password</key>" >> $UserPlist
	echo "<string>$Password</string>" >> $UserPlist
	echo "<key>AdditionalUsers</key>" >> $UserPlist
	echo "<array>" >> $UserPlist
	echo "<dict>" >> $UserPlist
	echo "<key>Username</key>" >> $UserPlist
	echo "<string>$Username</string>" >> $UserPlist
	echo "<key>Password</key>" >> $UserPlist
	echo "<string>$Password</string>" >> $UserPlist
	echo "</dict>" >> $UserPlist
	echo "</array>" >> $UserPlist
	echo "</dict>" >> $UserPlist
	echo "</plist>" >> $UserPlist

	StatusMSG $ScriptName "User File for ($Username) Generated for FileVault2, Importing..." uistatus
}

# Adds a migrated user to FileVault2 enabled users 
AddUserFileVault(){
	#Enabled user for FileVaut2 Access
	sleep 2
	StatusMSG $ScriptName "User ($Username) Successfully Imported for FileVault2" uistatus
	
	fdesetup add -inputplist < $UserPlist
	sleep 2
}

StatusMSG $ScriptName "FileVault2 Compatibility Steps" uiphase
StatusMSG $ScriptName "Checking if Macintosh HD is FileVault2 Enabled..." uistatus
sleep 4

if [[ $FileVaultStatus != "Off" ]]; then
	# Create empty user plist for func GenerateUserPlist
	 
	StatusMSG $ScriptName "Macintosh HD is Encrypted with FileVault2" uistatus
	sleep 2
	
	StatusMSG $ScriptName "Removing Previous User ($OldUser) from FileVault2" uistatus
	sleep 2
	fdesetup remove -user $OldUser ||
		StatusMSG $ScriptName "Failed to Remove Previous User ($OldUser) from FileVault2" uistatus

	touch $UserPlist
	
	GenerateUserPlist
	AddUserFileVault
	
	StatusMSG $ScriptName "Deleting User File Used for Import. Process Complete." uistatus
	# Deletes generated user plist
	rm -f $UserPlist
	sleep 2
else
	StatusMSG $ScriptName "FileVault2 is NOT Enabled. Exiting Step." uistatus
	sleep 2
	StatusMSG $ScriptName "Enabling FileVault2 Disk Encryption." uistatus
	jamf policy -trigger filevault2_encrypt &&
		StatusMSG $ScriptName "FileVault2 Disk Encryption Policy Succeeded." uistatus
	
fi		