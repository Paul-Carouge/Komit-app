# 7. Pauses and rest days in streaks

Date: 2026-10-30 · Status: accepted

## Context

A holiday or an illness breaks every streak today, and a daily habit has no room for an
occasional day off: users either log days they did not do or lose a long streak for one
missed day. Roadmap item 4 asks for paused periods and a weekly rest allowance. Both change
how a day counts, so the rules must be the same everywhere a streak, a rate or an achievement
is computed, and they must hold for past days after the pause ends.

## Decision

- **A pause is a period of calendar days** stored in a `habit_pauses` table (habit id,
  `start_day`, `end_day` included, null while the pause is open). A habit keeps every past
  pause, so its history reads the same after it resumes. Pauses of one habit never overlap; a
  pause may be planned ahead. Resuming closes the pause holding today on yesterday (or deletes
  it when it started today); with none, it cancels the earliest planned pause only.
- **A paused day counts like a day off the schedule**: it neither breaks nor extends a streak,
  even when a success was logged on it, and it leaves the success rate's denominator. The
  habit is not scheduled that day, so it asks for no log on the dashboard, sends no reminder,
  stays out of the "Today" widget and does not count against a perfect day.
- **Weekly targets**: a week is met when its successes on non-paused days reach the target; a
  week that is not met but holds a paused day is neutral (neither breaks nor extends); any
  other unmet week breaks the streak, as before. The same holds for the dashboard's weekly
  progress, the perfect-week achievement, and the Monday recap, which leaves out a habit
  whose week a pause made neutral.
- **Rest days** (`habits.rest_days_per_week`, 0 to 2, daily and weekday habits only): in each
  ISO week, the first missed scheduled days up to the allowance neither break nor extend the
  streak. The allowance is capped at the scheduled days per week minus one, so at least one
  scheduled day must be done and a streak can always break. Rest days are not stored: they
  are derived from the logs each time, like achievements. Today, while not logged, is never a
  miss. The allowance does not apply to the success rate or to perfect days, which keep
  counting a rest day as not done.
- **Backups** move to format version 3: each habit carries `restDaysPerWeek` and `pauses`
  (`start`, `end` as calendar days). Versions 1 and 2 still import, with no pause and no rest
  day.

## Consequences

- Schema version 3: a new table and a column, added by a Drift step migration.
- `computeScheduledStreakSummary` and `computeSuccessRate` take the pauses and the allowance;
  every caller passes them through `HabitHistory` or `HabitWithObjectives`.
- An older Komit refuses a version 3 backup instead of silently dropping pauses.
