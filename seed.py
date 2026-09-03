"""
seed.py — fills todo_app with sample data.

Safe to run repeatedly: it only inserts sample rows when the table is empty.
Notice how Python code here is just composing the same SQL you learned in
Lesson 1 — the database doesn't care which client sends the query.

Run:  python seed.py
"""

import db

# IF NOT EXISTS makes this idempotent (re-runnable without errors).
CREATE_TASKS = """
CREATE TABLE IF NOT EXISTS tasks (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      TEXT NOT NULL,
    done       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
"""

SAMPLE_TASKS = [
    ("Learn SQL basics", True),
    ("Design the schema for my todo app", True),
    ("Practice JOINs with tags", False),
    ("Try EXPLAIN ANALYZE on a slow query", False),
    ("Build the todo app UI in Python", False),
]


def seed():
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute(CREATE_TASKS)
            cur.execute("SELECT COUNT(*) AS n FROM tasks;")
            if cur.fetchone()["n"] > 0:
                print("Tasks table already has data — nothing to do.")
                return
            # One INSERT can add many rows at once.
            cur.executemany(
                "INSERT INTO tasks (title, done) VALUES (%s, %s);",
                SAMPLE_TASKS,
            )
        conn.commit()  # a transaction: all-or-nothing (Lesson 8 teaser)
    print(f"Seeded {len(SAMPLE_TASKS)} sample tasks.")


if __name__ == "__main__":
    seed()
