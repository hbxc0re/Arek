#!/bin/bash
#set -x
# ABOVE: Uncomment to turn on debug
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/local/include:/usr/bin:/bin:/usr/sbin:/sbin"
###############################################################################################
# 		NAME: 			adJoin.sh
#
# 		DESCRIPTION:  	This script joins the computer to Genentech's Active Directory     
#		SYNOPSIS:		sudo adJoin.sh
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/15/2013
###############################################################################################

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

[ $# = 0 ] &&
	FatalError "No arguments Given, but required for $ScriptName.sh"

declare -x awk="/usr/bin/awk"	
declare -x adjoin="/usr/sbin/adjoin"
declare -x adinfo="/usr/bin/adinfo"
declare -x ifconfig="/sbin/ifconfig"
declare -x ioreg="/usr/sbin/ioreg"

declare -x UnixId="$1"
declare -x ADBindAcct="$2"
declare -x ADBindPass="$3"
declare -x DefaultDomain="$4"
declare -x DefaultContainer="$5"
declare -x DefaultController="$6"

declare -x IsJoinedGNE=`dsconfigad -show | grep -o -m1 gne.windows.gene.com`
declare -x IsJoinedEMEA=`dsconfigad -show | grep -o -m1 emea.roche.com`
declare -x IsJoinedNALA=`dsconfigad -show | grep -o -m1 nala.roche.com`
declare -x IsJoinedASIA=`dsconfigad -show | grep -o -m1 asia.roche.com`

# Update for Apple Serial number change in 2010
export LastSixSN="$($ioreg -l |
	$awk -F'\"' '
	/IOPlatformSerialNumber/{
	if (length($4) == 12)
	  print substr($4,7,12)
	else 
	   print substr($4,6,11)
	}')"

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

initiateUnbind(){

	# Unbind if previously bound to Active Directory
	dsconfigad -remove -username $ADBindAcct -password $ADBindPass -force

}
	
checkIfJoined(){
	setInstallPercentage $CurrentPercentage.10
	
	if [[ $IsJoinedGNE == "gne.windows.gene.com" ]] ; then
		StatusMSG $FUNCNAME "Machine is Already Joined to $IsJoinedGNE" uistatus
		setInstallPercentage $CurrentPercentage.20
		StatusMSG $FUNCNAME "Leaving $IsJoinedGNE" uistatus
		initiateUnbind &&
			StatusMSG $FUNCNAME "Successfully Left $IsJoinedGNE" uistatus
		return 0
	else
		StatusMSG $FUNCNAME "Machine is Not Joined to Active Directory" uistatus		
		setInstallPercentage $CurrentPercentage.25
		return 0
	fi
	
	
	if [[ $IsJoinedEMEA == "emea.roche.com" ]] ; then
		StatusMSG $FUNCNAME "Machine is Already Joined to $IsJoinedEMEA" uistatus
		setInstallPercentage $CurrentPercentage.30
		StatusMSG $FUNCNAME "Leaving $IsJoinedEMEA" uistatus
		initiateUnbind &&
			StatusMSG $FUNCNAME "Successfully Left $IsJoinedEMEA" uistatus
		return 0
		
	else
		StatusMSG $FUNCNAME "Machine is Not Joined to Active Directory" uistatus		
		setInstallPercentage $CurrentPercentage.35
		return 0
	fi
	
	if [[ $IsJoinedNALA == "nala.roche.com" ]] ; then
		StatusMSG $FUNCNAME "Machine is Already Joined to $IsJoinedNALA" uistatus
		setInstallPercentage $CurrentPercentage.40
		StatusMSG $FUNCNAME "Leaving $IsJoinedNALA" uistatus
		initiateUnbind &&
			StatusMSG $FUNCNAME "Successfully Left $IsJoinedNALA" uistatus
		return 0
		
	else
		StatusMSG $FUNCNAME "Machine is Not Joined to Active Directory" uistatus		
		setInstallPercentage $CurrentPercentage.45
		return 0
	fi
	
	if [[ $IsJoinedASIA == "asia.roche.com" ]] ; then
		StatusMSG $FUNCNAME "Machine is Already Joined to $IsJoinedASIA" uistatus
		setInstallPercentage $CurrentPercentage.50
		StatusMSG $FUNCNAME "Leaving $IsJoinedASIA" uistatus
		initiateUnbind &&
			StatusMSG $FUNCNAME "Successfully Left $IsJoinedASIA" uistatus
		return 0
		
	else
		StatusMSG $FUNCNAME "Machine is Not Joined to Active Directory" uistatus		
		setInstallPercentage $CurrentPercentage.55
		return 0
	fi
	
	
}

JoinAD(){
	StatusMSG $FUNCNAME "Attempting to Join Domain: $DefaultDomain" uistatus
	setInstallPercentage $CurrentPercentage.65
	ComputerName="${UnixId:?}-${LastSixSN:?}"
	CommandOutput="$(dsconfigad -preferred $DefaultController -u $ADBindAcct -p "$ADBindPass" -ou $DefaultContainer -a "${ComputerName/ /}" -domain $DefaultDomain -mobile enable -mobileconfirm disable -force )"
	declare -i errorCheck="$?"
	
	if [ $errorCheck -ne 0 ]; then
		StatusMSG $FUNCNAME "ERROR: Could Not Join Domain: $DefaultDomain" uistatus
		StatusMSG $FUNCNAME "$CommandOutput"
		setInstallPercentage $CurrentPercentage.75
		return 1
	elif [ $errorCheck -eq 0 ]; then
		StatusMSG $FUNCNAME "Computer Successfully Joined Domain: $DefaultDomain" uistatus
		StatusMSG $FUNCNAME "Computer Successfully Joined Domain: $DefaultDomain"
		setInstallPercentage $CurrentPercentage.75
		return 0	
	fi	
}
begin
StatusMSG $ScriptName "Joining to Active Directory" uiphase
setInstallPercentage 5.00
checkIfJoined || die 0 # Already Joined so we exit the script
setInstallPercentage 60.00
JoinAD ||
	FatalError "Error Joining Domain: $DefaultDomain"
setInstallPercentage 90.00
die 0


