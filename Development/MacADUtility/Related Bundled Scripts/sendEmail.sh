#!/bin/bash
# set -x
###############################################################################################
# 		NAME: 			sendEmail.sh
#
# 		DESCRIPTION:  	This script sends a custom email to a specified email address when called
#               
#		USAGE:			sendEmail.sh <Subject> <Genentech UNIXID> <Error Code>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	04/16/2013
###############################################################################################
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"
exec 2>>"$LogFile"

Subject="$1"
UnixId="$2"
ErrorCode="$3"
ShortName=`last -1 | awk '{ print $1 }'`
Email="arek@gene.com"
EmailMessage="/tmp/emailmessage-$$$RANDOM.txt"
SystemProfiler='/usr/sbin/system_profiler'
SMTPServer="smtp.gene.com"

begin
StatusMSG $ScriptName "Sending Final Notifications" uiphase
StatusMSG $ScriptName "Generating Email Message" uistatus

declare -x touch="/usr/bin/touch"


echo "UNIX: $UnixId" > "$EmailMessage"
echo "MAC Shortname: $ShortName" >> "$EmailMessage"
echo "ERROR: $ErrorCode" >> "$EmailMessage"
echo "  " >> "$EmailMessage"
echo `$SystemProfiler | grep "Model Identifier"` >> "$EmailMessage"
echo `$SystemProfiler | grep -m 1 "Serial Number"` >> "$EmailMessage"
echo `$SystemProfiler | grep -m 1 "System Version"` >> "$EmailMessage"

if [ "$Subject" = "ERROR" ]; then
	StatusMSG $ScriptName "Sending Email about Issue" uistatus
	echo " " >> "$EmailMessage"
	echo "--=== Mac AD Utility - Mac_AD_Auth.log ===---" >> "$EmailMessage"
	echo " " >> "$EmailMessage"
	echo "--> START" >> "$EmailMessage"
	echo " "
#	echo `cat /Library/Logs/Genentech/Mac_AD_Auth.log` >> "$EmailMessage"
	echo "$ScriptVersion" >> "$EmailMessage"
	echo "<-- END" >> "$EmailMessage"
fi

if [ "$Subject" == "SUCCESS" ]; then
	StatusMSG $ScriptName "Sending Success Email to Engineering" uistatus
	echo " " >> "$EmailMessage"
	echo "--=== Computer Name ===---" >> "$EmailMessage"
	echo " " >> "$EmailMessage"
	echo `hostname` >> "$EmailMessage"
	echo "$ScriptVersion" >> "$EmailMessage"
	echo " " >> "$EmailMessage"
fi	
	
# Sends email using /bin/mail
#/usr/bin/mail -s "$Subject" "$Email" < $EmailMessage
# Updated to use perl script ZS
"$RunDirectory/sendEmail.pl" -f "$Email" -t "$Email" -u "$Subject ($UnixId)-- `date`" -m "$(cat "$EmailMessage")" -s "$SMTPServer" -a "$LogFile" -v -l "$LogFile"
declare EmailSuccess="$?"
if [ "$EmailSuccess" -gt 0 ] ; then
	StatusMSG $ScriptName "Email Script Error, exit value larger the 0" error
	StatusMSG $ScriptName "Email send failure" uistatus
 	cat "$EmailMessage" > "/Library/Caches/.$UnixId.emailneeded"
else
	StatusMSG $ScriptName "Disabling post reboot email" passed
	cat "$EmailMessage" > "/Library/Caches/.$UnixId.emailcomplete"
	rm "/Library/Caches/.$UnixId.emailneeded"
fi

# Added Exit 0 so we don't try and fail over to revert ZS
die 0
