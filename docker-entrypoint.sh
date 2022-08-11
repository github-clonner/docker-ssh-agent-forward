#!/bin/sh
set -eo pipefail

# enable debug mode if desired
if [[ "${DEBUG}" == "true" ]]; then 
    set -x
fi

echo "$AUTHORIZED_KEYS" | base64 -d >/root/.ssh/authorized_keys

chown root:root /root/.ssh/authorized_keys

ssh-keygen -A

exec "$@"
