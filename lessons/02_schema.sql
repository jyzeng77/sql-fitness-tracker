-- ============================================================
-- LESSON 2 — SCHEMA DESIGN (a sturdier schema)
-- ============================================================
-- Run me like this:
--   psql -d todo_app
--   \i lessons/02_schema.sql
--
-- Lesson 1 gave you a WORKING `tasks` table. It works, but as a
-- schema it's... thin. Real tables grow: you add columns, tighten
-- rules, fix mistakes — all while the data stays in place.
--
-- This lesson is about DESIGN + EVOLUTION:
--   * choosing honest types (TEXT vs VARCHAR, DATE vs TIMESTAMPTZ)
--   * letting the DATABASE enforce rules (CHECK, NOT NULL, UNIQUE)
--   * changing a table that already has rows — without breaking it
--
-- The star of this lesson is ALTER TABLE: the tool for evolving
-- a schema safely.
--
-- NOTE: this file MODIFIES your `tasks` table (that's the lesson).
-- It's written to run once; re-running it errors harmlessly on the
-- constraint lines ("already exists" = the rule is already there).
-- ============================================================

-- Make sure the Lesson 1 table exists (no-op if it already does).
CREATE TABLE IF NOT EXISTS tasks (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      TEXT NOT NULL,
    done       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 1. Take stock: what does the current schema look like?
-- ------------------------------------------------------------
--   \d tasks     ← do this now; you'll do it after every step below.

-- Current columns:
--   id          INTEGER     IDENTITY  PRIMARY KEY
--   title       TEXT        NOT NULL
--   done        BOOLEAN     NOT NULL  DEFAULT FALSE
--   created_at  TIMESTAMPTZ NOT NULL  DEFAULT now()

-- What a REAL todo app is missing:
--   * priority (low / medium / high)   → new column + CHECK
--   * a due date                       → new column
--   * notes                            → new column (Exercise 1)
--   * protection against empty titles  → CHECK (Exercise 2)

-- ------------------------------------------------------------
-- 2. Types: TEXT vs VARCHAR(n), DATE vs TIMESTAMPTZ
-- ------------------------------------------------------------
-- TEXT: unlimited length.  VARCHAR(n): capped at n characters.
-- Use VARCHAR(n) only when there's a REAL reason to cap (e.g. a
-- 2-letter country code). For titles and notes, TEXT is simpler —
-- "cap the title at 140 chars" is app logic, not schema logic.
--
-- TIMESTAMPTZ: an INSTANT in time ("when did this happen?").
-- DATE: a CALENDAR DAY ("what day is this due?").
-- A due date is a day, not an instant → DATE is the honest type.
-- Choosing the right type is half of schema design: the type is
-- the column's contract with every future query.

-- ------------------------------------------------------------
-- 3. ALTER TABLE ADD COLUMN — evolve safely, one step at a time
-- ------------------------------------------------------------

-- Add a priority. Existing rows get the DEFAULT; no data touched.
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS priority TEXT NOT NULL DEFAULT 'medium';

-- Check: every existing row now shows 'medium' — including your
-- Finish Exercise rows from Lesson 1.
SELECT id, title, priority FROM tasks ORDER BY id;

-- Add a due_date. NULL is fine: not every task has a due date.
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS due_date DATE;

-- Lesson: ADD COLUMN is SAFE and additive. It never rewrites or
-- deletes anything. This is the everyday, boring, good migration.

-- ------------------------------------------------------------
-- 4. CHECK — make the database reject bad data
-- ------------------------------------------------------------
-- priority is free text right now: someone could insert
-- 'urgent!!!'. A CHECK constraint makes the database refuse any
-- value that doesn't match. The rule lives in ONE authoritative
-- place (the schema), not in app code that might forget it.
ALTER TABLE tasks ADD CONSTRAINT tasks_priority_check
    CHECK (priority IN ('low', 'medium', 'high'));

-- This now FAILS. Run it and READ the error — that's the database
-- defending its contract:
INSERT INTO tasks (title, priority) VALUES ('Bad priority', 'urgent!!!');

-- And this is allowed:
INSERT INTO tasks (title, priority) VALUES ('Water the plants', 'high');

-- Delete that demo row so it doesn't clutter your list:
DELETE FROM tasks WHERE title = 'Water the plants' AND priority = 'high';

-- ------------------------------------------------------------
-- 5. DEFAULT — for NEW rows only
-- ------------------------------------------------------------
-- done defaults to FALSE, priority defaults to 'medium'. Note what
-- DEFAULT does NOT do: it never changes existing rows. It only
-- fills the value when an INSERT doesn't provide one. (Lesson 1's
-- table kept proving this — rows inserted long ago didn't get new
-- defaults retroactively.)

-- ------------------------------------------------------------
-- 6. The safe NOT NULL recipe (backfill, then tighten)
-- ------------------------------------------------------------
-- Suppose we decide due_date must exist for every task.
-- Trying it directly FAILS, because existing rows have NULL:
--   ALTER TABLE tasks ALTER COLUMN due_date SET NOT NULL;
--      → ERROR: column "due_date" contains null values
--
-- The safe 3-step migration (memorize this shape — it's how real
-- production migrations add a required column):
--   1. ADD COLUMN (nullable or with a DEFAULT)   ← already done
--   2. BACKFILL: UPDATE rows that have NULL
--   3. SET NOT NULL once no NULLs remain

-- Step 2 — give every NULL a value (due in one week):
UPDATE tasks SET due_date = CURRENT_DATE + 7 WHERE due_date IS NULL;

-- Always verify BEFORE tightening:
SELECT COUNT(*) AS still_null FROM tasks WHERE due_date IS NULL;

-- Step 3 — now the promise is safe to make:
ALTER TABLE tasks ALTER COLUMN due_date SET NOT NULL;

-- Lesson: SET NOT NULL is a PROMISE to the database. Check
-- (COUNT) before making it, or Postgres refuses — and that
-- refusal is a feature, not a bug.

-- ------------------------------------------------------------
-- 7. UNIQUE — no duplicates allowed
-- ------------------------------------------------------------
-- Remember Lesson 1's repeated 'Learn SQL basics' rows? A UNIQUE
-- constraint stops duplicates at the door, permanently:
ALTER TABLE tasks ADD CONSTRAINT tasks_title_unique UNIQUE (title);

-- If your table still has duplicate titles from re-running Lesson 1,
-- that line just errored ("could not create unique index...duplicate
-- key"). That's the right outcome: the data must be cleaned first.
-- (This table was reset, so yours is probably fine.)

-- Proof: this now FAILS if 'Learn SQL basics' already exists.
-- (Note: due_date is NOT NULL now, so the INSERT must supply it —
--  omitting it would fail on NOT NULL instead. Supply it so the
--  UNIQUE violation is what shows up:)
INSERT INTO tasks (title, due_date) VALUES ('Learn SQL basics', CURRENT_DATE + 1);

-- ------------------------------------------------------------
-- 8. RENAME and DROP — the destructive end of the scale
-- ------------------------------------------------------------
-- Renaming is cheap and non-destructive:
ALTER TABLE tasks RENAME TO todos;      -- look: everything still works
SELECT * FROM todos ORDER BY id LIMIT 3;
ALTER TABLE todos RENAME TO tasks;      -- rename back

-- Dropping a column throws away that column's data FOREVER:
--   ALTER TABLE tasks DROP COLUMN due_date;    -- DON'T run this!
--
-- The production rule of thumb: prefer ADDITIVE changes (new
-- columns, new constraints) over destructive ones (drop, rewrite,
-- repurpose). Additive changes can be undone; destructive ones
-- can't. Evolving a schema is a discipline before it's a skill.

-- ------------------------------------------------------------
-- EXERCISES — your turn!
-- ------------------------------------------------------------

-- EXERCISE 1: Add a `notes` column — TEXT, and NULL is fine.
-- (Some tasks have notes, some don't.)

-- EXERCISE 2: Add a CHECK constraint so a task can never have an
-- empty title. Hint: length(title) > 0. Name it tasks_title_not_empty.

-- EXERCISE 3: The 3-step recipe in miniature — set every task's
-- priority to 'high' (that's your backfill), then run the COUNT
-- check to prove no NULLs remain... then it's already NOT NULL,
-- so just confirm with \d tasks that the rule is in place.

-- EXERCISE 4 (thought experiment, answer in a comment):
-- You added due_date as NOT NULL in step 6. What happens to a new
-- INSERT that omits due_date entirely? Will it error, or does
-- something fill it in? (Remember: NOT NULL is not DEFAULT.)

-- ------------------------------------------------------------
-- UNDER THE HOOD
-- ------------------------------------------------------------
-- * Schema as contract: NOT NULL, CHECK, UNIQUE move data-quality
--   rules out of every app and into one authoritative place. Any
--   future client (another app, a script, a person in psql) gets
--   the same rules for free.
-- * Constraints are documentation: \d tasks reads like a spec of
--   what "a valid task" means. A new engineer learns the data
--   model by reading constraints, not asking around.
-- * Naming: <table>_<column>_check / _unique — follow it; other
--   people (and future you) will thank you.
-- * Migrations mindset: production tables can't be dropped and
--   recreated. The ADD → BACKFILL → TIGHTEN shape you learned in
--   step 6 is literally how real systems add required fields.
--
-- When you're done, tell me your exercise answers (or just say
-- "done") and we'll review, then move to Lesson 3: querying
-- deep-dive — ORDER BY, LIMIT, ILIKE, and dates.