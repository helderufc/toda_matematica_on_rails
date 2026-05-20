# Toda Matemática — API

Rails 8.1 API-only para gestão de cursos, módulos, aulas e quizzes com geração de conteúdo via IA. Sem autenticação — aplicação de professor único.

## Stack

- **Ruby** 3.4.7 · **Rails** 8.1 · **PostgreSQL** 17
- **Redis / Valkey** 8 — cache (Solid Cache) e Action Cable
- **Solid Queue** — jobs em background (sem Redis extra, usa o PostgreSQL principal)
- **Kamal** — deploy via Docker · **Thruster** — proxy HTTP na frente do Puma

## Domínio

```
Course → Modulo → Lesson
           └──→ Quiz → Question → Alternative
```

Conteúdo gerado por IA é efêmero (armazenado no cache com TTL de 1 hora). O professor chama o endpoint `confirmar` para persistir ou `regerar` para sobrescrever.

## Primeiros passos

### Pré-requisitos

- Ruby 3.4.7 (`rbenv` / `asdf`)
- Docker (para PostgreSQL e Redis/Valkey)

### Configuração

```bash
# 1. Copie os arquivos de configuração
cp .env.example .env
cp compose.yml.example compose.yml

# 2. Edite .env e compose.yml com suas credenciais
# (DB_PASSWORD precisa bater nos dois arquivos)

# 3. Suba o banco e o Redis
docker compose up -d

# 4. Instale gems e prepare o banco
bin/setup --skip-server

# 5. Inicie o servidor
bin/dev
```

A API estará disponível em `http://localhost:3000`.

## Desenvolvimento

```bash
bin/dev                              # inicia o servidor
bin/rails test                       # todos os testes
bin/rails test test/models/foo_test.rb:42  # teste específico
bin/rubocop                          # lint
bin/brakeman --quiet --no-pager      # análise de segurança estática
bin/bundler-audit                    # auditoria de gems
bin/ci                               # pipeline completa (lint + segurança + testes)
```

```bash
docker compose up -d     # sobe postgres + redis
docker compose down      # para (dados persistem)
docker compose down -v   # para e apaga volumes
```

## API

### Cursos

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/courses` | Lista cursos |
| `GET` | `/courses/:id` | Detalhe do curso |
| `POST` | `/courses` | Cria curso |
| `GET` | `/courses/:id/modules` | Lista módulos do curso |
| `POST` | `/courses/:id/modules` | Cria módulo |

### Módulos

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/modules/:id` | Detalhe do módulo |
| `GET` | `/modules/:id/lessons` | Lista aulas |
| `POST` | `/modules/:id/lessons` | Cria aula |
| `GET` | `/modules/:id/quiz` | Detalhe do quiz |
| `POST` | `/modules/:id/quiz` | Cria quiz manual |

### Aulas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/lessons/:id` | Detalhe da aula |
| `POST` | `/lessons/:id/gerar-conteudo` | Gera conteúdo via IA (pendente) |
| `GET` | `/lessons/:id/conteudo-pendente` | Consulta conteúdo pendente |
| `POST` | `/lessons/:id/confirmar-conteudo` | Persiste o conteúdo gerado |
| `POST` | `/lessons/:id/regerar-conteudo` | Regenera o conteúdo (sobrescreve pendente) |

### Quiz IA

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/modules/:id/quiz/gerar` | Gera quiz via IA (pendente) |
| `GET` | `/modules/:id/quiz/pendente` | Consulta quiz pendente |
| `POST` | `/modules/:id/quiz/confirmar` | Persiste o quiz gerado |
| `POST` | `/modules/:id/quiz/regerar` | Regenera o quiz (sobrescreve pendente) |

### Questões e Alternativas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/quizzes/:id/questions` | Lista questões |
| `POST` | `/quizzes/:id/questions` | Cria questão (com alternativas) |
| `POST` | `/quizzes/:id/configurar` | Reonfigura o quiz |
| `GET` | `/questions/:id/alternatives` | Lista alternativas |
| `POST` | `/questions/:id/alternatives` | Cria alternativa |

### Health check

```
GET /up
```

## Testes de carga (k6)

Requer k6 instalado e a aplicação rodando.

```bash
k6 run scripts/regression.js                      # perfil completo (~11 min, até 2700 VUs)
k6 run --vus 1 --duration 30s scripts/regression.js  # smoke test rápido
```

## Deploy

O deploy é feito via Kamal. Consulte `config/deploy.yml` para configuração de servidores e acessórios (PostgreSQL e Valkey).

```bash
bin/kamal deploy
bin/kamal logs          # tail dos logs
bin/kamal console       # rails console no servidor
```
