import pytest
import sqlite3
from testina import create_app
from testina.database import init_db

@pytest.fixture
def app(tmp_path):
    database_path = tmp_path / "test.db"
    return create_app(str(database_path))

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.mark.integration
def test_create_user(client, app):
    response = client.post(
        "/users",
        json={
            "name": "Alice",
            "email": "alice@example.com"
        }
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["name"] == "Alice"
    assert data["email"] == "alice@example.com"
    db = sqlite3.connect(app.config["DATABASE"])
    row = db.execute(
        "SELECT name, email FROM users WHERE email = ?",
        ("alice@example.com",)
    ).fetchone()
    db.close()
    assert row is not None
    assert row[0] == "Alice"
    assert row[1] == "alice@example.com"
