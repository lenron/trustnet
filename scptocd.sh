#!/bin/bash
#############################################################
# This script will scp a file to the chat.dance server.
#
# Usage: 
# scptocd push local-file  server-location
# scptocd pull server-file local-location
# 		  $1   $2		   $3
#############################################################

prefix="scp -P 21098"
location="chatriwe@162.213.255.28:/home/chatriwe/public_html/"

#echo $prefix $testfile $location
#$prefix $testfile $location

if [ "$1" == "push" ]; then
	echo "found push"
	final_location=${location}${3}
	echo $prefix $2 $final_location
	$prefix $2 $final_location
elif [ "$1" == "pull" ]; then
	echo "found pull"
	final_location=${location}${2}
	echo $prefix $final_location $3
	$prefix $final_location $3
else
	echo "Invalid input!\n"
fi

