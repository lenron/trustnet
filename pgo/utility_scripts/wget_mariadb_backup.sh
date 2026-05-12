#!/bin/bash
set -e
# -P tells wget to place acquired file in first parameter directory
wget -P /home/maker/trustnet/aes256cbc/mariadb_restores https://obf.mkrsvr.org/mariadb_backups/mariadb_backup_$(date +\%F).sql.gz
