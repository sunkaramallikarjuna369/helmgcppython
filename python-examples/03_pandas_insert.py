"""
Pandas example: Insert data from CSV or DataFrame

This script shows how to use pandas to load data from CSV files
or DataFrames and insert into PostgreSQL.

Setup:
    1. Copy config.py.example to config.py
    2. Update config.py with your database passwords
    3. Port-forward the database
    4. Run this script

Usage:
    python 03_pandas_insert.py
"""

import pandas as pd
from sqlalchemy import create_engine
import os
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

def create_engine_for_env(environment='dev'):
    """
    Create SQLAlchemy engine for the specified environment
    
    Args:
        environment: 'dev', 'preprod', or 'prod'
    
    Returns:
        SQLAlchemy engine
    """
    config = DB_CONFIG[environment]
    
    connection_string = (
        f"postgresql://{config['user']}:{config['password']}"
        f"@{config['host']}:{config['port']}/{config['database']}"
    )
    
    try:
        engine = create_engine(connection_string)
        with engine.connect() as conn:
            pass
        print(f"✓ Connected to {environment} database")
        return engine
    except Exception as e:
        print(f"✗ Error connecting: {e}")
        raise

def create_sample_dataframe():
    """
    Create a sample DataFrame with user data
    
    Returns:
        pandas DataFrame
    """
    data = {
        'name': [
            'Alice Johnson',
            'Bob Smith',
            'Charlie Brown',
            'Diana Prince',
            'Eve Adams',
            'Frank Miller',
            'Grace Lee',
            'Henry Ford',
            'Iris West',
            'Jack Ryan'
        ],
        'email': [
            'alice.johnson@example.com',
            'bob.smith@example.com',
            'charlie.brown@example.com',
            'diana.prince@example.com',
            'eve.adams@example.com',
            'frank.miller@example.com',
            'grace.lee@example.com',
            'henry.ford@example.com',
            'iris.west@example.com',
            'jack.ryan@example.com'
        ]
    }
    
    df = pd.DataFrame(data)
    return df

def insert_dataframe(engine, df, table_name='users', if_exists='append'):
    """
    Insert DataFrame into PostgreSQL table
    
    Args:
        engine: SQLAlchemy engine
        df: pandas DataFrame
        table_name: Name of the table
        if_exists: 'fail', 'replace', or 'append'
    
    Returns:
        Number of rows inserted
    """
    try:
        rows_inserted = df.to_sql(
            table_name,
            engine,
            if_exists=if_exists,
            index=False,
            method='multi'
        )
        
        print(f"✓ Inserted {len(df)} rows into '{table_name}' table")
        return len(df)
    except Exception as e:
        print(f"✗ Error inserting data: {e}")
        raise

def read_from_database(engine, query):
    """
    Read data from database into DataFrame
    
    Args:
        engine: SQLAlchemy engine
        query: SQL query string
    
    Returns:
        pandas DataFrame
    """
    try:
        df = pd.read_sql(query, engine)
        print(f"✓ Read {len(df)} rows from database")
        return df
    except Exception as e:
        print(f"✗ Error reading data: {e}")
        raise

def create_sample_csv(filename='sample_users.csv'):
    """
    Create a sample CSV file with user data
    
    Args:
        filename: Name of the CSV file to create
    """
    df = create_sample_dataframe()
    df.to_csv(filename, index=False)
    print(f"✓ Created sample CSV file: {filename}")
    return filename

def main():
    """Main function"""
    print("="*60)
    print("Pandas Insert Example")
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
    
    engine = create_engine_for_env(environment)
    
    try:
        print("\n--- Option 1: Insert from DataFrame ---")
        df = create_sample_dataframe()
        print(f"\nSample DataFrame:")
        print(df)
        print()
        
        choice = input("Insert this DataFrame? (yes/no) [yes]: ").strip() or 'yes'
        if choice.lower() == 'yes':
            insert_dataframe(engine, df, table_name='users', if_exists='append')
        
        print("\n--- Option 2: Insert from CSV ---")
        csv_file = input("Enter CSV file path (or press Enter to create sample): ").strip()
        
        if not csv_file:
            csv_file = create_sample_csv()
        
        if os.path.exists(csv_file):
            print(f"\nReading CSV file: {csv_file}")
            df_csv = pd.read_csv(csv_file)
            print(f"CSV contains {len(df_csv)} rows")
            print(df_csv.head())
            print()
            
            choice = input("Insert this CSV data? (yes/no) [yes]: ").strip() or 'yes'
            if choice.lower() == 'yes':
                insert_dataframe(engine, df_csv, table_name='users', if_exists='append')
        else:
            print(f"CSV file not found: {csv_file}")
        
        print("\n--- Current Users in Database ---")
        query = "SELECT id, name, email, created_at FROM users ORDER BY id"
        df_users = read_from_database(engine, query)
        print(df_users)
        
        print("\n--- Export to CSV ---")
        export_file = input("Export to CSV? Enter filename (or press Enter to skip): ").strip()
        if export_file:
            df_users.to_csv(export_file, index=False)
            print(f"✓ Exported to {export_file}")
        
    finally:
        engine.dispose()
        print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
