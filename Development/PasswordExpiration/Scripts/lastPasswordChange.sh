#!/bin/bash 
#                 ______
#              ,-'  __ ,`--.
#            ,'  ,-'O) \' _ \           FILE: 	lastPasswordChange.sh
#           /  _     _,:,'-`'    DESCRIPTION: 	This script will assist in determining the last password    
#          :  , /  ,'   :						set date to identify the days remaining
#          ; : \ (    ) |						
#         /. \_ `-`  /, `.      DEPENDENCIES:   Must be an AD mobile user account bound to Active Directory
#        /;`-._\    '/ \  `.      CREATED BY:	Arek Sokol (arek@gene.com)
#       // `- ,`'  ,' -','`-`.  LAST REVISED:	02/18/2013 10:00 AM PST
#      /`:/  '-'  ._,  / `-'`-\
#    ;`-|`/   /   ,  :`-'`-'`-\
#     |`-: `-' `-' `- |-'`-'`-':
#    :`-: |  |_ |  | :`-'`-'`-|
#     :`- :`-'   `-' `\'`-'`-'`;
#    \`-'\ \_, \_, |_:-'`-'`-':
#     \-''\    '-     \`-'`-'`/
#       `.-'\ \  `-'  `-:`-'`-'\
#         \-'\ `-'  \_, |'`-'`-':
#          :-'\ \_      : ' ' ' :
#          `.-'\  `-' \  \ ' ' ';
#            \-':`-'  :  : ' ' '\
#            `.|  `-':. (/ ;',';
#               ;`-'  \/'.\( ( (:
#                ),._// /. :''`.:
#               _/ /_/  )'`|''`.(
#          _..-`_,-`_. ( ' :''`.;
#        (,;/;_,-''  \,:' |\'`.:`.
#        / (,(/        `/\ ||\`.|  \
#      ;-'' '   ,-'   .  `:||:.(-. \
#    ,-' .    /         `   \| `'  `'
#   '    ':._        )     ,'('

declare -x SYSTEMINFO="/var/gne/.systeminfo"
declare -x DOMAIN=`cat $SYSTEMINFO | grep -m1 domain | awk '{print$2}'`
declare -x COCOADIALOG="/var/gne/gInstall/bin/cocoaDialog.app/Contents/MacOS/cocoaDialog"
declare -x TERMINALNOTIFIER="/var/gne/bin/ginstall-notifier.app/Contents/MacOS/ginstall-notifier"
declare -x DIALOG_ICON="/var/gne/gInstall/icons/Credentials.png"
declare -x OS_VERSION=`sw_vers | grep "ProductVersion" | awk '{print $2}' | awk -F"." '{print$2}'`

# Logged in user
LoggedInUser=`ls -l /dev/console | awk '{ print $3 }'`

# Current password change policy
PasswdPolicy=365

# Last password set date
LastPasswordSet=`dscl /Active\ Directory/GNE/All\ Domains/ read /Users//$LoggedInUser pwdLastSet | /usr/bin/awk '/pwdLastSet:/{print $2}'`

# Calculations
LastPasswordCalc1=`expr $LastPasswordSet / 10000000 - 1644473600`
LastPasswordCalc2=`expr $LastPasswordCalc1 - 10000000000`
TimeStampToday=`date +%s`
TimeSinceChange=`expr $TimeStampToday - $LastPasswordCalc2`
DaysSinceChange=`expr $TimeSinceChange / 86400`
DaysRemaining=`expr $PasswdPolicy - $DaysSinceChange`

if [ $DOMAIN == "GNE" ]; then
	if [ $OS_VERSION == "8" ]; then
		$TERMINALNOTIFIER -title "Genentech Password Expiration" -message "Your password will expire in $DaysRemaining days.  Click to change your password now." -open "https://pwcw.gene.com"
	else	
		DIALOG_RESULT=`$COCOADIALOG msgbox --icon-file $DIALOG_ICON --title "Genentech Password Expiration Notice" --text "Your password will expire in $DaysRemaining days." --informative-text "Would you like to change your password now?" --button1 "Yes" --button2 "No" --float`
		if [[ $DIALOG_RESULT == 1 ]]; then
			open -a /Applications/Safari.app "https://pwcw.gene.com"
		else
			echo " "
		fi	
		
	fi	
else
	if [ $OS_VERSION == "8" ]; then
		$TERMINALNOTIFIER -title "Roche Password Expiration" -message "Your password will expire in $DaysRemaining days.  Click to change your password now." -open "https://pass.roche.com"
	else	
		$COCOADIALOG msgbox --icon-file $DIALOG_ICON --title "Roche Password Expiration Notice" --text "Your password will expire in $DaysRemaining days." --informative-text "Would you like to change your password now?" --button1 "Yes" --button2 "No" --float
		if [[ $DIALOG_RESULT == 1 ]]; then
	
			open -a /Applications/Safari.app "https://pass.roche.com"
		else
			echo " "
		fi	
	fi	
fi		



