from .database import get_db
from textwrap import dedent
class UserService:

    def __init__(self, app):
        self.app = app

    def create_user(self, name, email):
        db = get_db(self.app)
        query = dedent("""
            INSERT INTO users (name, email)
            VALUES (?, ?)
            """).strip()
        cursor = db.execute(query, (name, email))
        db.commit()
        user_id = cursor.lastrowid
        db.close()
        return {
            "id": user_id,
            "name": name,
            "email": email
        }
