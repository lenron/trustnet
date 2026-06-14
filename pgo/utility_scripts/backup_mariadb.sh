#!/bin/bash
set -e

source $HOME/trustnet/pgo/secrets/utility_scripts.env

MARIADB_DUMP="$HOME/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz"
ENCRYPTED_DUMP="$HOME/trustnet/pgo/htdocs/$LONG_DIRECTORY/mariadb_backup_$(date +%F).sql.gz.enc"

# Run docker command inside container named pgo-mariadb: sudo docker exec -i pgo-mariadb
#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > $MARIADB_DUMP
sudo docker exec -i pgo-mariadb mariadb-dump -u root -p"$MARIADB_ROOT_PW" --single-transaction --all-databases | gzip > $MARIADB_DUMP

# Encrypt using openssl and shared key.
openssl enc -aes-256-cbc -e -pbkdf2 -in $MARIADB_DUMP -out $ENCRYPTED_DUMP -pass pass:$SHARED_OPENSSL_PASSWORD

# Cleanup backup file.
rm $MARIADB_DUMP

# Create log of date last backed up. 
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
LOG_LOCATION="$HOME/trustnet/pgo/auto_backup_log.txt"
echo -e "Last updated: $TIMESTAMP" >> $LOG_LOCATION
