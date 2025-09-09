"""Redis Roblox Visualization Tool.
"""

import redis
from collections import defaultdict
from fastapi import FastAPI, HTTPException
from datetime import datetime

app = FastAPI(title="Redis Roblox Visualization API")

# Redis connection - UPDATE THESE VALUES FOR YOUR REDIS INSTANCE
r = redis.Redis(
    host='your-redis-host.com',
    port=6379,
    decode_responses=True,
    username="your-username",
    password="your-password",
)

def get_keyspace_data():
    """Get detailed Redis key data grouped by keyspace using pipeline."""
    # Get all keys
    all_keys = r.keys('*')
    
    if not all_keys:
        return {
            "keyspaces": {},
            "metadata": {
                "total_keys": 0,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }
        }
    
    # Use pipeline for efficient batch operations
    pipe = r.pipeline()
    for key in all_keys:
        pipe.ttl(key)
        pipe.memory_usage(key)
        pipe.type(key)
    
    # Execute all commands at once
    results = pipe.execute()
    
    # Group results by keyspace
    keyspaces = defaultdict(lambda: {"keys": [], "total_count": 0, "total_size": 0})
    
    # Process results (3 results per key: ttl, memory, type)
    for i, key in enumerate(all_keys):
        ttl_idx = i * 3
        memory_idx = i * 3 + 1
        type_idx = i * 3 + 2
        
        ttl = results[ttl_idx]
        memory = results[memory_idx] or 0  # Handle None memory usage
        key_type = results[type_idx]
        
        # Extract keyspace
        if ':' in key:
            keyspace = key.split(':', 1)[0]
        else:
            keyspace = 'default'
        
        # Add key data
        keyspaces[keyspace]["keys"].append({
            "name": key,
            "type": key_type,
            "ttl": ttl,
            "size": memory
        })
        keyspaces[keyspace]["total_count"] += 1
        keyspaces[keyspace]["total_size"] += memory
    
    return {
        "keyspaces": dict(keyspaces),
        "metadata": {
            "total_keys": len(all_keys),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    }

def get_keyspace_counts():
    """Count Redis keys grouped by keyspace (legacy function)."""
    data = get_keyspace_data()
    return {keyspace: info["total_count"] for keyspace, info in data["keyspaces"].items()}

def get_single_key_data(key_name: str):
    """Get detailed data for a single Redis key."""
    # Check if key exists
    if not r.exists(key_name):
        raise HTTPException(status_code=404, detail=f"Key '{key_name}' not found")
    
    # Get key metadata
    key_type = r.type(key_name)
    ttl = r.ttl(key_name)
    memory = r.memory_usage(key_name) or 0
    
    # Get the actual data based on type
    if key_type == 'string':
        value = r.get(key_name)
    elif key_type == 'list':
        value = r.lrange(key_name, 0, -1)
    elif key_type == 'set':
        value = list(r.smembers(key_name))
    elif key_type == 'zset':
        value = r.zrange(key_name, 0, -1, withscores=True)
    elif key_type == 'hash':
        value = r.hgetall(key_name)
    elif key_type == 'ReJSON-RL':
        # Handle ReJSON (JSON document) data type
        try:
            value = r.execute_command('JSON.GET', key_name)
        except Exception as e:
            value = f"Error reading JSON: {str(e)}"
    else:
        value = f"Unsupported type: {key_type}"
    
    return {
        "key": key_name,
        "type": key_type,
        "ttl": ttl,
        "size": memory,
        "value": value,
        "metadata": {
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    }

@app.get("/redis-keyspace")
def get_redis_keyspace():
    """Get detailed Redis keyspace data for Roblox visualization."""
    return get_keyspace_data()

@app.get("/redis-keyspace/counts")
def get_redis_keyspace_counts():
    """Get Redis keyspace counts only."""
    return get_keyspace_counts()

@app.get("/redis-key/{key_name:path}")
def get_redis_key(key_name: str):
    """Get detailed data for a specific Redis key."""
    return get_single_key_data(key_name)

if __name__ == "__main__":
    keyspace_counts = get_keyspace_counts()
    
    print("Keyspace Counts:")
    for keyspace, count in keyspace_counts.items():
        print(f"{keyspace}: {count} keys")
