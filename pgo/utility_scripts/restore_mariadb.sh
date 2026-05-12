#!/bin/bash
set -e

# pipe unzipped logical backup into mariadb instance running in pgo-mariadb docker container.
gunzip -c /home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz | sudo docker exec -i pgo-mariadb mariadb -u root -p'pwd' chatriwe_obf 

