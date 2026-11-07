#!/bin/sh
set -eu

: "${MQTT_USERNAME:?MQTT_USERNAME is required}"
: "${MQTT_PASSWORD:?MQTT_PASSWORD is required}"

password_dir=/tmp/mosquitto-passwd
password_file="$password_dir/passwordfile"
mkdir -p "$password_dir"
chown mosquitto:mosquitto "$password_dir"
chmod 700 "$password_dir"
umask 077
rm -f "$password_file"
mosquitto_passwd -b -c "$password_file" "$MQTT_USERNAME" "$MQTT_PASSWORD"
chown mosquitto:mosquitto "$password_file"
chmod 600 "$password_file"

exec /docker-entrypoint.sh /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf