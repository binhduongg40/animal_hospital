-- =====================================================
-- ANIMAL HOSPITAL MOBILE HUB (Delta Executor)
-- Không cần thư viện ngoài - Chạy trực tiếp
-- =====================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Xóa GUI cũ nếu có
local oldGui = CoreGui:FindFirstChild("AH_MobileHub")
if oldGui then oldGui:Destroy() end

-- Tạo ScreenGui chính
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AH_MobileHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- ====================== GIAO DIỆN CHÍNH ======================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
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
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🐾 Animal Hospital Hub"
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Nút thu nhỏ
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

-- Khung nội dung (có thể cuộn)
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 4
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
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
    frame.Size = UDim2.new(1, 0, 0, 45)
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
    textBox.Size = UDim2.new(1, 0, 0, 22)
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

-- ====================== CÁC BIẾN TRẠNG THÁI ======================
local autoHealEnabled = false
local espAnimalsEnabled = false
local espAnomaliesEnabled = false
local instantInteractEnabled = false
local autoSanityEnabled = false
local walkSpeed = 16

-- ====================== TẠO CÁC NÚT CHỨC NĂNG ======================
CreateToggle("Tự động chữa trị (Auto Heal)", false, function(v)
    autoHealEnabled = v
end)

CreateToggle("Tự động uống Cà phê (giữ Sanity)", false, function(v)
    autoSanityEnabled = v
end)

CreateToggle("Tương tác tức thì (0 giây)", false, function(v)
    instantInteractEnabled = v
    -- Điều chỉnh tất cả ProximityPrompt
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if v then
                if not prompt:GetAttribute("OriginalDuration") then
                    prompt:SetAttribute("OriginalDuration", prompt.HoldDuration)
                end
                prompt.HoldDuration = 0
            else
                local orig = prompt:GetAttribute("OriginalDuration")
                if orig then prompt.HoldDuration = orig end
            end
        end
    end
end)

CreateToggle("Hiện Thú cưng (ESP xanh)", false, function(v)
    espAnimalsEnabled = v
end)

CreateToggle("Hiện Dị thường (ESP đỏ)", false, function(v)
    espAnomaliesEnabled = v
end)

CreateSlider("Tốc độ di chuyển", 16, 120, 16, function(v)
    walkSpeed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

-- ====================== ESP HIGHLIGHT ======================
local espObjects = {}

local function addHighlight(model, color)
    if espObjects[model] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = CoreGui
    espObjects[model] = hl

    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if hl then hl:Destroy() end
            espObjects[model] = nil
        end
    end)
end

local function clearHighlights()
    for model, hl in pairs(espObjects) do
        if hl then hl:Destroy() end
        espObjects[model] = nil
    end
end

-- ====================== CÁC VÒNG LẶP CHỨC NĂNG ======================

-- Auto Heal Loop
task.spawn(function()
    while task.wait(0.3) do
        if not autoHealEnabled then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local nearestPrompt = nil
            local nearestDist = math.huge

            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local action = desc.ActionText:lower()
                    if action:find("chữa") or action:find("điều trị") or action:find("heal") or action:find("treat") then
                        local part = desc.Parent
                        if part and (part:IsA("BasePart") or part:IsA("Model")) then
                            local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
                            local dist = (root.Position - pos).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestPrompt = desc
                            end
                        end
                    end
                end
            end

            if nearestPrompt then
                local part = nearestPrompt.Parent
                local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if nearestDist > nearestPrompt.MaxActivationDistance then
                        humanoid:MoveTo(pos)
                    else
                        fireproximityprompt(nearestPrompt)
                    end
                end
            end
        end)
    end
end)

-- Auto Sanity (Coffee) Loop
task.spawn(function()
    while task.wait(1.5) do
        if not autoSanityEnabled then continue end
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

-- ESP Loop
task.spawn(function()
    while task.wait(1) do
        if not espAnimalsEnabled and not espAnomaliesEnabled then
            clearHighlights()
            continue
        end

        if espAnimalsEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("IsPatient") == true or obj.Name:lower():find("patient")) then
                    addHighlight(obj, Color3.fromRGB(75, 255, 75))
                end
            end
        end

        if espAnomaliesEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetAttribute("Skinwalker") == true or obj:GetAttribute("IsAnomaly") == true or obj.Name:lower():find("anomaly") or obj.Name:lower():find("jumpscaredummy")) then
                    addHighlight(obj, Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end
end)

-- Giữ tốc độ khi hồi sinh
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = walkSpeed
    end
end)

-- ====================== XỬ LÝ NÚT THU NHỎ ======================
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ContentFrame.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 300, 0, 45) or UDim2.new(0, 300, 0, 400)
end)
