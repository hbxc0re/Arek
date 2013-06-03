#!/usr/bin/perl
###############################################################################################
# 		NAME: 			makehash.pl
#
# 		DESCRIPTION:  	This script generates manually created shadow hash files
#               
# 		LOCATION: 		Mac AD Utility Script --> /Library/Genentech/Centrify/.scripts
#		USAGE:			makehash.pl <password>
###############################################################################################
#		HISTORY:
#						- created by Zack Smith (zsmith@318.com) 	10/18/2010
###############################################################################################
use Digest::SHA1 qw(sha1_hex);;
$password = $ARGV[0];

sub genShadowHash($){
# get our salt integer, and it's hex value
$salt = rand(2**31-1);
$saltHex = sprintf("%X",$salt);
# get string representation of bytes
$saltStr = pack("N", $salt);

# compute salted hash. get uppercase values
$sha1_salt = sprintf ("%08s%s", uc($saltHex),uc(sha1_hex($saltStr.$password)));
# blank out other hashes 
$NTLM = 0 x 64;
$sha1 = 0 x 40;
$cram_md5 = 0 x 64;
$recoverable = 0 x 1024;

$string = $NTLM . $sha1 . $cram_md5 . $sha1_salt . $recoverable;
return "$string"
}
print &genShadowHash()