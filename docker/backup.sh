#!/bin/bash
set -euo pipefail

while true; do
    now=$(date +%s)
    target=$(date -d 'today 02:00:00' +%s)
    if (( now >= target )); then
        target=$(date -d 'tomorrow 02:00:00' +%s)
    fi
    sleep "$((target - now))"

    filename="tandon-$(date +%Y%m%d-%H%M%S).sql.gz"
    temporary="/backups/.${filename}.tmp"
    MYSQL_PWD="$DB_PASSWORD" mariadb-dump \
        --host="$DB_HOST" \
        --user="$DB_USERNAME" \
        --single-transaction \
        --routines \
        --events \
        --databases "$DB_DATABASE" \
        | gzip > "$temporary"
    mv "$temporary" "/backups/$filename"
    find /backups -type f -name 'tandon-*.sql.gz' -mmin +10080 -delete
done