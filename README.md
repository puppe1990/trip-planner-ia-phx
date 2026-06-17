
# TripPlanner IA (Phoenix + LiveView)

APP em Phoenix 1.8 + LiveView do planejador de viagens com IA.

<img width="800" height="447" alt="Screen Recording 2026-06-17 at 19 06 25" src="https://github.com/user-attachments/assets/bf63cffa-9f3c-435d-b6c0-7e01589f1dfe" />

## Stack

- Phoenix 1.8 + LiveView
- Turso / SQLite via `ecto_libsql`
- Google Gemini / NVIDIA NIM
- Tailwind CSS (design idêntico ao app React)
- ExUnit (TDD)

## Setup

```bash
cd ~/Desktop/Projetos/trip-planner-ia-phx
mix deps.get
./scripts/copy_env.sh   # copia .env do projeto ai-trip-planner
mix ecto.migrate
mix assets.setup && mix assets.build
mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000).

## Variáveis de ambiente

Veja `.env.example`. Principais:

| Variável                  | Descrição                           |
| ------------------------- | ----------------------------------- |
| `SECRET_KEY_BASE`         | Sessão Phoenix                      |
| `GEMINI_API_KEY`          | API Gemini                          |
| `NVIDIA_API_KEY`          | API NVIDIA NIM                      |
| `TURSO_DATABASE_URL`      | `libsql://...` (prod) ou path local |
| `TURSO_AUTH_TOKEN`        | Token Turso                         |
| `TRIP_PLANNER_MULTI_STEP` | `true` / `false`                    |

## Testes

```bash
mix test
```

## Scripts

| Comando                 | Descrição                      |
| ----------------------- | ------------------------------ |
| `mix phx.server`        | Dev server                     |
| `mix test`              | Testes ExUnit                  |
| `mix precommit`         | format + test                  |
| `./scripts/copy_env.sh` | Copia keys do projeto original |
