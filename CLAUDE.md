# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a real-time 3D visualization system that displays Redis keyspace data as interactive blocks in Roblox. The system consists of a three-tier architecture with careful separation of concerns between data access, 3D rendering, and user interaction.

## Architecture

### Multi-Platform Communication Flow
The system uses HTTP APIs to bridge Redis data into Roblox's 3D environment:

1. **FastAPI Backend** (`main.py`) - Connects to Redis and exposes REST endpoints
2. **Roblox Server Script** (`roblox/roblox_server.lua`) - Fetches data via HTTP, manages 3D parts and animations
3. **Roblox Client Script** (`roblox/roblox_client.lua`) - Handles GUI interactions and modal displays

Communication happens through:
- HTTP requests from Roblox server to FastAPI backend
- RemoteEvents between Roblox server and client scripts
- Redis pipelines for efficient bulk data retrieval

### Key Architectural Patterns

**Smart Part Management**: The Roblox server uses `existingParts` and `existingKeyspaceAnchors` tables to track 3D objects by Redis key names, enabling efficient updates without destroying/recreating parts on each refresh.

**TTL-Based Organization**: Keys are automatically sorted by TTL within each keyspace, creating visual progression from permanent (blue) to expiring (red) keys. The `getTTLSortOrder()` function determines positioning.

**Pipeline-Based Data Fetching**: The FastAPI backend uses Redis pipelines to batch `ttl()`, `memory_usage()`, and `type()` calls for all keys in a single network round trip, critical for performance with large datasets.

**Animation System**: Three types of animations handle data lifecycle:
- Growing animations for new keys spawning
- Shrinking animations for expired keys being removed  
- Sliding animations for TTL-based reorganization

## Common Development Commands

### Running the System
```bash
# Start FastAPI backend
uvicorn main:app --reload --port 8000

# Expose backend via ngrok (required for Roblox HTTP access)
ngrok http 8000

# Generate demo data
python scripts/demo_data_generator.py

# Generate large dataset for testing (1000+ keys)
python scripts/bicycle_data_generator.py
```

### Key Configuration Points
- **Redis Connection**: Update credentials in `main.py`, `scripts/demo_data_generator.py`, and `scripts/bicycle_data_generator.py`
- **API URLs**: Update ngrok URLs in `roblox/roblox_server.lua` configuration section
- **Animation Timing**: Modify `REFRESH_INTERVAL`, `PART_SIZE`, and spacing constants in `roblox/roblox_server.lua`
- **TTL Colors**: Update `TTL_COLORS` table in `roblox/roblox_server.lua` for different color schemes

### Roblox Setup Requirements
- Enable HttpService in Game Settings → Security → Allow HTTP Requests
- Place `roblox/roblox_server.lua` in ServerScriptService
- Place `roblox/roblox_client.lua` in StarterPlayer → StarterPlayerScripts
- Ensure RemoteEvent creation happens before client script loads

## Data Flow and State Management

**Redis Key Lifecycle**: Keys are extracted from Redis with metadata (TTL, type, size), grouped by keyspace (prefix before first colon), then rendered as 3D parts with TTL-based positioning and coloring.

**Efficient Updates**: The `updateVisualizationSmart()` function compares current Redis state with existing 3D parts, only creating/updating/removing parts that have changed, preventing expensive full recreation.

**Modal Data Loading**: When users click parts, the server fetches detailed key data via the `/redis-key/{key_name}` endpoint and sends it to the client via RemoteEvent, where it's formatted with custom JSON indentation and displayed in a scrollable modal.

## Critical Implementation Details

**TTL Color Mapping**: The system maps Redis TTL values to colors using specific thresholds (>1 day = green, >1 hour = yellow, >1 minute = orange, <1 minute = red, -1 = blue). This creates intuitive visual progression as keys approach expiration.

**Keyspace Extraction**: Redis keys are organized by extracting the prefix before the first colon as the keyspace name (e.g., `users:123` → `users` keyspace). Keys without colons go to a `default` keyspace.

**Animation Coordination**: The TweenService-based animations are carefully sequenced - removal animations complete before reorganization, growing animations start transparent and scale up, sliding animations only trigger when position changes exceed 0.1 studs.

**Performance Optimizations**: Large datasets (1000+ keys) benefit from increased `REFRESH_INTERVAL` and Redis connection pooling. The pipeline-based approach scales linearly with key count rather than quadratically.