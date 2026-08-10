# Daybreak

Daybreak is a personal browser start screen — a single-page Rails app that surfaces the day's most important information when you open a new tab. It renders a daily briefing composed by an agent, showing your calendar, weather, health goals, action items, long-term goals, and recent agent activity.

## Requirements

- Ruby 3.x
- PostgreSQL
- Node.js (for asset pipeline)

## Getting Started

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed   # loads representative example briefing data
bin/rails server
```

Open `http://localhost:3000` to see the dashboard.

## Dashboard Layout

**Row 1 — glanceable widgets** (equal height, responsive grid):
- **Date & Calendar** — today's date with upcoming events
- **Weather** — current conditions and hourly forecast strip
- **Daily Goals** — exercise, protein, and calorie progress bars

**Sections below:**
- **Action Items** — personal and work columns
- **Long Term Goals** — progress bars for multi-week objectives
- **Agent Activity** — recent agent actions with an overflow indicator when items exceed the visible area

## Data Model

The dashboard renders from a `DailyBriefing` record. Each briefing stores JSONB columns for each panel:

| Column | Contents |
|--------|----------|
| `calendar_data` | Events list (title, time, duration) |
| `weather_data` | Location, current temp, hourly forecast |
| `daily_goals_data` | Exercise / protein / calorie current and target values |
| `action_items_data` | Personal and work item arrays |
| `long_term_goals_data` | Goal text, progress, and target arrays |
| `agent_activity_data` | Activity text, timestamp, and icon arrays |

`DailyBriefing.for_today` returns today's record, falling back to the most recent record if none exists for today.

## Agent Widget Protocol

Daybreak's defining mechanic: all widget content is set by the user's assistant agent — there is no app-side data integration. The agent sends messages to the inbound API to populate each widget.

### Authentication

Set `DAYBREAK_API_TOKEN` to a secret string. The agent includes it as a Bearer token:

```
Authorization: Bearer <token>
```

Requests with a missing or wrong token are rejected with `401 Unauthorized`.

### Sending Widget Updates

```
POST /api/widgets
Content-Type: application/json
Authorization: Bearer <token>
```

Request body:

```json
{
  "type": "<widget_type>",
  "data": { ... }
}
```

Each message replaces all of that widget's data for today. Widgets not included in a message retain their previous values.

### Widget Types

| `type` | `data` shape | Required fields |
|--------|-------------|-----------------|
| `date_calendar` | object with `events` array | `events[].title` |
| `weather` | object with `hourly` array | `hourly[].hour`, `hourly[].temp` |
| `daily_goals` | object (keyed map of goals) | `<key>.label`, `.current`, `.target`, `.unit` |
| `action_items` | object with `personal` and `work` arrays | `personal[].text`, `work[].text` |
| `long_term_goals` | **array** of goals | `[].text`, `.progress`, `.target`, `.unit` |
| `agent_activity` | **array** of entries | `[].text`, `[].timestamp` |

A valid response looks like:

```json
{ "status": "ok", "widget": "weather", "date": "2026-08-09" }
```

An invalid message (unknown type, missing required field, wrong shape) returns `422 Unprocessable Entity` with an `errors` array describing each problem.

### Contract Document

`public/widget_contract.json` is a machine-readable JSON Schema (draft 2020-12) describing every widget type, its fields, and example payloads. It is also served statically at `/widget_contract.json`. Build your agent against this document. The test suite verifies that the contract's examples are accepted by the live validation logic.

## Outbound Protocol (Widget Actions → Agent)

Daybreak is bidirectional. When the user acts on a widget — for example, checking off an action item — Daybreak sends a message back to the agent describing the action. Delivery uses a live SSE push connection when the agent is connected, or an HTTP POST to a registered callback URL when it is not.

### Registering a Callback Endpoint

```
POST /api/agent/registrations
Content-Type: application/json
Authorization: Bearer <token>

{ "callback_url": "https://your-agent.example.com/daybreak/events" }
```

Response:

```json
{ "status": "ok", "callback_url": "https://your-agent.example.com/daybreak/events" }
```

Daybreak will POST outbound messages to this URL when no live push connection is active.

### Holding a Live Push Connection (SSE)

```
GET /api/events
Authorization: Bearer <token>
Accept: text/event-stream
```

Daybreak keeps the connection open and writes Server-Sent Events to it as user actions occur. A `ping` event is sent every 15 seconds to keep the connection alive. The agent's push connection takes precedence over the registered callback URL.

### Outbound Message Format

Outbound messages use the same `{ type, action, data }` envelope:

```json
{
  "type": "action_items",
  "action": "item_completed",
  "data": {
    "context": "personal",
    "item": {
      "text": "Call dentist to reschedule appointment",
      "priority": "high"
    }
  }
}
```

| Field | Description |
|-------|-------------|
| `type` | Widget type the action came from (`action_items`) |
| `action` | What the user did (`item_completed`) |
| `data.context` | Which column the item was in (`personal` or `work`) |
| `data.item.text` | The action item text |
| `data.item.priority` | The item's priority (`high`, `medium`, `low`) — omitted if not set |

The full outbound schema is in `public/widget_contract.json` under `$defs.outbound_action` and the top-level `outbound` key.

### Delivery Semantics

- If the agent holds a live `GET /api/events` SSE connection, the message is written to that stream.
- If no SSE connection is active, the message is POSTed to the most recently registered callback URL.
- If neither is available, the message is dropped (logged server-side). No user-visible error occurs.
- `AgentPushRegistry` is in-memory, so `WEB_CONCURRENCY` must remain `1` (the default).

## Testing

```bash
bin/rails test
```

## CI

```bash
bin/ci
```

On every push to `main`, CI also builds the Dockerfile and pushes the image to the GitHub Container Registry:

- `ghcr.io/dotdevlabs/daybreak:latest`
- `ghcr.io/dotdevlabs/daybreak:main-<unix-timestamp>-<short-sha>`

The build job uses the built-in `GITHUB_TOKEN` (no external secret required). It does not run on pull requests.

## Deployment

### Prerequisites

Before the first deploy, a Postgres role and four databases must exist on the production server:

```sql
CREATE ROLE daybreak WITH LOGIN PASSWORD '<secret>';
CREATE DATABASE daybreak_production OWNER daybreak;
CREATE DATABASE daybreak_production_cache OWNER daybreak;
CREATE DATABASE daybreak_production_queue OWNER daybreak;
CREATE DATABASE daybreak_production_cable OWNER daybreak;
```

### Environment Variables (production)

| Variable | Purpose |
|----------|---------|
| `DAYBREAK_DATABASE_PASSWORD` | Password for the `daybreak` Postgres role |
| `DAYBREAK_API_TOKEN` | Bearer token the agent uses to authenticate widget updates |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| `WEB_CONCURRENCY` | Must remain `1` (in-memory push registry) |

Action Cable uses the `cable` PostgreSQL database (Solid Cable adapter) — no Redis required.

### Deploying an Image

Pull and run any tagged image from the registry:

```bash
docker pull ghcr.io/dotdevlabs/daybreak:latest
docker run -e RAILS_ENV=production \
           -e DAYBREAK_DATABASE_PASSWORD=<secret> \
           -e DAYBREAK_API_TOKEN=<secret> \
           -e RAILS_MASTER_KEY=<key> \
           -p 3000:3000 \
           ghcr.io/dotdevlabs/daybreak:latest
```

On first deploy, prepare all four databases (creates them if absent and loads schemas):

```bash
docker run --rm -e RAILS_ENV=production ... ghcr.io/dotdevlabs/daybreak:latest bin/rails db:prepare
```

After schema changes on subsequent deploys:

```bash
docker run --rm -e RAILS_ENV=production ... ghcr.io/dotdevlabs/daybreak:latest bin/rails db:migrate
```

### Running the Worker

Solid Queue processes background jobs and is required for the application to function. Run it alongside the web process:

```bash
docker run -e RAILS_ENV=production \
           -e DAYBREAK_DATABASE_PASSWORD=<secret> \
           -e DAYBREAK_API_TOKEN=<secret> \
           -e RAILS_MASTER_KEY=<key> \
           ghcr.io/dotdevlabs/daybreak:latest bin/rails solid_queue:start
```

Or use the convenience script: `bin/jobs`.
