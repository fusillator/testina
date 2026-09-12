import sqlite3
from textwrap import dedent

def get_db(app):
    connection = sqlite3.connect(app.config["DATABASE"])
    connection.row_factory = sqlite3.Row
    return connection

def init_db(app):
    db = get_db(app)
    db.execute(dedent("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE
        )
    """).strip())
    db.commit()
    db.close()
