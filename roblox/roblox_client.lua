-- Redis Keyspace Visualizer - CLIENT SCRIPT
-- Place this script in StarterPlayer > StarterPlayerScripts
-- This handles all GUI and modal functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Wait for RemoteEvent to be created by server
local showKeyDataRemote = ReplicatedStorage:WaitForChild("ShowKeyData")

-- Helper function to format JSON with proper indentation
local function formatJSON(data, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    if type(data) == "table" then
        local isArray = true
        local count = 0
        
        -- Check if it's an array or object
        for k, v in pairs(data) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                isArray = false
                break
            end
        end
        
        if count == 0 then
            return "{}"
        end
        
        local result = isArray and "[\n" or "{\n"
        local first = true
        
        for k, v in pairs(data) do
            if not first then
                result = result .. ",\n"
            end
            first = false
            
            if isArray then
                result = result .. indentStr .. "  " .. formatJSON(v, indent + 1)
            else
                result = result .. indentStr .. "  \"" .. tostring(k) .. "\": " .. formatJSON(v, indent + 1)
            end
        end
        
        result = result .. "\n" .. indentStr .. (isArray and "]" or "}")
        return result
    elseif type(data) == "string" then
        return "\"" .. tostring(data) .. "\""
    elseif type(data) == "boolean" then
        return tostring(data)
    elseif type(data) == "number" then
        return tostring(data)
    else
        return "\"" .. tostring(data) .. "\""
    end
end

-- Create modal GUI for displaying key data
local function createKeyDataModal(keyData)
    -- Wait for player GUI to be ready
    if not LocalPlayer or not LocalPlayer:FindFirstChild("PlayerGui") then
        warn("PlayerGui not available")
        return
    end
    
    local playerGui = LocalPlayer.PlayerGui
    
    -- Remove existing modal if it exists
    local existingModal = playerGui:FindFirstChild("KeyDataModal")
    if existingModal then
        existingModal:Destroy()
    end
    
    -- Create the main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeyDataModal"
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui
    
    -- Create invisible background for click detection (no blur)
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundTransparency = 1  -- Fully transparent
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = screenGui
    
    -- Create modal container (start small for animation)
    local modalFrame = Instance.new("Frame")
    modalFrame.Size = UDim2.new(0, 0, 0, 0)  -- Start at 0 size
    modalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- Center position
    modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)  -- Center anchor
    modalFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    modalFrame.BorderSizePixel = 2
    modalFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    modalFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = modalFrame
    
    -- Create header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 50)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = modalFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = headerFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Redis Key: " .. keyData.key
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = headerFrame
    
    -- Create close button (X)
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = headerFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Create scrollable content area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -70)
    contentFrame.Position = UDim2.new(0, 10, 0, 60)
    contentFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 10
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    contentFrame.Parent = modalFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 5)
    contentCorner.Parent = contentFrame
    
    -- Format and display the data
    local dataText = ""
    
    -- Add metadata section with better formatting
    dataText = dataText .. "┌─ METADATA ─────────────────────────────────────────┐\n"
    dataText = dataText .. "│ Type: " .. keyData.type .. "\n"
    dataText = dataText .. "│ TTL: " .. (keyData.ttl == -1 and "No Expiry" or keyData.ttl .. " seconds") .. "\n"
    dataText = dataText .. "│ Size: " .. string.format("%.1f KB", keyData.size / 1024) .. "\n"
    dataText = dataText .. "│ Updated: " .. keyData.metadata.timestamp .. "\n"
    dataText = dataText .. "└────────────────────────────────────────────────────┘\n\n"
    
    dataText = dataText .. "┌─ DATA ─────────────────────────────────────────────┐\n"
    
    -- Format the value based on type with nice formatting
    if type(keyData.value) == "table" then
        -- Use our custom JSON formatter for better readability
        dataText = dataText .. formatJSON(keyData.value)
    elseif type(keyData.value) == "string" then
        -- Handle strings with proper escaping
        if keyData.type == "ReJSON-RL" then
            -- Try to parse and reformat JSON strings
            local success, parsedJSON = pcall(function()
                return HttpService:JSONDecode(keyData.value)
            end)
            if success then
                dataText = dataText .. formatJSON(parsedJSON)
            else
                dataText = dataText .. "\"" .. keyData.value .. "\""
            end
        else
            dataText = dataText .. "\"" .. keyData.value .. "\""
        end
    else
        -- Handle other primitive types
        dataText = dataText .. tostring(keyData.value)
    end
    
    dataText = dataText .. "\n└────────────────────────────────────────────────────┘"
    
    -- Create text label for data
    local dataLabel = Instance.new("TextLabel")
    dataLabel.Size = UDim2.new(1, -20, 0, 0) -- Height will be auto-calculated
    dataLabel.Position = UDim2.new(0, 10, 0, 10)
    dataLabel.BackgroundTransparency = 1
    dataLabel.Text = dataText
    dataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dataLabel.TextSize = 14
    dataLabel.Font = Enum.Font.Code
    dataLabel.TextXAlignment = Enum.TextXAlignment.Left
    dataLabel.TextYAlignment = Enum.TextYAlignment.Top
    dataLabel.TextWrapped = true
    dataLabel.Parent = contentFrame
    
    -- Function to close modal with animation
    local function closeModal()
        -- Check if the modal still exists before trying to tween
        if not screenGui or not screenGui.Parent then
            return  -- Modal was already destroyed
        end
        
        if not modalFrame or not modalFrame.Parent then
            -- Modal frame was destroyed, just destroy the screen gui
            screenGui:Destroy()
            return
        end
        
        local closeTween = TweenService:Create(
            modalFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        
        closeTween:Play()
        
        closeTween.Completed:Connect(function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(closeModal)
    
    -- Also close when clicking the background
    backgroundFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeModal()
        end
    end)
    
    -- Animate modal opening
    local openTween = TweenService:Create(
        modalFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 700, 0, 600)}  -- Made slightly larger for better formatting
    )
    
    openTween:Play()
    
    -- Calculate text height and set content size after a short delay (for proper text bounds calculation)
    wait(0.1)
    
    local textService = game:GetService("TextService")
    local textBounds = textService:GetTextSize(
        dataText,
        14,
        Enum.Font.Code,
        Vector2.new(660, math.huge)  -- Use fixed width for calculation
    )
    
    dataLabel.Size = UDim2.new(1, -20, 0, textBounds.Y + 20)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 40)
    
    return screenGui
end

-- Handle incoming key data from server
showKeyDataRemote.OnClientEvent:Connect(function(keyData)
    print("Received key data from server:", keyData.key)
    createKeyDataModal(keyData)
end)

print("Redis Keyspace Visualizer Client initialized!")
print("Ready to display key data modals.")