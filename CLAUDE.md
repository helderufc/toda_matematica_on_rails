# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup              # Install gems + prepare DB + start dev server
bin/setup --skip-server  # Install gems + prepare DB only
bin/dev                # Start dev server
bin/ci                 # Full CI pipeline (lint + security + tests)

bin/rails test                        # Run all tests
bin/rails test test/models/foo_test.rb  # Run a single test file
bin/rails test test/models/foo_test.rb:42  # Run a single test

bin/rubocop            # Lint Ruby
bin/brakeman --quiet --no-pager  # Static security analysis
bin/bundler-audit      # Gem vulnerability audit

bin/rails db:prepare   # Create + migrate DB
bin/rails db:seed:replant  # Reset DB and re-seed (used in CI)
```

## Architecture

Rails 8.1 **API-only** application (Ruby 3.4.7, SQLite). `config.api_only = true` — no views, helpers, or asset pipeline.

### Domain model

```
Course (1) → (N) Module → (N) Lesson
Module (1) → (0..1) Quiz → (N) Question → (N) Alternative
```

All cascades on delete. Module has a UNIQUE constraint on `quiz_id` — a module can have at most one quiz (RN09).

### Key domain rules

- **No authentication**: single professor exists, seeded. No login/session.
- **GET and POST only**: no PATCH, PUT, or DELETE endpoints anywhere.
- **AI-generated content is ephemeral**: generated lesson content and quizzes live in an **in-memory store** (Ruby hash/dict), never auto-persisted. The professor must explicitly call a `confirmar` endpoint to write to the database. Regenerating overwrites the in-memory value; ignoring discards it silently (RN04, RN05, RN14).
- **File uploads**: lessons accept only PDF (`application/pdf`). Course/module cover images are validated by magic bytes (not just MIME header) and must be `image/*`. Files stored locally under `UPLOAD_DIR` env var (RN03, RN12, RN13).
- **Quiz constraints**: manually-created quizzes must be submitted with questions and alternatives in the same request — there is no "empty quiz" creation. Each question needs ≥ 2 alternatives and exactly 1 correct (RN02, RN11).

### Infrastructure gems

| Gem | Role |
|---|---|
| `redis` | Rails cache store + Action Cable adapter in production |
| `solid_queue` | DB-backed Active Job backend (SQLite) |
| `kamal` | Docker deployment (Valkey/Redis accessory configured in `config/deploy.yml`) |
| `thruster` | Asset caching/compression in front of Puma |
| `image_processing` | Active Storage image variants |

### YJIT

YJIT is enabled globally via `config.yjit = true` in `config/application.rb`.

### Redis

`REDIS_URL` env var controls the Redis connection (default: `redis://localhost:6379`). Used for:
- **Action Cable** (`config/cable.yml`) — db 0 in production, `async` adapter in development
- **Rails cache** (`config/environments/production.rb`) — db 1, `:redis_cache_store`

CI spins up a Valkey container and sets `REDIS_URL=redis://localhost:6379/0`. Production uses a Valkey Kamal accessory.

Production uses two SQLite databases: primary and queue (cache and cable moved to Redis).

### Tests

Minitest with fixtures (`test/fixtures/`) and parallelization enabled. The CI seed step (`db:seed:replant`) runs in `RAILS_ENV=test` and validates that `db/seeds.rb` works cleanly against a fresh database.

### Linting

RuboCop with `rubocop-rails-omakase` — house style inherits Omakase defaults with no overrides currently set.
