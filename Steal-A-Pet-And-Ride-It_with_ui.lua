--[[
    Steal A Pet And Ride It - Clean Script with GUI
    Khusus untuk Delta Executor (Mobile & PC)
]]

local UI_URL = "https://raw.githubusercontent.com/csgo1compte-cloud/RayVoidUi/refs/heads/main/RayVoid"
local okUi, Ui = pcall(function()
    return loadstring(game:HttpGet(UI_URL))()
end)

if not okUi or not Ui then
    warn("[Steall] Gagal memuat UI Library, menjalankan script mode background.")
    return
end

local Window = Ui:CreateWindow({
    Name = "Steal a Pet & Ride It",
    LoadingTitle = "Steall Hub",
    LoadingSubtitle = "Delta Executor Edition",
    ConfigurationSaving = { Enabled = true, FolderName = "SteallHub", FileName = "config" },
})

-- Load Script Core
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

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
local ClaimDailyRemote    = getRemote("ClaimDaily")
local ClaimAllIndexRemote = getRemote("ClaimAllIndexRewards")
local ChampionClaimRemote = getRemote("ChampionClaim")
local BuyTrailRemote      = getRemote("BuyTrail")
local EquipTrailRemote    = getRemote("EquipTrail")

getgenv().SAP_Settings = {
    AutoSteal            = false,
    InstantTeleport      = true,
    AutoPlaceCage        = true,
    AutoOpenCage         = true,
    AutoTrain            = false,
    AutoUpgradeTreadmill = true,
    AutoTapBoost         = true,
    AutoBuyStalls        = true,
    AutoTrail            = true,
    AutoEquipBest        = true,
    AutoClaimRewards     = true,
    AutoRebirth          = false,
    WalkSpeed            = 16,
    Noclip               = false,
}

local Settings = getgenv().SAP_Settings

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
        local tween = TweenService:Create(RootPart, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- ================= LOOPS =================

-- 1. Claims & Best Pets
task.spawn(function()
    while task.wait(5) do
        if Settings.AutoEquipBest and EquipBestRemote then
            pcall(function() EquipBestRemote:FireServer() end)
        end
        if Settings.AutoClaimRewards then
            pcall(function()
                if ClaimDailyRemote then ClaimDailyRemote:FireServer() end
                if ClaimAllIndexRemote then ClaimAllIndexRemote:FireServer() end
                if ChampionClaimRemote then ChampionClaimRemote:FireServer() end
            end)
        end
        if Settings.AutoRebirth and RebirthRemote then
            pcall(function() RebirthRemote:FireServer() end)
        end
    end
end)

-- 2. Buy Stalls & Trails
task.spawn(function()
    while task.wait(10) do
        if Settings.AutoBuyStalls and UpgradePlotRemote then
            pcall(function() UpgradePlotRemote:FireServer() end)
        end
        if Settings.AutoTrail and BuyTrailRemote then
            pcall(function()
                BuyTrailRemote:FireServer()
                if EquipTrailRemote then EquipTrailRemote:FireServer() end
            end)
        end
    end
end)

-- 3. Cages Loop
task.spawn(function()
    while task.wait(1.5) do
        local myPlot = getMyPlot()
        if myPlot then
            local stalls = myPlot:FindFirstChild("Stalls")
            if stalls then
                for _, stall in ipairs(stalls:GetChildren()) do
                    if Settings.AutoPlaceCage and PlaceCageRemote then
                        pcall(function() PlaceCageRemote:FireServer(stall) end)
                    end
                    if Settings.AutoOpenCage and OpenCageRemote then
                        if stall:FindFirstChild("Cage") then
                            pcall(function() OpenCageRemote:FireServer(stall) end)
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Train (Treadmill) Loop
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoTrain then
            local myPlot = getMyPlot()
            if myPlot then
                local treadmill = myPlot:FindFirstChild("Treadmill") or myPlot:FindFirstChildWhichIsA("Model", true)
                local targetPart = treadmill and (treadmill:FindFirstChild("HumanoidRootPart") or treadmill:FindFirstChild("Base") or treadmill.PrimaryPart)
                if targetPart and (RootPart.Position - targetPart.Position).Magnitude > 6 then
                    teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                end
            end
            if Settings.AutoUpgradeTreadmill and UpgradeTreadmill then
                pcall(function() UpgradeTreadmill:FireServer() end)
            end
        end
    end
end)

-- 5. Steal Cage Loop
task.spawn(function()
    while task.wait(0.6) do
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

-- ================= GUI TABS =================
local FarmTab = Window:CreateTab("Auto Farm", "crosshair")

FarmTab:CreateSection("Auto Steal & Cages")
FarmTab:CreateToggle({
    Name = "Auto Steal Cage",
    CurrentValue = false,
    Callback = function(v) Settings.AutoSteal = v end,
})
FarmTab:CreateToggle({
    Name = "Instant Teleport (Fast Steal)",
    CurrentValue = true,
    Callback = function(v) Settings.InstantTeleport = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Place Cage",
    CurrentValue = true,
    Callback = function(v) Settings.AutoPlaceCage = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Open Cage",
    CurrentValue = true,
    Callback = function(v) Settings.AutoOpenCage = v end,
})

FarmTab:CreateSection("Training (Treadmill)")
FarmTab:CreateToggle({
    Name = "Auto Train (Treadmill)",
    CurrentValue = false,
    Callback = function(v) Settings.AutoTrain = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Upgrade Treadmill",
    CurrentValue = true,
    Callback = function(v) Settings.AutoUpgradeTreadmill = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Tap Boost",
    CurrentValue = true,
    Callback = function(v) Settings.AutoTapBoost = v end,
})

local UpgradeTab = Window:CreateTab("Auto Upgrades", "arrow-up-circle")
UpgradeTab:CreateSection("Auto Buy & Claims")
UpgradeTab:CreateToggle({
    Name = "Auto Buy Plot Stalls (Every 10s)",
    CurrentValue = true,
    Callback = function(v) Settings.AutoBuyStalls = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Buy Best Trail",
    CurrentValue = true,
    Callback = function(v) Settings.AutoTrail = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Claim Daily & Index Rewards",
    CurrentValue = true,
    Callback = function(v) Settings.AutoClaimRewards = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Equip Best Pets",
    CurrentValue = true,
    Callback = function(v) Settings.AutoEquipBest = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Callback = function(v) Settings.AutoRebirth = v end,
})

local PlayerTab = Window:CreateTab("Player Mods", "user")
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) Settings.WalkSpeed = v end,
})
PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Settings.Noclip = v end,
})

Ui:Notify({
    Title = "Steall Hub Loaded",
    Content = "Clean & Modified Script siap digunakan di Delta!",
    Duration = 5,
})
