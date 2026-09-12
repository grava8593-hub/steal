local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

pcall(function()
    if CoreGui:FindFirstChild("ERDEVA_HUB") then CoreGui:FindFirstChild("ERDEVA_HUB"):Destroy() end
    if CoreGui:FindFirstChild("ERDEVA_KEY") then CoreGui:FindFirstChild("ERDEVA_KEY"):Destroy() end
end)

local API_URL = "http://78.154.103.42:9458"
local LOGO_URL = "https://raw.githubusercontent.com/voxynoxy/ErdevaHub/main/icon.png"
local LOGO_FILE = "icon.png"
local KEY_FILE = "erdeva_saved_key.txt"

local LogoAssetId = nil
pcall(function()
    if not isfile or not writefile or not getcustomasset then return end
    if not isfile(LOGO_FILE) then
        local imgData = game:HttpGet(LOGO_URL)
        if imgData and #imgData > 100 then writefile(LOGO_FILE, imgData) end
    end
    if isfile(LOGO_FILE) then LogoAssetId = getcustomasset(LOGO_FILE) end
end)

local C = {
    Bg        = Color3.fromRGB(13, 14, 18),
    Top       = Color3.fromRGB(18, 20, 26),
    TabBg     = Color3.fromRGB(16, 18, 24),
    Card      = Color3.fromRGB(20, 23, 31),
    CardHover = Color3.fromRGB(26, 30, 42),
    Red       = Color3.fromRGB(235, 45, 65),
    RedGlow   = Color3.fromRGB(255, 60, 80),
    Txt       = Color3.fromRGB(245, 245, 250),
    Sub       = Color3.fromRGB(135, 142, 160),
    Border    = Color3.fromRGB(32, 36, 48),
    Off       = Color3.fromRGB(36, 40, 54),
    Green     = Color3.fromRGB(46, 204, 113),
}

local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function Notify(title, desc, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = desc, Duration = duration or 4 })
    end)
end

-- ================= ANTI-AFK 24 JAM BYPASS =================
pcall(function()
    local GC = getconnections or get_signal_cons
    if GC then
        for _, conn in ipairs(GC(player.Idled)) do
            if conn.Disable then conn:Disable()
            elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

-- Safe Remote Calling for Packages.Networking
local function GetNetRF(cat, name)
    local pkg = rs:FindFirstChild("Packages") and rs.Packages:FindFirstChild("Networking")
    if not pkg then return nil end
    local folder = pkg:FindFirstChild("RF") and pkg.RF:FindFirstChild(cat)
    return folder and folder:FindFirstChild(name)
end

local function GetNetRE(cat, name)
    local pkg = rs:FindFirstChild("Packages") and rs.Packages:FindFirstChild("Networking")
    if not pkg then return nil end
    local folder = pkg:FindFirstChild("RE") and pkg.RE:FindFirstChild(cat)
    return folder and folder:FindFirstChild(name)
end

local function CallRF(cat, name, ...)
    local rf = GetNetRF(cat, name)
    if not rf then return nil end
    local args = {...}
    local ok, res = pcall(function() return rf:InvokeServer(table.unpack(args)) end)
    return ok and res or nil
end

local function FireRE(cat, name, ...)
    local re = GetNetRE(cat, name)
    if not re then return false end
    local args = {...}
    return pcall(function() re:FireServer(table.unpack(args)) end)
end

local StartMainScript
local LaunchKeyUI

local function RequestValidation(keyText)
    local u = player.Name
    local reqUrl = API_URL .. "/validate?key=" .. keyText .. "&username=" .. u
    local ok, res = pcall(function() return game:HttpGet(reqUrl) end)
    if not ok or not res then return false, "Connection to server failed!" end
    local parseOk, data = pcall(function() return HttpService:JSONDecode(res) end)
    if parseOk and data then return data.valid, data.reason or data.message, data.expires end
    return false, "Invalid server response!"
end

local function RequestServerTrial()
    local reqUrl = API_URL .. "/check_trial?username=" .. player.Name .. "&userid=" .. tostring(player.UserId)
    local ok, res = pcall(function() return game:HttpGet(reqUrl) end)
    if not ok or not res then return false, 0, "Failed to connect to trial server!" end
    local parseOk, data = pcall(function() return HttpService:JSONDecode(res) end)
    if parseOk and data then return data.trial, tonumber(data.remaining) or 0, data.reason or data.message end
    return false, 0, "Invalid server response!"
end

LaunchKeyUI = function(isExpiredTrial)
    if CoreGui:FindFirstChild("ERDEVA_KEY") then return end

    local KeyGui = Instance.new("ScreenGui", CoreGui)
    KeyGui.Name = "ERDEVA_KEY"
    KeyGui.ResetOnSpawn = false
    KeyGui.IgnoreGuiInset = true
    KeyGui.DisplayOrder = 99999

    local Overlay = Instance.new("Frame", KeyGui)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    Overlay.BackgroundTransparency = 0.35
    Overlay.BorderSizePixel = 0

    local Panel = Instance.new("Frame", KeyGui)
    Panel.Size = UDim2.fromOffset(360, 240)
    Panel.AnchorPoint = Vector2.new(0.5, 0.5)
    Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    Panel.BackgroundColor3 = C.Bg
    Panel.BorderSizePixel = 0
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
    local PanelStroke = Instance.new("UIStroke", Panel)
    PanelStroke.Color = C.Red
    PanelStroke.Thickness = 1.4

    local Header = Instance.new("Frame", Panel)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = C.Top
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

    local HeaderFix = Instance.new("Frame", Header)
    HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
    HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
    HeaderFix.BackgroundColor3 = C.Top
    HeaderFix.BorderSizePixel = 0

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = isExpiredTrial and "TRIAL EXPIRED" or "ERDEVA HUB: STEAL AN EGG"
    TitleLabel.TextColor3 = C.Txt
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold

    local SubTitle = Instance.new("TextLabel", Panel)
    SubTitle.Size = UDim2.new(1, -20, 0, 26)
    SubTitle.Position = UDim2.fromOffset(10, 44)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = isExpiredTrial and "Free trial has ended. Enter your license key:" or "Enter license key from ERDEVA HUB Discord:"
    SubTitle.TextColor3 = isExpiredTrial and Color3.fromRGB(241, 196, 15) or C.Sub
    SubTitle.TextSize = 10
    SubTitle.Font = Enum.Font.Gotham

    local InputBox = Instance.new("Frame", Panel)
    InputBox.Size = UDim2.new(1, -20, 0, 36)
    InputBox.Position = UDim2.fromOffset(10, 76)
    InputBox.BackgroundColor3 = C.Card
    InputBox.BorderSizePixel = 0
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)
    local InputStroke = Instance.new("UIStroke", InputBox)
    InputStroke.Color = C.Border

    local TextInput = Instance.new("TextBox", InputBox)
    TextInput.Size = UDim2.new(1, -12, 1, 0)
    TextInput.Position = UDim2.fromOffset(6, 0)
    TextInput.BackgroundTransparency = 1
    TextInput.Text = ""
    TextInput.PlaceholderText = "XXXXXX-XXXXXX-XXXXXX-XXXXXX"
    TextInput.PlaceholderColor3 = Color3.fromRGB(80, 85, 100)
    TextInput.TextColor3 = C.Txt
    TextInput.TextSize = 11
    TextInput.Font = Enum.Font.GothamMedium
    TextInput.ClearTextOnFocus = false

    local StatusLabel = Instance.new("TextLabel", Panel)
    StatusLabel.Size = UDim2.new(1, -20, 0, 18)
    StatusLabel.Position = UDim2.fromOffset(10, 118)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = C.Sub
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamMedium

    local SubmitBtn = Instance.new("TextButton", Panel)
    SubmitBtn.Size = UDim2.new(1, -20, 0, 36)
    SubmitBtn.Position = UDim2.fromOffset(10, 142)
    SubmitBtn.BackgroundColor3 = C.Red
    SubmitBtn.Text = "ACTIVATE LICENSE"
    SubmitBtn.TextColor3 = C.Txt
    SubmitBtn.TextSize = 12
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.BorderSizePixel = 0
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

    local InfoFoot = Instance.new("TextButton", Panel)
    InfoFoot.Size = UDim2.new(1, -20, 0, 24)
    InfoFoot.Position = UDim2.fromOffset(10, 186)
    InfoFoot.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    InfoFoot.Text = "Buy License: discord.gg/P7g4jpZTU"
    InfoFoot.TextColor3 = Color3.fromRGB(255, 255, 255)
    InfoFoot.TextSize = 10
    InfoFoot.Font = Enum.Font.GothamMedium
    InfoFoot.BorderSizePixel = 0
    Instance.new("UICorner", InfoFoot).CornerRadius = UDim.new(0, 6)

    InfoFoot.MouseButton1Click:Connect(function()
        local discordUrl = "https://discord.gg/P7g4jpZTU"
        pcall(function()
            if setclipboard then setclipboard(discordUrl) elseif toclipboard then toclipboard(discordUrl) end
            if openurl then openurl(discordUrl) end
        end)
        InfoFoot.Text = "Link Copied to Clipboard"
        InfoFoot.TextColor3 = C.Green
        Notify("ERDEVA HUB", "Discord Link Copied!", 2.5)
        task.delay(2.5, function()
            InfoFoot.Text = "Buy License: discord.gg/P7g4jpZTU"
            InfoFoot.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end)

    local function SubmitKey(keyVal)
        keyVal = keyVal:gsub("%s+", ""):upper()
        if keyVal == "" then
            StatusLabel.Text = "Key cannot be empty!"
            StatusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
            return
        end

        SubmitBtn.Active = false
        SubmitBtn.Text = "Validating..."
        StatusLabel.Text = "Contacting server..."
        StatusLabel.TextColor3 = C.Sub

        local valid, msg = RequestValidation(keyVal)
        if valid then
            StatusLabel.Text = "License Valid!"
            StatusLabel.TextColor3 = C.Green
            SubmitBtn.Text = "SUCCESS"
            tw(SubmitBtn, { BackgroundColor3 = C.Green }, 0.2)
            pcall(function() if writefile then writefile(KEY_FILE, keyVal) end end)
            task.delay(0.8, function()
                pcall(function() KeyGui:Destroy() end)
                StartMainScript(false)
            end)
        else
            StatusLabel.Text = msg or "Invalid Key!"
            StatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
            SubmitBtn.Active = true
            SubmitBtn.Text = "ACTIVATE LICENSE"
        end
    end

    SubmitBtn.MouseButton1Click:Connect(function() if SubmitBtn.Active ~= false then SubmitKey(TextInput.Text) end end)
    TextInput.FocusLost:Connect(function(enter) if enter and SubmitBtn.Active ~= false then SubmitKey(TextInput.Text) end end)
end

StartMainScript = function(isTrialMode, trialTimeLeft)
    local IsRunning = true
    local W, H = 450, 300

    if isTrialMode then
        local hoursLeft = math.floor(trialTimeLeft / 3600)
        local minsLeft = math.floor((trialTimeLeft % 3600) / 60)
        Notify("ERDEVA HUB", "Active Trial: " .. hoursLeft .. "h " .. minsLeft .. "m", 4)
    else
        Notify("ERDEVA HUB", "Steal an Egg Loaded!", 4)
    end

    local Flags = {
        -- Steal & Base
        AutoSteal = false,
        AutoPlace = true,
        AutoHatch = true,
        AutoSkipGrowth = true,
        StealAll = false,
        StealSpecial = true,   -- Dragon, Brainrot, Admin, Shard
        StealLegendary = true,
        StealEpic = true,
        StealRare = false,
        TeleportBackToBase = true,
        
        -- Movement
        Fly = false,
        FlySpeed = 50,
        SpeedBoost = false,
        WalkSpeedValue = 40,
        Noclip = true,

        -- Combat & Auto Farm
        AutoSlapThieves = true,
        AutoUpgradeBase = false,
        AutoAwayEarnings = true,
        AutoClaimQuests = true,
        AutoGroupReward = true,
        AutoRedeemCodex = true,
    }

    local LOCKED_BASE_POS = nil
    local ToggleUpdaters = {}

    local function GetChar() return player.Character end
    local function GetRoot()
        local c = GetChar()
        return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
    end
    local function GetHum()
        local c = GetChar()
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    -- ================= AUTO DETEKSI BASE SENDIRI =================
    local function FindMyBasePos()
        if LOCKED_BASE_POS then return LOCKED_BASE_POS end

        -- Cek dari telur di PlacedEggRenders yang punya UserId kita
        local myUserIdStr = tostring(player.UserId)
        local renders = Workspace:FindFirstChild("PlacedEggRenders")
        if renders then
            for _, eggModel in ipairs(renders:GetChildren()) do
                if eggModel.Name:sub(1, #myUserIdStr) == myUserIdStr then
                    local hb = eggModel:FindFirstChild("Hitbox") or eggModel:FindFirstChildWhichIsA("BasePart")
                    if hb then
                        LOCKED_BASE_POS = hb.Position + Vector3.new(0, 3, 0)
                        return LOCKED_BASE_POS
                    end
                end
            end
        end

        -- Cadangan: Posisi berdiri saat pertama kali spawn
        local root = GetRoot()
        if root then return root.Position end
        return Vector3.new(0, 5, 0)
    end

    -- ================= NOCLIP & SPEED LOOP =================
    RunService.Stepped:Connect(function()
        if not IsRunning then return end
        pcall(function()
            local char = GetChar()
            if char and Flags.Noclip then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
            local hum = GetHum()
            if hum and Flags.SpeedBoost then
                hum.WalkSpeed = tonumber(Flags.WalkSpeedValue) or 40
            end
        end)
    end)

    -- ================= FLY ENGINE (TOUCH / CAMERA MOBILE) =================
    local BodyVel = nil
    local BodyGyr = nil

    local function SetFly(enable)
        local root = GetRoot()
        local hum = GetHum()
        if not root or not hum then return end

        if enable then
            pcall(function()
                if not BodyVel or not BodyVel.Parent then
                    BodyVel = Instance.new("BodyVelocity")
                    BodyVel.MaxForce = Vector3.new(9e5, 9e5, 9e5)
                    BodyVel.Parent = root
                end
                if not BodyGyr or not BodyGyr.Parent then
                    BodyGyr = Instance.new("BodyGyro")
                    BodyGyr.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
                    BodyGyr.P = 9e4
                    BodyGyr.Parent = root
                end
            end)
        else
            if BodyVel then BodyVel:Destroy(); BodyVel = nil end
            if BodyGyr then BodyGyr:Destroy(); BodyGyr = nil end
        end
    end

    -- Fly movement update
    RunService.RenderStepped:Connect(function()
        if not IsRunning or not Flags.Fly then
            if BodyVel then SetFly(false) end
            return
        end
        local root = GetRoot()
        local hum = GetHum()
        local cam = Workspace.CurrentCamera
        if not root or not hum or not cam then return end

        if not BodyVel or not BodyVel.Parent then SetFly(true) end

        local moveDir = hum.MoveDirection
        local speed = tonumber(Flags.FlySpeed) or 50

        if BodyGyr then BodyGyr.CFrame = cam.CFrame end

        if moveDir.Magnitude > 0.05 then
            local camCF = cam.CFrame
            local forward = camCF.LookVector
            local right = camCF.RightVector
            local targetVel = (right * moveDir.X + forward * -moveDir.Z).Unit * speed
            BodyVel.Velocity = targetVel
        else
            BodyVel.Velocity = Vector3.new(0, 0, 0)
        end
    end)

    -- ================= DETEKSI & PILIH TELUR MUSUH =================
    local function IsEggDesired(eggModel)
        if Flags.StealAll then return true end
        local name = eggModel.Name:lower()
        for _, child in ipairs(eggModel:GetChildren()) do
            name = name .. " " .. child.Name:lower()
        end
        -- Filter spesial
        if Flags.StealSpecial and (name:find("dragon") or name:find("brainrot") or name:find("admin") or name:find("shard") or name:find("limited") or name:find("parasite")) then
            return true
        end
        if Flags.StealLegendary and name:find("legend") then return true end
        if Flags.StealEpic and name:find("epic") then return true end
        if Flags.StealRare and name:find("rare") then return true end
        return Flags.StealAll
    end

    local function FindTargetEnemyEgg()
        local myUserIdStr = tostring(player.UserId)
        local renders = Workspace:FindFirstChild("PlacedEggRenders")
        if not renders then return nil end

        local root = GetRoot()
        if not root then return nil end

        local bestEgg, bestDist = nil, 99999
        for _, eggModel in ipairs(renders:GetChildren()) do
            -- Abaikan telur milik kita sendiri
            if eggModel.Name:sub(1, #myUserIdStr) ~= myUserIdStr then
                if IsEggDesired(eggModel) then
                    local hb = eggModel:FindFirstChild("Hitbox") or eggModel:FindFirstChildWhichIsA("BasePart")
                    if hb then
                        local d = (root.Position - hb.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestEgg = { model = eggModel, part = hb }
                        end
                    end
                end
            end
        end
        return bestEgg
    end

    local function IsHoldingEgg()
        local char = GetChar()
        if not char then return false end
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("egg") then
                return true
            end
        end
        return false
    end

    -- ================= LOOP 1: AUTO STEAL & TELEPORT BASE =================
    local isStealingNow = false
    task.spawn(function()
        while IsRunning do
            pcall(function()
                if not Flags.AutoSteal then return end

                local root = GetRoot()
                if not root or isStealingNow then return end

                -- Jika sedang memegang telur, bawa pulang ke base
                if IsHoldingEgg() then
                    local basePos = FindMyBasePos()
                    if basePos and Flags.TeleportBackToBase then
                        root.CFrame = CFrame.new(basePos)
                        task.wait(0.3)
                        CallRF("EggWorld", "AskPlaceEgg")
                        Notify("ERDEVA HUB", "Egg Deposited to Base! 🥚", 2)
                        task.wait(0.5)
                    end
                    return
                end

                -- Cari telur musuh target
                local target = FindTargetEnemyEgg()
                if target and target.part then
                    isStealingNow = true
                    -- Teleport / Dekati telur musuh
                    root.CFrame = CFrame.new(target.part.Position + Vector3.new(0, 2.5, 0))
                    task.wait(0.15)

                    -- Trigger Steal Prompt
                    local promptTriggered = false
                    for _, prompt in ipairs(Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.ActionText:lower():find("steal") then
                            local pPart = prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent
                            if pPart and (root.Position - pPart.Position).Magnitude <= 18 then
                                pcall(function()
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    else
                                        prompt:InputHoldBegin()
                                        task.wait(prompt.HoldDuration or 0.1)
                                        prompt:InputHoldEnd()
                                    end
                                end)
                                promptTriggered = true
                                break
                            end
                        end
                    end

                    -- Remote fallback
                    CallRF("EggWorld", "AskFieldEggCarry")
                    task.wait(0.3)

                    -- Begitu terambil, langsung teleport balik base
                    if IsHoldingEgg() and Flags.TeleportBackToBase then
                        local basePos = FindMyBasePos()
                        if basePos then
                            root.CFrame = CFrame.new(basePos)
                            task.wait(0.3)
                            CallRF("EggWorld", "AskPlaceEgg")
                            Notify("ERDEVA HUB", "Steal Success! Egg Placed 🥚", 2.5)
                        end
                    end

                    isStealingNow = false
                end
            end)
            task.wait(0.4)
        end
    end)

    -- ================= LOOP 2: AUTO HATCH & SKIP GROWTH =================
    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoSkipGrowth then
                    CallRF("EggWorld", "AskSkipGrowth")
                end
                if Flags.AutoHatch then
                    CallRF("EggWorld", "AskHatch")
                    CallRF("EggWorld", "AskFinishHatch")
                end
                if Flags.AutoUpgradeBase then
                    FireRE("Homestead", "AskBaseTierRaise")
                end
            end)
            task.wait(1.5)
        end
    end)

    -- ================= LOOP 3: COMBAT & AUTO REWARDS =================
    task.spawn(function()
        while IsRunning do
            pcall(function()
                -- Auto Slap musuh yang mendekat ke base kita
                if Flags.AutoSlapThieves then
                    local root = GetRoot()
                    local myBase = FindMyBasePos()
                    if root and myBase and (root.Position - myBase).Magnitude <= 35 then
                        for _, other in ipairs(Players:GetPlayers()) do
                            if other ~= player and other.Character then
                                local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
                                if oRoot and (myBase - oRoot.Position).Magnitude <= 30 then
                                    FireRE("BatSwing", "Trigger")
                                    break
                                end
                            end
                        end
                    end
                end

                -- Auto Claim Free Rewards
                if Flags.AutoAwayEarnings then CallRF("AwayEarnings", "AskCollect") end
                if Flags.AutoGroupReward then CallRF("GroupPerk", "RedeemPerk") end
                if Flags.AutoClaimQuests then CallRF("OnboardingQuestline", "AskClaim") end
                if Flags.AutoRedeemCodex then CallRF("Codex", "AskRedeemAll") end
            end)
            task.wait(2.5)
        end
    end)

    -- ================= GUI DESIGN =================
    local Gui = Instance.new("ScreenGui", CoreGui)
    Gui.Name = "ERDEVA_HUB"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    Gui.DisplayOrder = 9999

    local function Shutdown()
        IsRunning = false
        SetFly(false)
        for k in pairs(Flags) do Flags[k] = false end
        pcall(function() Gui:Destroy() end)
    end

    local Main = Instance.new("Frame", Gui)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.fromOffset(W, H)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.BackgroundColor3 = C.Bg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = C.Red
    MainStroke.Thickness = 1.2

    local Top = Instance.new("Frame", Main)
    Top.Size = UDim2.new(1, 0, 0, 36)
    Top.BackgroundColor3 = C.Top
    Top.BorderSizePixel = 0

    local TopLine = Instance.new("Frame", Top)
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, -1)
    TopLine.BackgroundColor3 = C.Border
    TopLine.BorderSizePixel = 0

    local HeaderLogo = nil
    if LogoAssetId then
        HeaderLogo = Instance.new("ImageLabel", Top)
        HeaderLogo.Size = UDim2.fromOffset(22, 22)
        HeaderLogo.Position = UDim2.fromOffset(10, 7)
        HeaderLogo.BackgroundTransparency = 1
        HeaderLogo.Image = LogoAssetId
        Instance.new("UICorner", HeaderLogo).CornerRadius = UDim.new(0, 4)
    end

    local Title = Instance.new("TextLabel", Top)
    Title.Size = UDim2.new(1, HeaderLogo and -95 or -75, 1, 0)
    Title.Position = UDim2.fromOffset(HeaderLogo and 38 or 12, 0)
    Title.BackgroundTransparency = 1
    Title.Text = isTrialMode and "ERDEVA HUB [STEAL EGG - TRIAL]" or "ERDEVA HUB: STEAL AN EGG"
    Title.TextColor3 = C.Txt
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Top)
    CloseBtn.Size = UDim2.fromOffset(24, 24)
    CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = C.Sub
    CloseBtn.TextSize = 11
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    local CloseStroke = Instance.new("UIStroke", CloseBtn)
    CloseStroke.Color = C.Border

    CloseBtn.MouseEnter:Connect(function()
        tw(CloseBtn, { BackgroundColor3 = C.Red, TextColor3 = C.Txt }, 0.15)
        tw(CloseStroke, { Color = C.RedGlow }, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        tw(CloseBtn, { BackgroundColor3 = Color3.fromRGB(24, 27, 36), TextColor3 = C.Sub }, 0.15)
        tw(CloseStroke, { Color = C.Border }, 0.15)
    end)
    CloseBtn.MouseButton1Click:Connect(Shutdown)

    local MinBtn = Instance.new("TextButton", Top)
    MinBtn.Size = UDim2.fromOffset(24, 24)
    MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
    MinBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    MinBtn.Text = "-"
    MinBtn.TextSize = 13
    MinBtn.TextColor3 = C.Sub
    MinBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)
    local MinStroke = Instance.new("UIStroke", MinBtn)
    MinStroke.Color = C.Border

    -- Mini Floating Icon (Drag & Tap to Restore)
    local MiniIcon = Instance.new("Frame", Gui)
    MiniIcon.Size = UDim2.fromOffset(50, 50)
    MiniIcon.Position = UDim2.new(0, 20, 0.5, -25)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
    MiniIcon.Visible = false
    MiniIcon.Active = true
    Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 10)
    local MiniStroke = Instance.new("UIStroke", MiniIcon)
    MiniStroke.Color = C.Red
    MiniStroke.Thickness = 1.4

    if LogoAssetId then
        local IconImg = Instance.new("ImageLabel", MiniIcon)
        IconImg.Size = UDim2.new(1, -12, 1, -12)
        IconImg.Position = UDim2.fromOffset(6, 6)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = LogoAssetId
        Instance.new("UICorner", IconImg).CornerRadius = UDim.new(0, 7)
    else
        local MiniLabel = Instance.new("TextLabel", MiniIcon)
        MiniLabel.Size = UDim2.new(1, 0, 1, 0)
        MiniLabel.BackgroundTransparency = 1
        MiniLabel.Text = "ERDEVA"
        MiniLabel.TextColor3 = C.Red
        MiniLabel.TextSize = 9
        MiniLabel.Font = Enum.Font.GothamBold
    end

    local minState = false
    local function SetMinimized(state)
        minState = state
        if state then
            tw(Main, { Size = UDim2.fromOffset(W, 0), BackgroundTransparency = 1 }, 0.2)
            task.delay(0.2, function()
                Main.Visible = false
                MiniIcon.Visible = true
            end)
        else
            MiniIcon.Visible = false
            Main.Visible = true
            Main.BackgroundTransparency = 0
            tw(Main, { Size = UDim2.fromOffset(W, H) }, 0.2)
        end
    end

    MinBtn.MouseButton1Click:Connect(function() SetMinimized(true) end)

    -- Draggable Mini Icon
    local miniDragging = false
    local miniDragStart, miniStartPos = nil, nil
    local miniMoveDist = 0

    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = true
            miniDragStart = input.Position
            miniStartPos = MiniIcon.Position
            miniMoveDist = 0
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    miniDragging = false
                    conn:Disconnect()
                    if miniMoveDist < 8 then SetMinimized(false) end
                end
            end)
        end
    end)

    -- Draggable Top Bar
    local mainDrag = false
    local mainDragStart, mainStartPos = nil, nil
    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mainDrag = true
            mainDragStart = input.Position
            mainStartPos = Main.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mainDrag = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local vs = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            if mainDrag and not minState then
                local delta = input.Position - mainDragStart
                Main.Position = UDim2.new(0.5, math.clamp(mainStartPos.X.Offset + delta.X, -vs.X / 2 + W / 2 + 10, vs.X / 2 - W / 2 - 10),
                                          0.5, math.clamp(mainStartPos.Y.Offset + delta.Y, -vs.Y / 2 + H / 2 + 25, vs.Y / 2 - H / 2 - 10))
            end
            if miniDragging and MiniIcon.Visible then
                local delta = input.Position - miniDragStart
                miniMoveDist = (Vector2.new(delta.X, delta.Y)).Magnitude
                local absX = math.clamp(miniStartPos.X.Scale * vs.X + miniStartPos.X.Offset + delta.X, 4, vs.X - 56)
                local absY = math.clamp(miniStartPos.Y.Scale * vs.Y + miniStartPos.Y.Offset + delta.Y, 4, vs.Y - 56)
                MiniIcon.Position = UDim2.new(0, absX, 0, absY)
            end
        end
    end)

    -- Tab Container
    local TabFrame = Instance.new("Frame", Main)
    TabFrame.Size = UDim2.new(1, -16, 0, 30)
    TabFrame.Position = UDim2.fromOffset(8, 42)
    TabFrame.BackgroundColor3 = C.TabBg
    Instance.new("UICorner", TabFrame).CornerRadius = UDim.new(0, 6)
    local TabList = Instance.new("UIListLayout", TabFrame)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Padding = UDim.new(0, 4)

    local Content = Instance.new("ScrollingFrame", Main)
    Content.Size = UDim2.new(1, -16, 1, -82)
    Content.Position = UDim2.fromOffset(8, 76)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = C.Red
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local CL = Instance.new("UIListLayout", Content)
    CL.Padding = UDim.new(0, 4)

    local Pages, TabBtns = {}, {}
    local function SetTab(name)
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, btnData in pairs(TabBtns) do
            local isSel = (n == name)
            tw(btnData.btn, { BackgroundColor3 = isSel and Color3.fromRGB(38, 18, 24) or Color3.fromRGB(18, 20, 26) }, 0.15)
            tw(btnData.label, { TextColor3 = isSel and C.Txt or C.Sub }, 0.15)
        end
    end

    local MakeTab = function(name, order)
        local btn = Instance.new("TextButton", TabFrame)
        btn.Size = UDim2.new(1 / 5, -4, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        btn.Text = ""
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = C.Sub
        label.TextSize = 10
        label.Font = Enum.Font.GothamBold

        TabBtns[name] = { btn = btn, label = label }
        local page = Instance.new("Frame", Content)
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 4)
        Pages[name] = page

        btn.MouseButton1Click:Connect(function() SetTab(name) end)
        return page
    end

    local function SetFlag(key, val)
        Flags[key] = val
        if ToggleUpdaters[key] then ToggleUpdaters[key](val) end
        if key == "Fly" then SetFly(val) end
    end

    local function AddToggle(parent, label, key)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -54, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local b = Instance.new("TextButton", f)
        b.Size = UDim2.fromOffset(36, 18)
        b.Position = UDim2.new(1, -44, 0.5, -9)
        b.BackgroundColor3 = C.Off
        b.Text = ""
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border

        local k = Instance.new("Frame", b)
        k.Size = UDim2.fromOffset(12, 12)
        k.Position = UDim2.fromOffset(3, 3)
        k.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

        local function upd(on)
            tw(b, { BackgroundColor3 = (on and C.Red or C.Off) })
            tw(bStroke, { Color = (on and C.RedGlow or C.Border) })
            tw(k, { Position = (on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)) })
            tw(fStroke, { Color = (on and Color3.fromRGB(55, 26, 34) or C.Border) })
        end

        ToggleUpdaters[key] = upd
        upd(Flags[key])

        b.MouseButton1Click:Connect(function()
            local ns = not Flags[key]
            SetFlag(key, ns)
        end)
    end

    local function AddButton(parent, label, callback)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = C.Card
        b.Text = label
        b.TextColor3 = C.Txt
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border

        b.MouseButton1Click:Connect(function()
            tw(b, { BackgroundColor3 = C.Red }, 0.1)
            task.delay(0.2, function() tw(b, { BackgroundColor3 = C.Card }, 0.15) end)
            if callback then callback(b) end
        end)
        return b
    end

    local function AddSlider(parent, label, minV, maxV, defV, key)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -65, 0, 16)
        l.Position = UDim2.fromOffset(10, 3)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local vl = Instance.new("TextLabel", f)
        vl.Size = UDim2.fromOffset(50, 16)
        vl.Position = UDim2.new(1, -58, 0, 3)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(defV)
        vl.TextColor3 = C.Red
        vl.TextSize = 11
        vl.Font = Enum.Font.GothamBold
        vl.TextXAlignment = Enum.TextXAlignment.Right

        local bar = Instance.new("Frame", f)
        bar.Size = UDim2.new(1, -20, 0, 4)
        bar.Position = UDim2.fromOffset(10, 23)
        bar.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", bar)
        local initRatio = math.clamp((defV - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.new(initRatio, 0, 1, 0)
        fill.BackgroundColor3 = C.Red
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local sld = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sld = true end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sld = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sld and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(r, 0, 1, 0)
                local v = math.floor(minV + (r * (maxV - minV)))
                vl.Text = tostring(v)
                Flags[key] = v
            end
        end)
    end

    -- TAB 1: STEAL TAB
    local StealPage = MakeTab("Steal", 1)
    AddToggle(StealPage, "Auto Steal Egg", "AutoSteal")
    AddToggle(StealPage, "Teleport Back to Base", "TeleportBackToBase")
    AddButton(StealPage, "[LOCK] Set / Lock My Base Nest", function(btn)
        local root = GetRoot()
        if root then
            LOCKED_BASE_POS = root.Position
            btn.Text = "Base Nest Locked!"
            btn.BackgroundColor3 = C.Green
            Notify("ERDEVA HUB", "Base Nest Locked at your position!", 3)
            task.delay(2.5, function()
                btn.Text = "[LOCK] Set / Lock My Base Nest"
                btn.BackgroundColor3 = C.Card
            end)
        end
    end)
    AddToggle(StealPage, "Steal Special (Dragon/Brainrot/Admin)", "StealSpecial")
    AddToggle(StealPage, "Steal Legendary Eggs", "StealLegendary")
    AddToggle(StealPage, "Steal Epic Eggs", "StealEpic")
    AddToggle(StealPage, "Steal Rare Eggs", "StealRare")
    AddToggle(StealPage, "Steal ALL Eggs (Any Tier)", "StealAll")

    -- TAB 2: MOVEMENT TAB
    local MovePage = MakeTab("Move", 2)
    AddToggle(MovePage, "Fly Mode (Mobile Camera)", "Fly")
    AddSlider(MovePage, "Fly Speed", 10, 150, 50, "FlySpeed")
    AddToggle(MovePage, "Speed Boost", "SpeedBoost")
    AddSlider(MovePage, "WalkSpeed", 16, 120, 40, "WalkSpeedValue")
    AddToggle(MovePage, "Noclip (Tembus Pagar & Base)", "Noclip")

    -- TAB 3: BASE & HATCH TAB
    local BasePage = MakeTab("Base", 3)
    AddToggle(BasePage, "Auto Place Egg to Nest", "AutoPlace")
    AddToggle(BasePage, "Auto Skip Egg Growth", "AutoSkipGrowth")
    AddToggle(BasePage, "Auto Instant Hatch", "AutoHatch")
    AddToggle(BasePage, "Auto Upgrade Base Tier", "AutoUpgradeBase")

    -- TAB 4: COMBAT & MISC TAB
    local CombatPage = MakeTab("Combat", 4)
    AddToggle(CombatPage, "Auto Slap Nearby Base Thieves", "AutoSlapThieves")
    AddButton(CombatPage, "Equip Best Pets", function()
        CallRF("PenRoster", "ConfirmEquipBestBadge")
        CallRF("Haul", "WearBest")
        Notify("ERDEVA HUB", "Best Pets Equipped!", 2)
    end)
    AddButton(CombatPage, "Sell Every Pet (Clean Bag)", function()
        FireRE("PetSatchel", "SellEveryPet")
        Notify("ERDEVA HUB", "Sold All Pets!", 2)
    end)

    -- TAB 5: REWARDS & INFO TAB
    local InfoPage = MakeTab("Rewards", 5)
    AddToggle(InfoPage, "Auto Claim Away Earnings", "AutoAwayEarnings")
    AddToggle(InfoPage, "Auto Claim Onboarding Quests", "AutoClaimQuests")
    AddToggle(InfoPage, "Auto Claim Group Reward", "AutoGroupReward")
    AddToggle(InfoPage, "Auto Redeem Codex Index", "AutoRedeemCodex")

    local discBtn = AddButton(InfoPage, "Discord: discord.gg/P7g4jpZTU", function(btn)
        local discordUrl = "https://discord.gg/P7g4jpZTU"
        pcall(function()
            if setclipboard then setclipboard(discordUrl) elseif toclipboard then toclipboard(discordUrl) end
            if openurl then openurl(discordUrl) end
        end)
        btn.Text = "Link Copied to Clipboard!"
        btn.BackgroundColor3 = C.Green
        Notify("ERDEVA HUB", "Discord Link Copied!", 2.5)
        task.delay(2.5, function()
            btn.Text = "Discord: discord.gg/P7g4jpZTU"
            btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        end)
    end)
    discBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    SetTab("Steal")
end

local function InitSystem()
    local savedKey = nil
    pcall(function()
        if isfile and isfile(KEY_FILE) and readfile then
            savedKey = readfile(KEY_FILE):gsub("%s+", ""):upper()
        end
    end)

    if savedKey and #savedKey > 10 then
        local valid, msg = RequestValidation(savedKey)
        if valid then
            StartMainScript(false)
            return
        else
            pcall(function() if delfile then delfile(KEY_FILE) end end)
        end
    end

    local isTrial, remainingTime, reason = RequestServerTrial()
    if isTrial and remainingTime > 0 then
        StartMainScript(true, remainingTime)
    else
        LaunchKeyUI(true)
    end
end

InitSystem()
