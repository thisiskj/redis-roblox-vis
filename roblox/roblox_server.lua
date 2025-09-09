-- Redis Keyspace Visualizer - SERVER SCRIPT
-- Place this script in ServerScriptService
-- Make sure HttpService is enabled in Game Settings

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game.Workspace

-- Configuration - UPDATE THESE URLs TO YOUR SERVER
local API_URL = "https://your-ngrok-url.app/redis-keyspace"  -- Update this to your server URL
local KEY_API_URL = "https://your-ngrok-url.app/redis-key/"  -- URL for individual key data
local VISUALIZATION_FOLDER = "RedisVisualization"
local PART_SIZE = 8       -- Fixed size for all parts
local KEYSPACE_SPACING = 20  -- Distance between keyspaces
local KEY_SPACING = 15    -- Distance between keys within a keyspace
local REFRESH_INTERVAL = 3  -- Seconds between updates

-- Create RemoteEvents for client communication
local showKeyDataRemote = Instance.new("RemoteEvent")
showKeyDataRemote.Name = "ShowKeyData"
showKeyDataRemote.Parent = ReplicatedStorage

-- Track existing parts by key name for efficient updates
local existingParts = {}  -- keyName -> part instance
local existingKeyspaceAnchors = {}  -- keyspaceName -> anchor part

-- TTL-based color mapping
local TTL_COLORS = {
    NO_EXPIRY = Color3.fromRGB(0, 100, 255),    -- Blue for ttl = -1
    LONG_TTL = Color3.fromRGB(0, 255, 0),       -- Green for > 1 day
    MEDIUM_TTL = Color3.fromRGB(255, 255, 0),   -- Yellow for > 1 hour
    SHORT_TTL = Color3.fromRGB(255, 100, 0),    -- Orange for > 1 minute
    EXPIRING = Color3.fromRGB(255, 0, 0)        -- Red for expiring soon
}

-- Helper function to get TTL-based color
local function getTTLColor(ttl)
    if ttl == -1 then
        return TTL_COLORS.NO_EXPIRY
    elseif ttl > 86400 then  -- > 1 day
        return TTL_COLORS.LONG_TTL
    elseif ttl > 3600 then   -- > 1 hour
        return TTL_COLORS.MEDIUM_TTL
    elseif ttl > 60 then     -- > 1 minute
        return TTL_COLORS.SHORT_TTL
    else
        return TTL_COLORS.EXPIRING
    end
end

-- Helper function to get TTL sort order (lower = appears first)
local function getTTLSortOrder(ttl)
    if ttl == -1 then
        return 0  -- No expiry first
    elseif ttl > 86400 then
        return 1  -- Long TTL second
    elseif ttl > 3600 then
        return 2  -- Medium TTL third
    elseif ttl > 60 then
        return 3  -- Short TTL fourth
    else
        return 4  -- Expiring last
    end
end

-- Helper function to sort keys by TTL
local function sortKeysByTTL(keys)
    table.sort(keys, function(a, b)
        local orderA = getTTLSortOrder(a.ttl)
        local orderB = getTTLSortOrder(b.ttl)
        
        if orderA == orderB then
            -- Within same TTL category, sort by key name for consistency
            return a.name < b.name
        else
            return orderA < orderB
        end
    end)
    return keys
end

-- Helper function to extract key suffix after keyspace prefix
local function getKeySuffix(keyName)
    if string.find(keyName, ":") then
        local suffix = string.match(keyName, ":(.+)$")
        return suffix or keyName
    else
        return keyName
    end
end

-- Fetch individual key data from API
local function fetchKeyData(keyName, callback)
    local success, response = pcall(function()
        return HttpService:GetAsync(KEY_API_URL .. HttpService:UrlEncode(keyName))
    end)
    
    if not success then
        warn("Failed to fetch key data for " .. keyName .. ": " .. tostring(response))
        callback(nil)
        return
    end
    
    local success2, keyData = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success2 then
        warn("Failed to parse key data JSON: " .. tostring(keyData))
        callback(nil)
        return
    end
    
    callback(keyData)
end

-- Animate part removal (shrinking)
local function animatePartRemoval(part, callback)
    local originalSize = part.Size
    
    local shrinkTween = TweenService:Create(
        part,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = Vector3.new(0, 0, 0),
            Transparency = 1
        }
    )
    
    -- Also fade out the surface GUI
    local surfaceGui = part:FindFirstChild("SurfaceGui")
    if surfaceGui then
        local textLabel = surfaceGui:FindFirstChild("TextLabel")
        if textLabel then
            local fadeTween = TweenService:Create(
                textLabel,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {TextTransparency = 1}
            )
            fadeTween:Play()
        end
    end
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function()
        if callback then callback() end
        part:Destroy()
    end)
end

-- Animate new part creation (growing)
local function animatePartCreation(part)
    local targetSize = part.Size
    local targetPosition = part.Position
    
    -- Start small and transparent
    part.Size = Vector3.new(0, 0, 0)
    part.Transparency = 0.8
    part.Position = Vector3.new(targetPosition.X, targetPosition.Y + 5, targetPosition.Z) -- Start higher
    
    -- Hide text initially
    local surfaceGui = part:FindFirstChild("SurfaceGui")
    if surfaceGui then
        local textLabel = surfaceGui:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.TextTransparency = 1
        end
    end
    
    -- Animate growing
    local growTween = TweenService:Create(
        part,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = targetSize,
            Transparency = 0,
            Position = targetPosition
        }
    )
    
    growTween:Play()
    
    -- Fade in text after a delay
    if surfaceGui then
        local textLabel = surfaceGui:FindFirstChild("TextLabel")
        if textLabel then
            wait(0.3)
            local textTween = TweenService:Create(
                textLabel,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 0}
            )
            textTween:Play()
        end
    end
end

-- Animate part sliding to new position
local function animatePartSliding(part, targetPosition)
    local slideTween = TweenService:Create(
        part,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = targetPosition}
    )
    slideTween:Play()
end

-- Create or update a part for a Redis key
local function createOrUpdateKeyPart(keyData, position, folder, isNewPart)
    local existingPart = existingParts[keyData.name]
    
    if existingPart and existingPart.Parent then
        -- Update existing part
        existingPart.Color = getTTLColor(keyData.ttl)
        
        -- Update the text label
        local surfaceGui = existingPart:FindFirstChild("SurfaceGui")
        if surfaceGui then
            local keyLabel = surfaceGui:FindFirstChild("TextLabel")
            if keyLabel then
                keyLabel.Text = getKeySuffix(keyData.name)
            end
        end
        
        -- Move to correct folder if needed
        if existingPart.Parent ~= folder then
            existingPart.Parent = folder
        end
        
        -- Animate sliding to new position if it changed
        local targetPosition = Vector3.new(position.X, PART_SIZE/8, position.Z)
        local currentPosition = existingPart.Position
        local distance = (targetPosition - currentPosition).Magnitude
        
        if distance > 0.1 then  -- Only animate if position changed significantly
            animatePartSliding(existingPart, targetPosition)
        end
        
        return existingPart
    else
        -- Create new part
        local part = Instance.new("Part")
        part.Name = keyData.name
        part.Shape = Enum.PartType.Block
        part.Material = Enum.Material.Neon
        part.Anchored = true
        part.CanCollide = false
        
        -- Fixed size for all parts
        part.Size = Vector3.new(PART_SIZE, PART_SIZE/4, PART_SIZE)  -- Make it flatter (height/4)
        
        -- Color based on TTL
        part.Color = getTTLColor(keyData.ttl)
        
        -- Position the part on the ground (Y = PART_SIZE/8 to sit on ground)
        part.Position = Vector3.new(position.X, PART_SIZE/8, position.Z)
        
        -- Add key suffix label on top of the part
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Face = Enum.NormalId.Top
        surfaceGui.Parent = part
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "TextLabel"
        keyLabel.Size = UDim2.new(1, 0, 1, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = getKeySuffix(keyData.name)
        keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyLabel.TextScaled = true
        keyLabel.Font = Enum.Font.Gotham
        keyLabel.TextStrokeTransparency = 0
        keyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        keyLabel.Parent = surfaceGui
        
        -- Add ClickDetector for interaction
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 50
        clickDetector.Parent = part
        
        -- Handle clicks to request key data from client
        clickDetector.MouseClick:Connect(function(player)
            print("Player " .. player.Name .. " clicked key: " .. keyData.name)
            
            -- Fetch detailed key data and send to client
            fetchKeyData(keyData.name, function(detailedKeyData)
                if detailedKeyData then
                    showKeyDataRemote:FireClient(player, detailedKeyData)
                else
                    warn("Failed to load data for key: " .. keyData.name)
                end
            end)
        end)
        
        part.Parent = folder
        existingParts[keyData.name] = part
        
        -- Animate creation if it's a new part
        if isNewPart then
            spawn(function()
                animatePartCreation(part)
            end)
        end
        
        return part
    end
end

-- Create or update visualization for a keyspace
local function createOrUpdateKeyspaceVisualization(keyspaceName, keyspaceData, basePosition, mainFolder)
    -- Get or create keyspace folder
    local folder = mainFolder:FindFirstChild(keyspaceName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = keyspaceName
        folder.Parent = mainFolder
    end
    
    -- Create or update invisible anchor part for billboard GUI
    local anchor = existingKeyspaceAnchors[keyspaceName]
    if not anchor or not anchor.Parent then
        anchor = Instance.new("Part")
        anchor.Name = keyspaceName .. "_Anchor"
        anchor.Shape = Enum.PartType.Block
        anchor.Material = Enum.Material.ForceField
        anchor.Color = Color3.fromRGB(0, 0, 0)
        anchor.Size = Vector3.new(1, 1, 1)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.Transparency = 1  -- Make it invisible
        anchor.Parent = folder
        
        -- Add Billboard GUI for keyspace name
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 0, 0)
        billboardGui.Parent = anchor
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 0.3
        textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Parent = billboardGui
        
        existingKeyspaceAnchors[keyspaceName] = anchor
    end
    
    -- Update anchor position and text
    anchor.Position = Vector3.new(basePosition.X, 15, basePosition.Z - 15)  -- Above and behind the keys
    local billboardGui = anchor:FindFirstChild("BillboardGui")
    if billboardGui then
        local textLabel = billboardGui:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = keyspaceName .. " (" .. #keyspaceData.keys .. " keys)"
        end
    end
    
    -- Sort keys by TTL for organized layout
    local sortedKeys = sortKeysByTTL(keyspaceData.keys)
    
    -- Create or update parts for each key in the keyspace (laid out in a 5 by X grid on the ground)
    local keysPerRow = 5  -- Number of keys per row
    local totalRows = math.ceil(#sortedKeys / keysPerRow)
    
    -- Track which keys are new for animation
    local newKeys = {}
    for _, keyData in ipairs(sortedKeys) do
        if not existingParts[keyData.name] or not existingParts[keyData.name].Parent then
            newKeys[keyData.name] = true
        end
    end
    
    for i, keyData in ipairs(sortedKeys) do
        local row = math.floor((i - 1) / keysPerRow)
        local col = (i - 1) % keysPerRow
        
        local partPosition = Vector3.new(
            basePosition.X + (col - 2) * KEY_SPACING,  -- Center the row (5 keys: -2, -1, 0, 1, 2)
            0,  -- Ground level
            basePosition.Z + row * KEY_SPACING
        )
        
        local isNewPart = newKeys[keyData.name] == true
        createOrUpdateKeyPart(keyData, partPosition, folder, isNewPart)
    end
    
    return folder, totalRows
end

-- Fetch data from Redis API
local function fetchRedisData()
    local success, response = pcall(function()
        return HttpService:GetAsync(API_URL)
    end)
    
    if not success then
        warn("Failed to fetch Redis data: " .. tostring(response))
        return nil
    end
    
    local success2, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success2 then
        warn("Failed to parse Redis data JSON: " .. tostring(data))
        return nil
    end
    
    return data
end

-- Smart update of the visualization
local function updateVisualizationSmart(data)
    -- Get or create main folder
    local mainFolder = Workspace:FindFirstChild(VISUALIZATION_FOLDER)
    if not mainFolder then
        mainFolder = Instance.new("Folder")
        mainFolder.Name = VISUALIZATION_FOLDER
        mainFolder.Parent = Workspace
    end
    
    -- Keep track of current keys to identify removed ones
    local currentKeys = {}
    for keyspaceName, keyspaceData in pairs(data.keyspaces) do
        for _, keyData in ipairs(keyspaceData.keys) do
            currentKeys[keyData.name] = true
        end
    end
    
    -- Remove parts for keys that no longer exist (with animation)
    local partsToRemove = {}
    for keyName, part in pairs(existingParts) do
        if not currentKeys[keyName] then
            table.insert(partsToRemove, {keyName = keyName, part = part})
        end
    end
    
    -- Animate removal of expired parts
    for _, removeData in ipairs(partsToRemove) do
        if removeData.part and removeData.part.Parent then
            -- Animate removal, then clean up tracking
            animatePartRemoval(removeData.part, function()
                existingParts[removeData.keyName] = nil
            end)
        else
            existingParts[removeData.keyName] = nil
        end
    end
    
    -- Remove keyspace anchors that no longer exist
    for keyspaceName, anchor in pairs(existingKeyspaceAnchors) do
        if not data.keyspaces[keyspaceName] then
            if anchor and anchor.Parent then
                anchor:Destroy()
            end
            existingKeyspaceAnchors[keyspaceName] = nil
            
            -- Remove empty keyspace folder
            local folder = mainFolder:FindFirstChild(keyspaceName)
            if folder and #folder:GetChildren() == 0 then
                folder:Destroy()
            end
        end
    end
    
    -- Create or update visualization for each keyspace
    local currentXOffset = 0
    
    for keyspaceName, keyspaceData in pairs(data.keyspaces) do
        local basePosition = Vector3.new(currentXOffset, 0, 0)
        createOrUpdateKeyspaceVisualization(keyspaceName, keyspaceData, basePosition, mainFolder)
        
        -- Calculate next X offset based on the grid width (5 keys per row)
        local keysPerRow = 5
        local keyspaceWidth = keysPerRow * KEY_SPACING
        currentXOffset = currentXOffset + keyspaceWidth + KEYSPACE_SPACING
    end
    
    local keyspaceCount = 0
    for _ in pairs(data.keyspaces) do keyspaceCount = keyspaceCount + 1 end
    
    print(string.format("Redis visualization updated: %d keyspaces, %d total keys", 
                       keyspaceCount, data.metadata.total_keys))
end

-- Main update function
local function updateVisualization()
    print("Fetching Redis data...")
    local data = fetchRedisData()
    
    if data then
        updateVisualizationSmart(data)
    else
        warn("Failed to update Redis visualization")
    end
end

-- Initial visualization
updateVisualization()

-- Set up periodic updates
spawn(function()
    while true do
        wait(REFRESH_INTERVAL)
        updateVisualization()
    end
end)

print("Redis Keyspace Visualizer Server initialized!")
print("Configuration:")
print("  API URL: " .. API_URL)
print("  Refresh Interval: " .. REFRESH_INTERVAL .. " seconds")
print("  Part Size: " .. PART_SIZE .. " studs")