#!/bin/bash

# Exit on error.
# DO NOT TURN THIS OFF IN PROD.
# Needs to be on for logs/last updated to report truthfully.
set -e

ENCRYPTED_FILE="$HOME/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
DECRYPTED_FILE="$HOME/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz"
SHARED_PASSWORD="0WolcMhmnlGm+qhEBKqKRDrDL5uEC1+fna1usK3+Vj8L8KGjb2vbV1CiTXLLJvq6rr3xAviZnSuI"

# Decrypt using openssl.
openssl enc -aes-256-cbc -d -pbkdf2 -in $ENCRYPTED_FILE -out $DECRYPTED_FILE -pass pass:$SHARED_PASSWORD

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
# -c sends output to standard out, allowing piping into mariadb container in this case.
gunzip -c $DECRYPTED_FILE | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

# Create log of date last updated. 
#TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
TIMESTAMP=$(date +"%H:%M on %A, %B %d, %Y")
LOG_LOCATION="$HOME/trustnet/pgo/htdocs/auto_update_log.txt"
echo -e "Last updated: $TIMESTAMP" >> $LOG_LOCATION
