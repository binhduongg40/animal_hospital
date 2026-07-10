-- ================================================================
-- ANIMAL HOSPITAL VIP HUB | TELEPORT TOÀN DIỆN
-- Tích hợp: Auto Heal Teleport, Auto Rooms, ESP, Instant Interact
-- Tối ưu cho Delta Executor (Mobile/PC) | KHÔNG KEY
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

-- ===== TẢI ORION LIBRARY (BẢN JENSONHIST TỐI ƯU) =====
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- ===== CẤU HÌNH TOÀN CỤC =====
_G.Config = {
    -- Auto
    AutoHeal = false,
    InstantInteract = false,
    AutoSanity = false,
    AutoShutter = false,
    AutoCheckIn = false,
    AutoRoom6 = false,
    AutoRoom7 = false,
    AutoRoom8 = false,
    AutoClean = false,
    AutoCarry = false,
    -- ESP
    ESP_Animals = false,
    ESP_Anomalies = false,
    ESP_Players = false,
    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    -- Teleport
    TeleportEnabled = true,
    TeleportOffset = 2.5,
}

local ESP_Objects = {}
local OriginalDurations = {}
local OriginalCollisions = {}

-- ===== HÀM TELEPORT THÔNG MINH =====
local function TeleportToPosition(pos)
    if not _G.Config.TeleportEnabled then return false end
    local char = LP.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- Nâng vị trí lên để tránh kẹt
    local newPos = pos + Vector3.new(0, _G.Config.TeleportOffset, 0)
    root.CFrame = CFrame.new(newPos)
    root.Velocity = Vector3.new(0, 0, 0)
    
    -- Đảm bảo nhân vật đứng vững
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

-- ===== HÀM TÌM KIẾM PROXIMITYPROMPT GẦN NHẤT =====
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

-- ===== HÀM HỖ TRỢ TƯƠNG TÁC =====
local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
    -- Teleport tới prompt trước khi tương tác
    TeleportToPrompt(prompt)
    task.wait(0.05)
    local success, err = pcall(function()
        fireproximityprompt(prompt)
    end)
    return success
end

-- ===== ESP FUNCTIONS =====
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

-- ===== KHỞI TẠO GIAO DIỆN =====
local Window = OrionLib:MakeWindow({
    Name = "ANIMAL HOSPITAL | VIP TELEPORT HUB",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AH_VIP_Teleport_Config",
    IntroEnabled = true,
    IntroText = "Chào mừng " .. LP.Name .. " đến với VIP Hub!",
})

OrionLib:MakeNotification({
    Name = "Hệ thống sẵn sàng!",
    Content = "Đã bật Teleport thông minh!",
    Time = 4,
})

-- ===== TAB: TRANG CHỦ =====
local Home = Window:MakeTab({ Name = "Trang chủ", Icon = "rbxassetid://4483345998" })
Home:AddLabel("Tài khoản: " .. LP.Name)
Home:AddLabel("Phiên bản: VIP Teleport v3.0")
Home:AddButton({
    Name = "Sao chép link hỗ trợ",
    Callback = function()
        setclipboard("https://discord.gg/vip")
        OrionLib:MakeNotification({ Name = "Thông báo", Content = "Đã sao chép!", Time = 3 })
    end
})

-- ===== TAB: TỰ ĐỘNG (FARM) =====
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
    Name = "Tự động đóng cửa sập (Shutter)",
    Default = false,
    Callback = function(v) _G.Config.AutoShutter = v end
})

Farm:AddToggle({
    Name = "Tự động uống cà phê (Giữ Sanity)",
    Default = false,
    Callback = function(v) _G.Config.AutoSanity = v end
})

Farm:AddToggle({
    Name = "Tự động dọn Slime & Dập lửa",
    Default = false,
    Callback = function(v) _G.Config.AutoClean = v end
})

Farm:AddToggle({
    Name = "Tự động bế bệnh nhân (Auto Carry)",
    Default = false,
    Callback = function(v) _G.Config.AutoCarry = v end
})

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

OrionLib:Init()

-- ===== LUỒNG XỬ LÝ NỀN =====

-- Duy trì chỉ số sau khi hồi sinh
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    task.wait(0.5)
    hum.WalkSpeed = _G.Config.WalkSpeed
    hum.JumpPower = _G.Config.JumpPower
end)

-- 1. AUTO-HEAL (CÓ TELEPORT)
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoHeal then continue end
        pcall(function()
            local char = LP.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Tìm prompt heal/treat gần nhất
            local prompt = FindClosestPrompt({"heal", "treat", "chữa", "điều trị"})
            if prompt then
                -- Teleport tới vị trí prompt
                TeleportToPrompt(prompt)
                task.wait(0.05)
                fireproximityprompt(prompt)
            end
        end)
    end
end)

-- 2. AUTO SANITY (UỐNG CÀ PHÊ + TELEPORT)
task.spawn(function()
    while task.wait(1.5) do
        if not _G.Config.AutoSanity then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"coffee", "cà phê"})
            if prompt then
                TeleportToPrompt(prompt)
                task.wait(0.3)
                fireproximityprompt(prompt)
            end
        end)
    end
end)

-- 3. AUTO CHECK-IN (TIẾP TÂN + TELEPORT)
task.spawn(function()
    while task.wait(0.4) do
        if not _G.Config.AutoCheckIn then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"photo", "stamp", "register", "chụp", "đóng dấu"})
            if prompt then
                TeleportToPrompt(prompt)
                task.wait(0.05)
                fireproximityprompt(prompt)
            end
        end)
    end
end)

-- 4. AUTO SHUTTER (ĐÓNG CỬA SẬP KHI CÓ ANOMALY)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoShutter then continue end
        pcall(function()
            local hasAnomaly = false
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    -- Bỏ qua Ratthew/Barney để tránh softlock Shift 11
                    if obj.Name == "Ratthew" or obj.Name == "Barney" then
                        continue
                    end
                    if obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true then
                        hasAnomaly = true
                        break
                    end
                end
            end
            
            if hasAnomaly then
                local prompt = FindClosestPrompt({"shutter", "cửa sập"})
                if prompt then
                    TeleportToPrompt(prompt)
                    task.wait(0.05)
                    fireproximityprompt(prompt)
                end
            end
        end)
    end
end)

-- 5. AUTO CLEAN (DỌN SLIME & DẬP LỬA)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoClean then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"slime", "extinguish", "dập", "dọn"})
            if prompt then
                TeleportToPrompt(prompt)
                task.wait(0.05)
                fireproximityprompt(prompt)
            end
        end)
    end
end)

-- 6. AUTO CARRY (BẾ BỆNH NHÂN)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoCarry then continue end
        pcall(function()
            local prompt = FindClosestPrompt({"carry", "bế", "pick up"})
            if prompt then
                TeleportToPrompt(prompt)
                task.wait(0.05)
                fireproximityprompt(prompt)
            end
        end)
    end
end)

-- 7. ESP LOOP (HIỂN THỊ XUYÊN TƯỜNG)
task.spawn(function()
    while task.wait(1) do
        if not _G.Config.ESP_Animals and not _G.Config.ESP_Anomalies and not _G.Config.ESP_Players then
            ClearESP()
            continue
        end
        
        -- Bệnh nhân thường (Xanh lá)
        if _G.Config.ESP_Animals then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:GetAttribute("IsPatient") == true then
                    AddESP(obj, Color3.fromRGB(75, 255, 75))
                end
            end
        end
        
        -- Dị thường / Skinwalker (Đỏ)
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
        
        -- Người chơi khác (Xanh dương)
        if _G.Config.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    AddESP(plr.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
    end
end)

-- 8. AUTO ROOM 6 (X-RAY)
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

-- 9. AUTO ROOM 7 (HEART SCAN)
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

-- 10. AUTO ROOM 8 (SURGERY + TENDRIL)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom8 then continue end
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("SurgeryStep") or
                           ReplicatedStorage:FindFirstChild("SubmitRoom8") or
                           ReplicatedStorage:FindFirstChild("Room8Remote")
            if remote then
                -- Chuỗi phẫu thuật cố định để diệt Tendril
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

-- 11. NOCLIP & WALKSPEED DUY TRÌ
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
end)

-- ===== THÔNG BÁO HOÀN TẤT =====
print("✅ Animal Hospital VIP Hub (Teleport) đã tải thành công!") là 
