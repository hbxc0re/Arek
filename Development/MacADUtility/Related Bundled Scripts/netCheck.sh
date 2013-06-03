#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			netCheck.sh
#
# 		DESCRIPTION:  	Checks to make sure computer is connected to the Genentech network     
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

declare -x dscacheutil="/usr/bin/dscacheutil"
declare -x ping="/sbin/ping"
declare -x ldapsearch="/usr/bin/ldapsearch"
declare -x Server="nala.roche.com"

StatusMSG "${ScriptName:="$0"}" "Checking Roche/Genentech Network Connectivity" uiphase
FlushCache
# Flush DirectoryService/opendirectoryd before running (helps with loop)
StatusMSG $ScriptName "Checking Connectivity to Active Directory" uistatus
CheckZero=`$ping -c 1 "$Server"`
declare -i CheckZeroStatus=$?
# LDAP Connectivity Test

setInstallPercentage 60.00

CheckNet(){
	setInstallPercentage $CurrentPercentage.70
 # ZS Added check for load balencer first
 if [ "$CheckZeroStatus" == 0 ] ; then
     StatusMSG $FUNCNAME "SUCCESS - On the Roche/Genentech Network" passed
     StatusMSG $FUNCNAME "Connected to the Roche/Genentech Network" uistatus
     setInstallPercentage $CurrentPercentage.90
	
 else 
     StatusMSG $FUNCNAME "FAILED - Not on the Roche/Genentech Network" passed
     StatusMSG $FUNCNAME "Not Connected to the Roche/Genentech Network" uistatus
	 die 1

 fi
	
}
	
begin
CheckNet
die 0

