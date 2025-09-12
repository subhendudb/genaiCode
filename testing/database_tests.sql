-- =============================================
-- Database Schema Validation Tests (pgTAP Alternative)
-- =============================================

-- Test results tracking
CREATE TEMP TABLE test_results (
    test_name TEXT,
    test_result TEXT,
    error_message TEXT
);

-- Helper function to record test results
CREATE OR REPLACE FUNCTION record_test(test_name TEXT, passed BOOLEAN, error_msg TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results (test_name, test_result, error_message)
    VALUES (test_name, CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END, error_msg);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Schema Existence Tests
-- =============================================

-- Test schema existence
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'accounting') THEN
        PERFORM record_test('Schema accounting exists', true);
    ELSE
        PERFORM record_test('Schema accounting exists', false, 'Schema accounting not found');
    END IF;
END $$;

-- Test role existence
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'accounting_admin') THEN
        PERFORM record_test('Role accounting_admin exists', true);
    ELSE
        PERFORM record_test('Role accounting_admin exists', false, 'Role accounting_admin not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'accounting_app') THEN
        PERFORM record_test('Role accounting_app exists', true);
    ELSE
        PERFORM record_test('Role accounting_app exists', false, 'Role accounting_app not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'accounting_readonly') THEN
        PERFORM record_test('Role accounting_readonly exists', true);
    ELSE
        PERFORM record_test('Role accounting_readonly exists', false, 'Role accounting_readonly not found');
    END IF;
END $$;

-- =============================================
-- Table Structure Tests
-- =============================================

-- Test accounts table structure
DO $$
DECLARE
    table_exists BOOLEAN;
    column_count INTEGER;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'accounting' AND table_name = 'accounts'
    ) INTO table_exists;
    
    IF table_exists THEN
        PERFORM record_test('Accounts table exists', true);
        
        -- Check column count
        SELECT COUNT(*) INTO column_count
        FROM information_schema.columns 
        WHERE table_schema = 'accounting' AND table_name = 'accounts';
        
        IF column_count >= 10 THEN
            PERFORM record_test('Accounts table has correct column count', true);
        ELSE
            PERFORM record_test('Accounts table has correct column count', false, 'Expected at least 10 columns, found ' || column_count);
        END IF;
        
        -- Check specific columns
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'accounts' AND column_name = 'id' AND is_nullable = 'NO') THEN
            PERFORM record_test('Accounts.id is NOT NULL', true);
        ELSE
            PERFORM record_test('Accounts.id is NOT NULL', false, 'id column is nullable or missing');
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'accounts' AND column_name = 'name' AND is_nullable = 'NO') THEN
            PERFORM record_test('Accounts.name is NOT NULL', true);
        ELSE
            PERFORM record_test('Accounts.name is NOT NULL', false, 'name column is nullable or missing');
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'accounts' AND column_name = 'type' AND is_nullable = 'NO') THEN
            PERFORM record_test('Accounts.type is NOT NULL', true);
        ELSE
            PERFORM record_test('Accounts.type is NOT NULL', false, 'type column is nullable or missing');
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'accounts' AND column_name = 'opening_balance' AND data_type = 'numeric') THEN
            PERFORM record_test('Accounts.opening_balance is numeric', true);
        ELSE
            PERFORM record_test('Accounts.opening_balance is numeric', false, 'opening_balance column is not numeric');
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'accounts' AND column_name = 'current_balance' AND data_type = 'numeric') THEN
            PERFORM record_test('Accounts.current_balance is numeric', true);
        ELSE
            PERFORM record_test('Accounts.current_balance is numeric', false, 'current_balance column is not numeric');
        END IF;
        
    ELSE
        PERFORM record_test('Accounts table exists', false, 'Accounts table not found');
    END IF;
END $$;

-- Test transactions table structure
DO $$
DECLARE
    table_exists BOOLEAN;
    column_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'accounting' AND table_name = 'transactions'
    ) INTO table_exists;
    
    IF table_exists THEN
        PERFORM record_test('Transactions table exists', true);
        
        SELECT COUNT(*) INTO column_count
        FROM information_schema.columns 
        WHERE table_schema = 'accounting' AND table_name = 'transactions';
        
        IF column_count >= 8 THEN
            PERFORM record_test('Transactions table has correct column count', true);
        ELSE
            PERFORM record_test('Transactions table has correct column count', false, 'Expected at least 8 columns, found ' || column_count);
        END IF;
        
        -- Check specific columns
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'transactions' AND column_name = 'amount' AND data_type = 'numeric') THEN
            PERFORM record_test('Transactions.amount is numeric', true);
        ELSE
            PERFORM record_test('Transactions.amount is numeric', false, 'amount column is not numeric');
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounting' AND table_name = 'transactions' AND column_name = 'is_void' AND data_type = 'boolean') THEN
            PERFORM record_test('Transactions.is_void is boolean', true);
        ELSE
            PERFORM record_test('Transactions.is_void is boolean', false, 'is_void column is not boolean');
        END IF;
        
    ELSE
        PERFORM record_test('Transactions table exists', false, 'Transactions table not found');
    END IF;
END $$;

-- Test other tables
DO $$
BEGIN
    -- Balance history table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'accounting' AND table_name = 'balance_history') THEN
        PERFORM record_test('Balance_history table exists', true);
    ELSE
        PERFORM record_test('Balance_history table exists', false, 'Balance_history table not found');
    END IF;
    
    -- Users table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'accounting' AND table_name = 'users') THEN
        PERFORM record_test('Users table exists', true);
    ELSE
        PERFORM record_test('Users table exists', false, 'Users table not found');
    END IF;
    
    -- Audit log table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'accounting' AND table_name = 'audit_log') THEN
        PERFORM record_test('Audit_log table exists', true);
    ELSE
        PERFORM record_test('Audit_log table exists', false, 'Audit_log table not found');
    END IF;
END $$;

-- =============================================
-- Index Tests
-- =============================================

DO $$
DECLARE
    index_count INTEGER;
BEGIN
    -- Check accounts indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE schemaname = 'accounting' AND tablename = 'accounts';
    
    IF index_count >= 3 THEN
        PERFORM record_test('Accounts table has indexes', true);
    ELSE
        PERFORM record_test('Accounts table has indexes', false, 'Expected at least 3 indexes, found ' || index_count);
    END IF;
    
    -- Check transactions indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE schemaname = 'accounting' AND tablename = 'transactions';
    
    IF index_count >= 4 THEN
        PERFORM record_test('Transactions table has indexes', true);
    ELSE
        PERFORM record_test('Transactions table has indexes', false, 'Expected at least 4 indexes, found ' || index_count);
    END IF;
END $$;

-- =============================================
-- View Tests
-- =============================================

DO $$
BEGIN
    -- Check views
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'accounting' AND table_name = 'current_balances') THEN
        PERFORM record_test('current_balances view exists', true);
    ELSE
        PERFORM record_test('current_balances view exists', false, 'current_balances view not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'accounting' AND table_name = 'transaction_history') THEN
        PERFORM record_test('transaction_history view exists', true);
    ELSE
        PERFORM record_test('transaction_history view exists', false, 'transaction_history view not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'accounting' AND table_name = 'monthly_profit_loss') THEN
        PERFORM record_test('monthly_profit_loss view exists', true);
    ELSE
        PERFORM record_test('monthly_profit_loss view exists', false, 'monthly_profit_loss view not found');
    END IF;
END $$;

-- =============================================
-- Data Integrity Tests
-- =============================================

-- Test account type constraint
DO $$
BEGIN
    BEGIN
        INSERT INTO accounting.accounts (name, type, opening_balance, current_balance) 
        VALUES ('Test Invalid', 'INVALID_TYPE', 0, 0);
        PERFORM record_test('Account type constraint works', false, 'Should have rejected invalid account type');
        ROLLBACK;
    EXCEPTION
        WHEN check_violation THEN
            PERFORM record_test('Account type constraint works', true);
            ROLLBACK;
        WHEN OTHERS THEN
            PERFORM record_test('Account type constraint works', false, 'Unexpected error: ' || SQLERRM);
            ROLLBACK;
    END;
END $$;

-- Test transaction amount constraint
DO $$
BEGIN
    BEGIN
        INSERT INTO accounting.transactions (account_id, contra_account_id, transaction_date, amount)
        VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', CURRENT_DATE, -100);
        PERFORM record_test('Transaction amount constraint works', false, 'Should have rejected negative amount');
        ROLLBACK;
    EXCEPTION
        WHEN check_violation THEN
            PERFORM record_test('Transaction amount constraint works', true);
            ROLLBACK;
        WHEN OTHERS THEN
            PERFORM record_test('Transaction amount constraint works', false, 'Unexpected error: ' || SQLERRM);
            ROLLBACK;
    END;
END $$;

-- =============================================
-- Sample Data Tests
-- =============================================

DO $$
DECLARE
    account_count INTEGER;
    transaction_count INTEGER;
BEGIN
    -- Check if sample data exists
    SELECT COUNT(*) INTO account_count FROM accounting.accounts;
    IF account_count > 0 THEN
        PERFORM record_test('Sample accounts data exists', true);
    ELSE
        PERFORM record_test('Sample accounts data exists', false, 'No accounts found');
    END IF;
    
    SELECT COUNT(*) INTO transaction_count FROM accounting.transactions;
    IF transaction_count >= 0 THEN
        PERFORM record_test('Transactions table accessible', true);
    ELSE
        PERFORM record_test('Transactions table accessible', false, 'Cannot access transactions table');
    END IF;
END $$;

-- =============================================
-- Display Test Results
-- =============================================

SELECT 
    test_name,
    test_result,
    error_message,
    CASE 
        WHEN test_result = 'PASS' THEN '✅'
        ELSE '❌'
    END as status
FROM test_results 
ORDER BY test_name;

-- Summary
SELECT 
    COUNT(*) as total_tests,
    COUNT(*) FILTER (WHERE test_result = 'PASS') as passed_tests,
    COUNT(*) FILTER (WHERE test_result = 'FAIL') as failed_tests,
    ROUND(COUNT(*) FILTER (WHERE test_result = 'PASS') * 100.0 / COUNT(*), 2) as success_rate
FROM test_results;
