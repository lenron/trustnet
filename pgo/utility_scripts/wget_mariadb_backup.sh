#!/bin/bash
set -e

URL_LOCATION="https://obf.mkrsvr.org/ya6K5EXJEN2TQW4VSvS0acE3SqmxyBDX4dJYZYFGRdXilEUG0ixZIHCOhkxHBY7nNPOz6FWSmoHVA/mariadb_backup_$(date +%F).sql.gz.enc"
SAVE_LOCATION="/home/maker/trustnet/pgo/mariadb_restores/mariadb_backup_$(date +%F).sql.gz.enc"
USERNAME="wV1yYhNvL+6I6hhCpK1dqYTg4jgTsl9ey4MJ0C1KjvS+vVrN360psRstFIZzNfOcsH8KzczeNYcP"
PASSWORD="42huHwCM4x9udYICC9rWFPBMer9LDadZQHWMRUwlExr56tGmVj5w4XUU5eRhxen+7GIYaMP2XW1x"

# -O saves to specific file location (overwriting older existing file).
wget --user $USERNAME --password $PASSWORD -O $SAVE_LOCATION $URL_LOCATION
