# Redis Roblox Visualizer

A real-time 3D visualization tool that displays Redis keyspace data as interactive blocks in Roblox. Watch your Redis keys come to life with TTL-based colors, smooth animations, and detailed data exploration.

View the result: https://medium.com/@thisiskj/visualize-your-redis-db-in-roblox-d0c823e2879e

**⚠️ Use at your own risk. Don't connect this to your prod DB! ⚠️**

## 🎥 Features

- **Real-time Visualization**: Live updates every 3 seconds showing current Redis state
- **TTL Color Coding**: Visual indication of key expiration times
  - 🔵 **Blue**: No expiry (-1 TTL)
  - 🟢 **Green**: Long TTL (>1 day)
  - 🟡 **Yellow**: Medium TTL (>1 hour)
  - 🟠 **Orange**: Short TTL (>1 minute)
  - 🔴 **Red**: Expiring soon (<1 minute)
- **Smooth Animations**: 
  - Growing animation for new keys
  - Shrinking animation for expired keys
  - Sliding reorganization by TTL
- **Interactive Data Exploration**: Click any key to view detailed information
- **Smart Organization**: Keys sorted by TTL within each keyspace
- **Performance Optimized**: Efficient part management for large datasets

## 🏗️ Architecture

The system consists of three main components:

### 1. FastAPI Backend (`main.py`)
- REST API serving Redis data
- Supports all Redis data types (String, Hash, List, Set, Sorted Set, ReJSON)
- Efficient pipeline-based data retrieval
- Individual key detail endpoints

### 2. Roblox Server Script (`roblox/roblox_server.lua`)
- Fetches data from FastAPI backend
- Creates and manages 3D visualization
- Handles animations and part lifecycle
- Manages RemoteEvent communication

### 3. Roblox Client Script (`roblox/roblox_client.lua`)
- Displays interactive modal windows
- Handles user input and GUI interactions
- Beautiful JSON formatting and data presentation

## 📦 Installation

### Prerequisites
- Python 3.8+
- Redis instance (local or cloud)
- Roblox Studio
- ngrok (for exposing local API to Roblox)

### Python Setup
1. Clone the repository
```bash
git clone <repository-url>
cd redis-roblox-viz
```

2. Create and activate virtual environment (recommended)
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

3. Install dependencies
```bash
# Install from requirements.txt
pip install -r requirements.txt

# Or install development dependencies (includes testing and linting tools)
pip install -e .[dev]
```

4. Update Redis connection in `main.py`:
```python
r = redis.Redis(
    host='your-redis-host',
    port=your-port,
    decode_responses=True,
    username="your-username",
    password="your-password",
)
```

### Roblox Setup
1. Enable HttpService in Roblox Studio:
   - File → Game Settings → Security → Allow HTTP Requests ✅

2. Copy scripts to Roblox:
   - `roblox/roblox_server.lua` → ServerScriptService
   - `roblox/roblox_client.lua` → StarterPlayer → StarterPlayerScripts

3. Update API URLs in `roblox/roblox_server.lua` to point to your server

## 🚀 Usage

### 1. Start the API Server
```bash
# Start FastAPI server
uvicorn main:app --reload --port 8000

# In another terminal, expose via ngrok
ngrok http 8000
```

### 2. Update Roblox Script URLs
Copy the ngrok HTTPS URL and update in `roblox/roblox_server.lua`:
```lua
local API_URL = "https://your-ngrok-url.app/redis-keyspace"
local KEY_API_URL = "https://your-ngrok-url.app/redis-key/"
```

### 3. Generate Demo Data (Optional)
```bash
# Create sample gaming data
python scripts/demo_data_generator.py

# Create large dataset for performance testing
python scripts/bicycle_data_generator.py

# Or use the installed console commands (if installed with pip install -e .)
demo-data
bicycle-data
```

### 4. Run in Roblox
- Start Roblox Studio
- Run the game
- Watch your Redis data visualize in 3D!

## 🎮 Controls

- **Walk around**: Use standard Roblox controls (WASD)
- **Click any part**: View detailed key information
- **Close modal**: Click X button or click outside modal
- **Automatic updates**: Visualization refreshes every 3 seconds

## 📊 API Endpoints

### GET `/redis-keyspace`
Returns complete keyspace visualization data
```json
{
  "keyspaces": {
    "users": {
      "keys": [
        {
          "name": "users:123",
          "type": "hash",
          "ttl": 3600,
          "size": 1024
        }
      ],
      "total_count": 1,
      "total_size": 1024
    }
  },
  "metadata": {
    "total_keys": 1,
    "timestamp": "2024-09-08T16:30:00Z"
  }
}
```

### GET `/redis-key/{key_name}`
Returns detailed information for a specific key
```json
{
  "key": "users:123",
  "type": "hash",
  "ttl": 3600,
  "size": 1024,
  "value": {
    "name": "John",
    "score": "150"
  },
  "metadata": {
    "timestamp": "2024-09-08T16:30:00Z"
  }
}
```

### GET `/redis-keyspace/counts`
Returns simple key counts per keyspace
```json
{
  "users": 123,
  "sessions": 45,
  "games": 12
}
```

## 🎨 Customization

### Animation Settings
Modify timing and easing in `roblox/roblox_server.lua`:
```lua
local REFRESH_INTERVAL = 3  -- Update frequency (seconds)
local PART_SIZE = 8         -- Part size (studs)
local KEY_SPACING = 15      -- Distance between parts
```

### Color Scheme
Update TTL colors in `roblox/roblox_server.lua`:
```lua
local TTL_COLORS = {
    NO_EXPIRY = Color3.fromRGB(0, 100, 255),    -- Blue
    LONG_TTL = Color3.fromRGB(0, 255, 0),       -- Green
    MEDIUM_TTL = Color3.fromRGB(255, 255, 0),   -- Yellow
    SHORT_TTL = Color3.fromRGB(255, 100, 0),    -- Orange
    EXPIRING = Color3.fromRGB(255, 0, 0)        -- Red
}
```

## 📁 File Structure

```
redis-roblox-viz/
├── main.py                         # FastAPI backend
├── roblox/                         # Roblox scripts directory
│   ├── roblox_server.lua          # Roblox server script
│   └── roblox_client.lua          # Roblox client script
├── scripts/                        # Data generation scripts
│   ├── demo_data_generator.py     # Sample gaming data
│   └── bicycle_data_generator.py  # Large dataset generator
└── README.md                      # This file
```

---

**Happy visualizing! 🎉**