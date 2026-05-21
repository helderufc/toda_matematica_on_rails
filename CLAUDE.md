# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup              # Install gems + prepare DB + start dev server
bin/setup --skip-server  # Install gems + prepare DB only
bin/dev                # Start dev server
bin/ci                 # Full CI pipeline (lint + security + tests)

bin/rails test                             # Run all tests
bin/rails test test/models/foo_test.rb     # Run a single test file
bin/rails test test/models/foo_test.rb:42  # Run a single test

bin/rubocop                        # Lint Ruby
bin/brakeman --quiet --no-pager    # Static security analysis
bin/bundler-audit                  # Gem vulnerability audit

bin/rails db:prepare               # Create + migrate DB
bin/rails db:seed:replant          # Reset DB and re-seed (used in CI)
```

## Performance / Regression tests (k6)

`scripts/` holds two k6 scripts: `regression.js` — the full mixed-traffic profile documented below — and `gets.js`, a shorter GET-only load test. Everything below refers to `regression.js`.

**Pré-requisitos**: k6 instalado (`brew install k6` / `apt install k6` / [k6.io/docs/get-started/installation](https://k6.io/docs/get-started/installation)) e a aplicação rodando.

```bash
# Rodar contra o servidor local (perfil completo: estável 300 VUs, pico 2700 VUs)
k6 run scripts/regression.js

# Apontar para outro ambiente
BASE_URL=https://staging.example.com k6 run scripts/regression.js

# Saída com percentis detalhados
k6 run --summary-trend-stats='p(50),p(90),p(95),p(99),max' scripts/regression.js

# Smoke rápido (1 VU, 30 s) para verificar conectividade antes do load test
k6 run --vus 1 --duration 30s scripts/regression.js
```

**Perfil de carga** (total ≈ 11 min):

| Fase          | Duração | VUs  |
|---------------|---------|------|
| Aquecimento   | 1 min   | 0 → 300  |
| Estado estável| 3 min   | 300      |
| Subida ao pico| 2 min   | 300 → 2700 |
| Pico          | 2 min   | 2700     |
| Recuperação   | 2 min   | 2700 → 300 |
| Desaquecimento| 1 min   | 300 → 0  |

**Thresholds** (o teste falha se ultrapassados):

| Métrica                          | Limite     |
|----------------------------------|------------|
| Taxa de erros HTTP               | < 1 %      |
| p95 geral                        | < 500 ms   |
| p99 geral                        | < 1500 ms  |
| p95 leituras (`group: reads`)    | < 300 ms   |
| p95 escritas (`group: writes`)   | < 800 ms   |
| p95 fluxos IA (`group: ia`)      | < 1200 ms  |

**Divisão das iterações**: 75 % leituras (todos os GETs) · 20 % escrita (fluxo CRUD completo) · 5 % IA (gerar → pendente → confirmar/regerar).

O `setup()` cria um curso/módulo/aula/quiz dedicados ao load test antes das VUs subirem; esses IDs são reutilizados pelos cenários de leitura em todas as VUs.

## Environment

Copy `.env` and fill in the values — `dotenv-rails` loads it automatically in development and test:

```
DB_HOST=localhost
DB_PORT=5433                         # Postgres directly (dev / test / migrations)
DB_USERNAME=
DB_PASSWORD=
DB_NAME=toda_matematica_production   # only used in production

REDIS_URL=redis://localhost:6379/0

UPLOAD_DIR=                          # absolute path for file storage; defaults to storage/uploads/
```

In **production** the app connects to PostgreSQL through **PgBouncer** in transaction pooling mode (a Kamal accessory — see `config/deploy.yml`). `prepared_statements` is disabled in `database.yml` for transaction-mode compatibility. Locally `compose.yml` runs PgBouncer on `6432`, but dev, tests and migrations connect to Postgres directly on `5433`: the parallel test harness drops/recreates per-worker databases, which a pooler blocks. To exercise the app against PgBouncer locally, start the server with `DB_PORT=6432`.

## Architecture

Rails 8.1 **API-only** application (Ruby 3.4.7, PostgreSQL). `config.api_only = true` — no views, helpers, or asset pipeline. YJIT enabled globally via `config.yjit = true`.

### Domain model

```
Course (1) → (N) Modulo → (N) Lesson
Modulo (1) → (0..1) Quiz → (N) Question → (N) Alternative
```

All foreign keys cascade on delete. The `quizzes.module_id` column has a UNIQUE index — a module can have at most one quiz.

**The ActiveRecord model for modules is named `Modulo`** (`self.table_name = "modules"`) to avoid collision with Ruby's built-in `Module` constant. Controllers and routes still use the conventional `modules` path and `ModulesController`.

### Key domain rules

- **No authentication** — single professor, no login/session.
- **GET and POST only** — no PATCH, PUT, or DELETE endpoints anywhere.
- **AI-generated content is ephemeral** — generated lesson content and quizzes are stored in `PendingContentStore` (Rails.cache → Redis in production, memory store in dev/test), never auto-persisted. The professor calls a `confirmar` endpoint to write to the DB; regenerating overwrites the pending value; ignoring discards it silently. TTL is 1 hour.
- **File uploads** — lessons accept only PDF (validated by magic bytes `%PDF`). Course/module cover images validated by magic bytes (JPEG/PNG/GIF/WEBP). Files stored at `UPLOAD_DIR`. No Active Storage — custom `FileUploadService` handles everything.
- **Quiz creation** — manual quizzes must be submitted with questions and alternatives in one request (no empty quiz). Each question needs ≥ 2 alternatives and exactly 1 correct. This is enforced as a model validation on `Question` that checks the in-memory `alternatives` collection before save.
- **`order_num` is server-assigned** — modules, lessons, and questions carry a 1-based `order_num` the client never sends. `ApplicationController#save_with_next_order_num!` sets it to `MAX(order_num) + 1` within the parent scope and retries on the unique-index conflict when two inserts race. Quiz questions submitted in bulk via `QuizzesController#create` are numbered by array index instead.

### Services (`app/services/`)

| Service | Role |
|---|---|
| `FileUploadService` | Magic-byte validation + file storage under `UPLOAD_DIR` |
| `PendingContentStore` | Rails.cache wrapper for ephemeral AI-generated content |
| `AiService` | **Stub** — replace with real provider (Anthropic, OpenAI, etc.) |

### Controllers

| Controller | Endpoints |
|---|---|
| `CoursesController` | `GET /courses`, `GET /courses/:id`, `POST /courses` |
| `ModulesController` | `GET /courses/:id/modules`, `POST /courses/:id/modules`, `GET /modules/:id` |
| `LessonsController` | `GET /modules/:id/lessons`, `POST /modules/:id/lessons`, `GET /lessons/:id` |
| `QuizzesController` | `GET /modules/:id/quiz`, `POST /modules/:id/quiz`, `POST /quizzes/:id/configurar` |
| `QuestionsController` | `GET /quizzes/:id/questions`, `POST /quizzes/:id/questions` |
| `AlternativesController` | `GET /questions/:id/alternatives`, `POST /questions/:id/alternatives` |
| `LessonAiController` | `POST /lessons/:id/gerar-conteudo`, `GET /lessons/:id/conteudo-pendente`, `POST /lessons/:id/confirmar-conteudo`, `POST /lessons/:id/regerar-conteudo` |
| `QuizAiController` | `POST /modules/:id/quiz/gerar`, `GET /modules/:id/quiz/pendente`, `POST /modules/:id/quiz/confirmar`, `POST /modules/:id/quiz/regerar` |

All controllers inherit from `ApplicationController` (`ActionController::API`), which rescues `ActiveRecord::RecordNotFound` → `404 {"error": …}` and `ActiveRecord::RecordInvalid` → `422 {"errors": [...]}`. Invalid file uploads raise `ArgumentError`, caught per-action → `422 {"error": …}`. Model-validation failures return an `errors` array; every other error returns a singular `error` string.

Quiz-domain responses (quiz, question, alternative) are built by Alba serializers in `app/serializers/`; courses, modules, and lessons still serialize via `as_json`.

### Caching

Read endpoints are served from `Rails.cache`. **Every write action must expire the caches its data feeds** — the easiest invariant to break when adding endpoints.

- **List endpoints** use `Paginatable#cached_page` — key `"<namespace>/p<page>"`, 30 s TTL, 20 items per page (`Paginatable::PER_PAGE`). List responses carry `X-Total-Count` / `X-Page` / `X-Per-Page` / `X-Total-Pages` headers.
- **Show endpoints** (`courses`, `modules`, `lessons`) use `Rails.cache.fetch("<resource>/:id/show", …)`, 30 s TTL.
- **Quiz** reads are cached under `Quiz.cache_key_for_module(id)` → `"modules/:id/quiz"`, 5 min TTL.
- **Alternatives** use a single un-paginated key per question (the collection is always tiny).

Invalidation helpers on `ApplicationController`: `expire_page_cache(ns)` glob-deletes the paginated keys for a namespace; `expire_quiz_cache(module_id)` drops the quiz key. Show and alternative caches are cleared with a plain `Rails.cache.delete`. `PendingContentStore` shares the same `Rails.cache` but uses its own key namespace (`pending_lesson:`, `pending_quiz:`) — see the ephemeral-content rule above.

### Infrastructure

| Gem | Role |
|---|---|
| `pg` | PostgreSQL adapter |
| `dotenv-rails` | Loads `.env` in development/test |
| `redis` | Rails cache (db 1) + Action Cable (db 0) in production |
| `solid_queue` | DB-backed Active Job (shares PostgreSQL primary in production) |
| `kamal` | Docker deployment — PostgreSQL and Valkey/Redis as Kamal accessories |
| `thruster` | HTTP asset caching/compression in front of Puma |
| `alba` | JSON serialization for quiz-domain responses (`app/serializers/`), encoded via `oj` |

### Tests

Minitest with fixtures and parallelization enabled (`parallelize workers: :number_of_processors`). The CI seed step (`db:seed:replant`) validates seeds against a clean test DB. CI also spins up PostgreSQL 17 and Valkey 8 containers.

`testes.yaml` at the repo root is an Insomnia export — an importable collection of every endpoint for manual exploration.

### Linting

RuboCop with `rubocop-rails-omakase` — no local overrides.
