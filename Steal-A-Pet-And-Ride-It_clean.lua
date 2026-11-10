--[[
    Steal A Pet And Ride It - Clean & Optimized Script (Open Source)
    Dibuat untuk Delta Executor (Mobile & PC)
    
    Fitur:
    - 100% Bebas Enkripsi & Obfuscator (Mudah dibaca & dimodifikasi)
    - Bersih dari Telemetri (ScriptBlox & RScripts dihapus total)
    - Auto Steal Cage (Instant Teleport ke Cage terdekat/terjauh)
    - Auto Place & Auto Open Cage
    - Auto Train (Treadmill) & Auto Upgrade Treadmill
    - Auto Tap Speed Boost (Mengklik balon speed boost otomatis)
    - Auto Buy Plot Stalls (Membeli slot kandang baru setiap 10 detik)
    - Auto Buy & Equip Best Trail
    - Auto Claim Daily & Index Rewards
    - Auto Equip Best Pet & Auto Rebirth
    - QoL Player (WalkSpeed slider & Noclip)
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
local ChampionClaimRemote = getRemote("ChampionClaim")
local BuyTrailRemote      = getRemote("BuyTrail")
local EquipTrailRemote    = getRemote("EquipTrail")

-- Konfigurasi Utama
getgenv().SAP_Settings = {
    -- Auto Steal & Cage
    AutoSteal            = false,
    InstantTeleport      = true,
    AutoPlaceCage        = true,
    AutoOpenCage         = true,
    
    -- Training & Upgrades
    AutoTrain            = false,
    AutoUpgradeTreadmill = true,
    AutoTapBoost         = true,
    AutoBuyStalls        = true,
    AutoTrail            = true,
    
    -- Claims & Pets
    AutoEquipBest        = true,
    AutoClaimRewards     = true,
    AutoRebirth          = false,
    
    -- Player Mods
    WalkSpeed            = 16,
    Noclip               = false,
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
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(RootPart, tweenInfo, {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- 1. Auto Claim (Daily, Index, Champion) & Auto Equip Best Loop
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

-- 2. Auto Buy Stalls & Auto Buy Trails Loop
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

-- 3. Auto Place & Open Cages Loop
task.spawn(function()
    while task.wait(1.5) do
        local myPlot = getMyPlot()
        if myPlot then
            local stalls = myPlot:FindFirstChild("Stalls")
            if stalls then
                for _, stall in ipairs(stalls:GetChildren()) do
                    -- Place Cage
                    if Settings.AutoPlaceCage and PlaceCageRemote then
                        pcall(function() PlaceCageRemote:FireServer(stall) end)
                    end
                    -- Open Cage
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

-- 4. Auto Train (Treadmill) & Auto Tap Boost Loop
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

-- Auto Tap Boost (Mengklik gelembung boost kecepatan saat latihan)
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoTapBoost and Settings.AutoTrain then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetDescendants()) do
                    if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                        if gui.Name:lower():find("boost") or gui.Name:lower():find("tap") or gui.Name:lower():find("bubble") then
                            if gui.Visible then
                                pcall(function()
                                    gui.Position = UDim2.new(0.5, 0, 0.5, 0)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 5. Auto Steal Cage Loop
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
                    
                    -- Bawa pulang langsung ke plot
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

-- 6. QoL Player Mods (Noclip & Speed)
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
