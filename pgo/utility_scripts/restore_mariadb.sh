#!/bin/bash

# Exit on error.
set -e

source $HOME/trustnet/pgo/secrets/utility_scripts.env

ENCRYPTED_FILE="$HOME/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
DECRYPTED_FILE="$HOME/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz"

# Decrypt using openssl.
openssl enc -aes-256-cbc -d -pbkdf2 -in $ENCRYPTED_FILE -out $DECRYPTED_FILE -pass pass:$SHARED_OPENSSL_PASSWORD

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
# -c sends output to standard out, allowing piping into mariadb container in this case.
#gunzip -c $DECRYPTED_FILE | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 
gunzip -c $DECRYPTED_FILE | sudo docker exec -i pgo-mariadb mariadb -u root -p"$MARIADB_ROOT_PW" chatriwe_obf 

# Create log of date last updated. 
TIMESTAMP=$(date +"%H:%M on %A, %B %d, %Y UTC")
LOG_LOCATION="$HOME/trustnet/pgo/htdocs/auto_update_log.txt"
echo -e "Last updated: $TIMESTAMP" >> $LOG_LOCATION
