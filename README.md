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

## PWA / Installability

Daybreak ships as a Progressive Web App. The web manifest (`/manifest.json`) is wired into the layout and enables "Add to Home Screen" / browser-install on Chrome, Edge, Safari, and Firefox for Android. Theme color: `#D4916E` (sunrise terracotta). Background color: `#F3EBE2` (warm sand). Display mode: standalone.

Icon set in `public/`:

| File | Size | Use |
|------|------|-----|
| `favicon.ico` | 16/32/48 multi-res | browser tab (legacy) |
| `favicon-16x16.png` | 16×16 | browser tab (PNG) |
| `favicon-32x32.png` | 32×32 | browser tab (PNG) |
| `apple-touch-icon.png` | 180×180 | iOS homescreen |
| `icon-192.png` | 192×192 | Android homescreen / PWA |
| `icon-512.png` | 512×512 | PWA splash screen + maskable |
| `icon.svg` | scalable | browser tab (SVG) |

All icons render the sunrise sun mark (warm yellow center `#FFCA6B` → peach `#E0A584`, horizon line `#D4916E`) on the `#F3EBE2` background. The 512×512 PNG is maskable-safe (mark padded within the 80 % safe zone).

## Dashboard Layout

The dashboard uses a warm terracotta design system with full light/dark mode support (follows `prefers-color-scheme`). Typography: Quicksand wordmark, Newsreader section titles, Inter body, Geist Mono for numeric readouts. The header shows a live clock and time-of-day greeting.

**Row 1 — glanceable widgets** (equal height on desktop, stacked on mobile):
- **Calendar** — mini week calendar with today highlighted + today's schedule list
- **Weather** — current temp/conditions with a clipped hourly forecast strip; current-hour tile highlighted
- **Daily Goals** — completed items (green dot + unit · Complete) and in-progress items with data-driven progress bars

**Sections below** (3-across card grid on desktop, single column on mobile):
- **Action Items** — Personal and Work widget cards side by side
- **Long Term Goals** — progress cards with percentage, agent insight sentence, and data-driven progress bars
- **Agent Activity** — activity cards with title, body summary, status chip, and a bottom-fade overflow indicator when card content exceeds the card's bounded height

## Data Model

The dashboard renders from a `DailyBriefing` record. Each briefing stores JSONB columns for each panel:

| Column | Contents |
|--------|----------|
| `calendar_data` | Events list (title, time, duration) |
| `weather_data` | Location, current temp, hourly forecast |
| `daily_goals_data` | Exercise / protein / calorie current and target values |
| `action_items_data` | Personal and work item arrays |
| `long_term_goals_data` | Goal text, progress, and target arrays |
| `agent_activity_data` | Activity text, timestamp, icon, optional body summary, and status arrays |

`DailyBriefing.for_today` returns today's record, falling back to the most recent record if none exists for today.

## Agent Widget Protocol

Daybreak's defining mechanic: all widget content is set by the user's assistant agent — there is no app-side data integration. The agent sends messages to the inbound API to populate each widget.

### Authentication

All API endpoints (except token creation) require a Bearer token:

```
Authorization: Bearer <token>
```

Requests with a missing or wrong token are rejected with `401 Unauthorized` and a JSON:API error body:

```json
{ "errors": [{ "detail": "Unauthorized" }] }
```

#### Obtaining a token programmatically

POST to `/api/tokens` — no authentication required. The server mints and returns a new token:

```
POST /api/tokens
Content-Type: application/vnd.api+json
```

Response (201 Created):

```json
{
  "data": {
    "type": "api_tokens",
    "id": "1",
    "attributes": { "token": "a3f7b91c2d6e..." },
    "links": { "self": "/api/tokens/1" }
  }
}
```

Store the returned `token` value; it is shown only once. Pass it as `Authorization: Bearer <token>` on all subsequent requests. Each call to `POST /api/tokens` mints a distinct token.

#### Legacy env-var token

You can also set `DAYBREAK_API_TOKEN` to a secret string, which is accepted as a valid bearer token. This is useful for development and for deployments that pre-configure the token via environment variables.

### API Contract

The full HTTP API is documented in `docs/api_spec.yaml` (OpenAPI 3.0.3). All endpoints use `Content-Type: application/vnd.api+json` and follow the JSON:API envelope (`{ data: { type, id, attributes } }`).

### Deploy Status

```
GET /api/status
Authorization: Bearer <token>
```

Returns the running application's version, commit SHA (baked in at Docker build time), and the current database schema migration version.

```json
{
  "data": {
    "type": "status",
    "id": "current",
    "attributes": {
      "version": "1.2.3",
      "sha": "abc1234",
      "db_version": "20260811000254"
    },
    "links": { "self": "/api/status" }
  }
}
```

`version` and `sha` are `null` when the image was built without the corresponding build args. `db_version` is the latest applied Rails migration version string, read at request time from the `schema_migrations` table.

### Browsing the Widget Catalog

```
GET /api/catalog
Authorization: Bearer <token>
```

Returns all available widget types and their data schemas:

```json
{
  "data": [
    {
      "type": "widget_types",
      "id": "weather",
      "attributes": {
        "name": "Weather Widget",
        "description": "Current conditions and hourly forecast.",
        "schema": { ... }
      },
      "links": { "self": "/api/catalog/weather" }
    }
  ],
  "links": {
    "self": "/api/catalog",
    "first": "/api/catalog",
    "last": "/api/catalog",
    "prev": null,
    "next": null
  },
  "meta": { "total_count": 6 }
}
```

### Sending Widget Updates

```
POST /api/widgets
Content-Type: application/vnd.api+json
Authorization: Bearer <token>
```

Request body (JSON:API envelope):

```json
{
  "data": {
    "type": "widget_messages",
    "attributes": {
      "widget_type": "<widget_type>",
      "data": { ... }
    }
  }
}
```

Each message replaces all of that widget's data for today. Widgets not included in a message retain their previous values.

### Widget Types

| `widget_type` | `data` shape | Required fields | Notable optional fields |
|---------------|-------------|-----------------|------------------------|
| `date_calendar` | object with `events` array | `events[].title` | `events[].dot_color` (CSS color for event dot) |
| `weather` | object with `hourly` array | `hourly[].hour`, `hourly[].temp` | `hi`, `lo` (daily high/low); `hourly[].is_current`, `hourly[].condition` |
| `daily_goals` | object (keyed map of goals) | `<key>.label`, `.current`, `.target`, `.unit` | `<key>.status` (`"complete"` or `"in_progress"`) |
| `action_items` | object with `personal` and `work` arrays | `personal[].text`, `work[].text` | `[].priority` |
| `long_term_goals` | **array** of goals | `[].text`, `.progress`, `.target`, `.unit` | `[].insight` (one-line summary), `[].subtitle` |
| `agent_activity` | **array** of entries | `[].text`, `[].timestamp` | `[].body` (longer summary), `[].status` (`"Completed"` or `"Pending"`) |

Full field descriptions and examples are in `public/widget_contract.json` (also served at `/widget_contract.json`). The per-type data schemas are also available at runtime via `GET /api/catalog`.

A successful response (201 Created):

```json
{
  "data": {
    "type": "widget_messages",
    "id": "2026-08-09",
    "attributes": { "widget_type": "weather", "date": "2026-08-09" },
    "links": { "self": "/api/widgets/2026-08-09" }
  }
}
```

An invalid message (unknown type, missing required field, wrong shape) returns `422 Unprocessable Entity` with a JSON:API errors body:

```json
{ "errors": [{ "detail": "weather_type is not a recognized widget type" }] }
```

### Contract Documents

- `docs/api_spec.yaml` — OpenAPI 3.0.3 spec for all HTTP endpoints. Authoritative source for request/response shapes, status codes, and content types. Contract-tested on every CI run.
- `public/widget_contract.json` — JSON Schema (draft 2020-12) for widget data payloads (the `data` field inside each widget message). Also served at `/widget_contract.json`.

## Outbound Protocol (Widget Actions → Agent)

Daybreak is bidirectional. When the user acts on a widget — for example, checking off an action item — Daybreak sends a message back to the agent describing the action. Delivery uses a live SSE push connection when the agent is connected, or an HTTP POST to a registered callback URL when it is not.

### Registering a Callback Endpoint

```
POST /api/agent/registrations
Content-Type: application/vnd.api+json
Authorization: Bearer <token>
```

Request body:

```json
{
  "data": {
    "type": "agent_registrations",
    "attributes": { "callback_url": "https://your-agent.example.com/daybreak/events" }
  }
}
```

Response (201 Created):

```json
{
  "data": {
    "type": "agent_registrations",
    "id": "42",
    "attributes": { "callback_url": "https://your-agent.example.com/daybreak/events" },
    "links": { "self": "/api/agent/registrations/42" }
  }
}
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

### Docker Build Args

These are passed at image build time (e.g. `docker build --build-arg APP_VERSION=1.2.3 --build-arg APP_SHA=abc1234 .`) and baked into the image as environment variables. When omitted, `GET /api/status` returns `null` for those fields.

| Build arg | Purpose |
|-----------|---------|
| `APP_VERSION` | Application version string, surfaced by `GET /api/status` |
| `APP_SHA` | Git commit SHA, surfaced by `GET /api/status` |

### Environment Variables (production)

| Variable | Purpose |
|----------|---------|
| `DAYBREAK_DATABASE_PASSWORD` | Password for the `daybreak` Postgres role |
| `DAYBREAK_API_TOKEN` | Optional legacy bearer token; accepted alongside programmatically-issued tokens |
| `DAYBREAK_USER_NAME` | Your first name — shown in the dashboard greeting ("Good morning, Alex") |
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
