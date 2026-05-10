#!/bin/bash
set -e

#wget obf.mkrsvr.org/backups/db_2026-05-10:03:38:01.sql.gz
gunzip -c /home/maker/trustnet/aes256cbc/restores/mariadb_backup_$(date +%F).sql.gz | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 
#gunzip -c /home/maker/trustnet/aes256cbc/restores/mariadb_test_$(date +%F).sql.gz | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

