ARG         ALPINE_VERSION="${ALPINE_VERSION:-latest}"
FROM        alpine:${ALPINE_VERSION}

# SGnet proxy
ENV http_proxy=http://fr.proxy.saint-gobain.com:8080
ENV https_proxy=http://fr.proxy.saint-gobain.com:8080

LABEL       maintainer="https://github.com/github-clonner/docker-ssh-agent-forward"

ENV         CONF_VOLUME="/conf.d"
ENV         OPENSSH_VERSION="${OPENSSH_VERSION}" \
            CACHED_SSH_DIRECTORY="${CONF_VOLUME}/ssh" \
            AUTHORIZED_KEYS_VOLUME="${CONF_VOLUME}/authorized_keys" \
            ROOT_KEYPAIR_LOGIN_ENABLED="true" \
            ROOT_LOGIN_UNLOCKED="true" \
            USER_LOGIN_SHELL="/bin/bash" \
            USER_LOGIN_SHELL_FALLBACK="/bin/ash"

RUN         { set -eux; \
            \
            mkdir -p /root/.ssh "${CONF_VOLUME}" "${AUTHORIZED_KEYS_VOLUME}"; \
            chmod 700 /root/.ssh; \
}

EXPOSE      22
VOLUME      ["/ssh-agent", "/etc/ssh"]

RUN         { set -eux; \
            \ 
            apk add --upgrade --no-cache bash bash-completion rsync openssh socat tini; \
            cp -a /etc/ssh "${CACHED_SSH_DIRECTORY}"; \
            rm -rf /var/cache/apk/*; \
}

COPY        docker-entrypoint.sh /
COPY        ssh-entrypoint.sh /
COPY        conf.d/etc/ /etc/

ENTRYPOINT  ["/sbin/tini", "--", "/docker-entrypoint.sh"]

CMD         ["/usr/sbin/sshd", "-D"]
