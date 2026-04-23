# Mortgage Application API

A Rails 8.1 JSON API for submitting mortgage applications and running basic affordability assessments.

## Tech Stack

- Ruby 3.4
- Rails 8.1.3
- SQLite3
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

## Run Tests

```bash
bundle exec rspec
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/mortgage_applications` | Submit a new application |
| `GET`  | `/api/v1/mortgage_applications/:id` | Retrieve an application |
| `GET`  | `/api/v1/mortgage_applications/:id/assessment` | Run affordability assessment |

### Example: Submit an application

```bash
curl -X POST http://localhost:3000/api/v1/mortgage_applications \
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

### Example: Run an assessment

```bash
curl http://localhost:3000/api/v1/mortgage_applications/1/assessment
```

**Sample response:**
```json
{
  "loan_to_value": 0.9,
  "debt_to_income": 0.4157,
  "maximum_borrowing": 270000.0,
  "decision": "approved",
  "explanation": "Application meets all affordability criteria. LTV: 90.0%, DTI: 41.6%."
}
```

## Design Decisions

### Architecture

- **API-only Rails app** (`config.api_only = true`)
- **Versioned routes** (`/api/v1/…`) to support future API evolution without breaking clients
- **Service object** (`AffordabilityAssessor`) for business logic — keeps models focused on persistence and controllers focused on HTTP

### Data Model

A single `MortgageApplication` model stores applicant data plus a `status` field that tracks lifecycle:

- `pending` — submitted but not yet assessed
- `approved` / `declined` — updated after `/assessment` is called

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

- **Model specs** — validation rules and helper methods
- **Service specs** — affordability logic unit-tested in isolation
- **Request specs** — end-to-end HTTP behaviour

### Trade-offs Considered

- **Kept the service pure (no persistence)**: `AffordabilityAssessor#assess` returns a hash without side effects, which makes it easy to test and reason about. Persistence of the decision happens in the controller.
- **Inline status transition vs state machine**: For this exercise a direct `update` is sufficient. In a larger app, `AASM` or similar would be a natural fit.
- **No pagination on `index`**: Simple listing is adequate for the exercise.

### What I'd Add With More Time

- **Background processing** — move the assessment into a Solid Queue job and update the record asynchronously
- **Basic authentication** — token- or API-key-based for protecting endpoints
- **Persisted assessment results** — store LTV/DTI/decision on the record to avoid recalculation
- **OpenAPI documentation** — for easier client integration
- **Logging & instrumentation** — structured logs + request IDs
