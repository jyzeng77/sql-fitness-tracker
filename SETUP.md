# SETUP — how this environment was built, step by step

This documents exactly what was done to get PostgreSQL + Python working for this
project, and why. Read it once, then keep it as your runbook for the next project.

## The big picture

Four separate things often get confused. Know the difference and setup stops being magic:

```
 your terminal            Postgres server              data on disk
┌─────────────┐   SQL   ┌──────────────────┐  reads/  ┌──────────────┐
│  psql       │ ──────► │ postgres process │ ◄──────► │ database     │
│  (client)   │         │  (the server)    │  writes  │ cluster      │
└─────────────┘         └──────────────────┘          └──────────────┘
                              ▲
                              │ speaks the Postgres protocol
                        ┌─────┴──────┐
                        │ Python app │
                        │ (psycopg)  │
                        └────────────┘
```

| Piece | What it is | Analogy |
|---|---|---|
| **Server** (`postgres`) | A background program that owns the data and answers queries | A bank vault |
| **Client** (`psql`) | A terminal app you type SQL into | The bank teller window |
| **Database** | A named namespace of tables *inside* the server (`todo_app`) | One account |
| **Driver** (`psycopg`) | A Python library that speaks Postgres's protocol | The ATM machine |

A database **server** is not the same as a **database**. The server is one process
that can host many databases. That's why we ran `brew install postgresql` once but
can create unlimited databases with `createdb`.

---

## What was run, in order

### 0. Check what's already installed
```bash
which psql python3 node   # "which" prints where a program lives, or nothing
```
Nothing Postgres-related existed yet, so we installed from scratch.

### 1. Install PostgreSQL (Homebrew)
```bash
brew install postgresql@17
```
- **Homebrew** is macOS's package manager — it downloads, builds, and updates dev
  software, and wires up `brew services` for background programs.
- `@17` pins the major version. Databases hold your data, so major-version
  upgrades are a big deal — pinning avoids surprises.
- Homebrew also ran `initdb`, which created a **cluster** (the on-disk home of all
  data) at `/opt/homebrew/var/postgresql@17`, and printed a warning worth knowing:
  > enabling "trust" authentication for local connections
  That means local connections need **no password**. Perfect for a dev machine;
  production servers are configured differently (via `pg_hba.conf`). Remember this
  exists — it's the number-one difference when you later deploy a real app.

### 2. Start the server as a background service
```bash
brew services start postgresql@17
```
- **Service** = a program the OS keeps running in the background and restarts at
  login. Your database survives closing the terminal and rebooting.
- Alternative: run the server in the foreground (`postgres -D <datadir>`) — good
  for debugging, dies with the terminal.
- Check on it: `brew services list`. Restart it: `brew services restart postgresql@17`.

### 3. Put psql on your PATH
```bash
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc
```
- The **PATH** is the list of directories your shell searches when you type a
  command. Versioned keg-only formulae (like `postgresql@17`) don't add themselves,
  so `psql` was "command not found" until we added their `bin` directory.
- `>>` appends a line to `~/.zshrc`, which runs every time you open a shell.
  **New terminals only** — already-open shells don't re-read it (or run
  `source ~/.zshrc` to force it).

### 4. Create the project's database
```bash
createdb todo_app
```
- One server, many databases. Each project gets its own — they can't interfere.
- No name given to `psql` = it defaults to your macOS username (`jerry`), which is
  also the superuser Homebrew created. That's why everything "just works" locally.

### 5. Verify (always verify!)
```bash
psql -d todo_app -c "SELECT version();"
```
Running a real query proves the whole chain: client → server → database.

### 6. Python environment
```bash
python3 -m venv .venv                      # create an isolated environment
.venv/bin/pip install "psycopg[binary]"    # install the driver INSIDE it
```
- A **virtualenv** is a private set of packages for one project, so projects
  can't break each other's dependencies. Always use one. To use it:
  `source .venv/bin/activate` (or just call `.venv/bin/python` directly, like our
  scripts do).
- **psycopg 3** is the standard Postgres driver for Python. It's how your code
  sends SQL and receives rows — the same SQL you type into psql.
- Note: `psycopg[binary]` — the bracket installs a prebuilt engine wheel (faster
  install). System Python here is 3.9; the venv inherits it.

### 7. Verify the Python path too
```bash
.venv/bin/python db.py   # prints server version; counts tasks if the table exists
```

---

## Troubleshooting (the classics)

| Symptom | Cause | Fix |
|---|---|---|
| `command not found: psql` | PATH not set in this shell | open a new terminal, or `source ~/.zshrc` |
| `connection refused ... port 5432` | server isn't running | `brew services start postgresql@17` |
| `database "x" does not exist` | never created | `createdb x` |
| `brew services list` shows error/status 1 | corrupt data dir or port clash | `brew services restart postgresql@17`; check `/opt/homebrew/var/log/postgresql@17.log` |
| `psql` connects to wrong database | no `-d` flag given | always pass `-d todo_app` |

The server log (`/opt/homebrew/var/log/postgresql@17.log`) is your friend — when a
database misbehaves, engineers read logs first.

---

## The reusable recipe (for your NEXT project)

```bash
# 1. one-time machine setup (already done on this Mac):
brew install postgresql@17
brew services start postgresql@17
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc

# 2. per-project setup:
mkdir myproject && cd myproject
git init
createdb myproject_db                 # one database per project
python3 -m venv .venv
.venv/bin/pip install "psycopg[binary]"
printf '.venv/\n__pycache__/\n.DS_Store\n' > .gitignore

# 3. verify the chain:
psql -d myproject_db -c "SELECT version();"
```

Swap `psycopg` for your app's other dependencies as needed. The shape never
changes: **install server → run service → create database → isolate language deps → verify.**
