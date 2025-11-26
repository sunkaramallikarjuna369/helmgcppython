"""
Bulk insert example: Insert multiple records efficiently

This script shows how to insert multiple records at once
using batch operations for better performance.

Setup:
    1. Copy config.py.example to config.py
    2. Update config.py with your database passwords
    3. Port-forward the database
    4. Run this script

Usage:
    python 02_bulk_insert.py
"""

import psycopg2
from psycopg2.extras import execute_batch
import time
import sys

try:
    from config import DB_CONFIG
except ImportError:
    print("ERROR: config.py not found!")
    print("\nPlease follow these steps:")
    print("  1. Copy the example config:")
    print("     cp config.py.example config.py")
    print("  2. Edit config.py with your database passwords from Helm values files")
    print("  3. Run this script again")
    sys.exit(1)

def connect_to_database(environment='dev'):
    """Connect to the PostgreSQL database"""
    config = DB_CONFIG[environment]
    
    try:
        conn = psycopg2.connect(
            host=config['host'],
            port=config['port'],
            database=config['database'],
            user=config['user'],
            password=config['password']
        )
        print(f"✓ Connected to {environment} database")
        return conn
    except Exception as e:
        print(f"✗ Error connecting: {e}")
        raise

def create_table(conn):
    """Create the users table if it doesn't exist"""
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        cur.close()
        print("✓ Table ready")
    except Exception as e:
        print(f"✗ Error creating table: {e}")
        raise

def bulk_insert_users(conn, users_data, batch_size=100):
    """
    Insert multiple users using batch operations
    
    Args:
        conn: Database connection
        users_data: List of tuples [(name, email), ...]
        batch_size: Number of records to insert per batch
    
    Returns:
        Number of successfully inserted records
    """
    try:
        cur = conn.cursor()
        
        query = "INSERT INTO users (name, email) VALUES (%s, %s) ON CONFLICT (email) DO NOTHING"
        
        start_time = time.time()
        execute_batch(cur, query, users_data, page_size=batch_size)
        elapsed_time = time.time() - start_time
        
        inserted_count = cur.rowcount
        conn.commit()
        cur.close()
        
        print(f"✓ Inserted {inserted_count} users in {elapsed_time:.2f} seconds")
        print(f"  ({inserted_count/elapsed_time:.0f} records/second)")
        
        return inserted_count
    except Exception as e:
        conn.rollback()
        print(f"✗ Error during bulk insert: {e}")
        raise

def generate_sample_data(count=1000):
    """
    Generate sample user data
    
    Args:
        count: Number of users to generate
    
    Returns:
        List of tuples [(name, email), ...]
    """
    users = []
    for i in range(count):
        name = f"User {i+1}"
        email = f"user{i+1}@example.com"
        users.append((name, email))
    
    return users

def count_users(conn):
    """Count total users in the database"""
    try:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM users")
        count = cur.fetchone()[0]
        cur.close()
        return count
    except Exception as e:
        print(f"✗ Error counting users: {e}")
        raise

def main():
    """Main function"""
    print("="*60)
    print("Bulk Insert Example")
    print("="*60)
    print()
    
    environment = input("Enter environment (dev/preprod/prod) [dev]: ").strip() or 'dev'
    
    if environment not in DB_CONFIG:
        print(f"Invalid environment: {environment}")
        return
    
    print(f"\nUsing {environment} environment")
    print(f"Make sure you have port-forwarded the database:")
    
    if environment == 'dev':
        print("  kubectl port-forward -n dev svc/platform-dev-postgresql 5432:5432")
    elif environment == 'preprod':
        print("  kubectl port-forward -n preprod svc/platform-preprod-postgresql 5433:5432")
    elif environment == 'prod':
        print("  kubectl port-forward -n prod svc/platform-prod-postgresql 5434:5432")
    
    print()
    input("Press Enter when port-forward is ready...")
    print()
    
    try:
        count = int(input("How many users to insert? [1000]: ").strip() or "1000")
    except ValueError:
        count = 1000
    
    conn = connect_to_database(environment)
    
    try:
        create_table(conn)
        
        existing_count = count_users(conn)
        print(f"\nExisting users: {existing_count}")
        
        print(f"\nGenerating {count} sample users...")
        users_data = generate_sample_data(count)
        print(f"✓ Generated {len(users_data)} users")
        
        print(f"\nInserting {count} users...")
        inserted = bulk_insert_users(conn, users_data, batch_size=100)
        
        final_count = count_users(conn)
        print(f"\nTotal users now: {final_count}")
        print(f"New users added: {final_count - existing_count}")
        
    finally:
        conn.close()
        print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
