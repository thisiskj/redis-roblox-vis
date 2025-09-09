"""
Large Scale Redis Data Generator - Bicycle Store
Creates 1000 keys in the sample_bicycle namespace for performance testing.
"""

import redis
import json
import random
from datetime import datetime, timedelta

# Redis connection - UPDATE THESE VALUES FOR YOUR REDIS INSTANCE
r = redis.Redis(
    host='your-redis-host.com',
    port=6379,
    decode_responses=True,
    username="your-username",
    password="your-password",
)

# Configuration
KEYSPACE = "sample_bicycle"
TOTAL_KEYS = 1000

# TTL ranges for varied visualization
TTL_RANGES = [
    -1,          # No expiry
    86400 * 3,   # 3 days
    3600 * 12,   # 12 hours
    1800,        # 30 minutes
    120,         # 2 minutes
    45           # 45 seconds
]

# Sample data for realistic bicycle store
BIKE_BRANDS = [
    "Trek", "Giant", "Specialized", "Cannondale", "Scott", "Merida", "Cube",
    "Bianchi", "Pinarello", "Cervelo", "Orbea", "Canyon", "Focus", "Felt",
    "BMC", "Ridley", "Wilier", "Colnago", "DeRosa", "Look"
]

BIKE_TYPES = [
    "road", "mountain", "hybrid", "electric", "gravel", "cyclocross",
    "bmx", "touring", "folding", "kids", "tandem", "cargo"
]

BIKE_COLORS = [
    "black", "white", "red", "blue", "green", "yellow", "orange",
    "purple", "pink", "gray", "silver", "gold", "carbon"
]

BIKE_SIZES = ["XS", "S", "M", "L", "XL", "XXL"]

CUSTOMER_NAMES = [
    "John Smith", "Emma Johnson", "Michael Brown", "Sarah Davis", "David Wilson",
    "Lisa Anderson", "James Taylor", "Jennifer White", "Robert Miller", "Maria Garcia",
    "William Jones", "Patricia Martinez", "Richard Rodriguez", "Linda Lewis", "Charles Lee",
    "Barbara Walker", "Joseph Hall", "Susan Allen", "Thomas Young", "Nancy King"
]

STORE_LOCATIONS = [
    "Downtown", "Northside", "Southpark", "Westfield", "Eastgate",
    "Mall Plaza", "City Center", "Riverside", "Hillcrest", "Lakewood"
]

def create_bike_inventory():
    """Create bicycle inventory data"""
    print("Creating bicycle inventory...")
    
    for i in range(400):  # 400 bikes in inventory
        bike_id = f"bike_{i+1:04d}"
        
        bike_key = f"{KEYSPACE}:inventory:bikes:{bike_id}"
        bike_data = {
            "brand": random.choice(BIKE_BRANDS),
            "model": f"Model {random.choice(['X1', 'Pro', 'Elite', 'Sport', 'Classic', 'Advanced'])}",
            "type": random.choice(BIKE_TYPES),
            "color": random.choice(BIKE_COLORS),
            "size": random.choice(BIKE_SIZES),
            "price": random.randint(200, 5000),
            "year": random.randint(2020, 2024),
            "in_stock": str(random.choice([True, False])),
            "stock_count": random.randint(0, 25),
            "last_updated": datetime.now().isoformat(),
            "supplier": f"Supplier_{random.randint(1, 10)}"
        }
        
        r.hset(bike_key, mapping=bike_data)
        
        # Random TTL
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(bike_key, ttl)

def create_customer_data():
    """Create customer data"""
    print("Creating customer data...")
    
    for i in range(200):  # 200 customers
        customer_id = f"cust_{i+1:04d}"
        
        # Customer profile (Hash)
        profile_key = f"{KEYSPACE}:customers:{customer_id}:profile"
        profile_data = {
            "name": random.choice(CUSTOMER_NAMES),
            "email": f"customer{i+1}@email.com",
            "phone": f"+1{random.randint(1000000000, 9999999999)}",
            "address": f"{random.randint(100, 9999)} {random.choice(['Main St', 'Oak Ave', 'Pine Rd', 'Elm Dr'])}",
            "city": random.choice(["Springfield", "Riverside", "Franklin", "Georgetown", "Clinton"]),
            "zip_code": f"{random.randint(10000, 99999)}",
            "member_since": (datetime.now() - timedelta(days=random.randint(1, 1000))).isoformat(),
            "loyalty_points": random.randint(0, 5000),
            "total_spent": random.randint(0, 15000)
        }
        
        r.hset(profile_key, mapping=profile_data)
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(profile_key, ttl)
        
        # Customer purchase history (List)
        history_key = f"{KEYSPACE}:customers:{customer_id}:purchases"
        num_purchases = random.randint(0, 8)
        for j in range(num_purchases):
            purchase = f"bike_{random.randint(1, 400):04d}"
            r.lpush(history_key, purchase)
        
        if num_purchases > 0:
            ttl = random.choice(TTL_RANGES)
            if ttl != -1:
                r.expire(history_key, ttl)
        
        # Customer preferences (Set)
        prefs_key = f"{KEYSPACE}:customers:{customer_id}:preferences"
        preferred_types = random.sample(BIKE_TYPES, random.randint(1, 4))
        for pref in preferred_types:
            r.sadd(prefs_key, pref)
        
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(prefs_key, ttl)

def create_order_data():
    """Create order and transaction data"""
    print("Creating order data...")
    
    for i in range(250):  # 250 orders
        order_id = f"order_{i+1:05d}"
        
        # Order details (Hash)
        order_key = f"{KEYSPACE}:orders:{order_id}"
        order_data = {
            "customer_id": f"cust_{random.randint(1, 200):04d}",
            "bike_id": f"bike_{random.randint(1, 400):04d}",
            "order_date": (datetime.now() - timedelta(days=random.randint(0, 180))).isoformat(),
            "status": random.choice(["pending", "processing", "shipped", "delivered", "cancelled"]),
            "total_amount": random.randint(200, 5000),
            "payment_method": random.choice(["credit_card", "debit_card", "cash", "financing"]),
            "store_location": random.choice(STORE_LOCATIONS),
            "sales_rep": f"Rep_{random.randint(1, 15)}",
            "shipping_address": f"{random.randint(100, 9999)} Delivery St",
            "tracking_number": f"TRK{random.randint(100000000, 999999999)}"
        }
        
        r.hset(order_key, mapping=order_data)
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(order_key, ttl)

def create_store_metrics():
    """Create store performance and metrics data"""
    print("Creating store metrics...")
    
    # Daily sales by location (Sorted Sets)
    for location in STORE_LOCATIONS:
        sales_key = f"{KEYSPACE}:metrics:daily_sales:{location.lower().replace(' ', '_')}"
        
        # Add sales data for random days
        for i in range(random.randint(10, 30)):
            date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            sales_amount = random.randint(1000, 15000)
            r.zadd(sales_key, {date: sales_amount})
        
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(sales_key, ttl)
    
    # Popular bike models (Sorted Set)
    popular_key = f"{KEYSPACE}:metrics:popular_models"
    for brand in BIKE_BRANDS[:10]:  # Top 10 brands
        model_name = f"{brand} {random.choice(['Pro', 'Elite', 'Sport'])}"
        sales_count = random.randint(5, 150)
        r.zadd(popular_key, {model_name: sales_count})
    
    ttl = random.choice(TTL_RANGES)
    if ttl != -1:
        r.expire(popular_key, ttl)

def create_maintenance_records():
    """Create service and maintenance records"""
    print("Creating maintenance records...")
    
    for i in range(100):  # 100 service records
        service_id = f"service_{i+1:04d}"
        
        service_key = f"{KEYSPACE}:services:{service_id}"
        service_data = {
            "customer_id": f"cust_{random.randint(1, 200):04d}",
            "bike_model": f"{random.choice(BIKE_BRANDS)} {random.choice(['Pro', 'Elite'])}",
            "service_type": random.choice([
                "tune_up", "brake_repair", "tire_replacement", "chain_service",
                "gear_adjustment", "wheel_truing", "full_overhaul"
            ]),
            "service_date": (datetime.now() - timedelta(days=random.randint(1, 90))).isoformat(),
            "cost": random.randint(25, 200),
            "technician": f"Tech_{random.randint(1, 8)}",
            "parts_used": random.choice([
                "brake_pads", "chain", "cassette", "tires", "tubes", "cables"
            ]),
            "warranty_work": str(random.choice([True, False])),
            "next_service_due": (datetime.now() + timedelta(days=random.randint(30, 365))).isoformat()
        }
        
        r.hset(service_key, mapping=service_data)
        ttl = random.choice(TTL_RANGES)
        if ttl != -1:
            r.expire(service_key, ttl)

def create_cache_data():
    """Create various cache and temporary data"""
    print("Creating cache and session data...")
    
    # Session data (String/JSON with short TTLs)
    for i in range(50):
        session_id = f"session_{i+1:06d}"
        session_key = f"{KEYSPACE}:cache:sessions:{session_id}"
        
        session_data = {
            "user_id": f"cust_{random.randint(1, 200):04d}",
            "cart_items": [f"bike_{random.randint(1, 400):04d}" for _ in range(random.randint(0, 3))],
            "last_activity": datetime.now().isoformat(),
            "ip_address": f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}",
            "user_agent": random.choice([
                "Chrome/91.0", "Firefox/89.0", "Safari/14.1", "Edge/91.0"
            ])
        }
        
        r.set(session_key, json.dumps(session_data))
        # Sessions get short TTLs
        r.expire(session_key, random.choice([120, 300, 600, 1800]))

def main():
    """Generate 1000 bicycle store keys"""
    print("=" * 60)
    print("Redis Bicycle Store Data Generator - 1000 Keys")
    print("=" * 60)
    
    try:
        # Test connection
        r.ping()
        print("✓ Connected to Redis successfully")
        
        # Generate data (no deletion - only addition)
        create_bike_inventory()        # ~400 keys
        create_customer_data()         # ~600 keys (profiles + purchases + preferences)
        create_order_data()            # ~250 keys
        create_store_metrics()         # ~20 keys
        create_maintenance_records()   # ~100 keys
        create_cache_data()            # ~50 keys
        
        print("\n" + "=" * 60)
        print("Bicycle store data generation complete!")
        print("=" * 60)
        
        # Show summary
        total_keys = len(r.keys(f"{KEYSPACE}:*"))
        print(f"Total keys in '{KEYSPACE}' namespace: {total_keys}")
        
        # Show breakdown by category
        categories = {
            "inventory": len(r.keys(f"{KEYSPACE}:inventory:*")),
            "customers": len(r.keys(f"{KEYSPACE}:customers:*")),
            "orders": len(r.keys(f"{KEYSPACE}:orders:*")),
            "metrics": len(r.keys(f"{KEYSPACE}:metrics:*")),
            "services": len(r.keys(f"{KEYSPACE}:services:*")),
            "cache": len(r.keys(f"{KEYSPACE}:cache:*"))
        }
        
        for category, count in categories.items():
            if count > 0:
                print(f"  {category}: {count} keys")
        
        print(f"\nNamespace: '{KEYSPACE}'")
        print("Keys have varied TTLs for animation demonstration")
        print("Ready for large-scale visualization testing!")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()