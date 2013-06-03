#!/bin/bash
# getADDomain.sh
# GNE Mac Status
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 318. All rights reserved.


declare -x awk="/usr/bin/awk"

declare -x joinedDomain=`dsconfigad -show | $awk '/Active Directory Domain/{print $NF}'`

if [ $joinedDomain != "" ] ; then
	declare AD_DOMAIN="$(dsconfigad -show | $awk '/Active Directory Domain/{print $NF}')"
	echo "$AD_DOMAIN"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi