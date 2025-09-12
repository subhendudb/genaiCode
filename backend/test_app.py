import os
import pytest
import json
from datetime import datetime, timedelta, date
from decimal import Decimal
from uuid import uuid4

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import warnings
warnings.filterwarnings("ignore", message="Using the in-memory storage for tracking rate limits*")
warnings.filterwarnings("ignore", category=DeprecationWarning, module="pythonjsonlogger")
warnings.filterwarnings("ignore", message="Pydantic V1 style `@validator` validators are deprecated*")

# Import the app and db from your backend
from app import app as flask_app, db, Account, Transaction, User

# --- Pytest Fixtures ---

@pytest.fixture(scope="session")
def app():
    # Use a test database (SQLite in-memory for speed)
    flask_app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    flask_app.config['TESTING'] = True
    flask_app.config['SECRET_KEY'] = 'test_secret'
    flask_app.config['JWT_ALGORITHM'] = 'HS256'
    flask_app.config['TOKEN_EXPIRES_SECONDS'] = 3600
    flask_app.config['RATELIMIT_ENABLED'] = False
    with flask_app.app_context():
        db.create_all()
        yield flask_app
        db.session.remove()
        #db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def runner(app):
    return app.test_cli_runner()

@pytest.fixture
def user(app):
    # Create a test user with a unique username for each test
    unique_username = f"testuser_{uuid4()}"
    u = User(username=unique_username)
    u.set_password("testpass")
    db.session.add(u)
    db.session.commit()
    return u

@pytest.fixture
def auth_token(client, user):
    # Use the unique username from the user fixture
    resp = client.post("/api/login", json={"username": user.username, "password": "testpass"})
    assert resp.status_code == 200
    return resp.get_json()["token"]

@pytest.fixture(autouse=True)
def session_rollback():
    yield
    db.session.rollback()

@pytest.fixture
def account_data():
    return {
        "name": "Cash",
        "type": "ASSET",
        "description": "Cash account",
        "opening_balance": "1000.0000"
    }

@pytest.fixture
def account(client, auth_token, account_data):
    # Create an account and return its ID
    resp = client.post("/api/accounts", json=account_data, headers={"Authorization": f"Bearer {auth_token}"})
    assert resp.status_code == 201
    return resp.get_json()

@pytest.fixture
def contra_account(client, auth_token):
    # Create a second account for transactions
    data = {
        "name": "Bank",
        "type": "ASSET",
        "description": "Bank account",
        "opening_balance": "500.0000"
    }
    resp = client.post("/api/accounts", json=data, headers={"Authorization": f"Bearer {auth_token}"})
    assert resp.status_code == 201
    return resp.get_json()

# --- Helper for Auth Header ---
def auth_header(token):
    return {"Authorization": f"Bearer {token}"}

# --- Test Cases ---


def test_health_check(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "healthy"}

def test_login_success(client, user):
    # Use the actual username from the user fixture
    resp = client.post("/api/login", json={"username": user.username, "password": "testpass"})
    assert resp.status_code == 200
    data = resp.get_json()
    assert "token" in data
    assert data["expires_in"] == 3600

def test_login_failure(client):
    resp = client.post("/api/login", json={"username": "wrong", "password": "wrong"})
    assert resp.status_code == 403
    assert "error" in resp.get_json()

def test_create_account_success(client, auth_token, account_data):
    resp = client.post("/api/accounts", json=account_data, headers=auth_header(auth_token))
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["name"] == account_data["name"]
    assert data["type"] == account_data["type"]
    assert data["opening_balance"] == float(account_data["opening_balance"])

def test_create_account_invalid_type(client, auth_token, account_data):
    bad_data = dict(account_data)
    bad_data["type"] = "INVALID"
    resp = client.post("/api/accounts", json=bad_data, headers=auth_header(auth_token))
    assert resp.status_code == 400
    assert "error" in resp.get_json()

def test_get_account_success(client, auth_token, account):
    resp = client.get(f"/api/accounts/{account['id']}", headers=auth_header(auth_token))
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["id"] == account["id"]

def test_get_account_not_found(client, auth_token):
    resp = client.get(f"/api/accounts/{uuid4()}", headers=auth_header(auth_token))
    assert resp.status_code == 404
    assert "error" in resp.get_json()

def test_update_account_success(client, auth_token, account):
    update = {"name": "Updated Cash"}
    resp = client.put(f"/api/accounts/{account['id']}", json=update, headers=auth_header(auth_token))
    assert resp.status_code == 200
    assert resp.get_json()["name"] == "Updated Cash"

def test_list_accounts(client, auth_token, account):
    resp = client.get("/api/accounts", headers=auth_header(auth_token))
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list)
    assert any(a["id"] == account["id"] for a in data)

def test_record_transaction_success(client, auth_token, account, contra_account):
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": contra_account["id"],
        "transaction_date": date.today().isoformat(),
        "amount": "100.0000",
        "description": "Test transfer"
    }
    resp = client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    assert resp.status_code == 201
    data = resp.get_json()
    assert "transaction" in data
    assert data["transaction"]["amount"] == 100.0

def test_record_transaction_invalid_account(client, auth_token, account):
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": str(uuid4()),
        "transaction_date": date.today().isoformat(),
        "amount": "100.0000",
        "description": "Invalid contra"
    }
    resp = client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    assert resp.status_code == 404
    assert "error" in resp.get_json()

def test_void_transaction_success(client, auth_token, account, contra_account):
    # First, record a transaction
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": contra_account["id"],
        "transaction_date": date.today().isoformat(),
        "amount": "50.0000",
        "description": "Void me"
    }
    resp = client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    tx_id = resp.get_json()["transaction"]["id"]

    # Now, void it
    void_resp = client.post(f"/api/transactions/{tx_id}/void", headers=auth_header(auth_token))
    assert void_resp.status_code == 200
    data = void_resp.get_json()
    assert data["transaction"]["is_void"] is True

def test_void_transaction_not_found(client, auth_token):
    resp = client.post(f"/api/transactions/{uuid4()}/void", headers=auth_header(auth_token))
    assert resp.status_code == 404
    assert "error" in resp.get_json()

def test_get_transaction_success(client, auth_token, account, contra_account):
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": contra_account["id"],
        "transaction_date": date.today().isoformat(),
        "amount": "25.0000",
        "description": "Get me"
    }
    resp = client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    tx_id = resp.get_json()["transaction"]["id"]

    get_resp = client.get(f"/api/transactions/{tx_id}", headers=auth_header(auth_token))
    assert get_resp.status_code == 200
    assert get_resp.get_json()["id"] == tx_id

def test_list_transactions(client, auth_token, account, contra_account):
    # Add a transaction
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": contra_account["id"],
        "transaction_date": date.today().isoformat(),
        "amount": "10.0000",
        "description": "List me"
    }
    client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    resp = client.get("/api/transactions", headers=auth_header(auth_token))
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list)
    assert any("id" in t for t in data)

def test_generate_balance_report(client, auth_token, account):
    resp = client.get("/api/reports/balance", headers=auth_header(auth_token))
    assert resp.status_code == 200
    data = resp.get_json()
    assert "accounts" in data
    assert "totals" in data

def test_generate_profit_loss_report(client, auth_token, account, contra_account):
    # Add an income transaction
    tx_data = {
        "account_id": account["id"],
        "contra_account_id": contra_account["id"],
        "transaction_date": date.today().isoformat(),
        "amount": "200.0000",
        "description": "Income"
    }
    client.post("/api/transactions", json=tx_data, headers=auth_header(auth_token))
    start = (date.today() - timedelta(days=1)).isoformat()
    end = (date.today() + timedelta(days=1)).isoformat()
    resp = client.get(f"/api/reports/profit-loss?start_date={start}&end_date={end}", headers=auth_header(auth_token))
    assert resp.status_code == 200
    data = resp.get_json()
    assert "total_income" in data
    assert "total_expenses" in data

def test_auth_required(client, account):
    # No token
    resp = client.get(f"/api/accounts/{account['id']}")
    assert resp.status_code == 403 or resp.status_code == 401

def test_invalid_token(client, account):
    resp = client.get(f"/api/accounts/{account['id']}", headers=auth_header("badtoken"))
    assert resp.status_code == 403

def test_404_route(client):
    resp = client.get("/api/doesnotexist")
    assert resp.status_code == 404
    assert "error" in resp.get_json() 