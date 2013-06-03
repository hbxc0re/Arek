#!/bin/bash

# getJoinedAs.sh
# Mac DNA
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 Genentech. All rights reserved.
declare -x awk="/usr/bin/awk"
declare -x computerACCT=`dsconfigad -show | $awk '/Computer Account/{print $NF}' | sed '$s/.$//'`

if [ $computerACCT != "" ] ; then
	declare -x COMPUTER_ACCOUNT=`dsconfigad -show | $awk '/Computer Account/{print $NF}' | sed '$s/.$//'`
	echo "Joined As: $COMPUTER_ACCOUNT"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi
