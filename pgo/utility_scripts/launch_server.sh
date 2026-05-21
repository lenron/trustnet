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

# Create logs folder.
mkdir -p $HOME/trustnet/pgo/htdocs/logs
# Make logs work by giving ownership of logs directory to apache.
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
if [[ crontab -l > /dev/null 2>&1 ]]; then
	echo "Found existing crontab. Running oneliner which will append our jobs if they have not yet been added."
	# if restore_mariadb is found in the existing crontab, || will exit this command.
	# if not found, append our jobs to existing.
	crontab -l | grep 'restore_mariadb' || (crontab -l; echo -e "$CRONJOB") | crontab -
else
	echo "Found no existing crontabs, creating one with default instructions and our wget, restore jobs."
	# Create new crontab by piping echo with variable replacement (-e) into crontab - which clobbers any existing crontabs.
	echo -e "$INSTRUCTIONS\n$CRONJOB" | crontab -
fi

########################################
#  MAKE SURE WE'RE BEHIND TLS SOMEHOW  #
########################################

#####################
#   Docker Setup    #
#####################
# Uninstall any docker-ish packages that could interfere with how docker runs.
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
#echo \
  #"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  #$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  #sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

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
# Run docker compose file docker-compose.yaml. This fill will download images and run the httpd (apache) and MariaDB containers in the background.
sudo docker compose up -d

#########################################
#     CHECK IF SERVER IS NOW UP?		#
#########################################

if [[ "$1" == "backup" ]]; then
	# Get copy of database and restore it to this backup site.
	bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh
	bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh
fi



# Check if everything is set up now?

# Check if file, contents got created for this_server_type, report. Should match input parameter.
# Check if crontab is set up to run, report.
# Check containers are running, report.
# Check 

echo "Setup completed successfully."


















