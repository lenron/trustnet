#!/bin/bash
set -e

URL_LOCATION="https://obf.mkrsvr.org/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz.enc"
SAVE_LOCATION="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
USERNAME="username"
PASSWORD="password"

# -O saves to specific file location (overwriting older existing file).
wget --user $USERNAME --password $PASSWORD -O $SAVE_LOCATION $URL_LOCATION
