#!/bin/sh

# getADZone.sh
# GNE Mac Status
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 318. All rights reserved.
declare -x awk="/usr/bin/awk"
declare -x preferredDC=`dsconfigad -show | $awk '/Preferred Domain controller/{print $NF}'`

if [ $preferredDC != "" ] ; then
	declare -x PREF_DC=`dsconfigad -show | $awk '/Preferred Domain controller/{print $NF}'`
	echo "Preferred DC: $PREF_DC"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi
