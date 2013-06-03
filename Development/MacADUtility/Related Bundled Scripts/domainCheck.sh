#!/bin/sh

###############################################################################################
# 		NAME: 			domainCheck.sh
#
# 		DESCRIPTION:  	Determines or asks for appropriate domain 
#		
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	10/14/2010
#						- modified by Arek Sokol (arek@gene.com)	04/15/2013
###############################################################################################
#set -x
# Variables
declare -x CocoaDialog="/var/gne/gInstall/bin/cocoaDialog.app/Contents/MacOS/cocoaDialog"
declare -x SystemInfoFile="/var/gne/.systeminfo"
declare -x DomainFile="/private/tmp/.domain"

# Check for existing values
AskDomain () {
	#Ensures CocoaDialog is installed in the correct location
	if [[ -e $CocoaDialog ]]; then
		DomainValue=`$CocoaDialog dropdown --title "MacADUtility" --text "Please select your domain:" --items "GNE" "RBAMOUSER" "RMOASIA" "RNUMDMAS" --button1 "Continue" --float --height 150 --string-output | sed -ne 2p`
		if [[ $DomainValue == "GNE" ]]; then
			echo "GNE" > $DomainFile
			exit 0
		fi	
	
		if [[ $DomainValue == "RBAMOUSER" ]]; then
			echo "EMEA" > $DomainFile
			exit 0
		fi	
	
		if [[ $DomainValue == "RNUMDMAS" ]]; then
			echo "NALA" > $DomainFile
			exit 0
		fi	
	
		if [[ $DomainValue == "RMOASIA" ]]; then
			echo "ASIA" > $DomainFile
			exit 0
		fi	
	else 
		exit 1	
	fi 
		
}

# Check for domain information in /var/gne/.systeminfo if already exists
CheckForDomain () {
	if [[ -e $SystemInfoFile ]]; then
	
		DefaultDomain=`cat $SystemInfoFile | grep "domain=" | awk '{print$2}'`
		ErrorCheck=`echo $?`
		
		# If domain info not capture correctly from .systeminfo, then ask
		if [[ $ErrorCheck == 1 ]]; then
			AskDomain
		fi	
	
		if [[ $DefaultDomain == "GNE" ]]; then
			echo "GNE" > $DomainFile
		fi	
		
		if [[ $DefaultDomain == "RBAMOUSER" ]]; then
			echo "EMEA" > $DomainFile
		fi	
		
		if [[ $DefaultDomain == "RNUMDMAS" ]]; then
			echo "NALA" > $DomainFile
		fi	
		
		if [[ $DefaultDomain == "RMOASIA" ]]; then
			echo "ASIA" > $DomainFile
		fi	
	
		# Double-check to ensure domain value present in .systeminfo
		if [[ $DefaultDomain != "GNE" && $DefaultDomain != "RBAMOUSER" && $DefaultDomain != "RNUMDMAS" && $DefaultDomain != "RMOASIA" ]]; then
			AskDomain
		fi	
	
	else
		# If no .systeminfo 
		AskDomain
	fi

}

if [[ -e $DomainFile ]]; then
	rm $DomainFile
fi	

CheckForDomain

