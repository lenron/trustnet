#!/bin/bash

# Stop running this script if any command returns exit status -- necessary for accurate reporting.
set -e

# Require exactly 1 command line argument that is either 'main' or 'backup'.
# Double brackets are bash specific, 'generally safer to use', and better with regex using =~ operator:
# https://stackoverflow.com/questions/669452/are-double-square-brackets-preferable-over-single-square-brackets-in-b
if [[ "$#" -ne 1 ]]; then # Require 1 argument/parameter.
    echo -e "Error: Needs exactly 1 argument!\nPlease specify 'main' or 'backup' with exactly 1 argument to run this server setup script."
    echo "Usage: 'bash $0 main' or 'bash $0 backup'"
    exit 1
elif [[ "$1" != "main" && "$1" != "backup" ]]; then # Require that single parameter to be either 'main' or 'backup'.
    echo -e "Error: Specify either 'main' or 'backup'!\nPlease specify 'main' or 'backup' with exactly 1 argumen to run this server setup script."
    echo "Usage: 'bash $0 main' or 'bash $0 backup'"
    exit 1
fi

# Set logs directory.
LOG_DIRECTORY="$HOME/trustnet/pgo/htdocs/logs"
# Create logs folder if it doesn't already exist.
mkdir -p $LOG_DIRECTORY
# Apache runs the process that runs the backend scripts that create logs. If Apache doesn't have ownership of the directory or something similar, logs won't get created.
sudo chown -R www-data $HOME/trustnet/pgo/htdocs/logs

#####################
#   Crontab Setup   #
#####################
# Crontab default instructions to be used if crontab doesn't yet exist.
INSTRUCTIONS="
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command"
# Cronjob for main site.
MAIN_JOB="
# every 10th hour on the hour every day run backup_mariadb
0 10 * * * bash $HOME/trustnet/pgo/utility_scripts/backup_mariadb.sh"
# Wget cronjob for backup sites.
BACKUP_JOB="
# every 30th minute of the 10th hour every day run wget_mariadb_backup
30 10 * * * bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh
# every 0th minute of the 11th hour every day run restore_mariadb
0 11 * * * bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh"
# File location for server type indicator that will be used by ingress_filter.pl
SERVER_TYPE_FILE="$HOME/trustnet/pgo/htdocs/this_server_type.txt"
# Main or backup conditional.
if [[ "$1" == "main" ]]; then
	# Indicate to ingress_filter.pl this server will be main. Single > should clobber pre-existing file.
	echo -e "main" > $SERVER_TYPE_FILE
	# Set up proper cronjob.
	CRONJOB="$MAIN_JOB"
elif [[ "$1" == "backup" ]]; then
	# Indicate to ingress_filter.pl this server will be backup.
	echo -e "backup" > $SERVER_TYPE_FILE
	# Set up proper cronjob.
	CRONJOB="$BACKUP_JOB"
	# Create directory where logical backups from main will be kept.
	# wget script won't run without this directory already existing. Single > should clobber pre-existing file.
	mkdir -p $HOME/trustnet/pgo/mariadb_restores
else
	echo "Invalid parameter somehow! This should never run. Exiting..."
	exit 1 # Exit on generic error status.
fi
# Install cronjob functionality.
sudo apt-get install cron -y
# Check if crontab exists while catching error exit status which would trigger set -e.
if [ crontab -l > /dev/null 2>&1 ]; then
	echo "Found existing crontab. Running oneliner which will append our jobs if they have not yet been added."
	# if restore_mariadb is found in the existing crontab, || will exit this command.
	# if not found, append our jobs to existing.
	crontab -l | grep 'restore_mariadb' || (crontab -l; echo -e "$CRONJOB") | crontab -
else
	echo "Found no existing crontabs, creating one with default instructions and our wget, restore jobs."
	# Create new crontab by piping echo with variable replacement (-e) into crontab - which clobbers any existing crontabs.
	echo -e "$INSTRUCTIONS\n$CRONJOB" | crontab -
fi

#########################################################################################################################################
# Make sure we have TLS set up on this server somehow before launching docker--> containers--> Apache2 which would expose filestructure #
#########################################################################################################################################

#####################
#   Docker Setup    #
#####################
# Uninstall any docker-ish packages that could interfere with how docker runs.
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
# First check if /etc/apt/keyrings/docker.asc has proper permissions, if it does, assume this block already ran.
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update
# Install docker.
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Create docker network proxy (if not already existing) for contianer communication here so 'external:proxy' doesn't need to be changed ever.
sudo docker network inspect proxy >/dev/null 2>&1 || sudo docker network create proxy
# Run docker compose file docker-compose.yaml. This fill will download images and run the httpd (apache) and MariaDB containers in the background.
sudo docker compose up -d # Not sure of exit status here. I think it will exit 1 on error?

#########################################################################################################################################
# When we have a clearer picture of VPS / Prod Server, do an additional check here to make sure pgo is accessible on the open internet. #
#########################################################################################################################################

# If we're a backup pull data from main server.
if [[ "$1" == "backup" ]]; then
	# Get copy of database and restore it to this backup site.
	bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh
	bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh
	# Could test restore by having a test contents stored in main database. If that store gets populated, can reasonably assume restore will work.
fi

# Check if everything is set up. Report to user how it's going. 
echo -e "\n\nEverything should now be set up! RUNNING TEST SUITE..."

# Check if log directory was successfully created and owner is www-data. Catch exit status so this script doesn't stop running.
echo -e "\nRUNNING TEST: Checking logs directory setup..."
if [ LOG_OWNER=$(stat -c '%U' "$LOG_DIRECTORY") > /dev/null 2>&1 ]; then
	LOG_OWNER=$(stat -c '%U' "$LOG_DIRECTORY")
	if [[ "$LOG_OWNER" == "www-data" ]]; then
		echo "PASS: Logs directory set up with proper owner"
	else
		echo "FAIL: Logs directory exists but NOT SET UP WITH PROPER OWNER!"
	fi
else
	echo "FAIL: Logs directory DOES NOT EXIST! (It should have pulled with repo?)"
fi

# Check if file, contents got created for this_server_type.txt, report. Should match input parameter.
echo -e "\nRUNNING TEST: Checking if server 'type' file (indicating main or backup) is set up correctly."
if [ -e "$SERVER_TYPE_FILE" ]; then
	FILE_TYPE_CONTENTS=$(cat $SERVER_TYPE_FILE)
	if [[ "$FILE_TYPE_CONTENTS" == "$1" ]]; then
		echo "PASS: Server type file contents appear to be set up correctly."
	else
		echo "FAIL: Server type file contents are WRONG! Parameter $1 should match $FILE_TYPE_CONTENTS"
	fi
else
	echo "FAIL: Server type file DOES NOT EXIST!"
fi

# Check if crontab is set up to run, report.
echo -e "\nRUNNING TEST: Checking if Cronjobs are set up properly."
if [[ "$1" == "main" ]]; then
	# Run test for main.
	MAIN_JOB_TEST="0 10 * * * bash $HOME/trustnet/pgo/utility_scripts/backup_mariadb.sh"
	MAIN_TEST=$(crontab -l | grep -cF "$MAIN_JOB_TEST")
	if [ $MAIN_TEST -eq 1 ]; then
		echo "PASS: Main cronjob appears be set up properly."
	else
		echo "FAIL: Main cronjob appears to not be set up properly!"
	fi
elif [[ "$1" == "backup" ]]; then
	# Run test for backup.
	BACKUP_JOB_TEST1="30 10 * * * bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
	BACKUP_JOB_TEST2="0 11 * * * bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh"
	BACKUP_TEST1=$(crontab -l | grep -cF "$BACKUP_JOB_TEST1")
	BACKUP_TEST2=$(crontab -l | grep -cF "$BACKUP_JOB_TEST2")
	if [[ $BACKUP_TEST1 -eq 0 || $BACKUP_TEST2 -eq 0 ]]; then
		echo "FAIL: Backup cronjobs appear to not be set up properly!"
	else
		echo "PASS: Backup cronjobs appear to be set up properly."
	fi
else
	echo "INVALID SCRIPT! THIS SHOULD NEVER RUN!"
	exit 1 # Exit on generic error status.
fi

# Check status of pgo-apache2 container.
echo -e "\nRUNNING TEST: Checking if Apache, MariaDB containers are running."
if [[ "$(sudo docker inspect -f '{{.State.Status}}' "pgo-apache2")" == "running" ]]; then
    echo "PASS: pgo-apache2 container is running"
else
    echo "FAIL: pgo-apache2 container is NOT running"
fi

# Check status of pgo-mariadb container.
if [[ "$(sudo docker inspect -f '{{.State.Status}}' "pgo-mariadb")" == "running" ]]; then
    echo "PASS: pgo-mariadb container is running"
else
    echo "FAIL: pgo-mariadb container is NOT running"
fi

echo -e "\nLaunch script completed."


















