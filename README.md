# Learn SQL by Building a Todo App

A hands-on course: you learn PostgreSQL by actually building a todo app — first by
typing SQL directly into `psql` (Postgres's interactive terminal), then by wiring the
same queries into Python.

> 🛠️ **New to this project, or want to know how the environment was built?**
> Read [`SETUP.md`](SETUP.md) — the full step-by-step runbook, reusable for any
> future project.

**Your setup**

| Piece        | What it is                                   | Status |
|--------------|----------------------------------------------|--------|
| PostgreSQL   | The database server (installed via Homebrew) | 17.11, running as a service |
| `todo_app`   | Your dedicated learning database             | created |
| `.venv/`     | Python virtualenv with the `psycopg` driver  | local, git-ignored |

---

## How each session works

1. Open the lesson file and read the concept explanations in the comments.
2. Run it in `psql` and watch what happens.
3. Solve the `-- EXERCISE` items yourself — that's where the learning happens.
4. Ask questions, break things, we move on.

### Running a lesson

```bash
# Interactive (recommended — you can experiment between statements):
psql -d todo_app
\i lessons/01_basics.sql        # inside psql

# Or all at once:
psql -d todo_app -f lessons/01_basics.sql
```

### Handy psql meta-commands (not SQL, just psql)

| Command     | Does                                  |
|-------------|---------------------------------------|
| `\dt`       | list tables                           |
| `\d tasks`  | describe the `tasks` table            |
| `\l`        | list all databases                    |
| `\timing`   | show how long each query takes        |
| `\q`        | quit                                  |
| `Ctrl+C`    | cancel a runaway query                |

---

## The roadmap

| #  | Lesson | You learn | You build |
|----|--------|-----------|-----------|
| 1  | `01_basics.sql` | Tables, `INSERT`, `SELECT`, `WHERE`, `UPDATE`, `DELETE` | the `tasks` table |
| 2  | Schema design | Keys, `NOT NULL`, `DEFAULT`, timestamps, evolving a schema safely | a sturdier schema |
| 3  | Querying deep-dive | `ORDER BY`, `LIMIT`, `ILIKE`, dates | "show my open tasks, newest first" |
| 4  | Aggregation | `COUNT`, `GROUP BY`, `HAVING` | "how many tasks per status/day" |
| 5  | JOINs | Foreign keys, `INNER`/`LEFT JOIN`, cascades | lists + tags across tables |
| 6  | Subqueries & views | `WITH` (CTEs), `CASE`, `CREATE VIEW` | a "my day" dashboard |
| 7  | Window functions | `ROW_NUMBER`, `RANK`, running totals | ranked/rolling queries |
| 8  | Transactions | `BEGIN`/`COMMIT`/`ROLLBACK`, ACID | safe multi-step changes |
| 9  | Performance | Indexes, `EXPLAIN ANALYZE` | making a slow query fast |
| 10 | SQL in apps | Parameterized queries, SQL injection, migrations | the Python app layer |

Each lesson also has short **"Under the hood"** notes — the software-engineering
concept hiding inside the SQL (data modeling, ACID, security, debugging). You're not
just learning syntax; you're learning how engineers think.

---

## The Python side

- `db.py` — tiny helper: connects to `todo_app`, runs a query, returns rows.
  Run `python db.py` for a demo.
- `seed.py` — fills the DB with sample data (safe to run repeatedly).
  Run `python seed.py` after Lesson 1 exists.

Used from Lesson 10 onward — and for the SQL-injection demo you won't forget.

---

## Cheat sheet: everyday commands

```bash
psql -d todo_app                 # open SQL shell
brew services list               # is Postgres running?
brew services restart postgresql@17   # if it ever stops
createdb todo_app                # (already done) create a database
```

## Git / GitHub

Everything is version-controlled locally. When you want this on GitHub, it's one
command (the `gh` CLI is already authenticated): `gh repo create --source . --push`.
