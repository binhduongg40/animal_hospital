-- ================================================================
-- ANIMAL HOSPITAL VIP PRO v5.0 ULTIMATE | TELEPORT + AUTO FARM
-- Tích hợp: Auto Heal, Auto Rooms, ESP, Auto Buy, Anti-Anomaly
-- Tối ưu cho Delta Executor (Mobile/PC) | KHÔNG KEY | TIẾNG VIỆT
-- ================================================================

-- ===== KIỂM TRA VÀ XÓA GIAO DIỆN CŨ (CHỐNG TRÙNG LẶP) =====
local CoreGui = game:GetService("CoreGui")
local safeParent = (gethui and pcall(gethui) and gethui()) or CoreGui
if safeParent:FindFirstChild("AH_VIP_HUB") then
    safeParent:FindFirstChild("AH_VIP_HUB"):Destroy()
end

-- ===== KHAI BÁO DỊCH VỤ =====
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera

-- ===== TẢI ORION LIBRARY (BẢN JENSONHIST TỐI ƯU CHO DI ĐỘNG) =====
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- ===== CẤU HÌNH TOÀN CỤC =====
_G.Config = {
    -- Auto Tasks
    AutoHeal = false,
    InstantInteract = false,
    AutoSanity = false,
    AutoShutterAnomaly = false,
    AutoShutterBarney = false,
    AutoCheckIn = false,
    AutoClean = false,
    AutoCarry = false,
    AutoAskLeaveAnomaly = false,
    AutoTaserAnomaly = false,
    AutoKillAnomalyOnTreat = false,
    
    -- Special Rooms
    AutoRoom6 = false,
    AutoRoom7 = false,
    AutoRoom8 = false,
    
    -- Auto Buy Shop
    AutoBuyShop = false,
    BuyMedkit = false,
    BuyBandage = false,
    BuyMedicine = false,
    BuySyrup = false,
    BuyTaser = false,
    BuyGun = false,
    
    -- ESP / Visuals
    ESP_Animals = false,
    ESP_Anomalies = false,
    ESP_Players = false,
    FullBright = false,
    NoFog = false,
    AntiLag = false,
    
    -- Player Settings
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    
    -- Teleport Settings
    TeleportEnabled = true,
    TeleportOffset = 2.5,
}

local ESP_Objects = {}
local OriginalDurations = {}
local OriginalCollisions = {}

-- ===== BỘ NHỚ ĐỆM PROMPT (TỐI ƯU HIỆU NĂNG) =====
local ItemPromptCache = {}
local CacheRefreshTime = 0
local CACHE_DURATION = 3

local function RefreshItemCache()
    ItemPromptCache = {}
    CacheRefreshTime = os.clock()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText then
            local key = string.lower(desc.ActionText)
            ItemPromptCache[key] = desc
        end
    end
end

local function GetCachedItemPrompt(itemName)
    if not itemName or itemName == "" then return nil end
    if os.clock() - CacheRefreshTime > CACHE_DURATION then
        RefreshItemCache()
    end
    local target = string.lower(itemName)
    for key, prompt in pairs(ItemPromptCache) do
        if string.find(key, target) or string.find(target, key) then
            return prompt
        end
    end
    return nil
end

-- ===== HÀM TELEPORT THÔNG MINH =====
local function TeleportToPosition(pos)
    if not _G.Config.TeleportEnabled then return false end
    local char = LP.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local newPos = pos + Vector3.new(0, _G.Config.TeleportOffset, 0)
    root.CFrame = CFrame.new(newPos)
    root.Velocity = Vector3.new(0, 0, 0)
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    return true
end

local function TeleportToPart(part)
    if not part then return false end
    if part:IsA("BasePart") then
        return TeleportToPosition(part.Position)
    elseif part:IsA("Model") then
        local rootPart = part:FindFirstChild("HumanoidRootPart") or part:FindFirstChildOfClass("BasePart")
        if rootPart then
            return TeleportToPosition(rootPart.Position)
        end
    end
    return false
end

local function TeleportToPrompt(prompt)
    if not prompt then return false end
    local parent = prompt.Parent
    local pos
    if parent:IsA("BasePart") then
        pos = parent.Position
    elseif parent:IsA("Model") then
        local part = parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChildOfClass("BasePart")
        if part then pos = part.Position end
    end
    if pos then
        return TeleportToPosition(pos)
    end
    return false
end

-- ===== HÀM MÔ PHỎNG GÓC NHÌN (TRÁNH ANTI-CHEAT) =====
local function LookAtPosition(targetPosition)
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, targetPosition)
        local head = char:FindFirstChild("Head")
        if head then
            local camPos = head.Position - (root.CFrame.LookVector * 4) + Vector3.new(0, 2, 0)
            Camera.CFrame = CFrame.lookAt(camPos, targetPosition)
        end
    end)
end

-- ===== HÀM TÌM PROXIMITYPROMPT GẦN NHẤT (SỬ DỤNG CACHE) =====
local function FindClosestPrompt(textFilters, searchRoot)
    searchRoot = searchRoot or Workspace
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local bestPrompt, bestDist = nil, math.huge
    for _, desc in ipairs(searchRoot:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            local action = string.lower(desc.ActionText or "")
            for _, filter in ipairs(textFilters) do
                if string.find(action, filter) then
                    local parent = desc.Parent
                    local pos
                    if parent:IsA("BasePart") then
                        pos = parent.Position
                    elseif parent:IsA("Model") then
                        local p = parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChildOfClass("BasePart")
                        if p then pos = p.Position end
                    end
                    if pos then
                        local dist = (root.Position - pos).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            bestPrompt = desc
                        end
                    end
                    break
                end
            end
        end
    end
    return bestPrompt, bestDist
end

-- ===== HÀM TƯƠNG TÁC PROMPT (CÓ TELEPORT VÀ LOOK-AT) =====
local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
    TeleportToPrompt(prompt)
    task.wait(0.05)
    LookAtPosition(TeleportToPrompt(prompt) and prompt.Parent.Position or Vector3.new())
    local success, err = pcall(function()
        fireproximityprompt(prompt)
    end)
    return success
end

-- ===== ESP VỚI HIGHLIGHT VÀ QUẢN LÝ BỘ NHỚ =====
local function AddESP(model, color)
    if not model or ESP_Objects[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = safeParent:FindFirstChild("AH_VIP_HUB") or safeParent
    ESP_Objects[model] = hl
    
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if hl then hl:Destroy() end
            ESP_Objects[model] = nil
        end
    end)
end

local function ClearESP()
    for model, hl in pairs(ESP_Objects) do
        if hl then hl:Destroy() end
        ESP_Objects[model] = nil
    end
end

-- ===== NOCLIP =====
local function SaveOriginalCollisions()
    local char = LP.Character
    if not char or next(OriginalCollisions) ~= nil then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then OriginalCollisions[part] = part.CanCollide end
    end
end

local function RestoreOriginalCollisions()
    local char = LP.Character
    if not char then return end
    for part, canCollide in pairs(OriginalCollisions) do
        if part and part.Parent then part.CanCollide = canCollide end
    end
    OriginalCollisions = {}
end

local function ApplyNoClip()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not _G.Config.NoClip
        end
    end
end

-- ===== HÀM TỰ ĐỘNG MUA ĐỒ (AUTO BUY) =====
local function checkAndBuyItem(itemName, configToggle)
    if not _G.Config.AutoBuyShop or not _G.Config then return end
    local hasItem = LP.Backpack:FindFirstChild(itemName) or (LP.Character and LP.Character:FindFirstChild(itemName))
    if not hasItem then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local txt = (desc.ObjectText or desc.ActionText or ""):lower()
                if txt:find(itemName:lower()) or desc.Parent.Name:lower():find(itemName:lower()) then
                    local currentPos = LP.Character.HumanoidRootPart.Position
                    TeleportToPrompt(desc)
                    task.wait(0.08)
                    fireproximityprompt(desc)
                    task.wait(0.08)
                    LP.Character.HumanoidRootPart.CFrame = CFrame.new(currentPos)
                    break
                end
            end
        end
    end
end

-- ===== HỆ THỐNG ĐA CẤU HÌNH (MULTI-PROFILE CONFIG) =====
local folderName = "AH_VIP_Configs"

local function saveProfileConfig(profileName, configData)
    if not isfolder(folderName) then
        makefolder(folderName)
    end
    local json = HttpService:JSONEncode(configData)
    writefile(folderName.. "/".. profileName.. ".json", json)
    OrionLib:MakeNotification({
        Name = "Hệ thống",
        Content = "Đã lưu cấu hình: ".. profileName,
        Time = 3
    })
end

local function loadProfileConfig(profileName)
    local path = folderName.. "/".. profileName.. ".json"
    if isfile(path) then
        local json = readfile(path)
        local success, data = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if success then
            _G.Config = data
            OrionLib:MakeNotification({
                Name = "Hệ thống",
                Content = "Tải cấu hình thành công!",
                Time = 3
            })
        end
    end
end

-- ===== KHỞI TẠO GIAO DIỆN CHÍNH =====
local Window = OrionLib:MakeWindow({
    Name = "ANIMAL HOSPITAL VIP PRO v5.0",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AH_VIP_Config",
    IntroEnabled = true,
    IntroText = "Chào mừng ".. LP.Name.. " đến với VIP PRO v5.0!",
})

OrionLib:MakeNotification({
    Name = "Hệ thống sẵn sàng!",
    Content = "Đã bật Teleport thông minh & các luồng tự động!",
    Time = 4,
})

-- ===== TAB: TRANG CHỦ =====
local Home = Window:MakeTab({ Name = "Trang chủ", Icon = "rbxassetid://4483345998" })
Home:AddLabel("Tài khoản: ".. LP.Name)
Home:AddLabel("Phiên bản: VIP PRO v5.0 Ultimate (Keyless)")
Home:AddButton({
    Name = "Sao chép link hỗ trợ Discord",
    Callback = function()
        setclipboard("https://discord.gg/vip")
        OrionLib:MakeNotification({ Name = "Thông báo", Content = "Đã sao chép!", Time = 3 })
    end
})

-- ===== TAB: TỰ ĐỘNG (FARM CHÍNH) =====
local Farm = Window:MakeTab({ Name = "Tự động", Icon = "rbxassetid://4483345998" })
Farm:AddSection({ Name = "Cài đặt Teleport" })

Farm:AddToggle({
    Name = "🔮 BẬT TELEPORT (Bay tới mục tiêu)",
    Default = true,
    Callback = function(v) _G.Config.TeleportEnabled = v end
})

Farm:AddSlider({
    Name = "Chiều cao teleport (tránh kẹt)",
    Min = 1, Max = 5, Default = 2.5,
    Callback = function(v) _G.Config.TeleportOffset = v end
})

Farm:AddSection({ Name = "Tác vụ tự động" })

Farm:AddToggle({
    Name = "Tự động chữa trị (Auto-Heal + Teleport)",
    Default = false,
    Callback = function(v) _G.Config.AutoHeal = v end
})

Farm:AddToggle({
    Name = "Tự động tiếp tân (Check-in + Stamp)",
    Default = false,
    Callback = function(v) _G.Config.AutoCheckIn = v end
})

Farm:AddToggle({
    Name = "Tự động dọn Slime & Dập lửa",
    Default = false,
    Callback = function(v) _G.Config.AutoClean = v end
})

Farm:AddToggle({
    Name = "Tự động bế bệnh nhân (Auto Carry & Lay Down)",
    Default = false,
    Callback = function(v) _G.Config.AutoCarry = v end
})

-- ===== TAB: DỊ THƯỜNG (ANTI-ANOMALY) =====
local AntiAnomaly = Window:MakeTab({ Name = "Dị thường", Icon = "rbxassetid://4483345998" })
AntiAnomaly:AddSection({ Name = "Bảo vệ & Xử lý quầy lễ tân" })

AntiAnomaly:AddToggle({
    Name = "Đóng sập cửa khi thấy Dị thường (Skinwalker)",
    Default = false,
    Callback = function(v) _G.Config.AutoShutterAnomaly = v end
})

AntiAnomaly:AddToggle({
    Name = "Đóng sập cửa khi thấy Barney (Tránh softlock)",
    Default = false,
    Callback = function(v) _G.Config.AutoShutterBarney = v end
})

AntiAnomaly:AddToggle({
    Name = "Tự động đuổi cổ dị thường (Auto Ask to Leave)",
    Default = false,
    Callback = function(v) _G.Config.AutoAskLeaveAnomaly = v end
})

AntiAnomaly:AddToggle({
    Name = "Tự động bắn điện dị thường (Auto Taser)",
    Default = false,
    Callback = function(v) _G.Config.AutoTaserAnomaly = v end
})

AntiAnomaly:AddToggle({
    Name = "Tự động tiêu diệt dị thường khi chữa trị",
    Default = false,
    Callback = function(v) _G.Config.AutoKillAnomalyOnTreat = v end
})

-- ===== TAB: CỬA HÀNG (AUTO BUY) =====
local AutoBuy = Window:MakeTab({ Name = "Cửa hàng", Icon = "rbxassetid://4483345998" })
AutoBuy:AddSection({ Name = "Tự động mua khi hết thuốc" })

AutoBuy:AddToggle({
    Name = "Kích hoạt tự động mua hàng",
    Default = false,
    Callback = function(v) _G.Config.AutoBuyShop = v end
})

AutoBuy:AddToggle({ Name = "Mua hộp cứu thương (Medkit)", Default = false, Callback = function(v) _G.Config.BuyMedkit = v end })
AutoBuy:AddToggle({ Name = "Mua băng cá nhân (Bandage)", Default = false, Callback = function(v) _G.Config.BuyBandage = v end })
AutoBuy:AddToggle({ Name = "Mua thuốc lọ (Medicine)", Default = false, Callback = function(v) _G.Config.BuyMedicine = v end })
AutoBuy:AddToggle({ Name = "Mua siro phong (Maple Syrup)", Default = false, Callback = function(v) _G.Config.BuySyrup = v end })
AutoBuy:AddToggle({ Name = "Mua súng điện (Taser)", Default = false, Callback = function(v) _G.Config.BuyTaser = v end })
AutoBuy:AddToggle({ Name = "Mua súng lục (Gun)", Default = false, Callback = function(v) _G.Config.BuyGun = v end })

-- ===== TAB: PHÒNG ĐẶC BIỆT =====
local Rooms = Window:MakeTab({ Name = "Phòng đặc biệt", Icon = "rbxassetid://4483345998" })
Rooms:AddSection({ Name = "Auto-Solve Minigame" })

Rooms:AddToggle({
    Name = "Tự động Phòng 6 (X-Ray)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom6 = v end
})

Rooms:AddToggle({
    Name = "Tự động Phòng 7 (Heart Scan)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom7 = v end
})

Rooms:AddToggle({
    Name = "Tự động Phòng 8 (Phẫu thuật + Tendril)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom8 = v end
})

-- ===== TAB: ĐỊNH VỊ (ESP) =====
local ESPTab = Window:MakeTab({ Name = "Định vị", Icon = "rbxassetid://4483345998" })
ESPTab:AddSection({ Name = "Hiển thị xuyên tường" })

ESPTab:AddToggle({
    Name = "Định vị Bệnh nhân thường (Xanh lá)",
    Default = false,
    Callback = function(v) _G.Config.ESP_Animals = v end
})

ESPTab:AddToggle({
    Name = "Định vị Dị thường / Skinwalker (Đỏ)",
    Default = false,
    Callback = function(v) _G.Config.ESP_Anomalies = v end
})

ESPTab:AddToggle({
    Name = "Định vị Người chơi khác (Xanh dương)",
    Default = false,
    Callback = function(v) _G.Config.ESP_Players = v end
})

-- ===== TAB: HỆ THỐNG =====
local Sys = Window:MakeTab({ Name = "Hệ thống", Icon = "rbxassetid://4483345998" })
Sys:AddSection({ Name = "Cài đặt nhân vật" })

Sys:AddSlider({
    Name = "Tốc độ di chuyển",
    Min = 16, Max = 200, Default = 16,
    Callback = function(v)
        _G.Config.WalkSpeed = v
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end
})

Sys:AddSlider({
    Name = "Sức nhảy",
    Min = 50, Max = 200, Default = 50,
    Callback = function(v)
        _G.Config.JumpPower = v
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            hum.JumpPower = v
            hum.UseJumpPower = true
        end
    end
})

Sys:AddToggle({
    Name = "NoClip (Xuyên tường)",
    Default = false,
    Callback = function(v)
        _G.Config.NoClip = v
        if not v then RestoreOriginalCollisions() end
    end
})

Sys:AddToggle({
    Name = "Tương tác tức thì (0s giữ nút)",
    Default = false,
    Callback = function(v)
        _G.Config.InstantInteract = v
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if v then
                    if not OriginalDurations[prompt] then
                        OriginalDurations[prompt] = prompt.HoldDuration
                    end
                    prompt.HoldDuration = 0
                else
                    if OriginalDurations[prompt] then
                        prompt.HoldDuration = OriginalDurations[prompt]
                    end
                end
            end
        end
    end
})

Sys:AddToggle({
    Name = "Tự động uống cà phê (Giữ Sanity)",
    Default = false,
    Callback = function(v) _G.Config.AutoSanity = v end
})

Sys:AddSection({ Name = "Tối ưu hóa đồ họa (Graphics & FPS Boost)" })

Sys:AddToggle({
    Name = "Sáng màn hình (Full Bright)",
    Default = false,
    Callback = function(v) _G.Config.FullBright = v end
})

Sys:AddToggle({
    Name = "Xóa sương mù (No Fog)",
    Default = false,
    Callback = function(v) _G.Config.NoFog = v end
})

Sys:AddToggle({
    Name = "Giảm Lag (Anti-Lag Mobile)",
    Default = false,
    Callback = function(v)
        _G.Config.AntiLag = v
        if v then
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Smoke") then
                    item.Enabled = false
                elseif item:IsA("Decal") or item:IsA("Texture") then
                    item.Transparency = 1
                end
            end
        end
    end
})

-- ===== TAB: CẤU HÌNH (MULTI-PROFILE) =====
local ConfigTab = Window:MakeTab({ Name = "Cấu hình", Icon = "rbxassetid://4483345998" })
ConfigTab:AddSection({ Name = "Quản lý cấu hình" })

ConfigTab:AddTextbox({
    Name = "Tên cấu hình",
    Default = "config1",
    Callback = function(value) _G.ProfileName = value end
})

ConfigTab:AddButton({
    Name = "Lưu cấu hình hiện tại",
    Callback = function()
        if _G.ProfileName then
            saveProfileConfig(_G.ProfileName, _G.Config)
        end
    end
})

ConfigTab:AddButton({
    Name = "Tải cấu hình",
    Callback = function()
        if _G.ProfileName then
            loadProfileConfig(_G.ProfileName)
        end
    end
})

OrionLib:Init()

-- ===== LUỒNG XỬ LÝ NỀN (BACKGROUND LOOPS) =====

-- Duy trì chỉ số nhân vật sau khi hồi sinh
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    task.wait(0.5)
    hum.WalkSpeed = _G.Config.WalkSpeed
    hum.JumpPower = _G.Config.JumpPower
    hum.UseJumpPower = true
end)

-- 1. LUỒNG TỰ ĐỘNG CHỮA TRỊ (AUTO-HEAL + TELEPORT)
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoHeal then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"heal", "treat", "chữa", "điều trị"})
            if prompt then
                FirePrompt(prompt)
            end
        end)
    end
end)

-- 2. LUỒNG AUTO SANITY (UỐNG CÀ PHÊ + TELEPORT)
task.spawn(function()
    while task.wait(1.5) do
        if not _G.Config.AutoSanity then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"coffee", "cà phê"})
            if prompt then
                FirePrompt(prompt)
            end
        end)
    end
end)

-- 3. LUỒNG AUTO CHECK-IN & TIẾP TÂN
task.spawn(function()
    while task.wait(0.4) do
        if not _G.Config.AutoCheckIn then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"photo", "stamp", "register", "chụp", "đóng dấu"})
            if prompt then
                FirePrompt(prompt)
            end
        end)
    end
end)

-- 4. LUỒNG ĐÓNG CỬA SẬP THÔNG MINH (ANTI-ANOMALY)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoShutterAnomaly and not _G.Config.AutoShutterBarney then continue end
        pcall(function()
            local closeShutter = false
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    if obj.Name == "Barney" and _G.Config.AutoShutterBarney then
                        closeShutter = true
                        break
                    end
                    if (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true) and _G.Config.AutoShutterAnomaly then
                        if obj.Name ~= "Barney" and obj.Name ~= "Ratthew" then
                            closeShutter = true
                            break
                        end
                    end
                end
            end
            
            if closeShutter then
                local prompt = FindClosestPrompt({"shutter", "cửa sập"})
                if prompt then
                    FirePrompt(prompt)
                end
            end
        end)
    end
end)

-- 5. LUỒNG AUTO CLEAN (DỌN SLIME & DẬP LỬA)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoClean then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"slime", "extinguish", "dập", "dọn"})
            if prompt then
                FirePrompt(prompt)
            end
        end)
    end
end)

-- 6. LUỒNG AUTO CARRY & LAY DOWN (BẾ VÀ ĐẶT BỆNH NHÂN NGẤT XỈU)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoCarry then continue end
        pcall(function()
            for _, npc in ipairs(Workspace:GetDescendants()) do
                if npc:IsA("Model") and npc:GetAttribute("IsPatient") == true then
                    if npc:GetAttribute("Fainted") == true or npc:FindFirstChild("FaintedState") then
                        local carryPrompt = npc:FindFirstChild("CarryPrompt", true) or npc:FindFirstChildOfClass("ProximityPrompt")
                        if carryPrompt and carryPrompt.Enabled then
                            FirePrompt(carryPrompt)
                            task.wait(0.1)
                            local assignedBed = npc:GetAttribute("AssignedBed") or npc:GetAttribute("Bed")
                            if assignedBed then
                                local layDownPrompt = assignedBed:FindFirstChild("LayDownPrompt", true) or assignedBed:FindFirstChildOfClass("ProximityPrompt")
                                if layDownPrompt then
                                    FirePrompt(layDownPrompt)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 7. LUỒNG ĐUỔI DỊ THƯỜNG (ASK TO LEAVE)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoAskLeaveAnomaly then continue end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true) then
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChild("PP", true)
                    if prompt and prompt.Enabled and (prompt.ActionText:lower():find("leave") or prompt.ActionText:lower():find("đuổi")) then
                        FirePrompt(prompt)
                    end
                end
            end
        end)
    end
end)

-- 8. LUỒNG TỰ ĐỘNG BẮN ĐIỆN DỊ THƯỜNG (AUTO TASER)
task.spawn(function()
    while task.wait(0.6) do
        if not _G.Config.AutoTaserAnomaly then continue end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true) then
                    local taser = LP.Character:FindFirstChild("Taser") or LP.Backpack:FindFirstChild("Taser")
                    if taser then
                        if taser.Parent == LP.Backpack then
                            taser.Parent = LP.Character
                        end
                        local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
                        if hrp then
                            LookAtPosition(hrp.Position)
                            task.wait(0.05)
                            taser:Activate()
                        end
                    end
                end
            end
        end)
    end
end)

-- 9. LUỒNG TỰ ĐỘNG TIÊU DIỆT DỊ THƯỜNG KHI CHỮA TRỊ
task.spawn(function()
    while task.wait(0.4) do
        if not _G.Config.AutoKillAnomalyOnTreat then continue end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true) then
                    local gun = LP.Character:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
                    if gun then
                        if gun.Parent == LP.Backpack then
                            gun.Parent = LP.Character
                        end
                        local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
                        if hrp then
                            LookAtPosition(hrp.Position)
                            task.wait(0.05)
                            gun:Activate()
                        end
                    end
                end
            end
        end)
    end
end)

-- 10. LUỒNG TỰ ĐỘNG MUA ĐỒ (AUTO BUY)
task.spawn(function()
    while task.wait(1.5) do
        if not _G.Config.AutoBuyShop then continue end
        pcall(function()
            checkAndBuyItem("Medkit", "BuyMedkit")
            checkAndBuyItem("Bandage", "BuyBandage")
            checkAndBuyItem("Medicine", "BuyMedicine")
            checkAndBuyItem("Maple Syrup", "BuySyrup")
            checkAndBuyItem("Taser", "BuyTaser")
            checkAndBuyItem("Gun", "BuyGun")
        end)
    end
end)

-- 11. LUỒNG ESP LOOP (HIỂN THỊ XUYÊN TƯỜNG)
task.spawn(function()
    while task.wait(1) do
        if not _G.Config.ESP_Animals and not _G.Config.ESP_Anomalies and not _G.Config.ESP_Players then
            ClearESP()
            continue
        end
        
        if _G.Config.ESP_Animals then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:GetAttribute("IsPatient") == true then
                    AddESP(obj, Color3.fromRGB(75, 255, 75))
                end
            end
        end
        
        if _G.Config.ESP_Anomalies then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    if obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true or
                       string.find(string.lower(obj.Name), "anomaly") or string.find(string.lower(obj.Name), "skinwalker") then
                        AddESP(obj, Color3.fromRGB(255, 0, 0))
                    end
                end
            end
        end
        
        if _G.Config.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    AddESP(plr.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
    end
end)

-- 12. AUTO ROOM 6 (X-RAY)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom6 then continue end
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("XRayAnswer") or
                           ReplicatedStorage:FindFirstChild("SubmitRoom6") or
                           ReplicatedStorage:FindFirstChild("Room6Remote")
            if remote then
                remote:FireServer()
            end
        end)
    end
end)

-- 13. AUTO ROOM 7 (HEART SCAN)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom7 then continue end
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("HeartScanClick") or
                           ReplicatedStorage:FindFirstChild("SubmitRoom7") or
                           ReplicatedStorage:FindFirstChild("Room7Remote")
            if remote then
                remote:FireServer("correct")
            end
        end)
    end
end)

-- 14. AUTO ROOM 8 (SURGERY + TENDRIL)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom8 then continue end
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("SurgeryStep") or
                           ReplicatedStorage:FindFirstChild("SubmitRoom8") or
                           ReplicatedStorage:FindFirstChild("Room8Remote")
            if remote then
                remote:FireServer("Scissors")
                task.wait(0.1)
                remote:FireServer("Transplant")
                task.wait(0.1)
                remote:FireServer("Scissors")
                task.wait(0.1)
                remote:FireServer("Transplant")
                task.wait(0.1)
                remote:FireServer("Medkit")
                remote:FireServer("Bandage")
                remote:FireServer("Medicine")
            end
        end)
    end
end)

-- 15. NOCLIP & WALKSPEED DUY TRÌ
RunService.Heartbeat:Connect(function()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = _G.Config.WalkSpeed
    end
    
    if _G.Config.NoClip then
        SaveOriginalCollisions()
        ApplyNoClip()
    else
        RestoreOriginalCollisions()
    end
    
    if _G.Config.FullBright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    end
    if _G.Config.NoFog then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 0
    end
end)

-- ===== THÔNG BÁO HOÀN TẤT =====
print("✅ Animal Hospital VIP PRO v5.0 Ultimate đã khởi chạy thành công!")
