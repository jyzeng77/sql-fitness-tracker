-- ============================================================
-- LESSON 1 — SQL BASICS
-- ============================================================
-- Run me like this:
--   psql -d todo_app
--   \i lessons/01_basics.sql
--
-- A relational database stores data in TABLES: rows and columns.
-- Each row is one "thing" (here: one task). Each column is one
-- attribute of that thing (title, done, created_at).
--
-- SQL is a DECLARATIVE language: you describe WHAT you want,
-- not HOW to get it. The database figures out the how.
-- ============================================================

-- ------------------------------------------------------------
-- 1. CREATE TABLE — define the shape of your data
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tasks (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      TEXT NOT NULL,
    done       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Reading it column by column:
--   id          — a number the database generates for us (1, 2, 3...).
--                 PRIMARY KEY = unique identifier for each row.
--   title       — TEXT, and NOT NULL means every row MUST have one.
--   done        — TRUE/FALSE, defaults to FALSE (a new task isn't done).
--   created_at  — timezone-aware timestamp, defaults to "right now".

-- INSPECT what you made (these are psql meta-commands, not SQL):
--   \d tasks

-- My notes:
-- INTEGER - data type
-- GENERATED ALWAYS AS IDENTITY - who supplies the value - in this case
--      the database. the user cannot define the value at all and would
--      result in error. 
-- use DEFAULT instead if you want to have default but changeable values.
-- PRIMARY KEY - type is constraint / rule

-- ------------------------------------------------------------
-- 2. INSERT — add rows
-- ------------------------------------------------------------

INSERT INTO tasks (title) VALUES
    ('Learn SQL basics'),
    ('Water the plants'),
    ('Read one chapter of a book');

-- We only gave `title`; `id`, `done`, `created_at` filled themselves in
-- thanks to IDENTITY / DEFAULT. That's the database doing work for you.

-- Insert with explicit values too:
INSERT INTO tasks (title, done) VALUES ('Pretend this is already finished', TRUE);

-- ------------------------------------------------------------
-- 3. SELECT — read rows
-- ------------------------------------------------------------

SELECT * FROM tasks;                -- * = every column (fine for learning,
                                    --   avoid in real apps: be explicit)

SELECT title, done FROM tasks;      -- just the columns you care about

-- ------------------------------------------------------------
-- 4. WHERE — filter rows
-- ------------------------------------------------------------

SELECT title FROM tasks WHERE done = FALSE;     -- everything still open
SELECT title FROM tasks WHERE done = TRUE;      -- everything finished

-- WHERE takes any expression that evaluates to TRUE/FALSE:
SELECT title FROM tasks WHERE id = 2;
SELECT title FROM tasks WHERE created_at > now() - INTERVAL '1 hour';

-- ------------------------------------------------------------
-- 5. UPDATE — change existing rows
-- ------------------------------------------------------------

UPDATE tasks SET done = TRUE WHERE id = 2;

-- !!!! Golden rule: UPDATE and DELETE almost always need a WHERE.
-- An UPDATE without WHERE changes EVERY row in the table.
-- (We'll learn how transactions save you from such mistakes in Lesson 8.)

SELECT title, done FROM tasks;    -- check the result — plant-watering: done!

-- ------------------------------------------------------------
-- 6. DELETE — remove rows
-- ------------------------------------------------------------

DELETE FROM tasks WHERE title = 'Pretend this is already finished';

SELECT * FROM tasks;

-- ------------------------------------------------------------
-- EXERCISES — your turn! Replace NULL with real SQL.
-- Write your answer on the line(s) below each comment, then
-- select them in psql (or use \i) and check the output.
-- ------------------------------------------------------------

-- EXERCISE 1: Insert three tasks of your own (just titles).

-- single quotes = strings, double quotes = identifiers
INSERT INTO tasks (title) VALUES ('Finish Exercise 1');
INSERT INTO tasks (title) VALUES 
    ('Finish Exercise 2'),
    ('Finish Exercise 3');

-- EXERCISE 2: SELECT only the titles of tasks that are not done.
SELECT title FROM tasks WHERE done = FALSE;

-- EXERCISE 3: Mark one of YOUR tasks as done using its id.

-- EXERCISE 4: Delete one of your tasks.

-- EXERCISE 5 (thought experiment, answer in a comment):
-- What happens if you run `UPDATE tasks SET done = TRUE;` — no WHERE?
-- Predict first, then try it on the row you don't care about... or
-- better: predict, DON'T run it, and tell me your answer.

-- ------------------------------------------------------------
-- UNDER THE HOOD
-- ------------------------------------------------------------
-- * PRIMARY KEY: every row needs a stable, unique identity so other
--   data can reference it ("task 3") and so updates hit exactly one row.
-- * Declarative thinking: `SELECT title FROM tasks WHERE done = FALSE`
--   says *what* you want; Postgres chooses indexes, scan order, etc.
--   This idea repeats all the way into how big systems are built.
-- * The schema is a contract: NOT NULL + defaults move data-quality
--   checks out of every app and into one authoritative place.
--
-- When you're done, tell me your exercise answers (or just say "done")
-- and we'll review them together, then move to Lesson 2: schema design.
