#!/bin/bash

# Stop running this script if any command returns exit status -- necessary for accurate reporting.
set -e

generate_key() {
	# Trim (tr) all non-alphanumeric chars (-dc), keeping 'a-zA-Z0-9' produced by /dev/urandom, stop once we have 32 chars.
	tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32
} # generate_key()

parse_parameters() {
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
} # parse_parameters()

build_logs() {
	# Set logs directory.
	LOG_DIRECTORY="$HOME/trustnet/pgo/logs"
	# Create logs folder if it doesn't already exist.
	mkdir -p $LOG_DIRECTORY
	# Apache runs the process that runs the backend scripts that create logs. If Apache doesn't have ownership of the directory or something similar, logs won't get created.
	sudo chown -R www-data $HOME/trustnet/pgo/logs
} # build_logs()

build_secrets() {
	SECRETS_DIRECTORY="$HOME/trustnet/pgo/secrets"
	SMTP_CREDS_LOCATION="$SECRETS_DIRECTORY/email_creds"
	if [[ $1 == "main" ]]; then
		# Check for existence of /secrets and create if not 
		if [ -d $SECRETS_DIRECTORY ]; then
			echo "Found secrets directory. To rebuild from scratch, delete secrets directory before running this script."
		else
			echo "Did not find secrets directory. Creating..."
			mkdir -p $SECRETS_DIRECTORY
		fi

		# List of files in secrets directory.
		MARIADB_LOGIN_LOCATION="$SECRETS_DIRECTORY/mariadb_login"
		MARIADB_PASSWORD_LOCATION="$SECRETS_DIRECTORY/mariadb_pw"
		MARIADB_ROOT_PASSWORD_LOCATION="$SECRETS_DIRECTORY/mariadb_root_pw"
		ENV_LOCATION="$SECRETS_DIRECTORY/utility_scripts.env"

		if [ -s "$SMTP_CREDS_LOCATION" ]; then
			echo "SMTP credentials file looks OK."
		else
			# Fill email_creds with input generated from user.
			echo "Now setting up SMTP for automatic email functionality."
			read -p "Please enter SMTP server: " SMTP_SERVER
			read -p "Please enter SMTP username: " SMTP_USERNAME
			read -p "Please enter SMTP password/token: " SMTP_PASSWORD
			read -p "Please enter SMTP port (probably 587): " SMTP_PORT
			cat <<- EOF > $SMTP_CREDS_LOCATION
				# Variables for swaks email functionality. 
				username:$SMTP_USERNAME
				password:$SMTP_PASSWORD
				server:$SMTP_SERVER
				port:$SMTP_PORT
			EOF
		fi

		# Create and fill utility_scripts.env
		if [ -s "$ENV_LOCATION" ]; then
			echo "Utility scripts's .env file looks OK."
		else
			# Generate keys, add to utility_scripts.env file.
			username_dir_access=$(generate_key)
			password_dir_access=$(generate_key)
			long_directory=$(generate_key)
			shared_openssl_password=$(generate_key)
			mariadb_root_pw=$(generate_key)
			cat <<- EOF > $ENV_LOCATION
				USERNAME_DIR_ACCESS=$username_dir_access
				PASSWORD_DIR_ACCESS=$password_dir_access
				LONG_DIRECTORY=$long_directory
				SHARED_OPENSSL_PASSWORD=$shared_openssl_password
				MARIADB_ROOT_PW=$mariadb_root_pw
			EOF
			# Install htpasswd creator
			sudo apt-get install apache2-utils -y
			# Generate .htpasswd with generated keys.
			HTPASSWD_LOCATION="$HOME/trustnet/pgo/.htpasswd"
			htpasswd -cb -B $HTPASSWD_LOCATION $username_dir_access $password_dir_access
			sudo chmod 644 $HTPASSWD_LOCATION
			# Generate new long directory
			mkdir $HOME/trustnet/pgo/htdocs/$long_directory
			# Place .htaccess inside it that points to .htpasswd location
			cat <<- EOF > $HOME/trustnet/pgo/htdocs/$long_directory/.htaccess
				# Activate Basic Auth (with username/password)
				AuthType Basic
				AuthName "restricted area"
				AuthUserFile "/usr/local/apache2/.htpasswd"
				require valid-user

				# Make this directory visible to public web.
				Options +Indexes
			EOF
		fi

		# Check if file exists and is not empty.
		if [ -s "$MARIADB_LOGIN_LOCATION" ]; then
			echo "MariaDB login file looks OK."
		else
			# If it doesn't look OK just make new one.
			echo "Generating MariaDB login file."
			generate_key > $MARIADB_LOGIN_LOCATION
		fi

		if [ -s "$MARIADB_PASSWORD_LOCATION" ]; then
			echo "MariaDB password file looks OK."
		else
			echo "Generating MariaDB password file."
			generate_key > $MARIADB_PASSWORD_LOCATION
		fi

		if [ -s "$MARIADB_ROOT_PASSWORD_LOCATION" ]; then
			echo "MariaDB root password file looks OK."
		else
			echo "Copying MariaDB root password file."
			echo $mariadb_root_pw > $MARIADB_ROOT_PASSWORD_LOCATION
		fi
	else # Don't gen secrets directory, keys if we're a backup.
		if [ ! -d $SECRETS_DIRECTORY ]; then
			# Maybe check all files too?
			# Inform user they need secrets directory from main.
			echo -e "Secrets directory not found! This server was specified as backup; please copy secrets directory and containing keys from main server into $SECRETS_DIRECTORY"
		else
			# If we're a backup and secrets directory exists, make sure email_creds is empty. All email set up to send from main server (contact.html not accessible on backup).
			touch $SMTP_CREDS_LOCATION
		fi
	fi
} # build_secrets()

setup_crontabs() {
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
} # setup_crontabs()

#########################################################################################################################################
# Make sure we have TLS set up on this server somehow before launching docker--> containers--> Apache2 which would expose filestructure #
#########################################################################################################################################
check_tls() {
	echo "TBD - The check for TLS will go here."
} # check_tls()

#####################
#   Docker Setup    #
#####################
setup_docker_and_containers() {
	# Uninstall any docker-ish packages that could interfere with how docker runs.
	sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
	# First check if /etc/apt/keyrings/docker.asc has proper permissions, if it does, assume this block already ran.
	# Add Docker's official GPG key:
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
	# Run docker compose file docker-compose.yaml which contains the 'Infrastructure as Code'.
	# This will download container images for httpd (apache2) and MariaDB and run them in the background (-d option - detach).
	sudo docker compose up -d # Not sure of exit status here. I think it will exit 1 on error?
} # setup_docker()

#########################################################################################################################################
# When we have a clearer picture of VPS / Prod Server, do an additional check here to make sure pgo is accessible on the open internet. #
#########################################################################################################################################
check_server_is_up() {
	echo "TBD - Here check that server is accessible on the open internet via prod URL."
} # check_server_is_up()

if_backup_pull_database_from_main_server() {
	# If we're a backup pull data from main server.
	if [[ "$1" == "backup" ]]; then
		echo "Waiting 5 seconds for mysqld socket and mariadb database setup..."
		sleep 5
		echo "Done waiting, now pulling database from main server"
		# Get copy of database and restore it to this backup site.
		bash $HOME/trustnet/pgo/utility_scripts/wget_mariadb_backup.sh
		bash $HOME/trustnet/pgo/utility_scripts/restore_mariadb.sh
		# Could test restore by having a test contents stored in main database. If that store gets populated, can reasonably assume restore will work.
	fi
} # if_backup_pull_database_from_main_server()

test_containers() {
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

} # test_containers()


# Main Function - must go after function declarations it uses.
main() {
	# Prepare Ubuntu to install programs. This also functions as a check for internet, etc.
	sudo apt-get update -y && sudo apt-get upgrade -y
	# Make sure input was gathered from user.
	# "$@" passes in command line argument variables. Doesn't appear to cause problems if those vars aren't used in function!
	parse_parameters "$@"
	# Build logs directory.
	build_logs "$@"
	# Build secrets directory with secrets files. These are 'server keys'. Must be copied over manually.
	build_secrets "$@"
	# Set up crontabs.
	setup_crontabs "$@"
	# Make sure TLS is active. -- To be determined how to do this - will depend on VPS setup.
	check_tls "$@"
	# Install Docker then create and start containers.
	setup_docker_and_containers "$@"
	# Check if this is a backup server and if so copy over the main database.
	if_backup_pull_database_from_main_server "$@"
	# Check container creation.
	test_containers "$@"
	# Check server is running. -- TBD - will depend on final, VPS setup.
	check_server_is_up "$@"
	# Report that we reached the end of the script.
	echo -e "\nLaunch script completed."
}

# Execute main function. following with "$@" passes in to the function the command line arguments.
# Then using "$@" on each internal function passes the arguments in to those functions 'as-is'
main "$@"













