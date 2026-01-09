#!/bin/bash

BACKUP_DIR="/var/spool/asterisk/backup"
DATE=$(date +"%Y%m%d_%H%M")

DB1="asterisk"
DB2="asteriskcdrdb"

FILE1="$BACKUP_DIR/db-$DB1-$DATE.sql"
FILE2="$BACKUP_DIR/db-$DB2-$DATE.sql"

/usr/bin/mariadb-dump -h 127.0.0.1 -u root "$DB1" > "$FILE1"
RET1=$?

/usr/bin/mariadb-dump -h 127.0.0.1 -u root "$DB2" > "$FILE2"
RET2=$?

if [[ $RET1 -eq 0 && $RET2 -eq 0 ]]; then
    find "$BACKUP_DIR" -type f -name "db-*.sql" -mtime +14 -exec rm -f {} \;
fi

