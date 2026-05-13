#!/bin/bash
set -e

# Install docker.
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

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Run docker compose file docker-compose.yaml. This fill will download images and run the httpd (apache) and MariaDB containers in the background.
sudo docker compose up -d

# Create mariadb auto backup/restore folders.
#mkdir -p mariadb_backups
#mkdir -p htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA

mkdir -p htdocs/logs
# Make logs work by giving ownership of logs directory to apache
sudo chown -R www-data htdocs/logs

# Add cronjob for daily backup to main server.
sudo apt-get install cron -y
# Capture existing cronjobs to a bash variable.
#EXISTING_CRON=$(crontab -l)
# Main site job to add.
#MAIN_JOB="0 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/backup_mariadb.sh"
#GET_BACKUP="5 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
#RESTORE_JOB="10 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/restore_mariadb.sh"
# Set the entirety of the crontab contents (crontab -) to an echoed variable that consists of the captured existing file, a newline (must use -e), the new job in that order.

#echo -e "$EXISTING_CRON\n$MAIN_JOB" | crontab -
# Add cronjob for daily backup to main server.
sudo apt-get install cron -y
# Capture existing cronjobs to a bash variable.
#EXISTING_CRON=$(crontab -l)
# Main site job to add.
#MAIN_JOB="0 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/backup_mariadb.sh"
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
MAIN_JOB="0 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/backup_mariadb.sh"
GET_BACKUP="
# every 5th minute of the 10th hour every day
5 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
RESTORE_JOB="
# every 10th minute of the 10th hour every day
10 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/restore_mariadb.sh"
# Set the entirety of the crontab contents (crontab -) to an echoed variable that consists of the captured existing file, a newline (must use -e), the new job in that order.
#echo -e "$EXISTING_CRON\n$GET_BACKUP\n$RESTORE_JOB" | crontab -

# Set new crontab for backup server.
echo -e "$INSTRUCTIONS\n$GET_BACKUP\n$RESTORE_JOB" | crontab -
# Set new crontab for main server.
#echo -e "$INSTRUCTIONS\n$MAIN_JOB" | crontab -


# Add cronjob for daily backup to main server.
# Capture existing cronjobs to a bash variable.
#EXISTING_CRON=$(crontab -l)
# Main site job to add.
#MAIN_JOB="0 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/backup_mariadb.sh"
#GET_BACKUP="5 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
#RESTORE_JOB="10 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/restore_mariadb.sh"
# Set the entirety of the crontab contents (crontab -) to an echoed variable that consists of the captured existing file, a newline (must use -e), the new job in that order.
#echo -e "$EXISTING_CRON\n$GET_BACKUP\n$RESTORE_JOB" | crontab -
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
GET_BACKUP="
# every 5th minute of the 10th hour every day
5 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh"
RESTORE_JOB="
# every 10th minute of the 10th hour every day
10 10 * * * sh /home/maker/trustnet/pgo/utility_scripts/restore_mariadb.sh"
# Set the entirety of the crontab contents (crontab -) to an echoed variable that consists of the captured existing file, a newline (must use -e), the new job in that order.
#echo -e "$EXISTING_CRON\n$GET_BACKUP\n$RESTORE_JOB" | crontab -
echo -e "$INSTRUCTIONS\n$GET_BACKUP\n$RESTORE_JOB" | crontab -

# Keep index.html 
#mv index.html main_index.html
# Set index.html to the read only index to be used by backup servers.
#mv readonly_index.html index.html



