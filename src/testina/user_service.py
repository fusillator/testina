from .database import get_db
class UserService:

    def __init__(self, app):
        self.app = app

    def create_user(self, name, email):
        db = get_db(self.app)
        cursor = db.execute(
            """
            INSERT INTO users (name, email)
            VALUES (?, ?)
            """,
            (name, email)
        )
        db.commit()
        user_id = cursor.lastrowid
        db.close()
        return {
            "id": user_id,
            "name": name,
            "email": email
        }
