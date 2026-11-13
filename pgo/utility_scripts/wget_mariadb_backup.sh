#!/bin/bash

# wget_mariadb_backup.sh
# Download a logical backup from main server that will be copied over the database of this readonly server.

# Halt execution of this script if any command fails.
set -e

# Load environment variables.
source $HOME/trustnet/pgo/secrets/utility_scripts.env

# Set bash variables.
URL_LOCATION="https://obf.mkrsvr.org/$LONG_DIRECTORY/mariadb_backup_$(date +%F).sql.gz.enc"
SAVE_LOCATION="$HOME/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"

# Download logical backup from main server using wget.
# -O saves to specific file location (overwriting older existing file).
wget --user $USERNAME_DIR_ACCESS --password $PASSWORD_DIR_ACCESS -O $SAVE_LOCATION $URL_LOCATION
