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

# Main or backup conditional.
if [[ "$1" == "main" ]]; then
	# Set up proper cronjob.
	CRONJOB="$MAIN_JOB"
	# Make sure long random directory exists for main backup -> readonly restore functionality.
elif [[ "$1" == "backup" ]]; then
	# Set up proper cronjob.
	CRONJOB="$BACKUP_JOB"
else
	echo "Invalid parameter somehow! This should never run. Exiting..."
	exit 1 # Exit on generic error status.
fi

# Create folder where mariadb backups reside. Keeping this in backup script but commented for visibility.
#mkdir -p htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA

# Create logs folder.
mkdir -p $HOME/trustnet/pgo/htdocs/logs
# Make logs work by giving ownership of logs directory to apache.
sudo chown -R www-data $HOME/trustnet/pgo/htdocs/logs

# Install cronjob functionality.
sudo apt-get install cron -y
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
GET_BACKUP="
# every 30th minute of the 10th hour every day run wget_mariadb_backup
30 10 * * * bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
# Mariadb restore cronjob for backup sites.
RESTORE_JOB="
# every 0th minute of the 11th hour every day run restore_mariadb
0 11 * * * bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh"

# Capture existing cronjobs to a bash variable (unused). Error indicates no existing cronjobs which should be caught by $? below.
EXISTING_CRON=$(crontab -l)
# $? returns exist status of most recent foreground process: 1 on error, 0 otherwise. Here we are checking if crontab -l returned error status.
# If crontab -l returned error, we need to create a new one.
if [[ $? -eq 0 ]]; then
	echo "Found existing crontab. Running oneliner which will append our jobs if they have not yet been added."
	# if restore_mariadb is found in the existing crontab, || will exit this command.
	# if not found, append our jobs to existing.
	crontab -l | grep 'restore_mariadb' || (crontab -l; echo -e "$GET_BACKUP\n$RESTORE_JOB") | crontab -
else
	echo "Found no existing crontabs, creating one with default instructions and our wget, restore jobs."
	# Create new crontab by piping echo with variable replacement (-e) into crontab - which clobbers any existing crontabs.
	echo -e "$INSTRUCTIONS\n$GET_BACKUP\n$RESTORE_JOB" | crontab -
fi

# Indicate to ingress_filter.pl the type of server (main or readonly) to compile, respond to request with (file exist means readonly site).
touch $HOME/trustnet/pgo/htdocs/readonly.txt

# Create directory where logical backups from main will be kept.
# wget script won't run without this directory already existing.
mkdir -p $HOME/trustnet/pgo/mariadb_restores





#####################
#   Docker setup    #
#####################
# Uninstall any docker-ish packages that could interfere with how docker runs.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Install docker.
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Run docker compose file docker-compose.yaml. This fill will download images and run the httpd (apache) and MariaDB containers in the background.
sudo docker compose up -d

# Check if server web accessible somehow?

# Get copy of database and restore it to this backup site.
bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh
bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh

