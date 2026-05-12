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

## Environment

Copy `.env` and fill in the values — `dotenv-rails` loads it automatically in development and test:

```
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=
DB_PASSWORD=
DB_NAME=toda_matematica_production   # only used in production

REDIS_URL=redis://localhost:6379/0

UPLOAD_DIR=                          # absolute path for file storage; defaults to storage/uploads/
```

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

### Infrastructure

| Gem | Role |
|---|---|
| `pg` | PostgreSQL adapter |
| `dotenv-rails` | Loads `.env` in development/test |
| `redis` | Rails cache (db 1) + Action Cable (db 0) in production |
| `solid_queue` | DB-backed Active Job (shares PostgreSQL primary in production) |
| `kamal` | Docker deployment — PostgreSQL and Valkey/Redis as Kamal accessories |
| `thruster` | HTTP asset caching/compression in front of Puma |

### Tests

Minitest with fixtures and parallelization enabled (`parallelize workers: :number_of_processors`). The CI seed step (`db:seed:replant`) validates seeds against a clean test DB. CI also spins up PostgreSQL 17 and Valkey 8 containers.

### Linting

RuboCop with `rubocop-rails-omakase` — no local overrides.
