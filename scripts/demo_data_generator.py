"""
Redis Demo Data Generator
Creates sample data in Redis for demonstrating the Roblox visualization tool.
"""

import redis
import json
import random
import time
from datetime import datetime, timedelta

# Redis connection - UPDATE THESE VALUES FOR YOUR REDIS INSTANCE
r = redis.Redis(
    host='your-redis-host.com',
    port=6379,
    decode_responses=True,
    username="your-username",
    password="your-password",
)

# Demo configuration
DEMO_KEYSPACE = "demo"
PLAYER_COUNT = 15
GAME_COUNT = 8
SESSION_COUNT = 12

# TTL ranges for different visualization colors
TTL_RANGES = {
    "no_expiry": -1,           # Blue - no expiration
    "long": 86400 * 2,         # Green - 2 days
    "medium": 3600 * 6,        # Yellow - 6 hours
    "short": 300,              # Orange - 5 minutes
    "expiring": 30             # Red - 30 seconds
}

def clear_demo_data():
    """Clear existing demo data"""
    print("Clearing existing demo data...")
    keys = r.keys(f"{DEMO_KEYSPACE}:*")
    if keys:
        r.delete(*keys)
        print(f"Deleted {len(keys)} existing demo keys")

def create_player_data():
    """Create demo player data with various data types and TTLs"""
    print("Creating player data...")
    
    player_names = [
        "PixelWarrior", "CyberNinja", "GalaxyHunter", "StormRider", "NeonGamer",
        "VoidWalker", "StarCrusher", "TechMage", "ShadowDancer", "FireStorm",
        "IcePhoenix", "ThunderBolt", "MysticSage", "BladeRunner", "CosmicDrift"
    ]
    
    for i in range(PLAYER_COUNT):
        player_id = f"player_{i+1:03d}"
        player_name = player_names[i % len(player_names)]
        
        # Choose random TTL category
        ttl_category = random.choice(list(TTL_RANGES.keys()))
        ttl = TTL_RANGES[ttl_category]
        
        # Player profile (Hash)
        profile_key = f"{DEMO_KEYSPACE}:players:{player_id}:profile"
        profile_data = {
            "username": player_name,
            "level": random.randint(1, 100),
            "experience": random.randint(0, 100000),
            "gold": random.randint(100, 50000),
            "last_login": datetime.now().isoformat(),
            "premium": str(random.choice([True, False])),
            "guild": random.choice(["Dragons", "Phoenix", "Wolves", "Eagles", "Lions"])
        }
        
        r.hset(profile_key, mapping=profile_data)
        if ttl != -1:
            r.expire(profile_key, ttl)
        
        # Player inventory (List)
        inventory_key = f"{DEMO_KEYSPACE}:players:{player_id}:inventory"
        items = ["sword", "shield", "potion", "scroll", "gem", "armor", "bow", "staff"]
        player_inventory = random.sample(items, random.randint(3, 6))
        
        for item in player_inventory:
            r.lpush(inventory_key, item)
        
        # Random TTL for inventory
        inv_ttl_category = random.choice(list(TTL_RANGES.keys()))
        inv_ttl = TTL_RANGES[inv_ttl_category]
        if inv_ttl != -1:
            r.expire(inventory_key, inv_ttl)
        
        # Player achievements (Set)
        achievements_key = f"{DEMO_KEYSPACE}:players:{player_id}:achievements"
        possible_achievements = [
            "first_kill", "level_10", "level_50", "rich_player", "guild_member",
            "quest_master", "arena_winner", "treasure_hunter"
        ]
        player_achievements = random.sample(possible_achievements, random.randint(2, 5))
        
        for achievement in player_achievements:
            r.sadd(achievements_key, achievement)
        
        # Random TTL for achievements
        ach_ttl_category = random.choice(list(TTL_RANGES.keys()))
        ach_ttl = TTL_RANGES[ach_ttl_category]
        if ach_ttl != -1:
            r.expire(achievements_key, ach_ttl)

def create_game_data():
    """Create demo game data"""
    print("Creating game data...")
    
    game_types = ["RPG", "FPS", "Racing", "Puzzle", "Strategy", "Adventure", "Sports", "Simulation"]
    
    for i in range(GAME_COUNT):
        game_id = f"game_{i+1:03d}"
        game_type = game_types[i]
        
        # Game info (String/JSON)
        game_key = f"{DEMO_KEYSPACE}:games:{game_id}:info"
        game_info = {
            "name": f"{game_type} Arena {i+1}",
            "type": game_type,
            "max_players": random.randint(2, 20),
            "created_at": datetime.now().isoformat(),
            "creator": random.choice(["DevStudio1", "GameMakers", "PixelCraft", "CodeWizards"]),
            "rating": round(random.uniform(3.0, 5.0), 1),
            "active": random.choice([True, False])
        }
        
        r.set(game_key, json.dumps(game_info))
        
        # Random TTL
        ttl_category = random.choice(list(TTL_RANGES.keys()))
        ttl = TTL_RANGES[ttl_category]
        if ttl != -1:
            r.expire(game_key, ttl)
        
        # Game leaderboard (Sorted Set)
        leaderboard_key = f"{DEMO_KEYSPACE}:games:{game_id}:leaderboard"
        
        # Add random players to leaderboard with scores
        for j in range(random.randint(3, 8)):
            player_name = f"Player_{j+1}"
            score = random.randint(100, 10000)
            r.zadd(leaderboard_key, {player_name: score})
        
        # Random TTL for leaderboard
        lb_ttl_category = random.choice(list(TTL_RANGES.keys()))
        lb_ttl = TTL_RANGES[lb_ttl_category]
        if lb_ttl != -1:
            r.expire(leaderboard_key, lb_ttl)

def create_session_data():
    """Create demo session data"""
    print("Creating session data...")
    
    for i in range(SESSION_COUNT):
        session_id = f"session_{i+1:08d}"
        
        # Session info (Hash)
        session_key = f"{DEMO_KEYSPACE}:sessions:{session_id}"
        
        session_data = {
            "player_id": f"player_{random.randint(1, PLAYER_COUNT):03d}",
            "game_id": f"game_{random.randint(1, GAME_COUNT):03d}",
            "start_time": (datetime.now() - timedelta(minutes=random.randint(1, 120))).isoformat(),
            "server": f"server_{random.randint(1, 5)}",
            "ip_address": f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}",
            "status": random.choice(["active", "idle", "disconnected"]),
            "score": random.randint(0, 5000)
        }
        
        r.hset(session_key, mapping=session_data)
        
        # Sessions typically have shorter TTLs
        ttl_category = random.choice(["medium", "short", "expiring"])
        ttl = TTL_RANGES[ttl_category]
        r.expire(session_key, ttl)

def create_realtime_data():
    """Create some real-time changing data for live demo effect"""
    print("Creating real-time demo data...")
    
    # Server stats (frequently updated)
    server_stats_key = f"{DEMO_KEYSPACE}:server:stats"
    stats = {
        "online_players": random.randint(100, 1000),
        "active_games": random.randint(20, 100),
        "cpu_usage": f"{random.randint(20, 80)}%",
        "memory_usage": f"{random.randint(30, 90)}%",
        "uptime_hours": random.randint(1, 720),
        "last_updated": datetime.now().isoformat()
    }
    
    r.hset(server_stats_key, mapping=stats)
    r.expire(server_stats_key, 60)  # Expires in 1 minute for live updates
    
    # Current events (List with short TTL)
    events_key = f"{DEMO_KEYSPACE}:events:current"
    current_events = [
        "Double XP Weekend Active!",
        "New player joined: PixelMaster",
        "Guild battle starting soon",
        "Server maintenance in 2 hours",
        "Special event: Treasure Hunt!"
    ]
    
    for event in random.sample(current_events, 3):
        r.lpush(events_key, event)
    
    r.expire(events_key, 45)  # Very short TTL for demo

def create_mixed_ttl_showcase():
    """Create keys specifically to showcase different TTL colors"""
    print("Creating TTL showcase data...")
    
    showcase_data = [
        ("permanent_config", "Configuration data that never expires", -1),
        ("daily_rewards", "Daily reward configuration", 86400),
        ("hourly_bonus", "Hourly bonus multiplier", 3600), 
        ("temp_boost", "Temporary boost active", 300),
        ("flash_sale", "Flash sale ending soon!", 30)
    ]
    
    for i, (name, description, ttl) in enumerate(showcase_data):
        key = f"{DEMO_KEYSPACE}:showcase:{name}"
        data = {
            "name": name.replace("_", " ").title(),
            "description": description,
            "created_at": datetime.now().isoformat(),
            "demo_purpose": "TTL color demonstration"
        }
        
        r.set(key, json.dumps(data))
        if ttl != -1:
            r.expire(key, ttl)

def main():
    """Main demo data generation function"""
    print("=" * 50)
    print("Redis Roblox Visualization - Demo Data Generator")
    print("=" * 50)
    
    try:
        # Test connection
        r.ping()
        print("✓ Connected to Redis successfully")
        
        # Clear existing demo data
        clear_demo_data()
        
        # Generate demo data
        create_player_data()
        time.sleep(3)
        create_game_data()
        time.sleep(3)
        create_session_data()
        time.sleep(3)
        create_realtime_data()
        time.sleep(3)
        create_mixed_ttl_showcase()
        time.sleep(3)
        
        print("\n" + "=" * 50)
        print("Demo data generation complete!")
        print("=" * 50)
        
        # Show summary
        total_keys = len(r.keys(f"{DEMO_KEYSPACE}:*"))
        print(f"Total demo keys created: {total_keys}")
        
        # Show keys by type
        for key_type in ["players", "games", "sessions", "server", "events", "showcase"]:
            count = len(r.keys(f"{DEMO_KEYSPACE}:{key_type}:*"))
            if count > 0:
                print(f"  {key_type}: {count} keys")
        
        print(f"\nDemo keyspace: '{DEMO_KEYSPACE}'")
        print("You can now view this data in your Roblox visualization!")
        print("\nTTL Color Legend:")
        print("  🔵 Blue: No expiry")
        print("  🟢 Green: Long TTL (>1 day)")
        print("  🟡 Yellow: Medium TTL (>1 hour)")
        print("  🟠 Orange: Short TTL (>1 minute)")
        print("  🔴 Red: Expiring soon")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()