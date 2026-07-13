# infra

Caddy (Caddyfile estático) + Forgejo (config via env vars nativas do Gitea/Forgejo,
`GITEA__section__KEY`) + Postgres isolado numa rede `internal: true` só pro Forgejo.
Um servidor, Docker Compose puro, sem Swarm.

```bash
cp caddy/.env.example caddy/.env       # ADMIN_USER_NAME / ADMIN_PASSWORD_HASH
cp forgejo/.env.example forgejo/.env   # domínio, secrets, senha do postgres
just setup   # ou ./setup.sh direto
```

Certs vêm de `/etc/letsencrypt` e `/etc/caddy/certs` no host (bind mount
`:ro`), não do repo.

Editou o Caddyfile? `just reload-caddy`.

Novo serviço atrás do Caddy: entra na rede `caddy-net`, adiciona o bloco no
`caddy/Caddyfile` (`reverse_proxy <nome-do-serviço>:<porta>` — o nome do
serviço no `services:` já é o DNS dele), `just reload-caddy`.

SSH do Forgejo continua fora do compose por natureza, sshd do host +
`docker exec` (ver `forgejo/ssh/`), porque o roteamento SSH tem que existir
antes do Docker entrar em cena.
