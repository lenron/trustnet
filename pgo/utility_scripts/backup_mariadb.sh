#!/bin/bash
set -e

#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/aes256cbc/backups/db_$(date +%F:%H:%M:%S).sql.gz
#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/aes256cbc/backups/mariadb_$(date +%F).sql.gz

# Run docker command inside container named pgo-mariadb: sudo docker exec -i pgo-mariadb
# 
#sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/pgo/htdocs/mariadb_backups/mariadb_backup_$(date +%F).sql.gz
sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > /home/maker/trustnet/pgo/htdocs/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz

