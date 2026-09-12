from flask import Flask, request, jsonify
from .user_service import UserService
from .database import get_db, init_db

def create_app(database_path="users.db"):
    app = Flask(__name__)
    app.config["DATABASE"] = database_path
    init_db(app)
    service = UserService(app)

    @app.get("/")
    def hello():
        return jsonify(
            message="✨ Welcome to day 5 ✨",
            tip="Built with Flask, shipped by Jenkins, running in Docker."
        )

    @app.post("/users")
    def create_user():
        data = request.get_json()
        user = service.create_user(
            name=data["name"],
            email=data["email"]
        )
        return jsonify(user), 201

    return app

