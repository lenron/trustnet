#!/bin/bash
set -e

sudo docker exec -i pgo-mariadb mariadb-dump -u root -p'pwd' --single-transaction --all-databases | gzip > backups/db_$(date +%F).sql.gz

