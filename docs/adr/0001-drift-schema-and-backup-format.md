# 1. Drift (SQLite) schema and versioned backup format

Date: 2026-10-28 · Status: accepted

## Context

The original Komit app (source lost) stored data in Isar. Its logs referenced their
objective by title and color, so renaming an objective silently detached its history.
Isar is no longer maintained by its author. The user's data (2 275 logs over
8 habits) exists only as a JSON export from that app and must be imported without loss.

## Decision

- Store data in SQLite through Drift: tables `habits`, `objectives`, `habit_logs`,
  `notes`, with foreign keys enabled at open, cascading deletes, and a unique key
  `(habit_id, day)` so a habit has at most one log per day.
- Store a log's day as a calendar day (days since 1970-01-01), not as an instant, so
  time zones and DST can never move a log to another day.
- Logs reference objectives by id; editing a habit updates objectives in place.
- Backups are JSON with `format` and `version` keys. v2 nests logs under their
  objective, so a file cannot contain a log pointing to a missing objective. v1 files
  from the original app are still accepted.
- An import is decoded and validated completely before any write, then applied in one
  transaction that replaces all data.

## Consequences

- Schema changes need a Drift migration and a `schemaVersion` bump.
- Logs of an objective deleted in the old app are kept by recreating that objective.
- The UI blocks logging future days, which the old app allowed.
