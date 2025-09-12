#!/usr/bin/env python3
"""
Simple test script for the Apartment Accounting System backend
"""
import requests
import json
import sys
from datetime import datetime, date

# Configuration
BASE_URL = "http://localhost:8000/api"
TEST_USERNAME = "admin"
TEST_PASSWORD = "admin123"

def test_health_check():
    """Test health check endpoint"""
    print("Testing health check...")
    try:
        response = requests.get("http://localhost:8000/health")
        if response.status_code == 200:
            print("✓ Health check passed")
            return True
        else:
            print(f"✗ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Health check error: {str(e)}")
        return False

def test_login():
    """Test login endpoint"""
    print("Testing login...")
    try:
        response = requests.post(
            f"{BASE_URL}/login",
            json={"username": TEST_USERNAME, "password": TEST_PASSWORD}
        )
        if response.status_code == 200:
            data = response.json()
            if 'token' in data:
                print("✓ Login successful")
                return data['token']
            else:
                print("✗ Login response missing token")
                return None
        else:
            print(f"✗ Login failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"✗ Login error: {str(e)}")
        return None

def test_accounts(token):
    """Test account endpoints"""
    print("Testing account operations...")
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        # Test list accounts
        response = requests.get(f"{BASE_URL}/accounts", headers=headers)
        if response.status_code == 200:
            accounts = response.json()
            print(f"✓ List accounts successful - found {len(accounts)} accounts")
        else:
            print(f"✗ List accounts failed: {response.status_code}")
            return False
        
        # Test create account
        new_account = {
            "name": "Test Account",
            "type": "INCOME",
            "description": "Test account for API testing",
            "opening_balance": 1000.00
        }
        
        response = requests.post(
            f"{BASE_URL}/accounts",
            headers=headers,
            json=new_account
        )
        
        if response.status_code == 201:
            account_data = response.json()
            account_id = account_data['id']
            print(f"✓ Create account successful - ID: {account_id}")
            
            # Test get account
            response = requests.get(f"{BASE_URL}/accounts/{account_id}", headers=headers)
            if response.status_code == 200:
                print("✓ Get account successful")
            else:
                print(f"✗ Get account failed: {response.status_code}")
            
            # Test update account
            update_data = {"name": "Updated Test Account"}
            response = requests.put(
                f"{BASE_URL}/accounts/{account_id}",
                headers=headers,
                json=update_data
            )
            if response.status_code == 200:
                print("✓ Update account successful")
            else:
                print(f"✗ Update account failed: {response.status_code}")
            
            return account_id
        else:
            print(f"✗ Create account failed: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"✗ Account operations error: {str(e)}")
        return None

def test_transactions(token, account_id):
    """Test transaction endpoints"""
    print("Testing transaction operations...")
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        # Get a contra account (first account that's not the test account)
        response = requests.get(f"{BASE_URL}/accounts", headers=headers)
        if response.status_code != 200:
            print("✗ Cannot get accounts for transaction test")
            return False
        
        accounts = response.json()
        contra_account_id = None
        for account in accounts:
            if account['id'] != account_id:
                contra_account_id = account['id']
                break
        
        if not contra_account_id:
            print("✗ No contra account found for transaction test")
            return False
        
        # Test create transaction
        new_transaction = {
            "account_id": account_id,
            "contra_account_id": contra_account_id,
            "transaction_date": date.today().isoformat(),
            "amount": 500.00,
            "description": "Test transaction",
            "reference_number": "TEST-001"
        }
        
        response = requests.post(
            f"{BASE_URL}/transactions",
            headers=headers,
            json=new_transaction
        )
        
        if response.status_code == 201:
            transaction_data = response.json()
            transaction_id = transaction_data['transaction']['id']
            print(f"✓ Create transaction successful - ID: {transaction_id}")
            
            # Test get transaction
            response = requests.get(f"{BASE_URL}/transactions/{transaction_id}", headers=headers)
            if response.status_code == 200:
                print("✓ Get transaction successful")
            else:
                print(f"✗ Get transaction failed: {response.status_code}")
            
            # Test list transactions
            response = requests.get(f"{BASE_URL}/transactions", headers=headers)
            if response.status_code == 200:
                transactions = response.json()
                print(f"✓ List transactions successful - found {len(transactions)} transactions")
            else:
                print(f"✗ List transactions failed: {response.status_code}")
            
            # Test void transaction
            response = requests.post(f"{BASE_URL}/transactions/{transaction_id}/void", headers=headers)
            if response.status_code == 200:
                print("✓ Void transaction successful")
            else:
                print(f"✗ Void transaction failed: {response.status_code}")
            
            return transaction_id
        else:
            print(f"✗ Create transaction failed: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"✗ Transaction operations error: {str(e)}")
        return None

def test_reports(token):
    """Test report endpoints"""
    print("Testing report generation...")
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        # Test balance report
        response = requests.get(f"{BASE_URL}/reports/balance", headers=headers)
        if response.status_code == 200:
            print("✓ Balance report successful")
        else:
            print(f"✗ Balance report failed: {response.status_code}")
        
        # Test profit/loss report
        start_date = date.today().replace(day=1).isoformat()
        end_date = date.today().isoformat()
        
        response = requests.get(
            f"{BASE_URL}/reports/profit-loss?start_date={start_date}&end_date={end_date}",
            headers=headers
        )
        if response.status_code == 200:
            print("✓ Profit/loss report successful")
        else:
            print(f"✗ Profit/loss report failed: {response.status_code}")
        
        # Test cash flow report
        response = requests.get(
            f"{BASE_URL}/reports/cash-flow?start_date={start_date}&end_date={end_date}",
            headers=headers
        )
        if response.status_code == 200:
            print("✓ Cash flow report successful")
        else:
            print(f"✗ Cash flow report failed: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"✗ Report operations error: {str(e)}")
        return False

def test_error_handling(token):
    """Test error handling and edge cases"""
    print("Testing error handling...")
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        # Test invalid account type
        invalid_account = {
            "name": "Invalid Account",
            "type": "INVALID_TYPE",
            "description": "This should fail",
            "opening_balance": 1000.00
        }
        
        response = requests.post(f"{BASE_URL}/accounts", headers=headers, json=invalid_account)
        if response.status_code == 400:
            print("✓ Invalid account type properly rejected")
        else:
            print(f"✗ Invalid account type not rejected: {response.status_code}")
        
        # Test get non-existent account
        response = requests.get(f"{BASE_URL}/accounts/999999", headers=headers)
        if response.status_code == 404:
            print("✓ Non-existent account properly returns 404")
        else:
            print(f"✗ Non-existent account not handled properly: {response.status_code}")
        
        # Test transaction with invalid account
        invalid_transaction = {
            "account_id": 999999,
            "contra_account_id": 999998,
            "transaction_date": date.today().isoformat(),
            "amount": 100.00,
            "description": "Invalid transaction"
        }
        
        response = requests.post(f"{BASE_URL}/transactions", headers=headers, json=invalid_transaction)
        if response.status_code == 404:
            print("✓ Invalid transaction accounts properly rejected")
        else:
            print(f"✗ Invalid transaction accounts not rejected: {response.status_code}")
        
        # Test void non-existent transaction
        response = requests.post(f"{BASE_URL}/transactions/999999/void", headers=headers)
        if response.status_code == 404:
            print("✓ Void non-existent transaction properly returns 404")
        else:
            print(f"✗ Void non-existent transaction not handled properly: {response.status_code}")
        
        # Test 404 route
        response = requests.get(f"{BASE_URL}/doesnotexist", headers=headers)
        if response.status_code == 404:
            print("✓ Non-existent route properly returns 404")
        else:
            print(f"✗ Non-existent route not handled properly: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"✗ Error handling test error: {str(e)}")
        return False

def test_authentication():
    """Test authentication requirements"""
    print("Testing authentication requirements...")
    
    try:
        # Test access without token
        response = requests.get(f"{BASE_URL}/accounts")
        if response.status_code in [401, 403]:
            print("✓ Unauthorized access properly rejected")
        else:
            print(f"✗ Unauthorized access not rejected: {response.status_code}")
        
        # Test access with invalid token
        headers = {"Authorization": "Bearer invalid_token"}
        response = requests.get(f"{BASE_URL}/accounts", headers=headers)
        if response.status_code in [401, 403]:
            print("✓ Invalid token properly rejected")
        else:
            print(f"✗ Invalid token not rejected: {response.status_code}")
        
        # Test login with wrong credentials
        response = requests.post(
            f"{BASE_URL}/login",
            json={"username": "wrong_user", "password": "wrong_password"}
        )
        if response.status_code in [401, 403]:
            print("✓ Wrong credentials properly rejected")
        else:
            print(f"✗ Wrong credentials not rejected: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"✗ Authentication test error: {str(e)}")
        return False

def main():
    """Main test function"""
    print("=" * 50)
    print("Apartment Accounting System - Backend Test")
    print("=" * 50)
    
    # Test health check
    if not test_health_check():
        print("\n❌ Health check failed. Make sure the backend is running.")
        sys.exit(1)
    
    # Test authentication
    if not test_authentication():
        print("\n❌ Authentication tests failed.")
        sys.exit(1)
    
    # Test login
    token = test_login()
    if not token:
        print("\n❌ Login failed. Cannot continue with tests.")
        sys.exit(1)
    
    # Test accounts
    account_id = test_accounts(token)
    if not account_id:
        print("\n❌ Account operations failed.")
        sys.exit(1)
    
    # Test transactions
    transaction_id = test_transactions(token, account_id)
    if not transaction_id:
        print("\n❌ Transaction operations failed.")
        sys.exit(1)
    
    # Test reports
    if not test_reports(token):
        print("\n❌ Report operations failed.")
        sys.exit(1)
    
    # Test error handling
    if not test_error_handling(token):
        print("\n❌ Error handling tests failed.")
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("✅ All tests passed successfully!")
    print("=" * 50)

if __name__ == "__main__":
    main()
