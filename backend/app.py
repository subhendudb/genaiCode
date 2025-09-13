import logging
import os
from datetime import date, datetime, timedelta
from decimal import Decimal
from enum import Enum
from functools import wraps
from logging.config import dictConfig
from typing import Dict, List, Optional

import bcrypt
import jwt
from dotenv import load_dotenv
from flask import Flask, Response, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from jwt.exceptions import InvalidTokenError
from pydantic import BaseModel, Field, ValidationError, validator
from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import joinedload
from werkzeug.security import check_password_hash, generate_password_hash

load_dotenv()  # Load .env file

# Application setup
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.environ["SECRET_KEY"]
app.config["JWT_ALGORITHM"] = os.environ.get("JWT_ALGORITHM", "HS256")
app.config["TOKEN_EXPIRES_SECONDS"] = int(os.environ.get("TOKEN_EXPIRES_SECONDS", 3600))

# CORS setup (restrict origins as needed)
# CORS(app, resources={r"/api/*": {"origins": os.environ.get('CORS_ORIGINS', '*')}},supports_credentials=True)
CORS(app, origins="*", supports_credentials=True)

# Database setup
db = SQLAlchemy(app)

# Configure logging for the application
dictConfig(
    {
        "version": 1,
        "formatters": {
            "json": {
                "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
                "format": "%(asctime)s %(levelname)s %(name)s %(message)s",
            }
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "json",
                "level": "INFO",
            }
        },
        "root": {"handlers": ["console"], "level": "INFO"},
    }
)

logger = logging.getLogger(__name__)


# Database Models
class Account(db.Model):
    """
    Represents an account in the accounting system.
    """

    __tablename__ = "accounts"
    __table_args__ = {"schema": "accounting"}

    id = db.Column(
        db.UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()"),
    )
    name = db.Column(db.String(255), nullable=False)
    type = db.Column(db.String(50), nullable=False)
    description = db.Column(db.Text)
    opening_balance = db.Column(db.Numeric(19, 4), nullable=False)
    current_balance = db.Column(db.Numeric(19, 4), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    updated_at = db.Column(
        db.DateTime(timezone=True), server_default=db.func.now(), onupdate=db.func.now()
    )
    created_by = db.Column(db.String(100), server_default=db.text("current_user"))
    updated_by = db.Column(db.String(100), server_default=db.text("current_user"))

    def to_dict(self):
        """
        Serialize the Account object to a dictionary for JSON responses.
        """
        return {
            "id": str(self.id),
            "name": self.name,
            "type": self.type,
            "description": self.description,
            "opening_balance": float(self.opening_balance),
            "current_balance": float(self.current_balance),
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


class Transaction(db.Model):
    """
    Represents a financial transaction between two accounts.
    """

    __tablename__ = "transactions"
    __table_args__ = {"schema": "accounting"}

    id = db.Column(
        db.UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()"),
    )
    account_id = db.Column(
        db.UUID(as_uuid=True), db.ForeignKey("accounting.accounts.id"), nullable=False
    )
    contra_account_id = db.Column(
        db.UUID(as_uuid=True), db.ForeignKey("accounting.accounts.id"), nullable=False
    )
    transaction_date = db.Column(db.Date, nullable=False)
    amount = db.Column(db.Numeric(19, 4), nullable=False)
    description = db.Column(db.String(500))
    reference_number = db.Column(db.String(100))
    is_void = db.Column(db.Boolean, nullable=False, server_default=db.text("false"))
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    created_by = db.Column(db.String(100), server_default=db.text("current_user"))

    account = db.relationship(
        "Account", foreign_keys=[account_id], backref="transactions"
    )
    contra_account = db.relationship(
        "Account", foreign_keys=[contra_account_id], backref="contra_transactions"
    )

    def to_dict(self):
        """
        Serialize the Transaction object to a dictionary for JSON responses.
        """
        return {
            "id": str(self.id),
            "account_id": str(self.account_id),
            "account_name": self.account.name if self.account else None,
            "contra_account_id": str(self.contra_account_id),
            "contra_account_name": self.contra_account.name
            if self.contra_account
            else None,
            "transaction_date": self.transaction_date.isoformat(),
            "amount": float(self.amount),
            "description": self.description,
            "reference_number": self.reference_number,
            "is_void": self.is_void,
            "created_at": self.created_at.isoformat(),
        }


class BalanceHistory(db.Model):
    """
    Stores historical balance snapshots for accounts.
    """

    __tablename__ = "balance_history"
    __table_args__ = {"schema": "accounting"}

    id = db.Column(
        db.UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()"),
    )
    account_id = db.Column(
        db.UUID(as_uuid=True), db.ForeignKey("accounting.accounts.id"), nullable=False
    )
    balance_date = db.Column(db.Date, nullable=False)
    balance = db.Column(db.Numeric(19, 4), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())

    account = db.relationship("Account", backref="balance_history")

    def to_dict(self):
        """
        Serialize the BalanceHistory object to a dictionary for JSON responses.
        """
        return {
            "id": str(self.id),
            "account_id": str(self.account_id),
            "balance_date": self.balance_date.isoformat(),
            "balance": float(self.balance),
            "created_at": self.created_at.isoformat(),
        }


class User(db.Model):
    """
    User model for authentication.
    """

    __tablename__ = "users"
    __table_args__ = {"schema": "accounting"}

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)


# Pydantic Models for Validation
class AccountCreate(BaseModel):
    """
    Pydantic model for validating account creation requests.
    """

    name: str = Field(..., max_length=255)
    type: str = Field(
        ..., pattern="^(INCOME|EXPENSE|ASSET|LIABILITY)$"
    )  # <-- changed here
    description: Optional[str] = None
    opening_balance: Decimal = Field(..., decimal_places=4)


class AccountUpdate(BaseModel):
    """
    Pydantic model for validating account update requests.
    """

    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None


class TransactionCreate(BaseModel):
    """
    Pydantic model for validating transaction creation requests.
    """

    account_id: str = Field(..., min_length=36, max_length=36)
    contra_account_id: str = Field(..., min_length=36, max_length=36)
    transaction_date: date
    amount: Decimal = Field(..., gt=0, decimal_places=4)
    description: Optional[str] = Field(None, max_length=500)
    reference_number: Optional[str] = Field(None, max_length=100)

    @validator("contra_account_id")
    def accounts_must_differ(cls, v, values):
        """
        Ensure that the account and contra account are not the same.
        """
        if "account_id" in values and v == values["account_id"]:
            raise ValueError("Account and contra account must be different")
        return v


# Custom Exceptions
class FinancialSystemError(Exception):
    """
    Base exception class for financial system errors.
    """

    status_code = 500
    detail = "An unexpected error occurred"

    def __init__(self, detail=None, status_code=None):
        super().__init__()
        if detail is not None:
            self.detail = detail
        if status_code is not None:
            self.status_code = status_code

    def to_dict(self):
        """
        Serialize the error to a dictionary for JSON responses.
        """
        return {"error": self.detail}


class RequestValidationError(FinancialSystemError):
    """
    Exception for validation errors.
    """

    status_code = 400
    detail = "Validation error"


class InsufficientFundsError(FinancialSystemError):
    """
    Exception for insufficient funds during a transaction.
    """

    status_code = 402
    detail = "Insufficient funds"


class NotFoundError(FinancialSystemError):
    """
    Exception for resources not found.
    """

    status_code = 404
    detail = "Resource not found"


class AuthorizationError(FinancialSystemError):
    """
    Exception for authorization errors.
    """

    status_code = 403
    detail = "Authorization error"


# Error Handlers
@app.errorhandler(FinancialSystemError)
def handle_financial_system_error(e):
    """
    Handle custom financial system errors.
    """
    logger.error(f"FinancialSystemError: {e.detail}", exc_info=True)
    return jsonify(e.to_dict()), e.status_code


@app.errorhandler(RequestValidationError)
def handle_validation_error(e):
    """
    Handle validation errors.
    """
    logger.error(f"RequestValidationError: {e.detail}", exc_info=True)
    return jsonify(e.to_dict()), e.status_code


@app.errorhandler(404)
def handle_not_found(e):
    """
    Handle 404 not found errors.
    """
    logger.error("Resource not found", exc_info=True)
    return jsonify({"error": "Resource not found"}), 404


@app.errorhandler(500)
def handle_internal_error(e):
    """
    Handle 500 internal server errors.
    """
    logger.error("Internal server error", exc_info=True)
    return jsonify({"error": "Internal server error"}), 500


# Authentication Decorator
def token_required(f):
    """
    Decorator to require JWT authentication for protected endpoints.
    """

    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if "Authorization" in request.headers:
            token = request.headers["Authorization"].split()[1]

        if not token:
            raise AuthorizationError("Token is missing")

        try:
            data = jwt.decode(
                token,
                app.config["SECRET_KEY"],
                algorithms=[app.config["JWT_ALGORITHM"]],
            )
            current_user = data["sub"]
        except InvalidTokenError:
            raise AuthorizationError("Token is invalid")

        return f(current_user, *args, **kwargs)

    return decorated


# Services
class AccountService:
    """
    Service class for account-related operations.
    """

    @staticmethod
    def create_account(data: dict) -> Account:
        """
        Create a new account with the provided data.
        """
        try:
            validated_data = AccountCreate(**data).dict()
        except ValidationError as e:
            raise RequestValidationError(str(e))

        account = Account(
            name=validated_data["name"],
            type=validated_data["type"],
            description=validated_data.get("description"),
            opening_balance=validated_data["opening_balance"],
            current_balance=validated_data["opening_balance"],
        )

        try:
            db.session.add(account)
            db.session.commit()
            logger.info(f"Created account: {account.id}")
            return account
        except IntegrityError as e:
            db.session.rollback()
            raise RequestValidationError(
                "Account creation failed due to database constraints"
            )
        except SQLAlchemyError as e:
            db.session.rollback()
            logger.error(f"Error creating account: {str(e)}")
            raise FinancialSystemError("Failed to create account")

    @staticmethod
    def get_account(account_id: str) -> Account:
        """
        Retrieve an account by its ID.
        """
        try:
            account = db.session.execute(
                select(Account).where(Account.id == account_id)
            ).scalar_one_or_none()

            if not account:
                raise NotFoundError("Account not found")
            return account
        except SQLAlchemyError as e:
            logger.error(f"Error fetching account: {str(e)}")
            raise FinancialSystemError("Failed to fetch account")

    @staticmethod
    def update_account(account_id: str, data: dict) -> Account:
        """
        Update an existing account with new data.
        """
        try:
            validated_data = AccountUpdate(**data).dict(exclude_unset=True)
        except ValidationError as e:
            raise RequestValidationError(str(e))

        try:
            account = AccountService.get_account(account_id)

            for key, value in validated_data.items():
                setattr(account, key, value)

            db.session.commit()
            logger.info(f"Updated account: {account.id}")
            return account
        except SQLAlchemyError as e:
            db.session.rollback()
            logger.error(f"Error updating account: {str(e)}")
            raise FinancialSystemError("Failed to update account")

    @staticmethod
    def list_accounts(
        filters: dict = None, page: int = 1, per_page: int = 20
    ) -> List[Account]:
        """
        List accounts, optionally filtered by type or name, with pagination.
        """
        try:
            query = select(Account)

            if filters:
                conditions = []
                if "type" in filters:
                    conditions.append(Account.type == filters["type"])
                if "name" in filters:
                    conditions.append(Account.name.ilike(f"%{filters['name']}%"))

                if conditions:
                    query = query.where(and_(*conditions))

            accounts = db.session.execute(query).scalars().all()
            # Pagination
            start = (page - 1) * per_page
            end = start + per_page
            return accounts[start:end]
        except SQLAlchemyError as e:
            logger.error(f"Error listing accounts: {str(e)}")
            raise FinancialSystemError("Failed to list accounts")


class TransactionService:
    """
    Service class for transaction-related operations.
    """

    @staticmethod
    def record_transaction(data: dict) -> dict:
        """
        Record a new transaction and update account balances.
        """
        try:
            validated_data = TransactionCreate(**data).dict()
        except ValidationError as e:
            raise RequestValidationError(str(e))

        try:
            # Get accounts with locking
            account = db.session.execute(
                select(Account)
                .where(Account.id == validated_data["account_id"])
                .with_for_update()
            ).scalar_one_or_none()

            contra_account = db.session.execute(
                select(Account)
                .where(Account.id == validated_data["contra_account_id"])
                .with_for_update()
            ).scalar_one_or_none()

            if not account or not contra_account:
                raise NotFoundError("One or both accounts not found")

            # Check sufficient funds for asset/liability accounts
            if account.type in ["ASSET", "LIABILITY"]:
                new_balance = account.current_balance + validated_data["amount"]
                if new_balance < 0:
                    raise InsufficientFundsError()

            # Create transaction
            transaction = Transaction(
                account_id=validated_data["account_id"],
                contra_account_id=validated_data["contra_account_id"],
                transaction_date=validated_data["transaction_date"],
                amount=validated_data["amount"],
                description=validated_data.get("description"),
                reference_number=validated_data.get("reference_number"),
            )

            # Update balances
            account.current_balance += validated_data["amount"]
            contra_account.current_balance -= validated_data["amount"]

            db.session.add(transaction)
            db.session.commit()

            logger.info(f"Recorded transaction: {transaction.id}")

            return {
                "transaction": transaction,
                "new_balances": {
                    "account": account.current_balance,
                    "contra_account": contra_account.current_balance,
                },
            }
        except SQLAlchemyError as e:
            db.session.rollback()
            logger.error(f"Error recording transaction: {str(e)}")
            raise FinancialSystemError("Failed to record transaction")

    @staticmethod
    def void_transaction(transaction_id: str) -> dict:
        """
        Void (reverse) a transaction and update account balances.
        """
        try:
            # 1. Lock the transaction row
            transaction = db.session.execute(
                select(Transaction)
                .where(Transaction.id == transaction_id)
                .with_for_update()
            ).scalar_one_or_none()

            if not transaction:
                raise NotFoundError("Transaction not found")

            if transaction.is_void:
                raise RequestValidationError("Transaction already voided")

            # 2. Lock the related accounts
            account = db.session.execute(
                select(Account)
                .where(Account.id == transaction.account_id)
                .with_for_update()
            ).scalar_one_or_none()

            contra_account = db.session.execute(
                select(Account)
                .where(Account.id == transaction.contra_account_id)
                .with_for_update()
            ).scalar_one_or_none()

            # 3. Update balances and void
            account.current_balance -= transaction.amount
            contra_account.current_balance += transaction.amount
            transaction.is_void = True

            db.session.commit()
            logger.info(f"Voided transaction: {transaction.id}")

            return {
                "transaction": transaction,
                "new_balances": {
                    "account": account.current_balance,
                    "contra_account": contra_account.current_balance,
                },
            }
        except SQLAlchemyError as e:
            db.session.rollback()
            logger.error(f"Error voiding transaction: {str(e)}")
            raise FinancialSystemError("Failed to void transaction")

    @staticmethod
    def get_transaction(transaction_id: str) -> Transaction:
        """
        Retrieve a transaction by its ID.
        """
        try:
            transaction = db.session.execute(
                select(Transaction)
                .where(Transaction.id == transaction_id)
                .options(
                    joinedload(Transaction.account),
                    joinedload(Transaction.contra_account),
                )
            ).scalar_one_or_none()

            if not transaction:
                raise NotFoundError("Transaction not found")
            return transaction
        except SQLAlchemyError as e:
            logger.error(f"Error fetching transaction: {str(e)}")
            raise FinancialSystemError("Failed to fetch transaction")

    @staticmethod
    def list_transactions(
        filters: dict = None, page: int = 1, per_page: int = 20
    ) -> List[Transaction]:
        """
        List transactions, optionally filtered by account, date, or void status, with pagination.
        """
        try:
            query = (
                select(Transaction)
                .options(
                    joinedload(Transaction.account),
                    joinedload(Transaction.contra_account),
                )
                .order_by(
                    Transaction.transaction_date.desc(), Transaction.created_at.desc()
                )
            )

            if filters:
                conditions = []
                if "account_id" in filters:
                    conditions.append(
                        or_(
                            Transaction.account_id == filters["account_id"],
                            Transaction.contra_account_id == filters["account_id"],
                        )
                    )
                if "start_date" in filters:
                    conditions.append(
                        Transaction.transaction_date >= filters["start_date"]
                    )
                if "end_date" in filters:
                    conditions.append(
                        Transaction.transaction_date <= filters["end_date"]
                    )
                if "is_void" in filters:
                    conditions.append(Transaction.is_void == filters["is_void"])

                if conditions:
                    query = query.where(and_(*conditions))

            if "limit" in filters:
                query = query.limit(filters["limit"])

            transactions = db.session.execute(query).scalars().unique().all()
            # Pagination
            start = (page - 1) * per_page
            end = start + per_page
            return transactions[start:end]
        except SQLAlchemyError as e:
            logger.error(f"Error listing transactions: {str(e)}")
            raise FinancialSystemError("Failed to list transactions")


class ReportService:
    """
    Service class for generating financial reports.
    """

    @staticmethod
    def generate_balance_report(report_date: date = None) -> dict:
        """
        Generate a balance report for all accounts as of a given date.
        """
        if not report_date:
            report_date = date.today()

        try:
            # Get all accounts with their current balances
            accounts = (
                db.session.execute(select(Account).order_by(Account.type, Account.name))
                .scalars()
                .all()
            )

            # Calculate totals by type
            totals = {
                "INCOME": Decimal("0.00"),
                "EXPENSE": Decimal("0.00"),
                "ASSET": Decimal("0.00"),
                "LIABILITY": Decimal("0.00"),
            }

            for account in accounts:
                totals[account.type] += account.current_balance

            # Calculate net worth (Assets - Liabilities)
            net_worth = totals["ASSET"] - totals["LIABILITY"]

            return {
                "report_date": report_date.isoformat(),
                "accounts": [account.to_dict() for account in accounts],
                "totals": {k: float(v) for k, v in totals.items()},
                "net_worth": float(net_worth),
            }
        except SQLAlchemyError as e:
            logger.error(f"Error generating balance report: {str(e)}")
            raise FinancialSystemError("Failed to generate balance report")

    @staticmethod
    def generate_profit_loss_report(start_date: date, end_date: date) -> dict:
        """
        Generate a profit and loss report for a date range.
        """
        try:
            # Query income and expense transactions
            income_result = db.session.execute(
                select(func.sum(Transaction.amount).label("total"))
                .join(Transaction.account)
                .where(
                    Account.type == "INCOME",
                    Transaction.transaction_date.between(start_date, end_date),
                    Transaction.is_void == False,
                )
            ).scalar_one()
            income = income_result if income_result is not None else Decimal("0.00")
            print(f"Debug statement:{income}")
            expenses_result = db.session.execute(
                select(func.sum(Transaction.amount).label("total"))
                .join(Transaction.contra_account)
                .where(
                    Account.type == "EXPENSE",
                    Transaction.transaction_date.between(start_date, end_date),
                    Transaction.is_void == False,
                )
            ).scalar_one()

            expenses = (
                expenses_result if expenses_result is not None else Decimal("0.00")
            )
            print(f"Debug Expense statement:{expenses_result}")
            # Calculate profit/loss
            profit_loss = income - expenses

            return {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "total_income": float(income),
                "total_expenses": float(expenses),
                "net_profit_loss": float(profit_loss),
            }
        except SQLAlchemyError as e:
            logger.error(f"Error generating profit/loss report: {str(e)}")
            raise FinancialSystemError("Failed to generate profit/loss report")


# API Endpoints


@app.route("/api/accounts", methods=["POST"])
@token_required
def create_account(current_user):
    """
    API endpoint to create a new account.
    """
    try:
        data = request.get_json()
        account = AccountService.create_account(data)
        return jsonify(account.to_dict()), 201
    except RequestValidationError as e:
        return jsonify(e.to_dict()), e.status_code
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in create_account: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/accounts/<account_id>", methods=["GET"])
@token_required
def get_account(current_user, account_id):
    """
    API endpoint to retrieve an account by ID.
    """
    try:
        account = AccountService.get_account(account_id)
        return jsonify(account.to_dict())
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in get_account: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/accounts/<account_id>", methods=["PUT"])
@token_required
def update_account(current_user, account_id):
    """
    API endpoint to update an account.
    """
    try:
        data = request.get_json()
        account = AccountService.update_account(account_id, data)
        return jsonify(account.to_dict())
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in update_account: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/accounts", methods=["GET"])
@token_required
def list_accounts(current_user):
    """
    API endpoint to list accounts with optional filters and pagination.
    """
    try:
        filters = request.args.to_dict()
        page = int(filters.pop("page", 1))
        per_page = int(filters.pop("per_page", 20))
        accounts = AccountService.list_accounts(filters, page, per_page)
        return jsonify([account.to_dict() for account in accounts])
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in list_accounts: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/transactions", methods=["POST"])
@token_required
def record_transaction(current_user):
    """
    API endpoint to record a new transaction.
    """
    try:
        data = request.get_json()
        result = TransactionService.record_transaction(data)
        return (
            jsonify(
                {
                    "transaction": result["transaction"].to_dict(),
                    "new_balances": {
                        "account": float(result["new_balances"]["account"]),
                        "contra_account": float(
                            result["new_balances"]["contra_account"]
                        ),
                    },
                }
            ),
            201,
        )
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in record_transaction: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/transactions/<transaction_id>/void", methods=["POST"])
@token_required
def void_transaction(current_user, transaction_id):
    """
    API endpoint to void (reverse) a transaction.
    """
    try:
        result = TransactionService.void_transaction(transaction_id)
        return jsonify(
            {
                "transaction": result["transaction"].to_dict(),
                "new_balances": {
                    "account": float(result["new_balances"]["account"]),
                    "contra_account": float(result["new_balances"]["contra_account"]),
                },
            }
        )
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in void_transaction: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/transactions/<transaction_id>", methods=["GET"])
@token_required
def get_transaction(current_user, transaction_id):
    """
    API endpoint to retrieve a transaction by ID.
    """
    try:
        transaction = TransactionService.get_transaction(transaction_id)
        return jsonify(transaction.to_dict())
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in get_transaction: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/transactions", methods=["GET"])
@token_required
def list_transactions(current_user):
    """
    API endpoint to list transactions with optional filters and pagination.
    """
    try:
        filters = request.args.to_dict()
        page = int(filters.pop("page", 1))
        per_page = int(filters.pop("per_page", 20))
        # Convert date strings to date objects if present
        if "start_date" in filters:
            filters["start_date"] = datetime.strptime(
                filters["start_date"], "%Y-%m-%d"
            ).date()
        if "end_date" in filters:
            filters["end_date"] = datetime.strptime(
                filters["end_date"], "%Y-%m-%d"
            ).date()
        transactions = TransactionService.list_transactions(filters, page, per_page)
        return jsonify([t.to_dict() for t in transactions])
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in list_transactions: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/reports/balance", methods=["GET"])
@token_required
def generate_balance_report(current_user):
    """
    API endpoint to generate a balance report.
    """
    try:
        report_date = request.args.get("date")
        if report_date:
            report_date = datetime.strptime(report_date, "%Y-%m-%d").date()

        report = ReportService.generate_balance_report(report_date)
        return jsonify(report)
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in generate_balance_report: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


@app.route("/api/reports/profit-loss", methods=["GET"])
@token_required
def generate_profit_loss_report(current_user):
    """
    API endpoint to generate a profit and loss report.
    """
    try:
        start_date = datetime.strptime(request.args["start_date"], "%Y-%m-%d").date()
        end_date = datetime.strptime(request.args["end_date"], "%Y-%m-%d").date()

        report = ReportService.generate_profit_loss_report(start_date, end_date)
        return jsonify(report)
    except FinancialSystemError as e:
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in generate_profit_loss_report: {str(e)}")
        raise FinancialSystemError("Unexpected error occurred")


# Health check endpoint
class LoginRequest(BaseModel):
    """
    Pydantic model for validating login requests.
    """

    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)  # In real apps, validate properly


@app.route("/api/login", methods=["POST"])
def login():
    """
    Login endpoint with password hashing and user table.
    """
    print(f"login started..")
    try:
        data = LoginRequest(**request.get_json()).dict()
        user = db.session.execute(
            select(User).where(User.username == data["username"])
        ).scalar_one_or_none()
        if not user or not user.check_password(data["password"]):
            raise AuthorizationError("Invalid credentials")

        payload = {
            "sub": user.username,
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow()
            + timedelta(seconds=app.config["TOKEN_EXPIRES_SECONDS"]),
        }
        token = jwt.encode(
            payload, app.config["SECRET_KEY"], algorithm=app.config["JWT_ALGORITHM"]
        )
        return jsonify(
            {"token": token, "expires_in": app.config["TOKEN_EXPIRES_SECONDS"]}
        )
    except ValidationError as e:
        raise RequestValidationError("Invalid request format")
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise AuthorizationError("Login failed")


class RegisterRequest(BaseModel):
    """
    Pydantic model for validating registration requests.
    """

    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


@app.route("/api/register", methods=["POST"])
def register():
    """
    User registration endpoint.
    """
    try:
        data = RegisterRequest(**request.get_json()).dict()
        # Check if user already exists
        existing_user = db.session.execute(
            select(User).where(User.username == data["username"])
        ).scalar_one_or_none()
        if existing_user:
            raise RequestValidationError("Username already exists")

        user = User(username=data["username"])
        user.set_password(data["password"])
        db.session.add(user)
        db.session.commit()
        return jsonify({"message": "User registered successfully"}), 201
    except ValidationError as e:
        raise RequestValidationError("Invalid request format")
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        raise FinancialSystemError("Registration failed")


# Keep the health check endpoint at the bottom
@app.route("/health", methods=["GET"])
def health_check():
    """
    Health check endpoint to verify the service is running.
    """
    return jsonify({"status": "healthy"}), 200


# Database initialization
def init_db():
    """
    Initialize the database tables (for development only).
    """
    with app.app_context():
        db.create_all()


if __name__ == "__main__":
    # Only for development! Use Alembic for migrations in production.
    if os.environ.get("FLASK_ENV") == "development":
        init_db()
    app.run(host="0.0.0.0", port=5000)
