from unittest.mock import Mock, patch
from testina.user_service import UserService

@patch("user_service.get_db")
def test_create_user(mock_get_db):
    # Fake database
    db = Mock()
    # Fake cursor
    cursor = Mock()
    # Pretend the database generated ID 123
    cursor.lastrowid = 123
    # When get_db() is called, return our fake db
    mock_get_db.return_value = db
    # When db.execute() is called, return our fake cursor
    db.execute.return_value = cursor
    service = UserService("fake_app")
    result = service.create_user(
        "Alice",
        "alice@example.com"
    )
    assert result == {
        "id": 123,
        "name": "Alice",
        "email": "alice@example.com"
    }

@patch("user_service.get_db")
def test_create_user(mock_get_db):
    db = Mock()
    mock_get_db.return_value = db
    service = UserService("fake_app")
    service.create_user("Alice", "alice@example.com")
    db.execute.assert_called_once()
    db.execute.assert_called_once_with(
        """
            INSERT INTO users (name, email)
            VALUES (?, ?)
        """,
        ("Alice", "alice@example.com")
    )
