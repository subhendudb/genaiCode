-- =============================================
-- Database Schema Validation Tests
-- =============================================

-- Test schema existence and permissions
BEGIN;
SELECT plan(1);
SELECT has_schema('accounting', 'Schema should exist');
SELECT * FROM finish();
ROLLBACK;

-- Test role existence and permissions
BEGIN;
SELECT plan(3);
SELECT has_role('accounting_admin', 'Admin role should exist');
SELECT has_role('accounting_app', 'Application role should exist');
SELECT has_role('accounting_readonly', 'Readonly role should exist');
SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- Table Structure Validation
-- =============================================

-- Test accounts table structure
BEGIN;
SELECT plan(14);

SELECT has_table('accounting', 'accounts', 'Accounts table should exist');
SELECT col_not_null('accounting', 'accounts', 'id', 'Accounts.id should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'name', 'Accounts.name should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'type', 'Accounts.type should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'opening_balance', 'Accounts.opening_balance should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'current_balance', 'Accounts.current_balance should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'created_at', 'Accounts.created_at should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'updated_at', 'Accounts.updated_at should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'created_by', 'Accounts.created_by should be NOT NULL');
SELECT col_not_null('accounting', 'accounts', 'updated_by', 'Accounts.updated_by should be NOT NULL');

SELECT col_type_is('accounting', 'accounts', 'type', 'character varying(50)', 'Accounts.type should be VARCHAR(50)');
SELECT col_type_is('accounting', 'accounts', 'opening_balance', 'numeric(19,4)', 'Accounts.opening_balance should be DECIMAL(19,4)');
SELECT col_type_is('accounting', 'accounts', 'current_balance', 'numeric(19,4)', 'Accounts.current_balance should be DECIMAL(19,4)');

SELECT has_check('accounting', 'accounts', 'Accounts table should have type constraint');

SELECT * FROM finish();
ROLLBACK;

-- Test transactions table structure
BEGIN;
SELECT plan(16);

SELECT has_table('accounting', 'transactions', 'Transactions table should exist');
SELECT col_not_null('accounting', 'transactions', 'id', 'Transactions.id should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'account_id', 'Transactions.account_id should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'contra_account_id', 'Transactions.contra_account_id should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'transaction_date', 'Transactions.transaction_date should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'amount', 'Transactions.amount should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'created_at', 'Transactions.created_at should be NOT NULL');
SELECT col_not_null('accounting', 'transactions', 'created_by', 'Transactions.created_by should be NOT NULL');

SELECT col_type_is('accounting', 'transactions', 'amount', 'numeric(19,4)', 'Transactions.amount should be DECIMAL(19,4)');
SELECT col_type_is('accounting', 'transactions', 'is_void', 'boolean', 'Transactions.is_void should be BOOLEAN');
SELECT col_default_is('accounting', 'transactions', 'is_void', 'false', 'Transactions.is_void should default to false');

SELECT has_check('accounting', 'transactions', 'Transactions table should have amount constraint');
SELECT has_check('accounting', 'transactions', 'Transactions table should have account_id != contra_account_id constraint');
SELECT has_foreign_key('accounting', 'transactions', 'transactions_account_id_fkey', 'Transactions should have account_id foreign key');
SELECT has_foreign_key('accounting', 'transactions', 'transactions_contra_account_id_fkey', 'Transactions should have contra_account_id foreign key');

SELECT index_is_unique('accounting', 'transactions', 'transactions_pkey', 'Transactions primary key should be unique');

SELECT * FROM finish();
ROLLBACK;

-- Test balance_history table structure
BEGIN;
SELECT plan(9);

SELECT has_table('accounting', 'balance_history', 'Balance_history table should exist');
SELECT col_not_null('accounting', 'balance_history', 'id', 'Balance_history.id should be NOT NULL');
SELECT col_not_null('accounting', 'balance_history', 'account_id', 'Balance_history.account_id should be NOT NULL');
SELECT col_not_null('accounting', 'balance_history', 'balance_date', 'Balance_history.balance_date should be NOT NULL');
SELECT col_not_null('accounting', 'balance_history', 'balance', 'Balance_history.balance should be NOT NULL');
SELECT col_not_null('accounting', 'balance_history', 'created_at', 'Balance_history.created_at should be NOT NULL');

SELECT col_type_is('accounting', 'balance_history', 'balance', 'numeric(19,4)', 'Balance_history.balance should be DECIMAL(19,4)');
SELECT has_foreign_key('accounting', 'balance_history', 'balance_history_account_id_fkey', 'Balance_history should have account_id foreign key');
SELECT index_is_unique('accounting', 'balance_history', 'balance_history_account_id_balance_date_key', 'Balance_history should have unique constraint on account_id+balance_date');

SELECT * FROM finish();
ROLLBACK;

-- Test users table structure
BEGIN;
SELECT plan(6);

SELECT has_table('accounting', 'users', 'Users table should exist');
SELECT col_not_null('accounting', 'users', 'id', 'Users.id should be NOT NULL');
SELECT col_not_null('accounting', 'users', 'username', 'Users.username should be NOT NULL');
SELECT col_not_null('accounting', 'users', 'password_hash', 'Users.password_hash should be NOT NULL');
SELECT col_not_null('accounting', 'users', 'created_at', 'Users.created_at should be NOT NULL');

SELECT index_is_unique('accounting', 'users', 'users_username_key', 'Users.username should be unique');

SELECT * FROM finish();
ROLLBACK;

-- Test audit_log table structure
BEGIN;
SELECT plan(10);

SELECT has_table('accounting', 'audit_log', 'Audit_log table should exist');
SELECT col_not_null('accounting', 'audit_log', 'id', 'Audit_log.id should be NOT NULL');
SELECT col_not_null('accounting', 'audit_log', 'table_name', 'Audit_log.table_name should be NOT NULL');
SELECT col_not_null('accounting', 'audit_log', 'record_id', 'Audit_log.record_id should be NOT NULL');
SELECT col_not_null('accounting', 'audit_log', 'operation', 'Audit_log.operation should be NOT NULL');
SELECT col_not_null('accounting', 'audit_log', 'changed_by', 'Audit_log.changed_by should be NOT NULL');
SELECT col_not_null('accounting', 'audit_log', 'changed_at', 'Audit_log.changed_at should be NOT NULL');

SELECT has_check('accounting', 'audit_log', 'Audit_log should have operation constraint');
SELECT index_is_unique('accounting', 'audit_log', 'audit_log_pkey', 'Audit_log primary key should be unique');
SELECT indexes_are('accounting', 'audit_log', ARRAY['audit_log_pkey', 'idx_audit_log_table_record', 'idx_audit_log_changed_at'], 'Audit_log should have correct indexes');

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- Index Validation
-- =============================================

BEGIN;
SELECT plan(9);

SELECT indexes_are('accounting', 'transactions', ARRAY[
    'transactions_pkey',
    'idx_transactions_account_id',
    'idx_transactions_contra_account_id',
    'idx_transactions_date',
    'idx_transactions_void_status'
], 'Transactions table should have correct indexes');

SELECT indexes_are('accounting', 'balance_history', ARRAY[
    'balance_history_pkey',
    'balance_history_account_id_balance_date_key',
    'idx_balance_history_account_date'
], 'Balance_history table should have correct indexes');

SELECT indexes_are('accounting', 'accounts', ARRAY[
    'accounts_pkey',
    'idx_accounts_type',
    'idx_accounts_name'
], 'Accounts table should have correct indexes');

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- View Validation
-- =============================================

BEGIN;
SELECT plan(3);

SELECT has_view('accounting', 'current_balances', 'current_balances view should exist');
SELECT has_view('accounting', 'transaction_history', 'transaction_history view should exist');
SELECT has_view('accounting', 'monthly_profit_loss', 'monthly_profit_loss view should exist');

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- Data Integrity Tests
-- =============================================

-- Test account type constraint
BEGIN;
SELECT plan(1);

PREPARE invalid_account_type AS 
INSERT INTO accounting.accounts (name, type, opening_balance, current_balance) 
VALUES ('Test', 'INVALID', 0, 0);

SELECT throws_ok(
    'invalid_account_type',
    '23514',
    'new row for relation "accounts" violates check constraint "accounts_type_check"',
    'Should reject invalid account type'
);

SELECT * FROM finish();
ROLLBACK;

-- Test transaction amount constraint
BEGIN;
SELECT plan(2);

PREPARE negative_amount AS 
INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', CURRENT_DATE, -100);

SELECT throws_ok(
    'negative_amount',
    '23514',
    'new row for relation "transactions" violates check constraint "transactions_amount_check"',
    'Should reject negative transaction amount'
);

PREPARE zero_amount AS 
INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', CURRENT_DATE, 0);

SELECT throws_ok(
    'zero_amount',
    '23514',
    'new row for relation "transactions" violates check constraint "transactions_amount_check"',
    'Should reject zero transaction amount'
);

SELECT * FROM finish();
ROLLBACK;

-- Test transaction account/contra_account constraint
BEGIN;
SELECT plan(1);

PREPARE same_account_transaction AS 
INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE, 100);

SELECT throws_ok(
    'same_account_transaction',
    '23514',
    'new row for relation "transactions" violates check constraint "transactions_check"',
    'Should reject transaction with same account and contra account'
);

SELECT * FROM finish();
ROLLBACK;

-- Test balance_history unique constraint
BEGIN;
SELECT plan(1);

-- Setup: Create test account
INSERT INTO accounting.accounts (id, name, type, opening_balance, current_balance)
VALUES ('00000000-0000-0000-0000-000000000001', 'Test', 'ASSET', 0, 0);

PREPARE duplicate_balance_history AS 
INSERT INTO accounting.balance_history (account_id, balance_date, balance)
VALUES ('00000000-0000-0000-0000-000000000001', CURRENT_DATE, 100),
       ('00000000-0000-0000-0000-000000000001', CURRENT_DATE, 200);

SELECT throws_ok(
    'duplicate_balance_history',
    '23505',
    'duplicate key value violates unique constraint "balance_history_account_id_balance_date_key"',
    'Should reject duplicate balance history for same account and date'
);

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- Default Value Tests
-- =============================================

BEGIN;
SELECT plan(6);

-- Test account defaults
INSERT INTO accounting.accounts (id, name, type, opening_balance, current_balance)
VALUES ('00000000-0000-0000-0000-000000000001', 'Test', 'ASSET', 100, 100);

SELECT results_eq(
    'SELECT created_at = updated_at FROM accounting.accounts WHERE id = ''00000000-0000-0000-0000-000000000001''',
    'VALUES (true)',
    'Account created_at and updated_at should be equal on creation'
);

SELECT results_eq(
    'SELECT created_by = updated_by FROM accounting.accounts WHERE id = ''00000000-0000-0000-0000-000000000001''',
    'VALUES (true)',
    'Account created_by and updated_by should be equal on creation'
);

-- Test transaction defaults
INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', CURRENT_DATE, 100);

SELECT results_eq(
    'SELECT is_void FROM accounting.transactions WHERE account_id = ''00000000-0000-0000-0000-000000000001''',
    'VALUES (false)',
    'Transaction is_void should default to false'
);

SELECT results_eq(
    'SELECT created_by FROM accounting.transactions WHERE account_id = ''00000000-0000-0000-0000-000000000001''',
    'SELECT current_user',
    'Transaction created_by should default to current user'
);

-- Test balance_history defaults
INSERT INTO accounting.balance_history (account_id, balance_date, balance)
VALUES ('00000000-0000-0000-0000-000000000001', CURRENT_DATE, 100);

SELECT results_eq(
    'SELECT created_at > (NOW() - INTERVAL ''1 minute'') FROM accounting.balance_history WHERE account_id = ''00000000-0000-0000-0000-000000000001''',
    'VALUES (true)',
    'Balance_history created_at should be recent'
);

-- Clean up
DELETE FROM accounting.balance_history WHERE account_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM accounting.transactions WHERE account_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM accounting.accounts WHERE id = '00000000-0000-0000-0000-000000000001';

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- View Content Tests
-- =============================================

BEGIN;
SELECT plan(3);

-- Setup test data
INSERT INTO accounting.accounts (id, name, type, opening_balance, current_balance)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Rent Income', 'INCOME', 0, 1000),
    ('00000000-0000-0000-0000-000000000002', 'Maintenance Expense', 'EXPENSE', 0, 500),
    ('00000000-0000-0000-0000-000000000003', 'Bank Account', 'ASSET', 1000, 1500);

INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount, description)
VALUES 
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', '2023-01-01', 1000, 'Rent payment'),
    ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', '2023-01-02', 500, 'Maintenance work');

-- Test current_balances view
SELECT results_eq(
    'SELECT COUNT(*) FROM accounting.current_balances',
    'VALUES (3::bigint)',
    'current_balances view should return all accounts'
);

-- Test transaction_history view
SELECT results_eq(
    'SELECT COUNT(*) FROM accounting.transaction_history',
    'VALUES (2::bigint)',
    'transaction_history view should return all transactions'
);

-- Test monthly_profit_loss view
SELECT results_eq(
    'SELECT net_profit_loss FROM accounting.monthly_profit_loss WHERE month = ''2023-01-01''::timestamp',
    'VALUES (500::numeric(19,4))',
    'monthly_profit_loss view should calculate correct net profit/loss'
);

-- Clean up
DELETE FROM accounting.transactions;
DELETE FROM accounting.accounts;

SELECT * FROM finish();
ROLLBACK;

-- =============================================
-- Permission Tests
-- =============================================

BEGIN;
SELECT plan(6);

-- Test accounting_app permissions
SET ROLE accounting_app;

SELECT has_table_privilege('accounting_app', 'accounting.accounts', 'SELECT', 'accounting_app should have SELECT on accounts');
SELECT has_table_privilege('accounting_app', 'accounting.accounts', 'INSERT', 'accounting_app should have INSERT on accounts');
SELECT has_table_privilege('accounting_app', 'accounting.accounts', 'UPDATE', 'accounting_app should have UPDATE on accounts');
SELECT has_table_privilege('accounting_app', 'accounting.transactions', 'DELETE', 'accounting_app should have DELETE on transactions');

-- Test accounting_readonly permissions
SET ROLE accounting_readonly;
SELECT has_table_privilege('accounting_readonly', 'accounting.accounts', 'SELECT', 'accounting_readonly should have SELECT on accounts');
SELECT lacks_table_privilege('accounting_readonly', 'accounting.accounts', 'INSERT', 'accounting_readonly should not have INSERT on accounts');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;