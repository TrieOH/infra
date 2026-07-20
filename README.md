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

## Forgejo Actions Runner

O runner (`forgejo-runner`) não se registra sozinho — depois de subir o compose, é preciso registrar manualmente uma vez:

```bash
docker run --rm -it \
  --network forgejo_internal \
  -v ~/infra/forgejo/runner/data:/data \
  -w /data \
  code.forgejo.org/forgejo/runner:12 \
  forgejo-runner register --no-interactive \
  --instance http://forgejo:3000 \
  --token <TOKEN> \
  --name trieoh-runner \
  --labels docker:docker://code.forgejo.org/forgejo/runner-images:ubuntu-22.04
```

Token vem de Site Admin → Actions → Runners → Create new Runner (ou por repo, Settings → Actions → Runners). 

Depois do registro, sobe o daemon normal:
```bash
docker compose -f forgejo/compose.yml up -d forgejo-runner
```
Ou se ele ja estiver de pe reinicie
```bash
docker compose -f forgejo/compose.yml restart forgejo-runner
```
