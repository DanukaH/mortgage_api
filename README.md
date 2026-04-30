# Mortgage Application API

A Rails 8.1 JSON API for submitting mortgage applications and running basic affordability assessments.

## Tech Stack

- Ruby 3.4 (see `.ruby-version`)
- Rails 8.1.3
- SQLite3
- Solid Queue (background jobs)
- RSpec, FactoryBot, Shoulda Matchers

## Setup

```bash
git clone <repo-url>
cd mortgage_api
bundle install
rails db:migrate
```

## Run the Application

```bash
bin/rails server
```

API available at `http://localhost:3000`.

In a separate terminal, start the background job processor:

```bash
bin/jobs
```

## Run Tests

```bash
bundle exec rspec
```

Covers model validations, affordability business logic, authentication, background processing, logging, and end-to-end request behaviour.

## Authentication

All `/api/v1/...` endpoints are protected with **HTTP Basic Authentication**.

Unauthenticated requests return `401 Unauthorized`.

### Credentials

Credentials are stored in Rails encrypted credentials (`config/credentials.yml.enc`):

```yaml
api_username: <your-username>
api_password: <your-password>
```

Edit them with:

```bash
EDITOR="nano" rails credentials:edit
```

They can also be overridden at runtime via the `API_USERNAME` and `API_PASSWORD` environment variables, which is handy for Docker / Kamal deploys.

### Example

```bash
curl -u admin:password123 http://localhost:3000/api/v1/mortgage_applications
```

### Implementation Notes

- Uses the built-in `authenticate_or_request_with_http_basic` helper
- `ActiveSupport::SecurityUtils.secure_compare` provides constant-time comparison to mitigate timing attacks
- Both username and password comparisons always run (`&` instead of `&&`) to remove timing side-channels
- Encapsulated in a concern (`app/controllers/concerns/authenticatable.rb`) so the strategy can be swapped later (e.g. JWT, OAuth) without touching controllers

## Background Processing

Affordability assessments run asynchronously using **Solid Queue** (database-backed Active Job).

### Why Solid Queue over Sidekiq?

Solid Queue ships with Rails 8 and uses the existing database, so there's no Redis dependency to deploy or monitor. For a small service like this — with modest throughput and a single job type — that simplicity is a net win. It also allows jobs to be enqueued inside a database transaction, so a rolled-back transaction cleanly removes any queued work. For higher-throughput workloads or complex batch workflows I'd reach for Sidekiq.

### Flow

1. `GET /api/v1/mortgage_applications/:id/assessment` while `status = pending`:
   - Enqueues an `AffordabilityAssessmentJob`
   - Updates status to `assessing`
   - Returns `202 Accepted`
2. While the job is processing, the same endpoint returns `202 Accepted` with `status: assessing`
3. Once the job completes, the endpoint returns `200 OK` with the persisted result (LTV, DTI, decision, etc.)

### Running the Job Processor

In development, start the processor in a separate terminal:

```bash
bin/jobs
```

In production (via Kamal), `bin/jobs` runs as a separate container — see the Docker section below.

## Logging & Instrumentation

The application emits **structured (JSON) log events** for key business moments, so they can be parsed directly by tools like Datadog, Splunk, or CloudWatch Insights.

### Tagged log lines

Every log entry is tagged with the `request_id` and `remote_ip`:

```
[abcd-1234-…] [203.0.113.5] Started POST "/api/v1/mortgage_applications" ...
```

This makes it possible to trace a single request across the controller, service, and background job.

### Business events

| Event | Where | Purpose |
|-------|-------|---------|
| `assessment_queued` | controller | Records the moment a user requests an assessment |
| `affordability_assessment_completed` | service | Captures the decision + ratios for auditing/metrics |
| `affordability_assessment_job_completed` | job | Records `duration_ms` for performance tracking |
| `affordability_assessment_skipped` | job | Records idempotent skip when already assessed |

### Example

```json
{"event":"affordability_assessment_completed","application_id":42,"decision":"approved","loan_to_value":0.9,"debt_to_income":0.4157,"maximum_borrowing":270000.0}
```

### Implementation Notes

- **Monotonic clock for durations** — uses `Process.clock_gettime(Process::CLOCK_MONOTONIC)` rather than `Time.current` so duration measurements are immune to wall-clock adjustments.
- **JSON-shaped payloads** — pre-formatted so log aggregators can index fields without regex parsing.
- **Tagged logs** — request ID propagation makes end-to-end tracing trivial in production.

## Docker

The application ships with a production-ready `Dockerfile` and a Kamal deployment configuration (`config/deploy.yml`).

### Build the image

```bash
docker build -t mortgage_api .
```

### Run the application

The API runs as **two processes** — a web server and a background job processor — so we run them as two containers sharing a volume for the SQLite database.

A convenience script `bin/docker-up` is included to start both:

```bash
bin/docker-up
```

This:
- Stops and removes any existing `mortgage_api_web` / `mortgage_api_jobs` containers
- Starts `mortgage_api_web` (Puma) on port 3000
- Starts `mortgage_api_jobs` (Solid Queue) processing the queue
- Mounts a shared `mortgage_api_storage` volume so both containers see the same SQLite database

### Logs

```bash
docker logs -f mortgage_api_web
docker logs -f mortgage_api_jobs
```

### Stop and clean up

```bash
docker rm -f mortgage_api_web mortgage_api_jobs
```

### Deploy with Kamal

```bash
bin/kamal setup
bin/kamal deploy
```

## Endpoints

All endpoints require Basic Auth credentials.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/mortgage_applications` | Submit a new application |
| `GET`  | `/api/v1/mortgage_applications` | List all applications (convenience for inspection) |
| `GET`  | `/api/v1/mortgage_applications/:id` | Retrieve an application |
| `GET`  | `/api/v1/mortgage_applications/:id/assessment` | Run affordability assessment |

### Example: List applications

```bash
curl -u admin:password123 http://localhost:3000/api/v1/mortgage_applications
```

**Sample response (`200 OK`):**
```json
[
  {
    "id": 1,
    "annual_income": "60000.0",
    "monthly_expenses": "500.0",
    "deposit_amount": "30000.0",
    "property_value": "300000.0",
    "term_years": 25,
    "status": "assessed",
    "decision": "approved",
    "created_at": "2026-04-20T12:00:00.000Z",
    "updated_at": "2026-04-20T12:05:00.000Z"
  }
]
```

### Example: Submit an application

```bash
curl -u admin:password123 -X POST http://localhost:3000/api/v1/mortgage_applications \
  -H "Content-Type: application/json" \
  -d '{
    "mortgage_application": {
      "annual_income": 60000,
      "monthly_expenses": 500,
      "deposit_amount": 30000,
      "property_value": 300000,
      "term_years": 25
    }
  }'
```

**Sample response (`201 Created`):**
```json
{
  "id": 1,
  "annual_income": "60000.0",
  "monthly_expenses": "500.0",
  "deposit_amount": "30000.0",
  "property_value": "300000.0",
  "term_years": 25,
  "status": "pending",
  "created_at": "2026-04-20T12:00:00.000Z",
  "updated_at": "2026-04-20T12:00:00.000Z"
}
```

### Example: Run an assessment

```bash
curl -u admin:password123 http://localhost:3000/api/v1/mortgage_applications/1/assessment
```

**First call (`202 Accepted`):**
```json
{
  "status": "assessing",
  "message": "Assessment is being queued"
}
```

**After the job completes (`200 OK`):**
```json
{
  "loan_to_value": "0.9",
  "debt_to_income": "0.4157",
  "maximum_borrowing": "270000.0",
  "decision": "approved",
  "explanation": "Application meets all affordability criteria. LTV: 90.0%, DTI: 41.6%.",
  "assessed_at": "2026-04-24T12:00:00.000Z"
}
```

The application's `status` becomes `assessed` once the job completes, and the affordability outcome is stored separately in the `decision` field.

## Design Decisions

### Architecture

- **API-only Rails app** (`config.api_only = true`) — lightweight middleware stack
- **Versioned routes** (`/api/v1/…`) — future evolution without breaking clients
- **Service object** (`AffordabilityAssessor`) — business logic isolated from models and controllers
- **Authentication as a concern** — swappable auth strategy without touching controllers
- **Background job for assessments** — keeps the API responsive and sets up cleanly for slower future work like credit-bureau integration

### Project Structure

```
app/
  controllers/
    api/v1/
      mortgage_applications_controller.rb   # API endpoints
    concerns/
      authenticatable.rb                    # HTTP Basic Auth
  jobs/
    affordability_assessment_job.rb         # Async assessment job
  models/
    mortgage_application.rb                 # Persistence + validations
  services/
    affordability_assessor.rb               # Affordability business logic
bin/
  docker-up                                 # Starts web + jobs containers
config/
  initializers/log_tags.rb                  # Request ID / IP log tagging
  routes.rb                                 # Versioned API routes
spec/
  jobs/           # Background job specs
  models/         # Validation specs
  services/       # Business logic + logging specs
  requests/       # End-to-end HTTP specs (including auth)
  factories/      # FactoryBot factories
  support/        # Shared RSpec helpers (auth headers, log capture)
```

### Data Model

A single `MortgageApplication` model stores the submission, plus separate fields for **lifecycle** and **outcome**:

- **`status`** — where in the lifecycle the application is:
  - `pending` — submitted, not yet assessed
  - `assessing` — assessment job in flight
  - `assessed` — assessment complete (the outcome lives in `decision`)
- **`decision`** — the actual affordability outcome, set once status is `assessed`:
  - `approved` / `declined`

Splitting the two means we can extend the lifecycle later (e.g. `manual_review`, `expired`) without changing the meaning of `decision`, and we can still answer "what's the decision?" without re-running the calculation.

Validations ensure every numerical input is positive and that the deposit is less than the property value.

### Affordability Logic

Three rules are applied. **All must pass** for approval:

| Rule | Limit |
|------|-------|
| Loan-to-Value (LTV) | ≤ 90% |
| Debt-to-Income (DTI) | ≤ 43% |
| Maximum borrowing | lower of 4.5× annual income or 90% of property value |

**Assumptions:**
- Monthly repayment estimated using the standard amortisation formula at a fixed 5% annual interest rate
- DTI combines the estimated mortgage repayment with existing monthly expenses
- Logic is intentionally simplified — it is not a real underwriting model

### Testing Strategy

- **Model specs** — validation rules (including the custom `deposit_less_than_property_value` check) and helper methods
- **Service specs** — affordability logic unit-tested in isolation (no DB)
- **Logging specs** — confirm structured events are emitted with the expected shape
- **Job specs** — verify the assessment is persisted and is idempotent on re-runs
- **Request specs** — end-to-end HTTP behaviour including async flow and status transitions
- **Authentication specs** — `401` for missing / invalid credentials, `200` for valid ones

### Trade-offs Considered

- **Service kept pure (no persistence) for `assess`**: returns a hash without side effects, making it easy to test. Persistence happens via `assess_and_persist!`, called from the job.
- **Inline status transition vs state machine**: A direct `update!` keeps this exercise focused. In a larger app a gem like AASM would document the lifecycle explicitly.
- **Separate `status` (lifecycle) and `decision` (outcome) fields**: Cleaner semantics. Status describes where the application *is* in its journey; decision describes the result of the affordability check. Each can evolve independently.
- **Basic Auth over token/JWT**: Simple, built-in, and matches "basic authentication" from the spec. For a real multi-user API I'd swap this for JWTs or OAuth.
- **Solid Queue over Sidekiq**: Zero extra infrastructure for the throughput we need. Easy to swap later if requirements change.
- **Polling over websockets for assessment results**: Simpler client integration. WebSockets / Action Cable would be the next step for richer real-time UX.
- **Unpaginated `index`**: Included as a convenience for inspection. A production version would add pagination and filtering.
- **Per-user authentication** — replace the shared Basic Auth credentials with real user accounts and JWT tokens
- **WebSocket / Action Cable notifications** — push assessment results to the client instead of polling
- **OpenAPI documentation** — generated from request specs
- **Job dashboard** — `mission_control-jobs` for visibility into queue health
- **Metrics export** — push the structured events to Prometheus/StatsD via a sidecar
```