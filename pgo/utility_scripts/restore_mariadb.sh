#!/bin/bash
set -e

# Decrypt using openssl.
#openssl enc -aes-256-cbc -e -pbkdf2 -in /home/maker/trustnet/pgo/mariadb_backup_$(date +%F).sql.gz -out htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz.enc -pass pass:ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA
openssl enc -aes-256-cbc -d -pbkdf2 -in  /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc -out /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz -pass pass:ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
gunzip -c /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

