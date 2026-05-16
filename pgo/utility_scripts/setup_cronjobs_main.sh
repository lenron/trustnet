#!/bin/bash

# Don't exit on error; script operates on if crontab -l fails (hasn't been set up yet).
#set -e

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
	#crontab -l | grep 'restore_mariadb' || (crontab -l; echo -e "$GET_BACKUP\n$RESTORE_JOB") | crontab -
	crontab -l | grep 'backup_mariadb' || (crontab -l; echo -e "$MAIN_JOB") | crontab -
else
	echo "Found no existing crontabs, creating one with default instructions and our wget, restore jobs."
	# Create new crontab by piping echo with variable replacement (-e) into crontab - which clobbers any existing crontabs.
	#echo -e "$INSTRUCTIONS\n$GET_BACKUP\n$RESTORE_JOB" | crontab -
	echo -e "$INSTRUCTIONS\n$MAIN_JOB" | crontab -
fi
