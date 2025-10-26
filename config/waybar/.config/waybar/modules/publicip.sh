#!/usr/bin/env bash
# shellcheck disable=SC1091,SC1090

# Entries in publicip.conf:
#   IP_QUERY_URL: URL to query public IP of the system.
#     return: JSON object with "ip" field.
#     note: This URL will be queried with short intervals (60s for example),
#           therefore it may not be a good idea to use a public API with
#           a limited number of calls.
#   IP_INFO_URL: URL to query IP location.
#     placeholder: <ip>
#     return: JSON object with "country_code" field.
#     note: This URL will only be quetried when public IP changes or when "force" is given as parameter.

path="$(dirname "$(readlink -f "$0")")"
cache_file="$path/publicip.cache"
config_file="$path/publicip.conf"
time_log="$path/publicip.log"

[ -f "$config_file" ] || exit 1
. "$config_file"
[ -z "$IP_QUERY_URL" ] && exit 1
[ -z "$IP_INFO_URL" ] && exit 1
[ "$1" == "force" ] && rm -f "$cache_file"
[ -f "$cache_file" ] && . "$cache_file"

# Try to check network connectivity before querying
if ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    # No network, return cached values if available
    [ -z "$CACHED_IP" ] && CACHED_IP="N/A"
    [ -z "$CACHED_CODE" ] && CACHED_CODE="N/A"

    echo "$(date +%Y-%m-%dT%H:%M:%S) - Waiting for network" >>"$time_log"

    jq -n --unbuffered --compact-output \
        --arg ip "$CACHED_IP" \
        --arg country "$CACHED_CODE" \
        '{alt: $ip, text: $country}'
    exit 0
fi

ip_current=$(curl -s -L -4 "$IP_QUERY_URL" | jq -r '.ip')
[ -z "$ip_current" ] && exit 1

if [ "$ip_current" != "$CACHED_IP" ]; then
    echo "$(date +%Y-%m-%dT%H:%M:%S) - IP changed: $CACHED_IP -> $ip_current" >>"$time_log"
    CACHED_IP="$ip_current"

    ip_info_url=${IP_INFO_URL//<ip>/$ip_current}
    CACHED_CODE=$(curl -s -L "$ip_info_url" | jq -r '.country_code')
    [ -z "$CACHED_CODE" ] && CACHED_CODE="N/A"

    echo "CACHED_IP=$CACHED_IP" >"$cache_file"
    echo "CACHED_CODE=$CACHED_CODE" >>"$cache_file"
    notify-send "New Public IP detected" "New IP: $ip_current\nCountry: $CACHED_CODE"
fi

jq -n --unbuffered --compact-output \
    --arg ip "$CACHED_IP" \
    --arg country "$CACHED_CODE" \
    '{alt: $ip, text: $country}'

