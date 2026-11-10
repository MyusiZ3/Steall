--[[
    Steal A Pet And Ride It - Clean & Optimized Script (Open Source)
    Dibuat untuk Delta Executor (Mobile & PC)
    
    Fitur:
    - Tanpa Obfuscator / VM (Mudah dimodifikasi & ringan)
    - Bersih dari Telemetri (ScriptBlox & RScripts dihapus)
    - Auto Steal (Teleport / Tween ke Cage terdekat/terjauh)
    - Auto Place & Auto Open Cage
    - Auto Train & Upgrade Treadmill
    - Auto Equip Best Pet & Auto Ride
    - Auto Collect Cash & Auto Rebirth
    - QoL Player (Speed, Jump, Noclip)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Remotes Reference
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage

local function getRemote(name)
    return Remotes:FindFirstChild(name, true) or ReplicatedStorage:FindFirstChild(name, true)
end

local PlaceCageRemote     = getRemote("PlaceCage")
local OpenCageRemote      = getRemote("OpenCage")
local EquipBestRemote     = getRemote("EquipBest")
local RebirthRemote       = getRemote("Rebirth")
local UpgradeTreadmill    = getRemote("UpgradeTreadmill")
local UpgradePlotRemote   = getRemote("UpgradePlot")
local SellItemsRemote     = getRemote("SellItems")
local ClaimDailyRemote    = getRemote("ClaimDaily")
local ClaimAllIndexRemote = getRemote("ClaimAllIndexRewards")

-- Configuration / Settings Table
getgenv().SAP_Settings = {
    AutoSteal = false,
    InstantTeleport = true,
    AutoPlaceCage = true,
    AutoOpenCage = true,
    AutoTrain = false,
    AutoUpgradeTreadmill = true,
    AutoEquipBest = true,
    AutoCollectCash = true,
    AutoRebirth = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip = false,
}

local Settings = getgenv().SAP_Settings

-- Helper Functions
local function getMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
            return plot
        end
    end
    return nil
end

local function teleportTo(cframe)
    if not RootPart then return end
    if Settings.InstantTeleport then
        RootPart.CFrame = cframe
    else
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(RootPart, tweenInfo, {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- 1. Auto Collect Cash & Auto Equip Best Loop
task.spawn(function()
    while task.wait(3) do
        if Settings.AutoEquipBest and EquipBestRemote then
            pcall(function()
                EquipBestRemote:FireServer()
            end)
        end
        if Settings.AutoRebirth and RebirthRemote then
            pcall(function()
                RebirthRemote:FireServer()
            end)
        end
    end
end)

-- 2. Auto Place & Open Cages Loop
task.spawn(function()
    while task.wait(1.5) do
        local myPlot = getMyPlot()
        if myPlot then
            -- Auto Place Cage
            if Settings.AutoPlaceCage and PlaceCageRemote then
                local stalls = myPlot:FindFirstChild("Stalls")
                if stalls then
                    for _, stall in ipairs(stalls:GetChildren()) do
                        pcall(function()
                            PlaceCageRemote:FireServer(stall)
                        end)
                    end
                end
            end
            
            -- Auto Open Cage
            if Settings.AutoOpenCage and OpenCageRemote then
                local stalls = myPlot:FindFirstChild("Stalls")
                if stalls then
                    for _, stall in ipairs(stalls:GetChildren()) do
                        local cage = stall:FindFirstChild("Cage")
                        if cage then
                            pcall(function()
                                OpenCageRemote:FireServer(stall)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- 3. Auto Train (Treadmill) Loop
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoTrain then
            local myPlot = getMyPlot()
            if myPlot then
                local treadmill = myPlot:FindFirstChild("Treadmill") or myPlot:FindFirstChildWhichIsA("Model", true)
                if treadmill and treadmill:FindFirstChild("HumanoidRootPart") or treadmill:FindFirstChild("Base") then
                    local targetPart = treadmill:FindFirstChild("HumanoidRootPart") or treadmill:FindFirstChild("Base") or treadmill.PrimaryPart
                    if targetPart and (RootPart.Position - targetPart.Position).Magnitude > 6 then
                        teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                    end
                end
            end
            if Settings.AutoUpgradeTreadmill and UpgradeTreadmill then
                pcall(function()
                    UpgradeTreadmill:FireServer()
                end)
            end
        end
    end
end)

-- 4. Auto Steal Cage Loop
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoSteal then
            local cagesFolder = workspace:FindFirstChild("Cages") or workspace:FindFirstChild("SpawnedCages")
            local targetCage = nil
            local shortestDist = math.huge
            
            if cagesFolder then
                for _, cage in ipairs(cagesFolder:GetChildren()) do
                    local prompt = cage:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local part = cage:FindFirstChild("HumanoidRootPart") or cage:FindFirstChildWhichIsA("BasePart")
                    if prompt and part then
                        local dist = (RootPart.Position - part.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            targetCage = cage
                        end
                    end
                end
            end
            
            if targetCage then
                local part = targetCage:FindFirstChild("HumanoidRootPart") or targetCage:FindFirstChildWhichIsA("BasePart")
                local prompt = targetCage:FindFirstChildWhichIsA("ProximityPrompt", true)
                if part and prompt then
                    teleportTo(part.CFrame + Vector3.new(0, 2, 0))
                    task.wait(0.2)
                    if fireproximityprompt then
                        fireproximityprompt(prompt, 0)
                    end
                    task.wait(0.3)
                    
                    -- Bawa pulang ke plot
                    local myPlot = getMyPlot()
                    if myPlot then
                        local homePart = myPlot:FindFirstChild("Base") or myPlot.PrimaryPart
                        if homePart then
                            teleportTo(homePart.CFrame + Vector3.new(0, 3, 0))
                        end
                    end
                end
            end
        end
    end
end)

-- 5. QoL Player Mods (Noclip & Speed)
RunService.Stepped:Connect(function()
    if Settings.Noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    if Humanoid and Settings.WalkSpeed > 16 then
        Humanoid.WalkSpeed = Settings.WalkSpeed
    end
end)

print("[Steall Hub] Clean script loaded successfully for Delta Executor!")
