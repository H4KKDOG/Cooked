local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local espThreshold = 100
local espUpdateInterval = 0.25
local lastUpdate = tick()

local function createSeeThroughOutline(character)
    if not character then return end

    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local existingOutline = part:FindFirstChild("Outline")
            if existingOutline then
                existingOutline:Destroy()
            end

            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Name = "Outline"
            surfaceGui.AlwaysOnTop = true
            surfaceGui.Face = Enum.NormalId.Front
            surfaceGui.Adornee = part
            surfaceGui.Parent = part

            local outlineFrame = Instance.new("Frame")
            outlineFrame.Size = UDim2.new(1, 0, 0.5, 0)
            outlineFrame.BackgroundColor3 = Color3.new(1, 0, 0)
            outlineFrame.BorderSizePixel = 0
            outlineFrame.BackgroundTransparency = 0.75
            outlineFrame.Parent = surfaceGui
        end
    end
end

local function createESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    if head:FindFirstChild("ESP") then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Adornee = head
    billboardGui.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 15
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Text = player.Name
    nameLabel.Parent = billboardGui

    createSeeThroughOutline(character)
end

local function shouldHideESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local distance = (character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).magnitude
    return distance < espThreshold
end

local function updateESPs()
    if tick() - lastUpdate < espUpdateInterval then return end
    lastUpdate = tick()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if shouldHideESP(player) then
                local esp = character and character:FindFirstChild("Head"):FindFirstChild("ESP")
                if esp then
                    esp:Destroy()
                end

                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local surfaceGui = part:FindFirstChild("Outline")
                        if surfaceGui then
                            surfaceGui:Destroy()
                        end
                    end
                end
            else
                if character and not character:FindFirstChild("Head"):FindFirstChild("ESP") then
                    createESP(player)
                end
            end
        end
    end
end

local function addESPToPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            createESP(player)
        end
    end
end

addESPToPlayers()
RunService.RenderStepped:Connect(updateESPs)
