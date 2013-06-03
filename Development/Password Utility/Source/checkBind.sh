#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			checkBind.sh
#
# 		DESCRIPTION:  	Checks to make sure computer is connected to the Genentech network     
# 		LOCATION: 		Mac AD Utility Script --> /Library/Genentech/Centrify/.scripts
#		SYNOPSIS:		sudo adJoin.sh
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	10/12/2010
###############################################################################################


declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

declare -x awk="/usr/bin/awk"
declare -x ldapsearch="/usr/bin/ldapsearch"

ldapAttribute(){
		declare -x UserShortName="$1" LdapServer="$2"
		setInstallPercentage $CurrentPercentage.10
		LdapRecord="`$ldapsearch -x -H "ldap://$LdapServer" -D "$UserName@$DefaultDomain" -w "$PassWord" -b "$DefaultSearchBase" "sAMAccountName=$UserName"`"
		declare -i CommandExit="$?"
		setInstallPercentage $CurrentPercentage.50
		StatusMSG $FUNCNAME "Found LDAP record on Server $LdapServer (Exit Status:$CommandExit )"
		StatusMSG $FUNCNAME "$LdapRecord"
		setInstallPercentage $CurrentPercentage.99
		return "${CommandExit:-1}"
}

checkCredentials(){
	setInstallPercentage $CurrentPercentage.10
	CheckZero="$(ldapAttribute "$UserName" "$DomainController0")"
        declare -xi CheckZeroStatus="$?"
        if [ $CheckZeroStatus = 0 ]; then
                StatusMSG $FUNCNAME "Credentials Check Succeeded!" uistatus
                setInstallPercentage $CurrentPercentage.99
                return 0
        fi	
	CheckOne="$(ldapAttribute "$UserName" "$DomainController1")"
	declare -xi CheckOneStatus="$?"
	setInstallPercentage $CurrentPercentage.20
	CheckTwo="$(ldapAttribute "$UserName" "$DomainController2")"
	declare -xi CheckTwoStatus="$?"
	setInstallPercentage $CurrentPercentage.30

	CheckThree="$(ldapAttribute "$UserName" "$DomainController2")"
	declare -x CheckThreeStatus="$?"
	setInstallPercentage $CurrentPercentage.50

	if [ $CheckOneStatus != 0 ] || [ $CheckTwoStatus != 0 ] || [ $CheckThreeStatus != 0 ]; then
		StatusMSG $FUNCNAME "Credentials Check Failed on all 3 Servers"
		setInstallPercentage $CurrentPercentage.99
		return 1
	else
		StatusMSG $FUNCNAME "Credentials Check Succeeded!" uistatus
		setInstallPercentage $CurrentPercentage.99
		return 0	
	fi
}

# Check script options
StatusMSG "$ScriptName"  "Processing script $# options:$@"
while getopts u:p: SWITCH ; do
	case $SWITCH in
		u ) export UserName="${OPTARG}" ;;
		p ) export PassWord="${OPTARG}" ;;		
	esac
done # END while

# Initialize Vars, = technically this is required with -i, here for readability	
declare -ix UserNameCheck="0"
declare -ix PassWordCheck="0"

begin
StatusMSG $ScriptName "Checking Bind..." uiphase
	setInstallPercentage 20.00

if [ "${#UserName}" -gt 0 ] && [ "${#PassWord}" -gt 0 ] ; then
	checkCredentials ||
		FatalError "User provided invalid credentials"
	setInstallPercentage 50.00

else
	FatalError $ScriptName "UserName or Password not passed to script"
fi
setInstallPercentage 80.00
die 0


