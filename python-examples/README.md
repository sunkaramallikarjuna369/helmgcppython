# Python Examples for Database Access

This directory contains Python examples showing how to push data to the PostgreSQL databases from your Python programs.

---

## Prerequisites

### 1. Install Python Dependencies

```powershell
cd python-examples
pip install -r requirements.txt
```

This installs:
- `psycopg2-binary` - PostgreSQL adapter for Python
- `pandas` - Data manipulation library
- `sqlalchemy` - SQL toolkit and ORM

### 2. Configure Database Credentials

Copy the example config file and update with your credentials:

```powershell
cp config.py.example config.py
```

Then edit `config.py` with your actual database passwords from your Helm values files:
- Dev: `values-dev.yaml`
- Preprod: `values-preprod.yaml`
- Prod: `values-prod.yaml`

**Note:** `config.py` is in `.gitignore` and will not be committed to the repository.

### 3. Port-Forward Database

Before running any script, you need to port-forward the database you want to access:

**Dev environment:**
```powershell
kubectl port-forward -n dev svc/platform-dev-postgresql 5432:5432
```

**Preprod environment:**
```powershell
kubectl port-forward -n preprod svc/platform-preprod-postgresql 5433:5432
```

**Prod environment:**
```powershell
kubectl port-forward -n prod svc/platform-prod-postgresql 5434:5432
```

Keep this terminal window open while running the Python scripts.

---

## Examples

### 1. Simple Insert (`01_simple_insert.py`)

**What it does:**
- Connects to the database
- Creates the `users` table
- Inserts individual records
- Lists all users

**Usage:**
```powershell
python 01_simple_insert.py
```

**Example output:**
```
Simple Insert Example
=====================
Enter environment (dev/preprod/prod) [dev]: dev
✓ Connected to dev database successfully!
✓ Table 'users' is ready

Inserting sample users...
✓ Inserted user: Alice Johnson (ID: 1)
✓ Inserted user: Bob Smith (ID: 2)
✓ Inserted user: Charlie Brown (ID: 3)

Current users in database:
============================================================
Total users: 3
============================================================
ID: 1, Name: Alice Johnson, Email: alice@example.com
ID: 2, Name: Bob Smith, Email: bob@example.com
ID: 3, Name: Charlie Brown, Email: charlie@example.com
```

**When to use:**
- Inserting a few records
- Learning basic database operations
- Testing database connectivity

---

### 2. Bulk Insert (`02_bulk_insert.py`)

**What it does:**
- Generates sample data
- Inserts thousands of records efficiently using batch operations
- Shows performance metrics

**Usage:**
```powershell
python 02_bulk_insert.py
```

**Example output:**
```
Bulk Insert Example
===================
Enter environment (dev/preprod/prod) [dev]: dev
How many users to insert? [1000]: 5000

Existing users: 3
Generating 5000 sample users...
✓ Generated 5000 users

Inserting 5000 users...
✓ Inserted 5000 users in 2.34 seconds
  (2137 records/second)

Total users now: 5003
New users added: 5000
```

**When to use:**
- Inserting large amounts of data
- Migrating data from other systems
- Performance testing

**Performance tips:**
- Use batch_size=100 for best performance
- Larger batch sizes may cause memory issues
- Use `ON CONFLICT DO NOTHING` to skip duplicates

---

### 3. Pandas Insert (`03_pandas_insert.py`)

**What it does:**
- Loads data from CSV files
- Inserts data from pandas DataFrames
- Exports data to CSV

**Usage:**
```powershell
python 03_pandas_insert.py
```

**Example output:**
```
Pandas Insert Example
=====================
Enter environment (dev/preprod/prod) [dev]: dev

--- Option 1: Insert from DataFrame ---
Sample DataFrame:
              name                      email
0   Alice Johnson   alice.johnson@example.com
1       Bob Smith       bob.smith@example.com
...

Insert this DataFrame? (yes/no) [yes]: yes
✓ Inserted 10 rows into 'users' table

--- Option 2: Insert from CSV ---
Enter CSV file path (or press Enter to create sample):
✓ Created sample CSV file: sample_users.csv
CSV contains 10 rows
...
```

**When to use:**
- Working with CSV files
- Data analysis and manipulation
- Exporting query results

**Supported operations:**
- Read from CSV: `pd.read_csv()`
- Insert DataFrame: `df.to_sql()`
- Read from database: `pd.read_sql()`
- Export to CSV: `df.to_csv()`

---

### 4. Custom Tables (`04_custom_table.py`)

**What it does:**
- Creates custom tables (products, orders)
- Inserts sample data with relationships
- Shows summary statistics

**Usage:**
```powershell
python 04_custom_table.py
```

**Example output:**
```
Custom Table Example
====================
Enter environment (dev/preprod/prod) [dev]: dev

Creating tables...
✓ Created 'products' table
✓ Created 'orders' table

Inserting sample data...
✓ Inserted 10 products
✓ Inserted 50 orders

============================================================
Database Summary
============================================================
Total Products: 10
Total Orders: 50
Total Revenue (Delivered): $12,345.67

Top 5 Products by Orders:
  1. Laptop: 8 orders, $7,999.92 revenue
  2. Monitor: 6 orders, $2,399.94 revenue
  3. Mouse: 5 orders, $149.95 revenue
  4. Keyboard: 4 orders, $319.96 revenue
  5. Desk Chair: 3 orders, $749.97 revenue
```

**When to use:**
- Creating your own database schema
- Working with related tables
- Building real applications

**Tables created:**
- `products` - Product catalog
- `orders` - Order records with foreign keys

---

## Database Connection Configuration

All scripts import their configuration from `config.py`:

```python
from config import DB_CONFIG
```

The `config.py` file (created from `config.py.example`) contains:

```python
DB_CONFIG = {
    'dev': {
        'host': 'localhost',
        'port': 5432,
        'database': 'devdb',
        'user': 'devuser',
        'password': 'your-dev-password'  # From values-dev.yaml
    },
    'preprod': {
        'host': 'localhost',
        'port': 5433,
        'database': 'preproddb',
        'user': 'preproduser',
        'password': 'your-preprod-password'  # From values-preprod.yaml
    },
    'prod': {
        'host': 'localhost',
        'port': 5434,
        'database': 'proddb',
        'user': 'produser',
        'password': 'your-prod-password'  # From values-prod.yaml
    }
}
```

**Important:**
- Dev uses port 5432
- Preprod uses port 5433
- Prod uses port 5434
- Make sure to port-forward to the correct port!
- **Never commit config.py** - it's in .gitignore for security

---

## Common Patterns

### Pattern 1: Connect to Database

```python
import psycopg2

conn = psycopg2.connect(
    host='localhost',
    port=5432,
    database='devdb',
    user='devuser',
    password='dev_password_123'
)
```

### Pattern 2: Insert Single Record

```python
cur = conn.cursor()
cur.execute(
    "INSERT INTO users (name, email) VALUES (%s, %s) RETURNING id",
    ('John Doe', 'john@example.com')
)
user_id = cur.fetchone()[0]
conn.commit()
cur.close()
```

### Pattern 3: Bulk Insert

```python
from psycopg2.extras import execute_batch

cur = conn.cursor()
data = [
    ('User 1', 'user1@example.com'),
    ('User 2', 'user2@example.com'),
    # ... more records
]
execute_batch(
    cur,
    "INSERT INTO users (name, email) VALUES (%s, %s)",
    data,
    page_size=100
)
conn.commit()
cur.close()
```

### Pattern 4: Query Data

```python
cur = conn.cursor()
cur.execute("SELECT id, name, email FROM users WHERE id = %s", (1,))
user = cur.fetchone()
cur.close()
```

### Pattern 5: Using Pandas

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://user:pass@localhost:5432/dbname')

# Insert DataFrame
df.to_sql('users', engine, if_exists='append', index=False)

# Read from database
df = pd.read_sql('SELECT * FROM users', engine)
```

---

## Error Handling

### Connection Errors

**Error:** `could not connect to server: Connection refused`

**Solution:**
- Make sure kubectl port-forward is running
- Check the port number matches your environment
- Verify the database pod is running: `kubectl get pods -n dev`

### Authentication Errors

**Error:** `FATAL: password authentication failed`

**Solution:**
- Check the password in DB_CONFIG matches your values file
- Verify you're connecting to the correct environment

### Duplicate Key Errors

**Error:** `duplicate key value violates unique constraint`

**Solution:**
- Use `ON CONFLICT DO NOTHING` to skip duplicates
- Use `ON CONFLICT (email) DO UPDATE` to update existing records

```python
cur.execute("""
    INSERT INTO users (name, email) 
    VALUES (%s, %s)
    ON CONFLICT (email) DO NOTHING
""", (name, email))
```

---

## Best Practices

### 1. Always Use Parameterized Queries

**Bad (SQL injection risk):**
```python
cur.execute(f"INSERT INTO users (name) VALUES ('{name}')")
```

**Good:**
```python
cur.execute("INSERT INTO users (name) VALUES (%s)", (name,))
```

### 2. Always Close Connections

```python
conn = psycopg2.connect(...)
try:
    # Do database operations
    pass
finally:
    conn.close()
```

### 3. Use Transactions

```python
try:
    cur.execute("INSERT INTO users ...")
    cur.execute("INSERT INTO orders ...")
    conn.commit()
except Exception as e:
    conn.rollback()
    raise
```

### 4. Use Batch Operations for Bulk Inserts

```python
from psycopg2.extras import execute_batch

# Much faster than individual inserts
execute_batch(cur, query, data, page_size=100)
```

### 5. Handle Errors Gracefully

```python
try:
    cur.execute(...)
except psycopg2.IntegrityError:
    conn.rollback()
    print("Duplicate record")
except Exception as e:
    conn.rollback()
    print(f"Error: {e}")
    raise
```

---

## Troubleshooting

### Issue: Port-Forward Keeps Disconnecting

**Solution:**
- Port-forward can timeout after inactivity
- Restart the port-forward command
- Use a longer timeout: `kubectl port-forward --pod-running-timeout=24h ...`

### Issue: Slow Insert Performance

**Solutions:**
1. Use batch operations (`execute_batch`)
2. Increase batch size (try 100, 500, 1000)
3. Disable autocommit and commit once at the end
4. Consider using COPY for very large datasets

### Issue: Out of Memory

**Solutions:**
1. Reduce batch size
2. Process data in chunks
3. Use generators instead of loading all data at once

```python
def data_generator():
    for i in range(1000000):
        yield (f"User {i}", f"user{i}@example.com")

for batch in chunks(data_generator(), 1000):
    execute_batch(cur, query, batch)
```

---

## Next Steps

1. **Customize for Your Use Case**
   - Modify the examples to match your data structure
   - Create your own tables and relationships
   - Add validation and error handling

2. **Integrate with Your Application**
   - Use these patterns in your FastAPI/Flask apps
   - Create data migration scripts
   - Build ETL pipelines

3. **Learn More**
   - psycopg2 documentation: https://www.psycopg.org/docs/
   - pandas documentation: https://pandas.pydata.org/docs/
   - SQLAlchemy documentation: https://docs.sqlalchemy.org/

---

## Summary

| Script | Purpose | Performance | Use Case |
|--------|---------|-------------|----------|
| 01_simple_insert.py | Single record inserts | ~10 records/sec | Learning, testing |
| 02_bulk_insert.py | Batch inserts | ~2000 records/sec | Large datasets |
| 03_pandas_insert.py | CSV and DataFrame | ~1000 records/sec | Data analysis |
| 04_custom_table.py | Custom schema | Varies | Real applications |

**Remember:** Always port-forward the database before running scripts!
