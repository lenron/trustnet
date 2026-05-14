#!/bin/bash
set -e

#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/aes256cbc/backups/db_$(date +%F:%H:%M:%S).sql.gz

# Run docker command inside container named pgo-mariadb: sudo docker exec -i pgo-mariadb
#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/pgo/htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz
sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz

# Encrypt using openssl and shared key.
#openssl enc -aes-256-cbc -e -pbkdf2 -in htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_2026-05-14.sql.gz -out htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_2026-05-14.sql.gz.enc -pass pass:l
openssl enc -aes-256-cbc -e -pbkdf2 -in /home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz -out htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz.enc -pass pass:ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA

# Cleanup backup file.
rm /home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz


