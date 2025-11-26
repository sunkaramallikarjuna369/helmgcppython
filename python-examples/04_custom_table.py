"""
Custom table example: Create and populate your own tables

This script shows how to create custom tables and insert data
for your specific use case.

Setup:
    1. Copy config.py.example to config.py
    2. Update config.py with your database passwords
    3. Port-forward the database
    4. Run this script

Usage:
    python 04_custom_table.py
"""

import psycopg2
from psycopg2.extras import execute_batch
from datetime import datetime, timedelta
import random
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

def create_products_table(conn):
    """
    Create a products table
    """
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(200) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2) NOT NULL,
                stock_quantity INTEGER DEFAULT 0,
                category VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        cur.close()
        print("✓ Created 'products' table")
    except Exception as e:
        print(f"✗ Error creating table: {e}")
        raise

def create_orders_table(conn):
    """
    Create an orders table
    """
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                user_id INTEGER,
                product_id INTEGER,
                quantity INTEGER NOT NULL,
                total_price DECIMAL(10, 2) NOT NULL,
                status VARCHAR(50) DEFAULT 'pending',
                order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
            )
        """)
        conn.commit()
        cur.close()
        print("✓ Created 'orders' table")
    except Exception as e:
        print(f"✗ Error creating table: {e}")
        raise

def insert_sample_products(conn):
    """
    Insert sample products
    """
    products = [
        ('Laptop', 'High-performance laptop', 999.99, 50, 'Electronics'),
        ('Mouse', 'Wireless mouse', 29.99, 200, 'Electronics'),
        ('Keyboard', 'Mechanical keyboard', 79.99, 150, 'Electronics'),
        ('Monitor', '27-inch 4K monitor', 399.99, 75, 'Electronics'),
        ('Desk Chair', 'Ergonomic office chair', 249.99, 30, 'Furniture'),
        ('Desk', 'Standing desk', 499.99, 20, 'Furniture'),
        ('Notebook', 'Spiral notebook', 4.99, 500, 'Stationery'),
        ('Pen Set', 'Set of 10 pens', 9.99, 300, 'Stationery'),
        ('Water Bottle', 'Insulated water bottle', 24.99, 100, 'Accessories'),
        ('Backpack', 'Laptop backpack', 59.99, 80, 'Accessories')
    ]
    
    try:
        cur = conn.cursor()
        query = """
            INSERT INTO products (name, description, price, stock_quantity, category)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING
        """
        execute_batch(cur, query, products)
        conn.commit()
        cur.close()
        print(f"✓ Inserted {len(products)} products")
    except Exception as e:
        conn.rollback()
        print(f"✗ Error inserting products: {e}")
        raise

def insert_sample_orders(conn, num_orders=20):
    """
    Insert sample orders
    """
    try:
        cur = conn.cursor()
        
        cur.execute("SELECT id FROM users LIMIT 10")
        user_ids = [row[0] for row in cur.fetchall()]
        
        if not user_ids:
            print("⚠ No users found. Please run 01_simple_insert.py first")
            return
        
        cur.execute("SELECT id, price FROM products")
        products = cur.fetchall()
        
        if not products:
            print("⚠ No products found")
            return
        
        orders = []
        for _ in range(num_orders):
            user_id = random.choice(user_ids)
            product_id, price = random.choice(products)
            quantity = random.randint(1, 5)
            total_price = float(price) * quantity
            status = random.choice(['pending', 'processing', 'shipped', 'delivered'])
            
            orders.append((user_id, product_id, quantity, total_price, status))
        
        query = """
            INSERT INTO orders (user_id, product_id, quantity, total_price, status)
            VALUES (%s, %s, %s, %s, %s)
        """
        execute_batch(cur, query, orders)
        conn.commit()
        cur.close()
        print(f"✓ Inserted {len(orders)} orders")
    except Exception as e:
        conn.rollback()
        print(f"✗ Error inserting orders: {e}")
        raise

def display_summary(conn):
    """
    Display summary statistics
    """
    try:
        cur = conn.cursor()
        
        cur.execute("SELECT COUNT(*) FROM products")
        product_count = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM orders")
        order_count = cur.fetchone()[0]
        
        cur.execute("SELECT SUM(total_price) FROM orders WHERE status = 'delivered'")
        total_revenue = cur.fetchone()[0] or 0
        
        cur.execute("""
            SELECT p.name, COUNT(o.id) as order_count, SUM(o.total_price) as revenue
            FROM products p
            LEFT JOIN orders o ON p.id = o.product_id
            GROUP BY p.id, p.name
            ORDER BY order_count DESC
            LIMIT 5
        """)
        top_products = cur.fetchall()
        
        cur.close()
        
        print("\n" + "="*60)
        print("Database Summary")
        print("="*60)
        print(f"Total Products: {product_count}")
        print(f"Total Orders: {order_count}")
        print(f"Total Revenue (Delivered): ${total_revenue:.2f}")
        print("\nTop 5 Products by Orders:")
        for i, (name, count, revenue) in enumerate(top_products, 1):
            revenue = revenue or 0
            print(f"  {i}. {name}: {count} orders, ${revenue:.2f} revenue")
        print("="*60)
        
    except Exception as e:
        print(f"✗ Error displaying summary: {e}")
        raise

def main():
    """Main function"""
    print("="*60)
    print("Custom Table Example")
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
        print("Creating tables...")
        create_products_table(conn)
        create_orders_table(conn)
        
        print("\nInserting sample data...")
        insert_sample_products(conn)
        insert_sample_orders(conn, num_orders=50)
        
        display_summary(conn)
        
    finally:
        conn.close()
        print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
