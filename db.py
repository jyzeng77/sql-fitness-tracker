"""
db.py — the bridge between Python and PostgreSQL.

From Lesson 10 onward, this is how our app talks to the database.
Run `python db.py` to see a live demo.

Under the hood:
- A *connection* is a live session with the database server.
- A *cursor* runs one query at a time. You send SQL, the server returns rows.
- We use `psycopg3`, the standard PostgreSQL driver for Python.
"""

import psycopg
from psycopg.rows import dict_row  # so rows come back as dicts, not tuples

DBNAME = "todo_app"


def connect():
    """Open a connection to the todo_app database."""
    return psycopg.connect(dbname=DBNAME, row_factory=dict_row)


def run(sql, params=None, fetch=True):
    """
    Run one SQL statement and return the rows (if fetch=True).

    The `params` argument is how you pass values into a query SAFELY.
    We'll dig into that in Lesson 10 — including why it matters a lot.
    """
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall() if fetch else None


if __name__ == "__main__":
    print("Connected to:", DBNAME)
    version = run("SELECT version();")[0]["version"]
    print("Server:", version.split(",")[0])
    try:
        count = run("SELECT COUNT(*) AS n FROM tasks;")[0]["n"]
        print(f"Tasks in the database: {count}")
    except psycopg.errors.UndefinedTable:
        print("No `tasks` table yet — run Lesson 1 first! (psql -d todo_app, then \\i lessons/01_basics.sql)")
