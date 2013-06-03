#!/bin/bash 
#                 ______
#              ,-'  __ ,`--.
#            ,'  ,-'O) \' _ \           FILE: 	mountShare.sh
#           /  _     _,:,'-`'    DESCRIPTION: 	This script will assist in mapping and mounting a network    
#          :  , /  ,'   :						share.  All shares will then always be available in the Dock
#          ; : \ (    ) |						in a folder labeled SHARES.
#         /. \_ `-`  /, `.      DEPENDENCIES:   util_ShareMounter.dmg (contains required images and binaries)
#        /;`-._\    '/ \  `.      CREATED BY:	Arek Sokol (arek@gene.com)
#       // `- ,`'  ,' -','`-`.  LAST REVISED:	02/14/2013 10:00 AM PST
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

DETAILS="/tmp/sharemapper_details.txt"
SHARE_ICON="/tmp/share_icon.png"
SHARE_FOLDER_ICON="/tmp/share_folder_icon.png"
COCOADIALOG="/usr/local/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog"
DOCKUTIL="/usr/local/bin/dockutil"
SETFILEICON="/usr/local/bin/SetFileIcon"
SHARENAME=""

destroyTICKETS(){
	# Just bc Mountain Lion hates bound systems 
	kdestroy -A >& /dev/null

}

getINPUTS(){
SHARENAME_INPUT=`$COCOADIALOG inputbox --title "Share Mapper" --informative-text "What would you like to label you share? (i.e. MyShare)" --button1 "Continue" --float`
SHARENAME=`echo $SHARENAME_INPUT | awk '{print$2$3$4$5}'`
USER_INPUT=`$COCOADIALOG inputbox --title "Share Mapper" --informative-text "What is your username? (i.e. jdoe)" --button1 "Continue" --float`
USER=`echo $USER_INPUT | awk '{print$2}'`
DOMAIN_INPUT=`$COCOADIALOG inputbox --title "Share Mapper" --informative-text "What is your domain? (i.e. GNE, RNUMDMAS...)" --button1 "Continue" --float`
DOMAIN=`echo $DOMAIN_INPUT | awk '{print$2}'`
SERVERSHARE_INPUT=`$COCOADIALOG inputbox --title "Share Mapper" --informative-text "What is the share path? Please use this format: dnausers.gene.com/jdoe" --button1 "Continue" --float`
SERVERSHARE=`echo $SERVERSHARE_INPUT | awk '{print$2}'`
PASSWORD_INPUT=`$COCOADIALOG inputbox --title "Share Mapper" --informative-text "What is the password for the share?" --button1 "Continue" --float --no-show`
PASSWORD=`echo $PASSWORD_INPUT | awk '{print$2}'`
POPULATE_DETAILS=`echo "Sharename = $SHARENAME" > $DETAILS; echo "User = $USER" >> $DETAILS; echo "Domain = $DOMAIN" >> $DETAILS; echo "Share Path = $SERVERSHARE" >> $DETAILS`
}

verifyINPUTS(){

	if [[ $SHARENAME == "" || $USER == "" || $DOMAIN == "" || $SERVERSHARE == "" || $PASSWORD == "" ]]; then
		
		STATUS_FAILED=`$COCOADIALOG msgbox --title "Share Mapper" --text "One or more of the required fields were left blank."  --informative-text "Would you like to try again?" --button1 "Try Again" --button2 "No, Exit" --float`
		TRY_RESULT=`echo $STATUS_FAILED | awk '{print$1}'`
		if [[ $TRY_RESULT == 1 ]]; then
			getINPUTS
		else
			exit 0
		fi		
		
	fi	
}

displayInputs () {


RESULTS=`$COCOADIALOG textbox --title "Share Mapper" --informative-text "Are these details correct?" --text-from-file $DETAILS --button1 "Yes" --button2 "No" --float --no-show`
RESULTS_BUTTON=`echo $RESULTS | awk '{print$1}'`

if [[ $RESULTS_BUTTON == 1 ]]; then
	
	echo " "
else
			
	STATUS_FAILED=`$COCOADIALOG msgbox --title "Share Mapper" --text "Would you like to try re-entering the information again?" --button1 "Try Again" --button2 "No, Exit" --float`
	TRY_RESULT=`echo $STATUS_FAILED | awk '{print$1}'`
	if [[ $TRY_RESULT == 1 ]]; then
		getINPUTS
	else
		exit 0
	fi		
		
fi	

}

$COCOADIALOG msgbox --icon-file $SHARE_FOLDER_ICON --title "Share Mapper" --text "Welcome to Share Mapper" --informative-text "This utility will assist you in mapping and mounting a network share.  All shares will then always be available in your Dock in a folder labeled SHARES." --button1 "Continue" --float

destroyTICKETS
getINPUTS
verifyINPUTS
displayInputs

SMBREQUEST="//$DOMAIN;$USER:@$SERVERSHARE"
SMBREQUEST_MOUNT="//$DOMAIN;$USER:$PASSWORD@$SERVERSHARE"
part1='<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict> 
        <key>URL</key> 
        <string>smb:'
part2='</string> 
</dict> 
</plist>' 

mkdir -p ~/Shares
echo $part1$SMBREQUEST$part2 > ~/Shares/$SHARENAME.inetloc 
$SETFILEICON -image $SHARE_ICON -file ~/Shares/$SHARENAME.inetloc
$SETFILEICON -image $SHARE_FOLDER_ICON -file ~/Shares
$DOCKUTIL --add ~/Shares >& /dev/null
sleep 5
killall Dock

$COCOADIALOG msgbox --icon-file $SHARE_FOLDER_ICON --title "Share Mapper" --text "Share '$SHARENAME' has been mapped successfully." --informative-text "You will find '$SHARENAME' available in your Dock in a folder labeled SHARES." --button1 "Quit" --float


mkdir /Volumes/$SHARENAME
mount_smbfs $SMBREQUEST_MOUNT /Volumes/$SHARENAME

exit 0