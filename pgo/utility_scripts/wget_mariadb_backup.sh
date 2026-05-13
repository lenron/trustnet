#!/bin/bash
set -e
# -P tells wget to place acquired file in first parameter directory
#wget -P /home/maker/trustnet/pgo/mariadb_restores https://obf.mkrsvr.org/mariadb_backups/mariadb_backup_$(date +\%F).sql.gz
wget -P /home/maker/trustnet/pgo/mariadb_restores https://obf.mkrsvr.org/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +\%F).sql.gz
