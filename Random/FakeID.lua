-- Global Configuration
if not getgenv().Config then
    getgenv().Config = {
        Headless = true,
        FakeName = "SayPanXD",
        FakeId = 1235931594,
    }
end

-- Services
local players = game:GetService('Players')
local runService = game:GetService("RunService")

-- Local Player Info
local lp = players.LocalPlayer
local oldUserId = tostring(lp.UserId)
local oldName = lp.Name

-- Functions
local function processtext(text)
    if not text then return '' end
    text = string.gsub(text, oldName, Config.FakeName)
    text = string.gsub(text, oldUserId, Config.FakeId)
    return text
end

-- Updates a UI object (TextBox, TextLabel, TextButton)
local function updateTextObject(obj)
    obj.Text = processtext(obj.Text)
    obj.Name = processtext(obj.Name)
end

-- Handles text updates for existing and new UI elements
local function monitorUIText()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("TextBox") or v:IsA("TextLabel") or v:IsA("TextButton") then
            updateTextObject(v)
            v.Changed:Connect(function()
                updateTextObject(v)
            end)
        end
    end

    game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("TextBox") or descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            updateTextObject(descendant)
            descendant.Changed:Connect(function()
                updateTextObject(descendant)
            end)
        end
    end)
end

-- Disguises the player's character
local function disguisechar(char, id)
    task.spawn(function()
        if not char then return end

        local hum = char:FindFirstChildOfClass('Humanoid')
        local desc
        repeat
            local success = pcall(function()
                desc = players:GetHumanoidDescriptionFromUserId(id)
            end)
            task.wait()
        until success

        desc.HeightScale = hum:WaitForChild("HumanoidDescription").HeightScale

        -- Clone and apply disguise
        local disguiseclone = char:Clone()
        disguiseclone.Name = "disguisechar"
        disguiseclone.Parent = workspace

        -- Remove unnecessary items from clone
        for _, v in pairs(disguiseclone:GetChildren()) do
            if v:IsA("Accessory") or v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") then
                v:Destroy()
            end
        end

        disguiseclone.Humanoid:ApplyDescriptionClientServer(desc)

        -- Process character's children
        for _, v in pairs(char:GetChildren()) do
            if (v:IsA("Accessory") and not v:GetAttribute("InvItem") and not v:GetAttribute("ArmorSlot")) or
               v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                v.Parent = game
            end
        end

        -- Handle animations
        for _, v in pairs(disguiseclone:WaitForChild("Animate"):GetChildren()) do
            v:SetAttribute("Disguise", true)
            local real = char.Animate:FindFirstChild(v.Name)
            if v:IsA("StringValue") and real then
                real.Parent = game
                v.Parent = char.Animate
            end
        end

        -- Apply disguise items to character
        for _, v in pairs(disguiseclone:GetChildren()) do
            v:SetAttribute("Disguise", true)
            if v:IsA("Accessory") then
                for _, v2 in pairs(v:GetDescendants()) do
                    if v2:IsA("Weld") and v2.Part1 then
                        v2.Part1 = char[v2.Part1.Name]
                    end
                end
                v.Parent = char
            elseif v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                v.Parent = char
            elseif v.Name == "Head" and v:FindFirstChildOfClass('SpecialMesh') then
                char.Head:FindFirstChildOfClass('SpecialMesh').MeshId = v:FindFirstChildOfClass('SpecialMesh').MeshId
            end
        end

        -- Apply face adjustments
        local localface = char:FindFirstChild("face", true)
        local cloneface = disguiseclone:FindFirstChild("face", true)
        if localface and cloneface then
            localface.Parent = game
            cloneface.Parent = char.Head
        end

        disguiseclone:Destroy()
    end)
end

-- Makes the player's character headless
local function makeHeadless()
    task.spawn(function()
        while runService.RenderStepped:Wait() do
            pcall(function()
                local char = lp.Character or lp.CharacterAdded:Wait()
                local head = char:WaitForChild("Head")
                head.Transparency = 1
                local face = head:FindFirstChildOfClass("Decal")
                if face then face:Destroy() end
            end)
        end
    end)
end

-- Initialization

lp.CharacterAppearanceId = Config.FakeId
monitorUIText()

if Config.Headless then
    makeHeadless()
end

pcall(function()
    disguisechar(lp.Character, Config.FakeId)
end)

lp.CharacterAdded:Connect(function()
    disguisechar(lp.Character, Config.FakeId)
end)
