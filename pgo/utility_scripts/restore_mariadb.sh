#!/bin/bash

# Exit on error. Not sure if we want this enabled?
set -e

SHARED_PASSWORD="0WolcMhmnlGm+qhEBKqKRDrDL5uEC1+fna1usK3+Vj8L8KGjb2vbV1CiTXLLJvq6rr3xAviZnSuI"
ENCRYPTED_FILE="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
DECRYPTED_FILE="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz"

# Decrypt using openssl.
openssl enc -aes-256-cbc -d -pbkdf2 -in $ENCRYPTED_FILE -out $DECRYPTED_FILE -pass pass:$SHARED_PASSWORD

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
# -c sends output to standard out, allowing piping into mariadb container in this case.
gunzip -c $DECRYPTED_FILE | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

