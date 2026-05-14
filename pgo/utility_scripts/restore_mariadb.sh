#!/bin/bash

# Exit on error. Not sure if we want this enabled?
set -e

SHARED_PASSWORD="ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA"
ENCRYPTED_FILE="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
DECRYPTED_FILE="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz"

# Decrypt using openssl.
#openssl enc -aes-256-cbc -d -pbkdf2 -in  /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc -out /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz -pass pass:ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA
openssl enc -aes-256-cbc -d -pbkdf2 -in $ENCRYPTED_FILE -out $DECRYPTED_FILE -pass pass:$SHARED_PASSWORD

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
#gunzip -c /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 
gunzip -c $DECRYPTED_FILE | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

