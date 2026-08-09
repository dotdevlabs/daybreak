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

## Testing

```bash
bin/rails test
```

## CI

```bash
bin/ci
```
