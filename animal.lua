-- TRÁNH TRÙNG LẶP GIAO DIỆN GÂY TRÀN BỘ NHỚ THIẾT BỊ DI ĐỘNG
local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local safeParent = (gethui and pcall(gethui) and gethui()) or coreGui
if safeParent:FindFirstChild("AH_VietHub") then
    safeParent:FindFirstChild("AH_VietHub"):Destroy()
end

-- TẢI THƯ VIỆN ĐỒ HỌA ORION LIBRARY TỪ CDN BẢO MẬT
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- THIẾT LẬP TRẠNG THÁI CẤU HÌNH TOÀN CỤC
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

-- CHỐNG TREO MÁY (ANTI-AFK) TỰ ĐỘNG GIẢ LẬP HÀNH VI CLICK
local VirtualUser = game:GetService("VirtualUser")
localPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- KHỞI TẠO CỬA SỔ GIAO DIỆN CHÍNH
local Window = OrionLib:MakeWindow({
    Name = "ANIMAL HOSPITAL | VIỆT HUB TỐI THƯỢNG",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AH_VietHub_Settings",
    IntroEnabled = true,
    IntroText = "Chào mừng ".. localPlayer.Name.. " đến với Việt Hub!"
})

-- ==================== CÁC HÀM HỖ TRỢ ĐỒ HỌA & TIỆN ÍCH ====================
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
    hl.Parent = safeParent:FindFirstChild("AH_VietHub") or safeParent
    ESP_Objects[model] = hl

    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if hl then hl:Destroy() end
            ESP_Objects[model] = nil
        end
    end)
end

local function clearESP()
    for model, hl in pairs(ESP_Objects) do
        if hl then hl:Destroy() end
        ESP_Objects[model] = nil
    end
end

-- ==================== PHÂN VÙNG GIAO DIỆN: TRANG CHỦ ====================
local Home = Window:MakeTab({ Name = "Trang Chủ", Icon = "rbxassetid://4483345998" })
Home:AddLabel("Tài khoản: ".. localPlayer.Name)
Home:AddLabel("Trạng thái: Đã tích hợp chống Softlock Shift 11")
Home:AddLabel("Phiên bản: Không cần Key (Miễn phí hoàn toàn)")

Home:AddButton({
    Name = "Sao chép liên kết hỗ trợ Discord",
    Callback = function()
        setclipboard("https://discord.gg/invite")
        OrionLib:MakeNotification({
            Name = "Thông báo",
            Content = "Đã sao chép link hỗ trợ thành công!",
            Time = 3
        })
    end
})

-- ==================== PHÂN VÙNG GIAO DIỆN: TỰ ĐỘNG (FARM CHÍNH) ====================
local Farm = Window:MakeTab({ Name = "Tự Động", Icon = "rbxassetid://4483345998" })
Farm:AddSection({ Name = "Hỗ Trợ Tác Vụ Thường Nhật" })

Farm:AddToggle({
    Name = "Tự động chữa trị bệnh nhân (Auto-Heal)",
    Default = false,
    Callback = function(v) _G.Config.AutoHeal = v end
})

Farm:AddToggle({
    Name = "Tương tác tức thì (0s giữ nút)",
    Default = false,
    Callback = function(v)
        _G.Config.InstantInteract = v
        for _, prompt in ipairs(workspace:GetDescendants()) do
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

Farm:AddToggle({
    Name = "Tự động tiếp tân (Chụp ảnh & Đóng dấu)",
    Default = false,
    Callback = function(v) _G.Config.AutoReception = v end
})

Farm:AddToggle({
    Name = "Tự đóng cửa sập tránh Dị thường (Bypass Ratthew/Barney)",
    Default = false,
    Callback = function(v) _G.Config.AutoShutter = v end
})

-- ==================== PHÂN VÙNG GIAO DIỆN: PHÒNG ĐẶC BIỆT ====================
local Rooms = Window:MakeTab({ Name = "Phòng Đặc Biệt", Icon = "rbxassetid://4483345998" })
Rooms:AddSection({ Name = "Auto-Solve các trò chơi nhỏ" })

Rooms:AddToggle({
    Name = "Tự động giải Phòng X-Ray (Phòng 6)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom6 = v end
})

Rooms:AddToggle({
    Name = "Tự động giải Heart Scan (Phòng 7)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom7 = v end
})

Rooms:AddToggle({
    Name = "Tự động giải Phẫu thuật & Diệt Xúc tu (Phòng 8)",
    Default = false,
    Callback = function(v) _G.Config.AutoRoom8 = v end
})

Rooms:AddToggle({
    Name = "Tự động dọn Slime & Dập Lửa",
    Default = false,
    Callback = function(v) _G.Config.AutoClean = v end
})

-- ==================== PHÂN VÙNG GIAO DIỆN: ĐỊNH VỊ (ESP) ====================
local ESPTab = Window:MakeTab({ Name = "Định Vị", Icon = "rbxassetid://4483345998" })
ESPTab:AddSection({ Name = "Bản đồ hiển thị xuyên tường" })

ESPTab:AddToggle({
    Name = "Định vị Thú cưng (Bệnh nhân thường)",
    Default = false,
    Callback = function(v) _G.Config.ESP_Animals = v end
})

ESPTab:AddToggle({
    Name = "Định vị Dị thường (Skinwalker đỏ cảnh báo)",
    Default = false,
    Callback = function(v) _G.Config.ESP_Anomalies = v end
})

ESPTab:AddToggle({
    Name = "Định vị Người chơi khác",
    Default = false,
    Callback = function(v) _G.Config.ESP_Players = v end
})

-- ==================== PHÂN VÙNG GIAO DIỆN: NHÂN VẬT & HỆ THỐNG ====================
local Sys = Window:MakeTab({ Name = "Hệ Thống", Icon = "rbxassetid://4483345998" })
Sys:AddSection({ Name = "Cài đặt nhân vật" })

Sys:AddSlider({
    Name = "Tốc độ di chuyển",
    Min = 16, Max = 120, Default = 16,
    Callback = function(v)
        _G.Config.WalkSpeed = v
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

Sys:AddSlider({
    Name = "Sức nhảy",
    Min = 50, Max = 150, Default = 50,
    Callback = function(v)
        _G.Config.JumpPower = v
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.JumpPower = v
        end
    end
})

Sys:AddToggle({
    Name = "Tự động uống Cà phê (Giữ Sanity 100%)",
    Default = false,
    Callback = function(v) _G.Config.AutoSanity = v end
})

-- ==================== CÁC LUỒNG CHẠY NỀN (BACKGROUND LOOPS) ====================

-- 1. Luồng xử lý Auto-Heal (Tìm, di chuyển vật lý và tương tác an toàn)
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
                        -- TƯƠNG TÁC KHÓA LIÊN ĐỘNG AN TOÀN: Kiểm tra túi đồ để đảm bảo người chơi có thuốc tương thích, tránh nhấp nhầm chết bệnh nhân
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

-- 2. Luồng xử lý Auto Sanity (Cà phê duy trì tinh thần)
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

-- 3. Luồng quét và đóng cửa sập bảo vệ khi phát hiện Skinwalker (Phòng tránh Softlock Shift 11)
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoShutter then continue end
        pcall(function()
            local hasAnomaly = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    -- HẠN CHẾ SOFTLOCK CỐT TRUYỆN: Bỏ qua kiểm tra cửa sập đối với các NPC cốt truyện như Ratthew và Barney để kích hoạt hội thoại đầy đủ
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

-- 4. Luồng xử lý công việc Tiếp tân (Chụp ảnh & Đóng dấu tự động)
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

-- 5. Luồng xử lý hiển thị Định vị (ESP) mượt mà không leak RAM
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

-- 6. Tự động giải phòng chụp X-Ray (Phòng 6)
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

-- 7. Tự động giải quét nhịp tim (Phòng 7)
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
                            -- Gửi phản hồi tương tác GUI an toàn để kích hoạt nhịp tim chính xác
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

-- 8. Tự động giải cứu Phẫu thuật & Diệt xúc tu Tendril khẩn cấp (Phòng 8)
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom8 then continue end
        pcall(function()
            local room8 = workspace:FindFirstChild("Room8", true)
            if room8 then
                local tendril = room8:FindFirstChild("Tendril", true)
                if tendril then
                    -- Trình tự loại bỏ Tendril khẩn cấp: Scissors -> Transplant -> Scissors -> Transplant
                    local steps = {"Scissors", "Transplant", "Scissors", "Transplant"}
                    for _, stepName in ipairs(steps) do
                        local prompt = room8:FindFirstChild(stepName, true)
                        if prompt and prompt:IsA("ProximityPrompt") then
                            fireproximityprompt(prompt)
                            task.wait(0.2)
                        end
                    end
                else
                    -- Phẫu thuật thường: Cấp dung dịch IV Drops tự động lúc bắt đầu
                    local firstPrompt = room8:FindFirstChild("IV Drops", true) or room8:FindFirstChild("IV", true)
                    if firstPrompt and firstPrompt.Enabled then
                        fireproximityprompt(firstPrompt)
                    end
                end
            end
        end)
    end
end)

-- 9. Tự động dọn dẹp Slime & Dập Lửa cứu hộ lâm sàng
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

OrionLib:Init()
