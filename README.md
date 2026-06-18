# TripPlanner IA (Phoenix + LiveView)

Planejador de viagens com IA, reescrito em **Phoenix 1.8 + LiveView**. Gera roteiros personalizados (destino, duração, orçamento, estilo, companhia), salva viagens e oferece suporte a trânsito e i18n (PT/EN).

**Produção:** [https://trip.gestaobem.com](https://trip.gestaobem.com)  
**Repositório:** [github.com/puppe1990/trip-planner-ia-phx](https://github.com/puppe1990/trip-planner-ia-phx)

<img width="800" height="447" alt="Screen Recording 2026-06-17 at 19 06 25" src="https://github.com/user-attachments/assets/bf63cffa-9f3c-435d-b6c0-7e01589f1dfe" />

## Funcionalidades

- Geração de roteiros com **Google Gemini** ou **NVIDIA NIM**
- Modo multi-step ou prompt único (`TRIP_PLANNER_MULTI_STEP`)
- Autenticação com `phx.gen.auth` (registro, login, sessão persistente)
- Viagens salvas por usuário
- Destinos rápidos, informações de trânsito e visualização estruturada do roteiro
- Interface em português e inglês

## Stack

| Camada   | Tecnologia                            |
| -------- | ------------------------------------- |
| Backend  | Phoenix 1.8, LiveView, Ecto           |
| Banco    | Turso / SQLite (`ecto_libsql`)        |
| IA       | Google Gemini, NVIDIA NIM             |
| Frontend | Tailwind CSS v4, HEEx                 |
| Produção | AWS Lightsail, Caddy (HTTPS), systemd |
| Testes   | ExUnit, `mix precommit`               |

## Desenvolvimento local

```bash
git clone https://github.com/puppe1990/trip-planner-ia-phx.git
cd trip-planner-ia-phx
mix deps.get
./scripts/copy_env.sh          # Netlify ou projeto ai-trip-planner
mix ecto.migrate
mix assets.setup && mix assets.build
mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000).

### Variáveis de ambiente

Copie `.env.example` para `.env` ou use `./scripts/copy_env.sh`.

| Variável                  | Descrição                                       |
| ------------------------- | ----------------------------------------------- |
| `SECRET_KEY_BASE`         | Sessão Phoenix                                  |
| `GEMINI_API_KEY`          | API Gemini                                      |
| `NVIDIA_API_KEY`          | API NVIDIA NIM                                  |
| `AI_PROVIDER`             | `gemini` ou `nvidia-nim`                        |
| `AI_MODEL`                | Modelo (padrão: `gemini-2.5-flash`)             |
| `TURSO_DATABASE_URL`      | `libsql://...` (prod) ou path local             |
| `TURSO_AUTH_TOKEN`        | Token Turso                                     |
| `TRIP_PLANNER_MULTI_STEP` | `true` / `false`                                |
| `PHX_HOST`                | Host local (`localhost`) ou domínio de produção |

### Sync de env do Netlify

Para puxar variáveis do app legado TanStack/Netlify:

```bash
./scripts/copy_env_from_netlify.sh
# ou
./scripts/copy_env.sh
```

O script converte `BETTER_AUTH_SECRET` em `SECRET_KEY_BASE` quando necessário.

### Testes

```bash
mix test
mix precommit   # format + credo + test
```

## Produção (AWS Lightsail)

Deploy com **build nativo no servidor** (linux/amd64), **Caddy** para HTTPS automático e **systemd** (`trip_planner_ia`).

```
┌─────────────┐     HTTPS      ┌────────┐     :4000     ┌──────────────────┐
│   Browser   │ ──────────────▶│ Caddy  │ ─────────────▶│ trip_planner_ia  │
└─────────────┘                └────────┘               │ (Phoenix release)│
                                                        └────────┬─────────┘
                                                                 │
                                                                 ▼
                                                        ┌──────────────────┐
                                                        │ Turso (libsql)   │
                                                        └──────────────────┘
```

**Instância atual:** `trip-planner-ia` · IP estático `100.59.80.29` · região `us-east-1`

### Atualizar o código no servidor

**Duplo clique (Mac):** `update.command`

**Terminal:**

```bash
./scripts/deploy/update.sh
```

O script envia o código, compila o release no servidor, roda migrations e reinicia a app.

### Configuração local do deploy

```bash
cp scripts/deploy/deploy.local.env.example scripts/deploy/deploy.local.env
```

Edite IP, domínio e chave SSH. Esse arquivo fica no `.gitignore`.

| Variável         | Descrição                                       |
| ---------------- | ----------------------------------------------- |
| `DEPLOY_IP`      | IP estático do Lightsail                        |
| `DEPLOY_HOST`    | Domínio público (usado no Caddy e health check) |
| `DEPLOY_SSH_KEY` | Chave PEM do Lightsail                          |
| `DEPLOY_USER`    | Usuário SSH (padrão: `ubuntu`)                  |

### Primeiro deploy / servidor novo

```bash
# 1. Criar instância Lightsail
./scripts/deploy/provision.sh

# 2. Bootstrap: Caddy, systemd, env de produção
export DEPLOY_HOST=seu-dominio.com
export CADDY_EMAIL=seu@email.com
./scripts/deploy/sync-production-env.sh
./scripts/deploy/bootstrap-server.sh

# 3. Build e deploy
./scripts/deploy/update.sh
```

### Domínio customizado

1. **DNS** — registro **A** apontando para o IP estático do Lightsail:
   - `@` ou subdomínio (ex.: `trip`) → `100.59.80.29`
2. **Servidor** — com DNS propagado:

```bash
export DEPLOY_HOST=trip.gestaobem.com
export CADDY_EMAIL=seu@email.com
./scripts/deploy/sync-production-env.sh
./scripts/deploy/bootstrap-server.sh
ssh -i ~/.ssh/lightsail-default-key-us-east-1.pem ubuntu@100.59.80.29 \
  'sudo systemctl restart trip_planner_ia caddy'
```

SSL é automático via **Caddy + Let's Encrypt**. Não precisa configurar certificado manualmente.

> **Dica DNS:** cole o IP sem espaços extras. Se o painel reclamar de IPv4 inválido, tente digitar manualmente ou usar apenas os dígitos e pontos.

### Banco Turso compartilhado

Produção usa o mesmo banco Turso do app legado (TanStack/Netlify). Se migrations estiverem marcadas como aplicadas sem terem rodado de fato, pode haver drift de schema (ex.: coluna `users.name`, timestamps em `saved_trips`). Após mudanças de schema, valide no Turso ou rode `mix ecto.migrate` em produção via `update.sh`.

## Arquivos sensíveis (não commitar)

| Arquivo                           | Conteúdo                              |
| --------------------------------- | ------------------------------------- |
| `.env`                            | Chaves de API, tokens, secrets locais |
| `tmp/production.env`              | Env gerado para o servidor            |
| `scripts/deploy/deploy.local.env` | IP, domínio e chave SSH locais        |
| `priv/data/*.db`                  | SQLite de desenvolvimento             |

O repositório pode conter IPs e hosts de infraestrutura nos defaults dos scripts — isso **não** inclui API keys.

## Scripts

| Comando                                   | Descrição                                  |
| ----------------------------------------- | ------------------------------------------ |
| `mix phx.server`                          | Dev server                                 |
| `mix test`                                | Testes ExUnit                              |
| `mix precommit`                           | format + credo + test                      |
| `./scripts/copy_env.sh`                   | Copia `.env` (Netlify ou projeto local)    |
| `./scripts/copy_env_from_netlify.sh`      | Sync env do Netlify                        |
| `./scripts/deploy/update.sh`              | Build no servidor + migrate + restart      |
| `./update.command`                        | Atalho Mac para `update.sh`                |
| `./scripts/deploy/bootstrap-server.sh`    | Caddy, systemd, env de produção            |
| `./scripts/deploy/provision.sh`           | Cria instância Lightsail                   |
| `./scripts/deploy/sync-production-env.sh` | Gera env de produção com `PHX_HOST`        |
| `./scripts/deploy/build-on-server.sh`     | Envia código e compila release no servidor |

## Estrutura do projeto

```
lib/trip_planner_ia/          # Contextos: Accounts, Trips, Planner, Llm, Transit…
lib/trip_planner_ia_web/      # LiveViews, controllers, components
scripts/deploy/               # Provisionamento e deploy Lightsail
deploy/                       # Caddyfile, env.production.example
rel/                          # Release OTP
```

## Licença

Projeto privado — uso conforme acordado com os mantenedores.
