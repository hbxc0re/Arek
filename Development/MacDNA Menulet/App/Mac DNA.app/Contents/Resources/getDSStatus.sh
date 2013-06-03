#!/bin/bash

# getDSStatus.sh
# GNE Mac Status
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 318. All rights reserved.
declare -x adinfo="/usr/bin/adinfo"
declare -x awk="/usr/bin/awk"

declare -x SYSTEM_TYPE="$($cat /var/gne/.systemtype)"
declare -x joinedDomain=`dsconfigad -show | $awk '/Active Directory Domain/{print $NF}'`

if [ $joinedDomain != "" ] ; then
	declare AD_DOMAIN="$(dsconfigad -show | $awk '/Active Directory Domain/{print $NF}')"
		
	if [ "$AD_DOMAIN" == "gne.windows.gene.com" ] ; then
		echo "Joined to Active Directory"
		exit 0
	else
		exit 2
	fi
else
	if [ "$SYSTEM_TYPE" = 'Loner' ] ; then
		exit 192
	else
		# If the command is not installed
		exit 1
	fi
fi

