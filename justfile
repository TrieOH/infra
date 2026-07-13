setup:
    ./setup.sh

down:
    (cd forgejo && docker compose down)
    (cd caddy && docker compose down)

reload-caddy:
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
