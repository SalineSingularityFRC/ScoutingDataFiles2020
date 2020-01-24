#!/usr/bin/env bash 

#
# FRC USB Connection Kit - A tool for easily sending files back and forth offline for FRC scouting 
#

# Print an error message and return code 1
fail() {
	printf "\e[31mERROR!:\e[0m %s\n" "$1"
	exit 1
}

# Print an error message and unmount drive
safe_fail() {
	printf "\e[31mERROR!:\e[0m %s...Unmounting drive\n"
	umount $MNT || fail "Failed to unmount $MNT"
	exit 1
}

# Clean up
cleanup() {
	printf "Cleaning up..."
	# If device is mounted, unmount it
	if [[ $(findmnt -M $MNT) ]]; then umount $MNT; fi
	printf "OK\n"
}

# Print usage and quit
usage() {
	printf "Usage:\n\t# umv.sh <send|get|auto> <device> <target>\n"
	exit 0 
}

# Check for a command
check() {
	command -v "$1" &> /dev/null || fail "umv.sh requires $1. Please install it or add it to your path."
}

###
### Commands
###

# Send a file to /sdcard/db/$FILE
send() {
        printf "Sending $FILE...\n"
	mount $DEV $MNT || fail "Failed to mount $DEV"

	# Copy file to mountpoint
	cp $FILE $MNT/$FILE || safe_fail "Failed to copy $FILE to $MNT"
	umount $MNT || safe_fail "Failed to unmount $MNT"
        printf "Successfully sent $FILE!\n"
}

# Get a file from /sdcard/db/$FILE
get() {
	printf "Getting $FILE...\n"
	mount $DEV $MNT || fail "Failed to mount $DEV"

	# Copy file from mountpoint
	cp $MNT/$FILE $FILE || safe_fail "Failed to copy $FILE from $MNT"
	umount $MNT || safe_fail "Failed to unmount $MNT"
	printf "Successfully got $FILE!\n"
}

# Wait for a device to be plugged in and then drop files to it
auto() {
	# Init git repo dir isn't already one
	if [ ! -d .git ]; then git init; fi

	while :; do
		if ls $DEV &> /dev/null; then
			printf "Found a new device! Attempting to get $FILE\n"

			umv.sh get $DEV $FILE || fail "Failed to get $FILE" 
			git add . || fail "Failed to add to git"
			git commit -m "NEW AUTOMATIC DOWNLOAD $(date)"
		fi
		sleep 1
	done	
}

# If no arguments are supplied, print the usage and exit
if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then usage; fi

###
### Setup
###

# Get Run Commands
if [ ! -d ~/.config/mvrc ]; then
	source ~/.config/mvrc
else
	UMV_TARGET_DIR=/mnt
fi

# Check for dependancies
check git

# Ensure users are root
if [ "$EUID" -ne 0 ]; then fail "Please run as root"; fi

COMMAND="$1"
DEV="$2"
FILE="$3"
MNT="$UMV_TARGET_DIR"

# Catch exit
trap cleanup EXIT

# Iterate over command
case $1 in
        "send" | "s") send ;;
        "get" | "g")  get ;;
	"auto" | "a") auto ;;
	*) fail "$1 is not a valid command!" ;;
esac
