#!/bin/bash
# set -vx
###############################################################################################
# 		NAME: 			moveKerberos.sh
#
# 		DESCRIPTION:  	This script renames the default Kerberos configuration file to edu.mit.Kerberos.old
#
#		USAGE:			moveKerberos.sh
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/15/2013
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

# Commands required by this script
declare -x mv="/bin/mv"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

MoveKerberosConfig(){
	setInstallPercentage $CurrentPercentage.10
	StatusMSG $FUNCNAME "Updating Single Sign On Files..."
	if [ -f "/Library/Preferences/edu.mit.Kerberos" ]; then
		$mv /Library/Preferences/edu.mit.Kerberos  /Library/Preferences/edu.mit.Kerberos.old
		StatusMSG $FUNCNAME "MoveKerberosConfig - SUCCESSFULLY renamed Kerberos configuration file" passed
	else
		StatusMSG $FUNCNAME "MoveKerberosConfig - Kerberos config file does not exist and no changes are necessary" notice
	fi	
	setInstallPercentage $CurrentPercentage.99
}


begin &&
	setInstallPercentage 50.00
MoveKerberosConfig >> "$LogFile" 2>&1 &&
	setInstallPercentage 70.00
die 0