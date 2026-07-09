-- =====================================================
-- ANIMAL HOSPITAL HUB (ScreenGui Edition)
-- Chạy trực tiếp trên Delta Executor - Không cần thư viện ngoài
-- =====================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Xoá GUI cũ nếu có
local oldGui = CoreGui:FindFirstChild("AH_VietHub")
if oldGui then oldGui:Destroy() end

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AH_VietHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- ==================== GIAO DIỆN CHÍNH ====================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 450)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Thanh tiêu đề
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🐾 Việt Hub - Animal Hospital"
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 5)
MinimizeBtn.Text = "─"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.TextColor3 = Color3.new(1,1,1)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 0)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 5)

-- Khung nội dung cuộn
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 4
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 800) -- đủ chỗ cho các nút
ContentFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ContentFrame

-- Hàm tạo nút bật/tắt
local function CreateToggle(name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = default and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(60, 160, 60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name .. " (OFF)"
    if default then btn.Text = name .. " (ON)" end
    btn.BorderSizePixel = 0
    btn.Parent = ContentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            btn.Text = name .. " (ON)"
        else
            btn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            btn.Text = name .. " (OFF)"
        end
        callback(state)
    end)
    return btn
end

-- Hàm tạo thanh trượt
local function CreateSlider(name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = ContentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 0, 24)
    textBox.Position = UDim2.new(0, 0, 0, 22)
    textBox.Text = tostring(default)
    textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    textBox.TextColor3 = Color3.new(1,1,1)
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.Parent = frame

    textBox.FocusLost:Connect(function(enterPressed)
        local val = tonumber(textBox.Text)
        if val then
            val = math.clamp(val, min, max)
            textBox.Text = tostring(val)
            label.Text = name .. ": " .. tostring(val)
            callback(val)
        end
    end)
    return frame
end

-- ==================== BIẾN CẤU HÌNH ====================
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

-- ==================== TẠO CÁC NÚT ĐIỀU KHIỂN ====================
CreateToggle("Tự động chữa trị (Auto Heal)", false, function(v) _G.Config.AutoHeal = v end)
CreateToggle("Tương tác tức thì (0 giây)", false, function(v)
    _G.Config.InstantInteract = v
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if v then
                if not OriginalDurations[prompt] then OriginalDurations[prompt] = prompt.HoldDuration end
                prompt.HoldDuration = 0
            else
                if OriginalDurations[prompt] then prompt.HoldDuration = OriginalDurations[prompt] end
            end
        end
    end
end)
CreateToggle("Tự động uống Cà phê (giữ Sanity)", false, function(v) _G.Config.AutoSanity = v end)
CreateToggle("Tự động tiếp tân (Chụp ảnh & Đóng dấu)", false, function(v) _G.Config.AutoReception = v end)
CreateToggle("Tự đóng cửa sập tránh Dị thường", false, function(v) _G.Config.AutoShutter = v end)
CreateToggle("Tự động giải Phòng X-Ray (Phòng 6)", false, function(v) _G.Config.AutoRoom6 = v end)
CreateToggle("Tự động giải Heart Scan (Phòng 7)", false, function(v) _G.Config.AutoRoom7 = v end)
CreateToggle("Tự động giải Phẫu thuật (Phòng 8)", false, function(v) _G.Config.AutoRoom8 = v end)
CreateToggle("Tự động dọn Slime & Dập Lửa", false, function(v) _G.Config.AutoClean = v end)
CreateToggle("ESP Thú cưng (xanh)", false, function(v) _G.Config.ESP_Animals = v end)
CreateToggle("ESP Dị thường (đỏ)", false, function(v) _G.Config.ESP_Anomalies = v end)
CreateToggle("ESP Người chơi khác", false, function(v) _G.Config.ESP_Players = v end)
CreateSlider("Tốc độ di chuyển", 16, 120, 16, function(v)
    _G.Config.WalkSpeed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
CreateSlider("Sức nhảy", 50, 150, 50, function(v)
    _G.Config.JumpPower = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)

-- Nút thu nhỏ
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ContentFrame.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 320, 0, 45) or UDim2.new(0, 320, 0, 450)
end)

-- ==================== CHỐNG AFK ====================
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- ==================== CÁC HÀM HỖ TRỢ ESP ====================
local espFolder = Instance.new("Folder")
espFolder.Name = "AH_ESP"
espFolder.Parent = CoreGui

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

-- ==================== CÁC VÒNG LẶP CHỨC NĂNG ====================

-- Auto Heal
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoHeal then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local bestPrompt, bestDist = nil, math.huge

            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local action = desc.ActionText:lower()
                    if action:find("chữa") or action:find("điều trị") or action:find("heal") or action:find("treat") then
                        local toolName = desc.Parent.Name
                        local backpack = LocalPlayer:FindFirstChild("Backpack")
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

-- Auto Sanity
task.spawn(function()
    while task.wait(1.5) do
        if not _G.Config.AutoSanity then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            for _, prompt in ipairs(Workspace:GetDescendants()) do
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

-- Auto Shutter
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoShutter then continue end
        pcall(function()
            local hasAnomaly = false
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    if obj.Name == "Ratthew" or obj.Name == "Barney" then continue end
                    if obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true then
                        hasAnomaly = true
                        break
                    end
                end
            end
            if hasAnomaly then
                for _, prompt in ipairs(Workspace:GetDescendants()) do
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

-- Auto Reception
task.spawn(function()
    while task.wait(0.4) do
        if not _G.Config.AutoReception then continue end
        pcall(function()
            for _, prompt in ipairs(Workspace:GetDescendants()) do
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

-- ESP Loop
task.spawn(function()
    while task.wait(1) do
        if not _G.Config.ESP_Animals and not _G.Config.ESP_Anomalies and not _G.Config.ESP_Players then
            clearESP()
            continue
        end

        if _G.Config.ESP_Animals then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("IsPatient") == true or obj.Name:lower():find("patient")) then
                    addESP(obj, Color3.fromRGB(75, 255, 75))
                end
            end
        end

        if _G.Config.ESP_Anomalies then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true or obj.Name:lower():find("anomaly") or obj.Name:lower():find("jumpscaredummy")) then
                    addESP(obj, Color3.fromRGB(255, 0, 0))
                end
            end
        end

        if _G.Config.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    addESP(plr.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
    end
end)

-- Auto Room 6
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom6 then continue end
        pcall(function()
            local room6 = Workspace:FindFirstChild("Room6", true) or Workspace:FindFirstChild("Emergency", true):FindFirstChild("Room6")
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

-- Auto Room 7
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom7 then continue end
        pcall(function()
            local room7 = Workspace:FindFirstChild("Room7", true)
            if room7 then
                local scanPrompt = room7:FindFirstChild("ProximityPrompt", true)
                if scanPrompt and scanPrompt.Enabled then
                    fireproximityprompt(scanPrompt)
                end

                local localGui = LocalPlayer:WaitForChild("PlayerGui")
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

-- Auto Room 8
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoRoom8 then continue end
        pcall(function()
            local room8 = Workspace:FindFirstChild("Room8", true)
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

-- Auto Clean
task.spawn(function()
    while task.wait(0.5) do
        if not _G.Config.AutoClean then continue end
        pcall(function()
            for _, desc in ipairs(Workspace:GetDescendants()) do
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

-- Giữ tốc độ khi hồi sinh
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.Config.WalkSpeed
        char.Humanoid.JumpPower = _G.Config.JumpPower
    end
end)
