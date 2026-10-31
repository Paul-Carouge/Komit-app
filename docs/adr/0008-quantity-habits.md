# 8. Quantity habits

Date: 2026-10-31 · Status: accepted

## Context

Some habits are an amount, not an outcome: "8 glasses", "20 min", "2 L". Roadmap item 5 asks
for a habit that tracks a value with a unit and a daily target, logged by steps or typed, and
whose day succeeds once the target is reached. Every surface reads a day through the same rule
(streaks, recaps, achievements, year in review, reminders, the "Today" widget, statistics), so
the rule must live in one place, and the user's existing objective habits and their backups
(including the original app's v1 file) must not change.

## Decision

- **A habit is of one kind**: "objectives" (as today) or "quantity". A quantity habit has a
  unit (free text, at most `maximumQuantityUnitLength` characters), a daily target and a step
  (the amount one tap adds, 1 by default), all greater than zero. Objectives and a quantity do
  not mix: an objective says *how* the day went, a quantity says *how much*, and a habit with
  both would need two answers per day.
- **Storage** (schema version 4): nullable columns `quantity_unit`, `quantity_target` and
  `quantity_step` on `habits` (all null for an objective habit) and a nullable `quantity` on
  `habit_logs`. A quantity habit keeps exactly one objective row, hidden from the interface and
  kept in sync with the unit and the habit color: logs keep their non-null `objective_id`, the
  one-log-per-day key and the backup nesting unchanged, and no table has to be rebuilt.
- **Success is `value >= target`**, decided when reading, never stored, so changing the
  target re-reads every past day. The repository's day maps (`watchObjectiveIdByDay...`) leave
  out a quantity day below its target, so the streak, success rate, recap, achievement,
  celebration, year-in-review, reminder and widget code reads a partial day exactly like a day
  without a log and needs no change. The values themselves come from separate streams
  (`watchQuantityByDay...`) for the screens that draw progress.
- **Values** are rounded to three decimals on write, so repeated 0.1 steps reach a target of
  0.3; a value is at most `maximumQuantityValue`. Clearing a day deletes its log; a value of
  zero is never stored.
- **One tap adds a step**, even past the target, with "Undo" restoring the exact previous
  value. **"Done" from a reminder or a tap on the "Today" widget completes the day**: it raises
  the value to the target and never lowers a bigger one. "Done" means "I did it", and adding one
  step out of eight from a notification would rarely be what the person meant; the dashboard is
  where steps are counted. Both go through `logObjectiveForDay`, which applies this rule to a
  quantity habit, so the background code is unchanged.
- **The kind cannot change once the habit has a log**: the old logs would have no value, or a
  value without an outcome. The repository refuses it (`HabitKindChangeException`) and the
  editor explains why.
- **Backups** move to format version 4: a quantity habit carries `quantity` (`unit`, `target`,
  `step`) and its single objective a `quantities` list aligned with `loggedDays`. Versions 1 to
  3 still import as objective habits; an older Komit refuses a version 4 file instead of
  silently turning quantities into plain logs.

## Consequences

- A partial day counts as "not logged" in every count of logs (achievement totals, the yearly
  log count, the "Today" header). The dashboard's "last logged" text, which reads the raw logs,
  still says a partial day was logged.
- The statistics screen replaces the objective distribution with the year's total amount and
  the days the target was reached for a quantity habit.
- The widget snapshot format is unchanged: "logged today" means "target reached", and the
  widget's optimistic check matches the "complete the day" tap.
