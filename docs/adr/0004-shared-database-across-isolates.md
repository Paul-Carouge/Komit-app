# 4. One database connection shared across isolates

Date: 2026-10-29 · Status: accepted

## Context

Upcoming features run Dart code outside the UI isolate: logging a habit from a
reminder notification action, and home-screen widgets. Two independent SQLite
connections on the same file can block each other ("database is locked") and Drift
stream queries in the UI would not see writes made by another connection.

## Decision

- `AppDatabase()` opens the file through `driftDatabase(name: 'komit')` with
  `DriftNativeOptions(shareAcrossIsolates: true)`. Drift then runs one database
  server isolate and every isolate that opens the database this way connects to it,
  so stream queries see every write.
- **Background code must open the database through `AppDatabase()` and never through
  its own `NativeDatabase` on the same file.**
- `beforeOpen` sets `PRAGMA journal_mode = WAL`, so readers do not wait for writers, and
  `PRAGMA busy_timeout` to `databaseBusyTimeout`, so a connection that still meets a
  lock waits briefly instead of failing at once.
- Schema versions are exported with `dart run drift_dev make-migrations` into
  `drift_schemas/`, which also generates the migration tests in `test/drift/`.
  Migrations are written with `stepByStep`.

## Consequences

- WAL adds `komit-wal` and `komit-shm` files next to the database; backups go through
  the JSON export, never by copying the file.
- Tests keep injecting an in-memory `NativeDatabase`, where WAL is a no-op.
