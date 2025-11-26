"""
Simple example: Insert data into PostgreSQL database

This script shows how to connect to the PostgreSQL database
and insert a single record.

Setup:
    1. Copy config.py.example to config.py
    2. Update config.py with your database passwords
    3. Port-forward the database
    4. Run this script

Usage:
    python 01_simple_insert.py
"""

import psycopg2
from psycopg2 import sql
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
    """
    Connect to the PostgreSQL database for the specified environment
    
    Args:
        environment: 'dev', 'preprod', or 'prod'
    
    Returns:
        psycopg2 connection object
    """
    config = DB_CONFIG[environment]
    
    try:
        conn = psycopg2.connect(
            host=config['host'],
            port=config['port'],
            database=config['database'],
            user=config['user'],
            password=config['password']
        )
        print(f"✓ Connected to {environment} database successfully!")
        return conn
    except Exception as e:
        print(f"✗ Error connecting to database: {e}")
        raise

def create_table(conn):
    """
    Create the users table if it doesn't exist
    """
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
        print("✓ Table 'users' is ready")
    except Exception as e:
        print(f"✗ Error creating table: {e}")
        raise

def insert_user(conn, name, email):
    """
    Insert a single user into the database
    
    Args:
        conn: Database connection
        name: User's name
        email: User's email
    
    Returns:
        The ID of the inserted user
    """
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO users (name, email) VALUES (%s, %s) RETURNING id",
            (name, email)
        )
        user_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        print(f"✓ Inserted user: {name} (ID: {user_id})")
        return user_id
    except psycopg2.IntegrityError:
        conn.rollback()
        print(f"✗ User with email {email} already exists")
        return None
    except Exception as e:
        conn.rollback()
        print(f"✗ Error inserting user: {e}")
        raise

def list_users(conn):
    """
    List all users in the database
    """
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, name, email, created_at FROM users ORDER BY id")
        users = cur.fetchall()
        cur.close()
        
        print(f"\n{'='*60}")
        print(f"Total users: {len(users)}")
        print(f"{'='*60}")
        
        if users:
            for user in users:
                print(f"ID: {user[0]}, Name: {user[1]}, Email: {user[2]}, Created: {user[3]}")
        else:
            print("No users found")
        
        print(f"{'='*60}\n")
        
        return users
    except Exception as e:
        print(f"✗ Error listing users: {e}")
        raise

def main():
    """
    Main function
    """
    print("="*60)
    print("Simple Insert Example")
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
    
    conn = connect_to_database(environment)
    
    try:
        create_table(conn)
        
        print("\nInserting sample users...")
        insert_user(conn, "Alice Johnson", "alice@example.com")
        insert_user(conn, "Bob Smith", "bob@example.com")
        insert_user(conn, "Charlie Brown", "charlie@example.com")
        
        print("\nCurrent users in database:")
        list_users(conn)
        
    finally:
        conn.close()
        print("✓ Database connection closed")

if __name__ == "__main__":
    main()
