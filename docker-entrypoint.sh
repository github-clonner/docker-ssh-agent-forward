#!/bin/sh
set -eo pipefail

# enable debug mode if desired
[ "$DEBUG" == 'true' ] && set -x

echo "$AUTHORIZED_KEYS" | base64 -d >/root/.ssh/authorized_keys

chown root:root /root/.ssh/authorized_keys

ssh-keygen -A

exec "$@"
