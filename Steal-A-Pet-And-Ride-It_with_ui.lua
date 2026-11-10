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

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- Remotes Reference (Sesuai struktur asli ReplicatedStorage.Shared.Remotes)
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
local ClaimDailyRemote    = getRemote("ClaimDaily")
local ClaimAllIndexRemote = getRemote("ClaimAllIndexRewards")
local ChampionClaimRemote = getRemote("ChampionClaim")
local BuyTrailRemote      = getRemote("BuyTrail")
local EquipTrailRemote    = getRemote("EquipTrail")

local DEFAULT_EGG_DIST = 28

getgenv().SAP_Settings = {
    AutoSteal            = false,
    AutoPlaceCage        = true,
    AutoOpenCage         = true,
    SlowModeNearEgg      = true,
    SlowModeEggDist      = 0, -- 0 = Default (28 studs), > 0 = Custom studs
    SlowModeInBase       = true,
    AutoTrain            = false,
    AutoUpgradeTreadmill = true,
    AutoTapBoost         = true,
    AutoBuyStalls        = true,
    AutoTrail            = true,
    AutoEquipBest        = true,
    AutoClaimRewards     = true,
    AutoRebirth          = false,
    Noclip               = false,
}

local Settings = getgenv().SAP_Settings

local function getEffectiveEggDist()
    local val = tonumber(Settings.SlowModeEggDist) or 0
    if val <= 0 then
        return DEFAULT_EGG_DIST
    end
    return val
end

-- ================= GAME HELPERS =================

-- Mendapatkan Plot milik pemain (Sesuai struktur workspace.Hub.Plots.Plot{PlotId})
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
        if plot:GetAttribute("Owner") == LocalPlayer.Name or plot:GetAttribute("OwnerId") == LocalPlayer.UserId then
            return plot
        end
    end
    return nil
end

-- Mengecek apakah pemain sedang membawa Cage/Egg
local function isCarryingCage()
    if LocalPlayer:GetAttribute("CarryingCage") then return true end
    if Character and Character:GetAttribute("CarryingCage") then return true end
    return false
end

-- Mengecek apakah pemain berada di Safe Zone / Base
local function isInSafeZone()
    if LocalPlayer:GetAttribute("InSafeZone") == true then return true end
    if Character and Character:GetAttribute("InSafeZone") == true then return true end

    if not RootPart then return false end
    local myPlot = getMyPlot()
    if myPlot then
        local plotPos = myPlot:GetPivot().Position
        if (RootPart.Position - plotPos).Magnitude <= 65 then
            return true
        end
    end
    local hub = workspace:FindFirstChild("Hub")
    if hub then
        local hubPos = hub:GetPivot().Position
        if (RootPart.Position - hubPos).Magnitude <= 90 then
            return true
        end
    end
    return false
end

-- Mencari semua Cage/Egg yang aktif di semua Path (workspace.Paths.PathX.Cages)
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
    -- Fallback jika ada folder Cages langsung di workspace
    local fallbackFolder = workspace:FindFirstChild("Cages") or workspace:FindFirstChild("SpawnedCages")
    if fallbackFolder then
        for _, cage in ipairs(fallbackFolder:GetChildren()) do
            local root = cage:FindFirstChild("Root") or cage:FindFirstChildWhichIsA("BasePart")
            local prompt = cage:FindFirstChildWhichIsA("ProximityPrompt", true)
            if root and prompt and prompt.Enabled then
                table.insert(list, { model = cage, root = root, prompt = prompt })
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

-- Mencari tombol "Slow Mode" bawaan game di PlayerGui
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
                -- Cari GuiButton di dalam container yang sama (tombol switch di sebelah kiri label Slow Mode)
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
                if container.Parent and container.Parent:IsA("GuiButton") then
                    cachedSlowButton = container.Parent
                    cachedSlowContainer = container.Parent
                    return cachedSlowButton, cachedSlowContainer
                end
            end
        end
    end
    return nil, nil
end

-- Mengecek apakah Slow Mode di game sedang ON atau OFF
local function isSlowModeActive()
    -- 1. Cek Attribute jika game menyimpannya di LocalPlayer / Character
    local attr = LocalPlayer:GetAttribute("SlowMode")
    if type(attr) == "boolean" then return attr end
    if Character then
        local charAttr = Character:GetAttribute("SlowMode")
        if type(charAttr) == "boolean" then return charAttr end
    end

    -- 2. Cek posisi knob biru di dalam tombol Slow Mode UI
    -- Saat OFF: knob biru berada di sebelah kiri (Position.X.Scale < 0.35)
    -- Saat ON: knob biru bergeser ke sebelah kanan (Position.X.Scale >= 0.35)
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

    -- 3. Fallback dari WalkSpeed aktual karakter (ketika punya speed tinggi, Slow Mode menurunkan WalkSpeed)
    if Humanoid then
        return Humanoid.WalkSpeed <= 38
    end
    return false
end

-- Menekan tombol Slow Mode bawaan game tanpa memodifikasi WalkSpeed secara paksa
local function setSlowMode(desiredState)
    if os.clock() - lastSlowToggleClock < 0.35 then return end
    local currentState = isSlowModeActive()
    if currentState == desiredState then return end

    local btn = findSlowModeButton()
    if not btn then return end

    lastSlowToggleClock = os.clock()

    -- Metode 1: firesignal (standar di Delta Executor)
    local fired = false
    if firesignal then
        pcall(function()
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            fired = true
        end)
    end

    -- Metode 2: getconnections (jika firesignal tidak memicu handler)
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

    -- Metode 3: VirtualInputManager (klik koordinat tombol di layar)
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

-- Event Listener: Begitu player mulai Hold E (ambil egg/cage), langsung matikan Slow Mode!
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

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and Settings.SlowModeNearEgg then
        setSlowMode(false)
    end
end)

-- Loop Pemantau Otomatis Slow Mode (Near Egg & In Base 2 Detik)
local safeZoneEnterTime = nil
local isGoingToSteal = false

task.spawn(function()
    while task.wait(0.15) do
        local inBase = isInSafeZone()
        local carrying = isCarryingCage()

        -- 1. Logika Slow Mode saat di Base / Safe Zone (Deteksi 2 Detik)
        if inBase then
            if not safeZoneEnterTime then
                safeZoneEnterTime = os.clock()
            end
        else
            safeZoneEnterTime = nil
        end

        -- Jika sedang mau berangkat Steal Egg keluar base -> Matikan Slow Mode!
        if isGoingToSteal and inBase then
            if Settings.SlowModeInBase or Settings.SlowModeNearEgg then
                setSlowMode(false)
            end
        -- Jika berada di Safe Zone >= 2 detik dan tidak sedang mau berangkat steal -> Aktifkan Slow Mode!
        elseif Settings.SlowModeInBase and inBase and safeZoneEnterTime and (os.clock() - safeZoneEnterTime >= 2.0) then
            setSlowMode(true)
        -- 2. Logika Slow Mode saat di luar Base (Mendekati Egg vs Kabur Bawa Egg)
        elseif not inBase and Settings.SlowModeNearEgg then
            -- Jika sedang Hold E atau sudah membawa Cage -> Matikan Slow Mode agar tidak kena monster!
            if isHoldingStealPrompt or carrying then
                setSlowMode(false)
            else
                -- Cek jarak ke Egg terdekat (0 = Default 28 studs)
                local targetDist = getEffectiveEggDist()
                local nearestEntry, dist = getNearestCage()
                if nearestEntry and dist <= targetDist then
                    -- Sudah dekat dengan Egg -> Aktifkan Slow Mode agar tidak terpeleset (sliding)!
                    setSlowMode(true)
                elseif dist > (targetDist + 8) then
                    -- Masih jauh dari Egg -> Pastikan Slow Mode mati agar lari kencang
                    setSlowMode(false)
                end
            end
        end
    end
end)

-- Berjalan kaki secara natural menggunakan Humanoid:MoveTo (tanpa teleport)
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

-- 4. Train (Treadmill) Loop
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

-- 5. Steal Cage Loop (Walks to cage, activates Slow Mode near cage, turns off Slow Mode on Hold E, walks home)
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoSteal then
            local targetEntry = getNearestCage()
            if targetEntry then
                local part = targetEntry.root
                local prompt = targetEntry.prompt
                local targetCage = targetEntry.model

                -- Tandai bahwa player sedang berangkat mencuri egg (agar Slow Mode di base langsung dimatikan)
                isGoingToSteal = true
                if Settings.SlowModeInBase or Settings.SlowModeNearEgg then
                    setSlowMode(false)
                end

                local reached = walkTo(part.Position, 5.5, function()
                    return Settings.AutoSteal and targetCage.Parent ~= nil and prompt.Enabled
                end)

                isGoingToSteal = false

                if reached and prompt.Parent and prompt.Enabled then
                    -- Begitu mulai Hold E / memicu StealPrompt, langsung matikan Slow Mode!
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

RunService.Stepped:Connect(function()
    if Settings.Noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ================= GUI TABS =================
local FarmTab = Window:CreateTab("Auto Farm", "crosshair")

FarmTab:CreateSection("Auto Slow Mode (Anti-Sliding)")
FarmTab:CreateToggle({
    Name = "Auto Slow Mode Near Egg",
    CurrentValue = true,
    Callback = function(v) Settings.SlowModeNearEgg = v end,
})
FarmTab:CreateSlider({
    Name = "Slow Mode Egg Distance (0 = Default 28)",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v)
        Settings.SlowModeEggDist = tonumber(v) or 0
    end,
})
if FarmTab.CreateInput then
    FarmTab:CreateInput({
        Name = "Custom Egg Studs (0 = Default)",
        PlaceholderText = "0 = Default (28 studs)",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            local num = tonumber(text)
            if num and num >= 0 then
                Settings.SlowModeEggDist = num
            else
                Settings.SlowModeEggDist = 0
            end
        end,
    })
end
FarmTab:CreateToggle({
    Name = "Auto Slow Mode In Base (2s Safe Zone)",
    CurrentValue = true,
    Callback = function(v) Settings.SlowModeInBase = v end,
})

FarmTab:CreateSection("Auto Steal & Cages")
FarmTab:CreateToggle({
    Name = "Auto Steal Cage",
    CurrentValue = false,
    Callback = function(v) Settings.AutoSteal = v end,
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
PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Settings.Noclip = v end,
})

Ui:Notify({
    Title = "Steall Hub Loaded",
    Content = "Fitur Auto Slow Mode (Anti-Sliding) Aktif!",
    Duration = 5,
})
