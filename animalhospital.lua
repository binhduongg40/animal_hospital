-- ============================================================
-- ANIMAL HOSPITAL VIỆT HUB (Rayfield Edition)
-- Dùng cho Delta Executor (Mobile) – Không cần Key
-- ============================================================

-- Môi trường an toàn
local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- Xác định nơi chứa giao diện và ESP
local safeParent = (typeof(gethui) == "function" and gethui()) or coreGui

-- Xóa folder ESP cũ nếu có
local oldEsp = safeParent:FindFirstChild("AH_ESP")
if oldEsp then oldEsp:Destroy() end

-- Tạo folder mới cho ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "AH_ESP"
espFolder.Parent = safeParent

-- ==================== TẢI THƯ VIỆN RAYFIELD ====================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source"))()

-- ==================== CỬA SỔ CHÍNH ====================
local Window = Rayfield:CreateWindow({
    Name = "ANIMAL HOSPITAL | VIỆT HUB TỐI THƯỢNG",
    LoadingTitle = "Đang tải Việt Hub...",
    LoadingSubtitle = "by binhduongg40",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AH_VietHub",
        FileName = "config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false
    },
    KeySystem = false
})

-- ==================== CẤU HÌNH TOÀN CỤC ====================
_G.Config = {
    AutoHeal = false,
    InstantInteract = false,
    AutoSanity = false,
    AutoShutter = false,
    AutoReception = false,
    AutoRoom6 = false,
    AutoRoom7 = false,
    AutoRoom8 = false,
    AutoClean = false,
    ESP_Animals = false,
    ESP_Anomalies = false,
    ESP_Players = false,
    WalkSpeed = 16,
    JumpPower = 50
}

local ESP_Objects = {}
local OriginalDurations = {}

-- ==================== CÁC HÀM TIỆN ÍCH ====================
-- Hàm tạo Highlight ESP
local function addESP(model, color)
    if not model or ESP_Objects[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = espFolder
    ESP_Objects[model] = hl

    -- Tự xóa khi model bị hủy
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if hl then hl:Destroy() end
            ESP_Objects[model] = nil
        end
    end)
end

-- Hàm xóa tất cả ESP
local function clearESP()
    for model, hl in pairs(ESP_Objects) do
        if hl then hl:Destroy() end
        ESP_Objects[model] = nil
    end
end

-- ==================== TAB: TRANG CHỦ ====================
local Home = Window:CreateTab("Trang Chủ", 4483345998)
Home:CreateLabel("Tài khoản: " .. localPlayer.Name)
Home:CreateLabel("Trạng thái: Đã tích hợp chống Softlock Shift 11")
Home:CreateLabel("Phiên bản: Miễn phí, không cần Key")
Home:CreateButton({
    Name = "Sao chép link hỗ trợ Discord",
    Callback = function()
        setclipboard("https://discord.gg/invite")
        Rayfield:Notify({
            Title = "Thông báo",
            Content = "Đã sao chép link hỗ trợ!",
            Duration = 3,
            Image = 4483345998
        })
    end
})

-- ==================== TAB: TỰ ĐỘNG ====================
local Farm = Window:CreateTab("Tự Động", 4483345998)
Farm:CreateToggle({
    Name = "Tự động chữa trị bệnh nhân (Auto-Heal)",
    CurrentValue = false,
    Flag = "AutoHeal",
    Callback = function(v) _G.Config.AutoHeal = v end
})
Farm:CreateToggle({
    Name = "Tương tác tức thì (0s giữ nút)",
    CurrentValue = false,
    Flag = "InstantInteract",
    Callback = function(v)
        _G.Config.InstantInteract = v
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if v then
                    if not OriginalDurations[prompt] then OriginalDurations[prompt] = prompt.HoldDuration end
                    prompt.HoldDuration = 0
                else
                    if OriginalDurations[prompt] then prompt.HoldDuration = OriginalDurations[prompt] end
                end
            end
        end
    end
})
Farm:CreateToggle({
    Name = "Tự động tiếp tân (Chụp ảnh & Đóng dấu)",
    CurrentValue = false,
    Flag = "AutoReception",
    Callback = function(v) _G.Config.AutoReception = v end
})
Farm:CreateToggle({
    Name = "Tự đóng cửa sập tránh Dị thường (Bypass Ratthew/Barney)",
    CurrentValue = false,
    Flag = "AutoShutter",
    Callback = function(v) _G.Config.AutoShutter = v end
})

-- ==================== TAB: PHÒNG ĐẶC BIỆT ====================
local Rooms = Window:CreateTab("Phòng Đặc Biệt", 4483345998)
Rooms:CreateToggle({
    Name = "Tự động giải Phòng X-Ray (Phòng 6)",
    CurrentValue = false,
    Flag = "AutoRoom6",
    Callback = function(v) _G.Config.AutoRoom6 = v end
})
Rooms:CreateToggle({
    Name = "Tự động giải Heart Scan (Phòng 7)",
    CurrentValue = false,
    Flag = "AutoRoom7",
    Callback = function(v) _G.Config.AutoRoom7 = v end
})
Rooms:CreateToggle({
    Name = "Tự động giải Phẫu thuật & Diệt Xúc tu (Phòng 8)",
    CurrentValue = false,
    Flag = "AutoRoom8",
    Callback = function(v) _G.Config.AutoRoom8 = v end
})
Rooms:CreateToggle({
    Name = "Tự động dọn Slime & Dập Lửa",
    CurrentValue = false,
    Flag = "AutoClean",
    Callback = function(v) _G.Config.AutoClean = v end
})

-- ==================== TAB: ĐỊNH VỊ (ESP) ====================
local EspTab = Window:CreateTab("Định Vị", 4483345998)
EspTab:CreateToggle({
    Name = "Định vị Thú cưng (Bệnh nhân thường)",
    CurrentValue = false,
    Flag = "ESP_Animals",
    Callback = function(v) _G.Config.ESP_Animals = v end
})
EspTab:CreateToggle({
    Name = "Định vị Dị thường (Skinwalker đỏ cảnh báo)",
    CurrentValue = false,
    Flag = "ESP_Anomalies",
    Callback = function(v) _G.Config.ESP_Anomalies = v end
})
EspTab:CreateToggle({
    Name = "Định vị Người chơi khác",
    CurrentValue = false,
    Flag = "ESP_Players",
    Callback = function(v) _G.Config.ESP_Players = v end
})

-- ==================== TAB: HỆ THỐNG ====================
local Sys = Window:CreateTab("Hệ Thống", 4483345998)
Sys:CreateSlider({
    Name = "Tốc độ di chuyển",
    Range = {16, 120},
    Increment = 1,
    Suffix = " WS",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        _G.Config.WalkSpeed = v
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})
Sys:CreateSlider({
    Name = "Sức nhảy",
    Range = {50, 150},
    Increment = 1,
    Suffix = " JP",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        _G.Config.JumpPower = v
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.JumpPower = v
        end
    end
})
Sys:CreateToggle({
    Name = "Tự động uống Cà phê (Giữ Sanity 100%)",
    CurrentValue = false,
    Flag = "AutoSanity",
    Callback = function(v) _G.Config.AutoSanity = v end
})

-- ==================== CÁC LUỒNG CHẠY NỀN ====================
-- 1. Auto Heal
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoHeal then continue end
        pcall(function()
            local char = localPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local bestPrompt, bestDist = nil, math.huge

            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local action = desc.ActionText:lower()
                    if action:find("chữa") or action:find("điều trị") or action:find("heal") or action:find("treat") then
                        local toolName = desc.Parent.Name
                        local backpack = localPlayer:FindFirstChild("Backpack")
                        if backpack and (backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)) then
                            local parent = desc.Parent
                            if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                                local pos = parent:IsA("BasePart") and parent.Position or parent:GetPivot().Position
                                local dist = (root.Position - pos).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    bestPrompt = desc
                                end
                            end
                        end
                    end
                end
            end

            if bestPrompt then
                local parent = bestPrompt.Parent
                local pos = parent:IsA("BasePart") and parent.Position or parent:GetPivot().Position
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if bestDist > bestPrompt.MaxActivationDistance then
                        humanoid:MoveTo(pos)
                    else
                        fireproximityprompt(bestPrompt)
                    end
                end
            end
        end)
    end
end)

-- 2. Auto Sanity (Cà phê)
task.spawn(function()
    while task.wait(1.5) do
        if not _G.Config.AutoSanity then continue end
        pcall(function()
            local char = localPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local text = prompt.ActionText:lower()
                    if text:find("cà phê") or text:find("coffee") or prompt.Name:lower():find("coffee") then
                        local pos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or prompt.Parent:GetPivot().Position
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid:MoveTo(pos)
                            task.wait(0.5)
                            fireproximityprompt(prompt)
                        end
                        break
                    end
                end
            end
        end)
    end
end)

-- 3. Auto Shutter (chống dị thường, bỏ qua Ratthew/Barney)
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoShutter then continue end
        pcall(function()
            local hasAnomaly = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    if obj.Name == "Ratthew" or obj.Name == "Barney" then continue end
                    if obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true then
                        hasAnomaly = true
                        break
                    end
                end
            end
            if hasAnomaly then
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        if prompt.ActionText:lower():find("shutter") or prompt.Name:lower():find("shutter") then
                            fireproximityprompt(prompt)
                            break
                        end
                    end
                end
            end
        end)
    end
end)

-- 4. Auto Reception
task.spawn(function()
    while task.wait(0.4) do
        if not _G.Config.AutoReception then continue end
        pcall(function()
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local action = prompt.ActionText:lower()
                    if action:find("chụp") or action:find("photo") then
                        fireproximityprompt(prompt)
                        task.wait(0.2)
                    elseif action:find("đóng dấu") or action:find("stamp") or action:find("nhận") or action:find("register") then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end)
    end
end)

-- 5. ESP Loop
task.spawn(function()
    while task.wait(1) do
        if not _G.Config.ESP_Animals and not _G.Config.ESP_Anomalies and not _G.Config.ESP_Players then
            clearESP()
            continue
        end

        if _G.Config.ESP_Animals then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("IsPatient") == true or obj.Name:lower():find("patient")) then
                    addESP(obj, Color3.fromRGB(75, 255, 75))
                end
            end
        end

        if _G.Config.ESP_Anomalies then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true or obj.Name:lower():find("anomaly") or obj.Name:lower():find("jumpscaredummy")) then
                    addESP(obj, Color3.fromRGB(255, 0, 0))
                end
            end
        end

        if _G.Config.ESP_Players then
            for _, plr in ipairs(players:GetPlayers()) do
                if plr ~= localPlayer and plr.Character then
                    addESP(plr.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
    end
end)

-- 6. Auto Room 6 (X-Ray)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom6 then continue end
        pcall(function()
            local room6 = workspace:FindFirstChild("Room6", true) or workspace:FindFirstChild("Emergency", true):FindFirstChild("Room6")
            if room6 then
                local beginPrompt = room6:FindFirstChild("PP", true) or room6:FindFirstChild("ProximityPrompt", true)
                if beginPrompt and beginPrompt.Enabled then
                    fireproximityprompt(beginPrompt)
                end

                local colorsFolder = room6:FindFirstChild("Colors", true)
                if colorsFolder then
                    for _, buttonModel in ipairs(colorsFolder:GetChildren()) do
                        local btnPart = buttonModel:FindFirstChild("Button") or buttonModel:FindFirstChildOfClass("BasePart")
                        if btnPart then
                            local clickDetector = btnPart:FindFirstChildOfClass("ClickDetector")
                            if clickDetector then
                                fireclickdetector(clickDetector)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 7. Auto Room 7 (Heart Scan)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom7 then continue end
        pcall(function()
            local room7 = workspace:FindFirstChild("Room7", true)
            if room7 then
                local scanPrompt = room7:FindFirstChild("ProximityPrompt", true)
                if scanPrompt and scanPrompt.Enabled then
                    fireproximityprompt(scanPrompt)
                end

                local localGui = localPlayer:WaitForChild("PlayerGui")
                local scanUi = localGui:FindFirstChild("HeartScanUI", true)
                if scanUi then
                    for _, element in ipairs(scanUi:GetDescendants()) do
                        if element:IsA("ImageButton") and element.Visible and not element.Name:lower():find("skull") then
                            if typeof(guirespond) == "function" then
                                guirespond(element)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 8. Auto Room 8 (Surgery & Tendril)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom8 then continue end
        pcall(function()
            local room8 = workspace:FindFirstChild("Room8", true)
            if room8 then
                local tendril = room8:FindFirstChild("Tendril", true)
                if tendril then
                    local steps = {"Scissors", "Transplant", "Scissors", "Transplant"}
                    for _, stepName in ipairs(steps) do
                        local prompt = room8:FindFirstChild(stepName, true)
                        if prompt and prompt:IsA("ProximityPrompt") then
                            fireproximityprompt(prompt)
                            task.wait(0.2)
                        end
                    end
                else
                    local firstPrompt = room8:FindFirstChild("IV Drops", true) or room8:FindFirstChild("IV", true)
                    if firstPrompt and firstPrompt.Enabled then
                        fireproximityprompt(firstPrompt)
                    end
                end
            end
        end)
    end
end)

-- 9. Auto Clean (Slime & Fire)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoClean then continue end
        pcall(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local text = desc.ActionText:lower()
                    if text:find("slime") or text:find("extinguish") or text:find("dọn") or text:find("dập") or text:find("lửa") then
                        fireproximityprompt(desc)
                    end
                end
            end
        end)
    end
end)

-- ==================== KHỞI ĐỘNG RAYFIELD ====================
Rayfield:LoadNotification()
