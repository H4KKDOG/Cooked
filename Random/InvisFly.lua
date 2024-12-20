local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local horizontalSpeed = 175
local verticalSpeed = 75

local bodyVelocity
local InvisCon
local InputCon
local Flying = false
local isInvisible = false
local visibleParts = {}

local function onCharacterAdded(newCharacter)
    local Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
    local HumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    local Character = newCharacter

    visibleParts = {}
    Flying = false
    isInvisible = false

    if InputCon then InputCon:Disconnect() end
    if InvisCon then InvisCon:Disconnect() end

    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency == 0 then
            table.insert(visibleParts, part)
        end
    end

    local function fly()
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(5000, 5000, 5000)
        bodyVelocity.Parent = HumanoidRootPart

        while Flying do
            local moveDirection = Humanoid.MoveDirection

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
            end

            local verticalVelocity = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                verticalVelocity = verticalSpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                verticalVelocity = -verticalSpeed
            end

            bodyVelocity.Velocity = Vector3.new(
                moveDirection.X * horizontalSpeed,
                verticalVelocity,
                moveDirection.Z * horizontalSpeed
            )

            RunService.RenderStepped:Wait()
        end

        task.wait()
        bodyVelocity:Destroy()
    end

    local function Invis()
        isInvisible = true

        InvisCon = RunService.Heartbeat:Connect(function()
            if isInvisible then
                local originalCFrame = HumanoidRootPart.CFrame
                local offsetCFrame = originalCFrame * CFrame.new(0, -100, 0)
                Humanoid.CameraOffset = offsetCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
                HumanoidRootPart.CFrame = offsetCFrame

                RunService.RenderStepped:Wait()

                Humanoid.CameraOffset = Vector3.new()
                HumanoidRootPart.CFrame = originalCFrame
            end

            task.wait()
        end)
    end

    local function unInvis()
        isInvisible = false

        if InvisCon then
            InvisCon:Disconnect()
            InvisCon = nil
        end
    end

    InputCon = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.X then
                Flying = not Flying

                for _, part in pairs(visibleParts) do
                    part.Transparency = part.Transparency == 0 and 0.5 or 0
                end

                if Flying then
                    Invis()
                    fly()
                else
                    unInvis()
                end
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
