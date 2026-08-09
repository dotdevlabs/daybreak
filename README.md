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

## Testing

```bash
bin/rails test
```

## CI

```bash
bin/ci
```
