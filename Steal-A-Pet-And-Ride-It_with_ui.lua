--[[
    Steal A Pet And Ride It - Clean Script with GUI
    Khusus untuk Delta Executor (Mobile & PC)
]]

local UI_URL = "https://raw.githubusercontent.com/csgo1compte-cloud/RayVoid/refs/heads/main/AirFlow"
local okUi, Ui = pcall(function()
    return loadstring(game:HttpGet(UI_URL))()
end)

if not okUi or not Ui then
    warn("[Steall] Gagal memuat AirFlow UI Library.")
    return
end

pcall(function()
    if Ui.SetScriptName then Ui:SetScriptName("Steal a Pet and Ride It") end
end)

local Window = Ui:CreateWindow({
    Name = "Steal a Pet & Ride It | Steall Hub",
    Subtitle = "Clean Open-Source Edition",
    ToggleUIKeybind = Enum.KeyCode.RightControl,
    OpenButton = { Enabled = true, Title = "Steall" },
    ConfigurationSaving = { Enabled = true, FolderName = "SteallHub", FileName = "StealAPet" },
})

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

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
local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
local Remotes = (Shared and Shared:WaitForChild("Remotes", 5)) or ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage

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
local TapBoostRemote      = getRemote("TapBoost")

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

local function getMyPlot()
    local plotId = LocalPlayer:GetAttribute("PlotId")
    local hub = workspace:FindFirstChild("Hub")
    local plots = (hub and hub:FindFirstChild("Plots")) or workspace:FindFirstChild("Plots")
    if not plots then return nil end

    if plotId then
        local myPlot = plots:FindFirstChild("Plot" .. tostring(plotId))
        if myPlot then return myPlot end
    end
    return nil
end

local function getOwnedStalls()
    local myPlot = getMyPlot()
    if not myPlot then return {} end
    local list = {}
    for _, barnName in ipairs({ "Barn", "Barn2" }) do
        local barn = myPlot:FindFirstChild(barnName)
        local stalls = barn and barn:FindFirstChild("Stalls")
        if stalls then
            for _, s in ipairs(stalls:GetChildren()) do
                if s:GetAttribute("Owned") == true then
                    local idx = tonumber(s:GetAttribute("Index"))
                    local part = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart", true)
                    if idx and part then
                        table.insert(list, { index = idx, part = part, model = s })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end

local function isStallOccupied(stallIndex)
    local petsFolder = LocalPlayer:FindFirstChild("Pets")
    if petsFolder then
        for _, pet in ipairs(petsFolder:GetChildren()) do
            if tonumber(pet:GetAttribute("Stall")) == stallIndex then
                return true
            end
        end
    end
    local cagesFolder = LocalPlayer:FindFirstChild("Cages")
    if cagesFolder then
        for _, cage in ipairs(cagesFolder:GetChildren()) do
            if tonumber(cage:GetAttribute("Stall")) == stallIndex then
                return true
            end
        end
    end
    return false
end

local function getFreeStall()
    for _, entry in ipairs(getOwnedStalls()) do
        if not isStallOccupied(entry.index) then
            return entry
        end
    end
    return nil
end

local function isCarryingCage()
    local attr = LocalPlayer:GetAttribute("CarryingCage")
    if attr ~= nil and attr ~= false and attr ~= "" then return true end
    if Character and Character:GetAttribute("CarryingCage") then return true end
    return false
end

local function equipCarriedCageTool()
    if not Character or not Humanoid then return end
    if Character:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() Humanoid:EquipTool(tool) end)
            task.wait(0.2)
        end
    end
end

local function isInSafeZone()
    if LocalPlayer:GetAttribute("InSafeZone") == true then return true end
    if LocalPlayer:GetAttribute("OnTreadmill") == true then return true end
    if Character and Character:GetAttribute("InSafeZone") == true then return true end

    if not RootPart then return false end
    local myPlot = getMyPlot()
    if myPlot and (RootPart.Position - myPlot:GetPivot().Position).Magnitude <= 75 then
        return true
    end
    local hub = workspace:FindFirstChild("Hub")
    if hub and (RootPart.Position - hub:GetPivot().Position).Magnitude <= 95 then
        return true
    end
    return false
end

local function getAllSpawnedCages()
    local list = {}
    local seenModels = {}

    local function scanContainer(container)
        if not container then return end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Name == "StealPrompt" then
                local rootPart = obj.Parent
                local cageModel = (rootPart and rootPart:FindFirstAncestorOfClass("Model")) or rootPart
                if cageModel and rootPart and rootPart:IsA("BasePart") and not seenModels[cageModel] then
                    seenModels[cageModel] = true
                    local pathModel = cageModel:FindFirstAncestorWhichIsA("Model") or cageModel.Parent
                    table.insert(list, { model = cageModel, root = rootPart, prompt = obj, path = pathModel })
                end
            end
        end
    end

    local paths = workspace:FindFirstChild("Paths")
    if paths then scanContainer(paths) end

    local worlds = workspace:FindFirstChild("Worlds")
    if worlds then scanContainer(worlds) end

    if #list == 0 then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Name == "StealPrompt" then
                local rootPart = desc.Parent
                local cageModel = (rootPart and rootPart:FindFirstAncestorOfClass("Model")) or rootPart
                if cageModel and rootPart and rootPart:IsA("BasePart") and not seenModels[cageModel] then
                    seenModels[cageModel] = true
                    table.insert(list, { model = cageModel, root = rootPart, prompt = desc, path = cageModel.Parent })
                end
            end
        end
    end

    return list
end

-- Mendeteksi telur spesifik yang sedang dituju oleh player (bukan sembarang telur di map)
local function getTargetEgg()
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil, math.huge end

    local allCages = getAllSpawnedCages()
    if #allCages == 0 then return nil, math.huge end

    -- 1. Cek target eksplisit jika diset oleh script AutoSteal
    if getgenv().SAP_CurrentTargetCage and getgenv().SAP_CurrentTargetCage.Parent then
        local targetModel = getgenv().SAP_CurrentTargetCage
        local targetRoot = targetModel:FindFirstChild("Root") or targetModel:FindFirstChildWhichIsA("BasePart")
        if targetRoot then
            local prompt = (targetRoot and targetRoot:FindFirstChild("StealPrompt")) or targetModel:FindFirstChild("StealPrompt", true)
            local dist = (hrp.Position - targetRoot.Position).Magnitude
            return { model = targetModel, root = targetRoot, prompt = prompt }, dist
        end
    end

    -- 2. Cek Humanoid.WalkToPoint (saat script AI bergerak menggunakan Humanoid:MoveTo)
    local walkToPoint = hum.WalkToPoint
    if walkToPoint and walkToPoint.Magnitude > 1 then
        for _, entry in ipairs(allCages) do
            if entry.root and (entry.root.Position - walkToPoint).Magnitude <= 14 then
                local dist = (hrp.Position - entry.root.Position).Magnitude
                return entry, dist
            end
        end
    end

    -- 3. Cek arah jalan karakter (Humanoid.MoveDirection) saat berjalan manual atau script
    local moveDir = hum.MoveDirection
    local isMoving = moveDir.Magnitude > 0.08

    local bestEntry = nil
    local bestDist = math.huge
    local bestScore = -math.huge

    for _, entry in ipairs(allCages) do
        local offset = entry.root.Position - hrp.Position
        local dist = offset.Magnitude

        if isMoving then
            local dir = offset / (dist > 0 and dist or 1)
            local dot = moveDir:Dot(dir)
            -- Hanya telur yang searah di depan pergerakan player (dot > 0.45)
            if dot > 0.45 then
                local score = dot * 100 - dist
                if score > bestScore then
                    bestScore = score
                    bestEntry = entry
                    bestDist = dist
                end
            end
        else
            if dist < bestDist then
                bestDist = dist
                bestEntry = entry
            end
        end
    end

    if bestEntry then
        return bestEntry, bestDist
    end
    return nil, math.huge
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
local IGNORED_GUI_NAMES = {
    AirflowUI = true,
    Rayfield  = true,
    RayVoid   = true,
    SteallHub = true,
}

local cachedWidget = nil

local function findSlowModeWidget()
    if cachedWidget and cachedWidget.label and cachedWidget.label.Parent and cachedWidget.label.AbsoluteSize.X > 5 then
        return cachedWidget
    end

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local labelObj = nil
    local screenGui = nil

    for _, desc in ipairs(playerGui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local sg = desc:FindFirstAncestorOfClass("ScreenGui")
            if not (sg and IGNORED_GUI_NAMES[sg.Name]) then
                local rawText = tostring(desc.Text or "")
                local cleanText = rawText:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
                if cleanText and cleanText:lower() == "slow mode" and desc.Visible and desc.AbsoluteSize.X > 5 then
                    labelObj = desc
                    screenGui = sg or playerGui
                    break
                end
            end
        end
    end

    if not labelObj then
        return nil
    end

    local lblCenterY = labelObj.AbsolutePosition.Y + (labelObj.AbsoluteSize.Y * 0.5)
    local lblLeftX   = labelObj.AbsolutePosition.X

    local rowObjects = {}
    local targets = {}
    local seenTargets = {}

    local function addTarget(obj)
        if obj and not seenTargets[obj] then
            seenTargets[obj] = true
            table.insert(targets, obj)
        end
    end

    local searchRoot = (labelObj.Parent and labelObj.Parent.Parent and labelObj.Parent.Parent.Parent) or screenGui
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible and obj.AbsoluteSize.X >= 8 and obj.AbsoluteSize.Y >= 8 and obj.AbsoluteSize.Y <= 95 then
            local cy = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y * 0.5)
            if math.abs(cy - lblCenterY) <= 32 then
                if obj.AbsolutePosition.X <= lblLeftX + 25 and (obj.AbsolutePosition.X + obj.AbsoluteSize.X) >= (lblLeftX - 220) then
                    table.insert(rowObjects, obj)
                end
            end
        end
    end

    local trackObj = nil
    local bestTrackArea = 0
    for _, obj in ipairs(rowObjects) do
        if obj ~= labelObj and (obj.AbsolutePosition.X + obj.AbsoluteSize.X) <= (lblLeftX + 25) then
            if obj.AbsoluteSize.X >= 24 and obj.AbsoluteSize.X <= 160 and obj.AbsoluteSize.Y >= 14 and obj.AbsoluteSize.Y <= 70 then
                if obj.AbsoluteSize.X >= obj.AbsoluteSize.Y * 1.10 then
                    local area = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
                    if area > bestTrackArea then
                        bestTrackArea = area
                        trackObj = obj
                    end
                end
            end
        end
    end

    local knobObj = nil
    if trackObj then
        for _, obj in ipairs(rowObjects) do
            if obj ~= trackObj and obj ~= labelObj and not obj:IsA("TextLabel") then
                if obj.AbsoluteSize.X >= 8 and obj.AbsoluteSize.X <= (trackObj.AbsoluteSize.X * 0.88) and obj.AbsoluteSize.Y >= 8 and obj.AbsoluteSize.Y <= (trackObj.AbsoluteSize.Y * 1.25) then
                    local kcx = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
                    if kcx >= (trackObj.AbsolutePosition.X - 6) and kcx <= (trackObj.AbsolutePosition.X + trackObj.AbsoluteSize.X + 6) then
                        knobObj = obj
                        break
                    end
                end
            end
        end
    end

    for _, obj in ipairs(rowObjects) do
        if obj:IsA("GuiButton") then addTarget(obj) end
    end
    if trackObj then
        addTarget(trackObj)
        for _, child in ipairs(trackObj:GetDescendants()) do
            if child:IsA("GuiButton") then addTarget(child) end
        end
    end
    if knobObj and knobObj:IsA("GuiButton") then addTarget(knobObj) end
    if labelObj:IsA("GuiButton") then addTarget(labelObj) end

    cachedWidget = {
        label     = labelObj,
        track     = trackObj,
        knob      = knobObj,
        targets   = targets,
        screenGui = screenGui,
    }
    return cachedWidget
end

local function isSlowModeActive()
    local attr = LocalPlayer:GetAttribute("SlowMode")
    if type(attr) == "boolean" then return attr end
    if Character then
        local charAttr = Character:GetAttribute("SlowMode")
        if type(charAttr) == "boolean" then return charAttr end
    end

    local w = findSlowModeWidget()
    if w then
        if w.track and w.track.Parent then
            local bg = w.track.BackgroundColor3
            if bg then
                if bg.G > (bg.R + 0.15) and bg.G > (bg.B + 0.15) then
                    return true
                end
                if math.abs(bg.R - bg.G) < 0.08 and math.abs(bg.G - bg.B) < 0.08 then
                    return false
                end
            end
        end

        if w.track and w.knob and w.track.Parent and w.knob.Parent and w.track.AbsoluteSize.X > 0 then
            local trackCenterX = w.track.AbsolutePosition.X + (w.track.AbsoluteSize.X * 0.5)
            local knobCenterX  = w.knob.AbsolutePosition.X + (w.knob.AbsoluteSize.X * 0.5)
            return knobCenterX > trackCenterX
        end

        for _, t in ipairs(w.targets) do
            if t.Parent and t.AbsoluteSize.X >= 24 then
                local bg = t.BackgroundColor3
                if bg and bg.G > (bg.R + 0.15) and bg.G > (bg.B + 0.15) then
                    return true
                end
            end
        end
    end

    return false
end

local isTogglingSlowMode = false
local lastSlowToggleClock = 0

local function setSlowMode(desiredState, forceImmediate)
    if isTogglingSlowMode then return false end
    if not forceImmediate and (os.clock() - lastSlowToggleClock < 0.30) then return false end

    local currentState = isSlowModeActive()
    if not forceImmediate and currentState == desiredState then
        return true
    end

    local w = findSlowModeWidget()
    if not w or #w.targets == 0 then
        return false
    end

    isTogglingSlowMode = true
    lastSlowToggleClock = os.clock()

    local ok, result = pcall(function()
        local targetBtn = nil
        for _, t in ipairs(w.targets) do
            if t:IsA("GuiButton") then
                targetBtn = t
                break
            end
        end
        targetBtn = targetBtn or w.track or w.targets[1]

        if VirtualInputManager and targetBtn and targetBtn.AbsoluteSize.X > 0 then
            local inset = GuiService:GetGuiInset()
            local cx = targetBtn.AbsolutePosition.X + (targetBtn.AbsoluteSize.X * 0.5)
            local cyWithInset = targetBtn.AbsolutePosition.Y + (targetBtn.AbsoluteSize.Y * 0.5) + inset.Y

            VirtualInputManager:SendMouseButtonEvent(cx, cyWithInset, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(cx, cyWithInset, 0, false, game, 1)
            task.wait(0.12)
            if isSlowModeActive() == desiredState then return true end
        end

        if type(firesignal) == "function" and targetBtn and targetBtn:IsA("GuiButton") then
            local activatedSig = pcall(function() return targetBtn.Activated end) and targetBtn.Activated
            local clickSig = pcall(function() return targetBtn.MouseButton1Click end) and targetBtn.MouseButton1Click
            local sig = activatedSig or clickSig
            if sig then
                pcall(firesignal, sig)
                task.wait(0.12)
                if isSlowModeActive() == desiredState then return true end
            end
        end

        if type(getconnections) == "function" and targetBtn then
            local sig = (pcall(function() return targetBtn.Activated end) and targetBtn.Activated)
                or (pcall(function() return targetBtn.MouseButton1Click end) and targetBtn.MouseButton1Click)
            if sig then
                local okConn, conns = pcall(getconnections, sig)
                if okConn and type(conns) == "table" and #conns > 0 then
                    for _, conn in ipairs(conns) do
                        if type(conn.Fire) == "function" then
                            pcall(function() conn:Fire() end)
                        elseif type(conn.Function) == "function" then
                            pcall(task.spawn, conn.Function)
                        end
                    end
                    task.wait(0.12)
                    if isSlowModeActive() == desiredState then return true end
                end
            end
        end

        return false
    end)

    lastSlowToggleClock = os.clock()
    isTogglingSlowMode = false
    return ok and result or false
end

local isHoldingStealPrompt = false

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if player == LocalPlayer and Settings.SlowModeNearEgg then
        isHoldingStealPrompt = true
        task.spawn(setSlowMode, false, true)
    end
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
    if player == LocalPlayer then
        task.delay(0.4, function()
            isHoldingStealPrompt = false
        end)
    end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and Settings.SlowModeNearEgg then
        task.spawn(setSlowMode, false, true)
    end
end)

-- Loop Pemantau Otomatis Slow Mode (Near Egg & In Base 2 Detik)
local safeZoneEnterTime = nil
local isGoingToSteal = false

task.spawn(function()
    while task.wait(0.12) do
        local inBase = isInSafeZone()
        local carrying = isCarryingCage()

        if inBase then
            if not safeZoneEnterTime then
                safeZoneEnterTime = os.clock()
            end
        else
            safeZoneEnterTime = nil
        end

        if isHoldingStealPrompt or carrying then
            if Settings.SlowModeNearEgg or Settings.SlowModeInBase then
                setSlowMode(false)
            end
        elseif inBase then
            if isGoingToSteal then
                if Settings.SlowModeInBase or Settings.SlowModeNearEgg then
                    setSlowMode(false)
                end
            elseif Settings.SlowModeInBase and safeZoneEnterTime and (os.clock() - safeZoneEnterTime >= 2.0) then
                setSlowMode(true)
            end
        elseif not inBase and Settings.SlowModeNearEgg then
            local targetDist = getEffectiveEggDist()
            local targetEgg, dist = getTargetEgg()

            if targetEgg and targetEgg.root then
                local prompt = targetEgg.prompt
                local promptMaxDist = (prompt and prompt.MaxActivationDistance and prompt.MaxActivationDistance > 0) and prompt.MaxActivationDistance or 10
                local stealZoneDist = promptMaxDist + 2 -- zona interaksi/ambil telor (~12 studs)

                -- A. Player sudah memasuki zona ambil telor (<= stealZoneDist) -> Matikan Slow Mode!
                if dist <= stealZoneDist then
                    setSlowMode(false)
                -- B. Player sedang mendekati telor (stealZoneDist < dist <= targetDist) -> Aktifkan Slow Mode!
                elseif dist <= targetDist then
                    setSlowMode(true)
                -- C. Masih jauh dari telor (> targetDist) -> Matikan Slow Mode!
                else
                    setSlowMode(false)
                end
            else
                -- Tidak sedang menuju ke telor mana pun -> Matikan Slow Mode!
                setSlowMode(false)
            end
        end
    end
end)

-- Berjalan kaki secara natural menggunakan Humanoid:MoveTo (tanpa teleport)
local function walkTo(targetPos, stopDist, checkActiveFn)
    stopDist = stopDist or 6
    if not Humanoid or not RootPart then return false end
    local startTime = os.clock()
    while (RootPart.Position - targetPos).Magnitude > stopDist do
        if checkActiveFn and not checkActiveFn() then return false end
        if not Humanoid or Humanoid.Health <= 0 then return false end
        if os.clock() - startTime > 35 then return false end
        Humanoid:MoveTo(targetPos)
        task.wait(0.15)
    end
    return true
end

-- ================= LOOPS =================

if TapBoostRemote then
    TapBoostRemote.OnClientEvent:Connect(function()
        if Settings.AutoTapBoost and LocalPlayer:GetAttribute("OnTreadmill") then
            task.delay(0.35 + math.random() * 0.4, function()
                if Settings.AutoTapBoost and LocalPlayer:GetAttribute("OnTreadmill") then
                    pcall(function() TapBoostRemote:FireServer() end)
                end
            end)
        end
    end)
end

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
        if Settings.AutoUpgradeTreadmill and UpgradeTreadmill then
            pcall(function() UpgradeTreadmill:FireServer() end)
        end
    end
end)

-- 3. Main Farm Loop (Place Carried Cage -> Open Ready Cages -> Steal Cage -> Train)
task.spawn(function()
    while task.wait(0.3) do
        -- A. Jika sedang membawa Cage dan AutoPlaceCage aktif, taruh ke stall kosong
        if Settings.AutoPlaceCage and isCarryingCage() and PlaceCageRemote then
            local freeStall = getFreeStall()
            if freeStall and freeStall.part then
                isGoingToSteal = false
                if walkTo(freeStall.part.Position, 7, function() return Settings.AutoPlaceCage and isCarryingCage() end) then
                    equipCarriedCageTool()
                    pcall(function() PlaceCageRemote:FireServer(freeStall.part.Name) end)
                    task.wait(0.4)
                end
            end
        end

        -- B. Jika ada Cage di plot yang timernya sudah selesai (ReadyAt <= ServerTimeNow), buka otomatis
        if Settings.AutoOpenCage and OpenCageRemote then
            local cagesFolder = LocalPlayer:FindFirstChild("Cages")
            if cagesFolder then
                local ownedStalls = getOwnedStalls()
                local stallByIdx = {}
                for _, s in ipairs(ownedStalls) do stallByIdx[s.index] = s end

                for _, cage in ipairs(cagesFolder:GetChildren()) do
                    local stallIdx = tonumber(cage:GetAttribute("Stall"))
                    local opening = cage:GetAttribute("Opening")
                    local readyAt = tonumber(cage:GetAttribute("ReadyAt")) or 0
                    if stallIdx and not opening and (readyAt - workspace:GetServerTimeNow() <= 0) then
                        local stallEntry = stallByIdx[stallIdx]
                        if stallEntry and stallEntry.part then
                            if walkTo(stallEntry.part.Position, 7, function() return Settings.AutoOpenCage end) then
                                pcall(function() OpenCageRemote:FireServer(cage.Name) end)
                                task.wait(0.4)
                            end
                        end
                    end
                end
            end
        end

        -- C. Auto Steal Cage
        if Settings.AutoSteal and not isCarryingCage() and RootPart and Humanoid and Humanoid.Health > 0 then
            local entry = getNearestCage()
            if entry and entry.root and entry.prompt then
                getgenv().SAP_CurrentTargetCage = entry.model
                isGoingToSteal = true
                if isInSafeZone() and (Settings.SlowModeInBase or Settings.SlowModeNearEgg) then
                    setSlowMode(false)
                end

                local reached = walkTo(entry.root.Position, 6, function()
                    return Settings.AutoSteal and entry.prompt.Parent ~= nil and entry.prompt.Enabled and not isCarryingCage()
                end)

                isGoingToSteal = false

                if reached and entry.prompt.Parent and entry.prompt.Enabled then
                    isHoldingStealPrompt = true
                    if Settings.SlowModeNearEgg then
                        task.spawn(setSlowMode, false, true)
                    end

                    if entry.prompt.HoldDuration and entry.prompt.HoldDuration > 0 then
                        pcall(function()
                            entry.prompt:InputHoldBegin()
                            task.wait(entry.prompt.HoldDuration + 0.1)
                            entry.prompt:InputHoldEnd()
                        end)
                    elseif fireproximityprompt then
                        pcall(fireproximityprompt, entry.prompt)
                    end
                    isHoldingStealPrompt = false
                    getgenv().SAP_CurrentTargetCage = nil

                    task.wait(0.2)
                    local myPlot = getMyPlot()
                    if myPlot then
                        walkTo(myPlot:GetPivot().Position, 10, function()
                            return Settings.AutoSteal
                        end)
                    end
                else
                    getgenv().SAP_CurrentTargetCage = nil
                end
            else
                getgenv().SAP_CurrentTargetCage = nil
                isGoingToSteal = false
            end
        else
            getgenv().SAP_CurrentTargetCage = nil
            isGoingToSteal = false
        end

        -- D. Auto Train di Treadmill saat sedang idle
        if Settings.AutoTrain and not Settings.AutoSteal and not isCarryingCage() then
            if not LocalPlayer:GetAttribute("OnTreadmill") then
                local myPlot = getMyPlot()
                local tm = myPlot and myPlot:FindFirstChild("Treadmill", true)
                if tm then
                    local tmPos = tm:GetPivot().Position
                    walkTo(tmPos, 5, function() return Settings.AutoTrain and not LocalPlayer:GetAttribute("OnTreadmill") end)
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
end)

-- ================= GUI TABS (AirFlow UI) =================
local FarmTab = Window:CreateTab({ Name = "Farm", Icon = "package" })

FarmTab:CreateSection("Slow Mode (Anti-Sliding)")
FarmTab:CreateToggle({
    Name = "Auto Slow Mode Near Egg",
    Desc = "Otomatis ON Slow Mode saat dekat Egg agar tidak sliding, dan OFF saat mulai Hold E.",
    Default = true,
    Flag = "SAPSlowNearEgg",
    Callback = function(v) Settings.SlowModeNearEgg = v end,
})
FarmTab:CreateSlider({
    Name = "Slow Mode Egg Distance (0 = Default 28)",
    Desc = "0 = Default (28 studs). Geser di atas 0 atau klik angkanya untuk custom jarak studs.",
    Min = 0,
    Max = 100,
    Step = 1,
    Default = 0,
    Suffix = " studs",
    Flag = "SAPSlowEggDist",
    Callback = function(v)
        Settings.SlowModeEggDist = tonumber(v) or 0
    end,
})
FarmTab:CreateInput({
    Name = "Custom Egg Studs (0 = Default)",
    Desc = "Ketik 0 untuk Default (28 studs), atau ketik angka custom studs.",
    Placeholder = "0 = Default (28 studs)",
    Default = "0",
    Flag = "SAPSlowEggDistInput",
    Callback = function(text)
        local num = tonumber(text)
        if num and num >= 0 then
            Settings.SlowModeEggDist = num
        else
            Settings.SlowModeEggDist = 0
        end
    end,
})
FarmTab:CreateToggle({
    Name = "Auto Slow Mode In Base (2s Safe Zone)",
    Desc = "Otomatis ON Slow Mode setelah 2 detik di Safe Zone/Base, dan OFF saat berangkat steal.",
    Default = true,
    Flag = "SAPSlowInBase",
    Callback = function(v) Settings.SlowModeInBase = v end,
})
FarmTab:CreateButton({
    Name = "Test Klik Slow Mode Sekarang",
    Desc = "Klik untuk mengetes apakah tombol Slow Mode game berhasil dipencet otomatis.",
    Callback = function()
        task.spawn(function()
            setSlowMode(not isSlowModeActive(), true)
        end)
    end,
})

FarmTab:CreateSection("Auto Steal & Cages")
FarmTab:CreateToggle({
    Name = "Auto Steal Cage",
    Desc = "Berjalan natural ke Cage, mencurinya, dan membawanya pulang ke plot.",
    Default = false,
    Flag = "SAPAutoSteal",
    Callback = function(v) Settings.AutoSteal = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Place Cage",
    Desc = "Menaruh Cage yang dibawa ke stall kosong di plot.",
    Default = true,
    Flag = "SAPAutoPlace",
    Callback = function(v) Settings.AutoPlaceCage = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Open Cage",
    Desc = "Membuka Cage di stall segera setelah timernya selesai.",
    Default = true,
    Flag = "SAPAutoOpen",
    Callback = function(v) Settings.AutoOpenCage = v end,
})

FarmTab:CreateSection("Training (Treadmill)")
FarmTab:CreateToggle({
    Name = "Auto Train (Treadmill)",
    Default = false,
    Flag = "SAPAutoTrain",
    Callback = function(v) Settings.AutoTrain = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Upgrade Treadmill",
    Default = true,
    Flag = "SAPAutoTreadmill",
    Callback = function(v) Settings.AutoUpgradeTreadmill = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Tap Boost",
    Default = true,
    Flag = "SAPAutoTapBoost",
    Callback = function(v) Settings.AutoTapBoost = v end,
})

local UpgradeTab = Window:CreateTab({ Name = "Upgrades", Icon = "sparkles" })
UpgradeTab:CreateSection("Auto Buy & Claims")
UpgradeTab:CreateToggle({
    Name = "Auto Buy Plot Stalls",
    Default = true,
    Flag = "SAPAutoStall",
    Callback = function(v) Settings.AutoBuyStalls = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Buy Best Trail",
    Default = true,
    Flag = "SAPAutoTrail",
    Callback = function(v) Settings.AutoTrail = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Claim Daily & Index Rewards",
    Default = true,
    Flag = "SAPAutoClaims",
    Callback = function(v) Settings.AutoClaimRewards = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Equip Best Pets",
    Default = true,
    Flag = "SAPAutoEquipBest",
    Callback = function(v) Settings.AutoEquipBest = v end,
})
UpgradeTab:CreateToggle({
    Name = "Auto Rebirth",
    Default = false,
    Flag = "SAPAutoRebirth",
    Callback = function(v) Settings.AutoRebirth = v end,
})

local PlayerTab = Window:CreateTab({ Name = "Player", Icon = "settings" })
PlayerTab:CreateToggle({
    Name = "Noclip",
    Default = false,
    Flag = "SAPNoclip",
    Callback = function(v) Settings.Noclip = v end,
})
