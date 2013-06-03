#!/usr/bin/env expect
###############################################################################################
# 		NAME: 			cacheAD.sh
#
# 		DESCRIPTION:  	This script uses the entered Genentech username and password to log 
#						into AD for the first time to cache the credentials locally
#
# 		LOCATION: 		Mac AD Utility Script --> /Library/Genentech/Centrify/.scripts
#		SYNOPSIS:		cacheAD.sh <Genentech UNIXID> <Genentech PASSWORD>
###############################################################################################
#		HISTORY:
#						- created by Arek Sokol (arek@gene.com) 	09/28/2010
#						- modified by Arek Sokol (arek@gene.com)	10/10/2010
###############################################################################################

set username [lindex $argv 0]
set pass [lindex $argv 1]

spawn login ${username}

expect "Password:"
send "${pass}\r"
send "exit\r"

# **** INSERT: Error checking for "Login incorrect" - rollback 
# ...or prompt for Genentech password again and re-run once - if fail, revert and tell to rerun later

expect eof