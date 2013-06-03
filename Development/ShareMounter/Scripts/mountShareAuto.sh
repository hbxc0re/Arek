#!/bin/bash 
#                 ______
#              ,-'  __ ,`--.
#            ,'  ,-'O) \' _ \           FILE: 	mountShareAuto.sh
#           /  _     _,:,'-`'    DESCRIPTION: 	This script will automatically map and attempt to mount a GNE or   
#          :  , /  ,'   :						Roche home share.  Share will then always be available in the Dock
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

declare -x SHARE_ICON="/var/gne/gInstall/icons/share_icon.png"
declare -x SHARE_FOLDER_ICON="/var/gne/gInstall/icons/share_folder_icon.png"
declare -x DOCKUTIL="/var/gne/gInstall/bin/dockutil"
declare -x SETFILEICON="/usr/local/bin/SetFileIcon"
declare -x SYSTEMINFO="/var/gne/.systeminfo"
declare -x LOGFILE="/Library/Logs/gInstall/firstlogin.log"

if [ -e $SYSTEMINFO ]; then
	
	USER=`cat $SYSTEMINFO | grep -m1 unixid | awk '{print$2}'`
	DOMAIN=`cat $SYSTEMINFO | grep -m1 domain | awk '{print$2}'`
	SERVER=`cat $SYSTEMINFO | grep -m1 homeServer | awk '{print$2}'`
	SHARE=`cat $SYSTEMINFO | grep -m1 homeShare | awk '{print$2}'`
	SERVERSHARE="$SERVER/$SHARE"
	SMBREQUEST="//$DOMAIN;$USER:@$SERVERSHARE"
	SHARENAME="$DOMAIN:$USER"
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
	
	echo "mountShareAuto.sh >> SHARE $SMBREQUEST has been successfully mapped."	>> $LOGFILE
else
	echo "mountShareAuto.sh >> SHARE $SMBREQUEST has NOT been successfully mapped."	>> $LOGFILE
fi	


exit 0