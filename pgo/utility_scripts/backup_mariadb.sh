#!/bin/bash
set -e

SHARED_PASSWORD="ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA"
MARIADB_DUMP="/home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz"
ENCRYPTED_DUMP="/home/maker/trustnet/pgo/htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz.enc"

# Run docker command inside container named pgo-mariadb: sudo docker exec -i pgo-mariadb
#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz
sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > $MARIADB_DUMP

# Encrypt using openssl and shared key.
openssl enc -aes-256-cbc -e -pbkdf2 -in $MARIADB_DUMP -out $ENCRYPTED_DUMP -pass pass:$SHARED_PASSWORD

# Cleanup backup file.
rm $MARIADB_DUMP


