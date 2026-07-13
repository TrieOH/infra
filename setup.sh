#!/bin/sh
set -eu
cd "$(dirname "$0")"

docker network inspect caddy-net >/dev/null 2>&1 || docker network create caddy-net

[ -f caddy/.env ] || cp caddy/.env.example caddy/.env
(cd caddy && docker compose up -d)

[ -f forgejo/.env ] || cp forgejo/.env.example forgejo/.env
(cd forgejo && docker compose up -d)

sudo cp forgejo/ssh/forgejo-shell forgejo/ssh/gitea /usr/local/bin/
sudo chmod +x /usr/local/bin/forgejo-shell /usr/local/bin/gitea

id git >/dev/null 2>&1 || sudo useradd -m -s /usr/local/bin/forgejo-shell git
sudo usermod -s /usr/local/bin/forgejo-shell git

VOLUME_PATH="$(pwd)/forgejo/data/forgejo"
sudo mkdir -p /etc/ssh/sshd_config.d
cat <<SSHD | sudo tee /etc/ssh/sshd_config.d/50-forgejo.conf >/dev/null
Match User git
    AuthorizedKeysCommand /bin/cat ${VOLUME_PATH}/git/.ssh/authorized_keys
    AuthorizedKeysCommandUser root
    PermitTTY no
SSHD

sudo sshd -t
sudo systemctl reload ssh 2>/dev/null || sudo systemctl reload sshd

. ./forgejo/.env
echo "done: https://${FORGEJO_DOMAIN} | ssh -T git@localhost"
