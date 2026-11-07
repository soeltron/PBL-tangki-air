#!/bin/sh
set -eu

: "${MQTT_USERNAME:?MQTT_USERNAME is required}"
: "${MQTT_PASSWORD:?MQTT_PASSWORD is required}"

password_file=/mosquitto/data/passwordfile
mkdir -p /mosquitto/data
umask 077
printf '%s\n%s\n' "$MQTT_PASSWORD" "$MQTT_PASSWORD" \
    | mosquitto_passwd -c "$password_file" "$MQTT_USERNAME"
chmod 600 "$password_file"

exec /docker-entrypoint.sh /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf