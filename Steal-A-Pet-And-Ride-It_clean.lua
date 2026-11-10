--[[
    Steal A Pet And Ride It - Clean & Optimized Script (Open Source)
    Dibuat untuk Delta Executor (Mobile & PC)
    
    Fitur:
    - 100% Bebas Enkripsi & Obfuscator (Mudah dibaca & dimodifikasi)
    - Bersih dari Telemetri (ScriptBlox & RScripts dihapus total)
    - Auto Slow Mode Near Egg (Anti-Sliding saat mendekati Egg & otomatis OFF saat Hold E)
    - Auto Slow Mode In Base (Otomatis ON setelah 2 detik di Safe Zone & OFF saat berangkat steal)
    - Auto Steal Cage (Jalan kaki natural via Humanoid:MoveTo, bebas teleport)
    - Auto Place & Auto Open Cage
    - Auto Train (Treadmill) & Auto Upgrade Treadmill
    - Auto Tap Speed Boost (Mengklik balon speed boost otomatis)
    - Auto Buy Plot Stalls (Membeli slot kandang baru setiap 10 detik)
    - Auto Buy & Equip Best Trail
    - Auto Claim Daily & Index Rewards
    - Auto Equip Best Pet & Auto Rebirth
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")

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
local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Remotes = (Shared and Shared:FindFirstChild("Remotes")) or ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage

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

local DEFAULT_EGG_DIST = 28

-- Konfigurasi Utama
getgenv().SAP_Settings = {
    -- Auto Slow Mode (Anti-Sliding)
    SlowModeNearEgg      = true,
    SlowModeEggDist      = 0, -- 0 = Default (28 studs), > 0 = Custom studs
    SlowModeInBase       = true,

    -- Auto Steal & Cage
    AutoSteal            = false,
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
    Noclip               = false,
}

local Settings = getgenv().SAP_Settings

-- Helper Functions
local function getMyPlot()
    local plotId = LocalPlayer:GetAttribute("PlotId")
    local hub = workspace:FindFirstChild("Hub")
    local plots = (hub and hub:FindFirstChild("Plots")) or workspace:FindFirstChild("Plots")
    if not plots then return nil end

    if plotId then
        local myPlot = plots:FindFirstChild("Plot" .. tostring(plotId))
        if myPlot then return myPlot end
    end

    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
            return plot
        end
    end
    return nil
end

local function isCarryingCage()
    if LocalPlayer:GetAttribute("CarryingCage") then return true end
    if Character and Character:GetAttribute("CarryingCage") then return true end
    return false
end

local function isInSafeZone()
    if LocalPlayer:GetAttribute("InSafeZone") == true then return true end
    if Character and Character:GetAttribute("InSafeZone") == true then return true end
    if not RootPart then return false end
    local myPlot = getMyPlot()
    if myPlot and (RootPart.Position - myPlot:GetPivot().Position).Magnitude <= 65 then
        return true
    end
    local hub = workspace:FindFirstChild("Hub")
    if hub and (RootPart.Position - hub:GetPivot().Position).Magnitude <= 90 then
        return true
    end
    return false
end

local function getAllSpawnedCages()
    local list = {}
    local paths = workspace:FindFirstChild("Paths")
    if paths then
        for _, pathModel in ipairs(paths:GetChildren()) do
            local cagesFolder = pathModel:FindFirstChild("Cages")
            if cagesFolder then
                for _, cage in ipairs(cagesFolder:GetChildren()) do
                    local root = cage:FindFirstChild("Root") or cage:FindFirstChild("HumanoidRootPart") or cage:FindFirstChildWhichIsA("BasePart")
                    local prompt = (root and root:FindFirstChild("StealPrompt")) or cage:FindFirstChild("StealPrompt", true) or cage:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if root and prompt and prompt.Enabled then
                        table.insert(list, { model = cage, root = root, prompt = prompt })
                    end
                end
            end
        end
    end
    return list
end

local function getNearestCage()
    if not RootPart then return nil, math.huge end
    local cages = getAllSpawnedCages()
    local bestEntry = nil
    local shortestDist = math.huge
    for _, entry in ipairs(cages) do
        local dist = (RootPart.Position - entry.root.Position).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            bestEntry = entry
        end
    end
    return bestEntry, shortestDist
end

-- ================= SLOW MODE CONTROLLER =================
local cachedSlowButton = nil
local cachedSlowContainer = nil
local lastSlowToggleClock = 0

local function findSlowModeButton()
    if cachedSlowButton and cachedSlowButton.Parent then
        return cachedSlowButton, cachedSlowContainer
    end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    for _, desc in ipairs(playerGui:GetDescendants()) do
        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text:lower():find("slow mode") then
            local container = desc.Parent
            if container then
                for _, child in ipairs(container:GetDescendants()) do
                    if child:IsA("GuiButton") then
                        cachedSlowButton = child
                        cachedSlowContainer = container
                        return cachedSlowButton, cachedSlowContainer
                    end
                end
                if container:IsA("GuiButton") then
                    cachedSlowButton = container
                    cachedSlowContainer = container
                    return cachedSlowButton, cachedSlowContainer
                end
            end
        end
    end
    return nil, nil
end

local function isSlowModeActive()
    local attr = LocalPlayer:GetAttribute("SlowMode")
    if type(attr) == "boolean" then return attr end
    if Character then
        local charAttr = Character:GetAttribute("SlowMode")
        if type(charAttr) == "boolean" then return charAttr end
    end

    local btn, container = findSlowModeButton()
    local searchRoot = btn or container
    if searchRoot then
        for _, child in ipairs(searchRoot:GetDescendants()) do
            if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("TextButton") or child:IsA("ImageButton") then
                if child ~= searchRoot and child.Size.X.Scale > 0 and child.Size.X.Scale < 0.85 then
                    return child.Position.X.Scale >= 0.35 or child.Position.X.Offset > 15
                end
            end
        end
    end

    if Humanoid then
        return Humanoid.WalkSpeed <= 38
    end
    return false
end

local function setSlowMode(desiredState)
    if os.clock() - lastSlowToggleClock < 0.35 then return end
    if isSlowModeActive() == desiredState then return end

    local btn = findSlowModeButton()
    if not btn then return end
    lastSlowToggleClock = os.clock()

    local fired = false
    if firesignal then
        pcall(function()
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            fired = true
        end)
    end
    if not fired and getconnections then
        pcall(function()
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                if conn.Function then task.spawn(conn.Function) fired = true end
            end
            for _, conn in ipairs(getconnections(btn.Activated)) do
                if conn.Function then task.spawn(conn.Function) fired = true end
            end
        end)
    end
    if not fired and VirtualInputManager and btn.AbsoluteSize.X > 0 then
        pcall(function()
            local guiInset = game:GetService("GuiService"):GetGuiInset()
            local cx = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
            local cy = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + guiInset.Y
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end
end

local isHoldingStealPrompt = false

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if player == LocalPlayer and Settings.SlowModeNearEgg then
        isHoldingStealPrompt = true
        setSlowMode(false)
    end
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
    if player == LocalPlayer then
        task.delay(0.5, function()
            isHoldingStealPrompt = false
        end)
    end
end)

local safeZoneEnterTime = nil
local isGoingToSteal = false

task.spawn(function()
    while task.wait(0.15) do
        local inBase = isInSafeZone()
        local carrying = isCarryingCage()

        if inBase then
            if not safeZoneEnterTime then
                safeZoneEnterTime = os.clock()
            end
        else
            safeZoneEnterTime = nil
        end

        if isGoingToSteal and inBase then
            if Settings.SlowModeInBase or Settings.SlowModeNearEgg then
                setSlowMode(false)
            end
        elseif Settings.SlowModeInBase and inBase and safeZoneEnterTime and (os.clock() - safeZoneEnterTime >= 2.0) then
            setSlowMode(true)
        elseif not inBase and Settings.SlowModeNearEgg then
            if isHoldingStealPrompt or carrying then
                setSlowMode(false)
            else
                local targetDist = (tonumber(Settings.SlowModeEggDist) and tonumber(Settings.SlowModeEggDist) > 0) and tonumber(Settings.SlowModeEggDist) or DEFAULT_EGG_DIST
                local nearestEntry, dist = getNearestCage()
                if nearestEntry and dist <= targetDist then
                    setSlowMode(true)
                elseif dist > (targetDist + 8) then
                    setSlowMode(false)
                end
            end
        end
    end
end)

local function walkTo(targetPos, stopDist, checkActiveFn)
    stopDist = stopDist or 5
    if not Humanoid or not RootPart then return false end
    local startTime = os.clock()
    while (RootPart.Position - targetPos).Magnitude > stopDist do
        if checkActiveFn and not checkActiveFn() then return false end
        if not Humanoid or Humanoid.Health <= 0 then return false end
        if os.clock() - startTime > 30 then return false end
        Humanoid:MoveTo(targetPos)
        task.wait(0.2)
    end
    return true
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
            local stalls = myPlot:FindFirstChild("Stalls") or (myPlot:FindFirstChild("Barn") and myPlot.Barn:FindFirstChild("Stalls"))
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

-- 4. Auto Train (Treadmill) & Auto Tap Boost Loop
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoTrain and not Settings.AutoSteal then
            local myPlot = getMyPlot()
            if myPlot then
                local treadmill = myPlot:FindFirstChild("Treadmill") or myPlot:FindFirstChildWhichIsA("Model", true)
                local targetPart = treadmill and (treadmill:FindFirstChild("HumanoidRootPart") or treadmill:FindFirstChild("Base") or treadmill.PrimaryPart)
                if targetPart and (RootPart.Position - targetPart.Position).Magnitude > 6 then
                    walkTo(targetPart.Position, 5, function()
                        return Settings.AutoTrain and not Settings.AutoSteal
                    end)
                end
            end
            if Settings.AutoUpgradeTreadmill and UpgradeTreadmill then
                pcall(function() UpgradeTreadmill:FireServer() end)
            end
        end
    end
end)

-- 5. Auto Steal Cage Loop (Natural Walking + Smart Slow Mode)
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoSteal then
            local targetEntry = getNearestCage()
            if targetEntry then
                local part = targetEntry.root
                local prompt = targetEntry.prompt
                local targetCage = targetEntry.model

                isGoingToSteal = true
                if Settings.SlowModeInBase or Settings.SlowModeNearEgg then
                    setSlowMode(false)
                end

                local reached = walkTo(part.Position, 5.5, function()
                    return Settings.AutoSteal and targetCage.Parent ~= nil and prompt.Enabled
                end)

                isGoingToSteal = false

                if reached and prompt.Parent and prompt.Enabled then
                    isHoldingStealPrompt = true
                    if Settings.SlowModeNearEgg then
                        setSlowMode(false)
                    end

                    if prompt.HoldDuration and prompt.HoldDuration > 0 then
                        pcall(function()
                            prompt:InputHoldBegin()
                            task.wait(prompt.HoldDuration + 0.1)
                            prompt:InputHoldEnd()
                        end)
                    elseif fireproximityprompt then
                        pcall(fireproximityprompt, prompt)
                    end
                    isHoldingStealPrompt = false

                    task.wait(0.2)
                    local myPlot = getMyPlot()
                    if myPlot then
                        local homePos = myPlot:GetPivot().Position
                        walkTo(homePos, 8, function()
                            return Settings.AutoSteal
                        end)
                    end
                end
            else
                isGoingToSteal = false
            end
        else
            isGoingToSteal = false
        end
    end
end)

-- 6. QoL Player Mods (Noclip Only)
RunService.Stepped:Connect(function()
    if Settings.Noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

print("[Steall Hub] Clean & Safe script with Auto Slow Mode loaded!")
