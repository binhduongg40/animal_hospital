-- =====================================================
-- ANIMAL HOSPITAL HUB (Orion Library Edition - No Key)
-- Tối ưu hóa tối đa cho Delta Executor (Mobile/PC)
-- =====================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- 1. TRÁNH TRÙNG LẬP GIAO DIỆN GÂY TRÀN RAM
local safeParent = (gethui and pcall(gethui) and gethui()) or CoreGui
if safeParent:FindFirstChild("Orion") then
    safeParent:FindFirstChild("Orion"):Destroy()
end

-- 2. TẢI THƯ VIỆN ORION TỪ CDN
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- 3. CHỐNG AFK TOÀN DIỆN
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- 4. BIẾN CẤU HÌNH TOÀN CỤC
_G.Config = {
    AutoHeal = false, InstantInteract = false, AutoSanity = false, 
    AutoShutter = false, AutoReception = false, AutoRoom6 = false, 
    AutoRoom7 = false, AutoRoom8 = false, AutoClean = false,
    ESP_Animals = false, ESP_Anomalies = false, ESP_Players = false,
    WalkSpeed = 16, JumpPower = 50
}
local ESP_Objects = {}
local OriginalDurations = {}

-- 5. KHỞI TẠO GIAO DIỆN
local Window = OrionLib:MakeWindow({
    Name = "🐾 Việt Hub - Animal Hospital Tối Thượng",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AH_VietHub_Settings",
    IntroEnabled = true,
    IntroText = "Chào mừng " .. LocalPlayer.Name .. "!"
})

-- ==================== TAB: TỰ ĐỘNG ====================
local AutoTab = Window:MakeTab({ Name = "Tự Động (Farm)", Icon = "rbxassetid://4483345998", PremiumOnly = false })

AutoTab:AddToggle({ Name = "Tự động chữa trị (Khóa liên động an toàn)", Default = false, Callback = function(v) _G.Config.AutoHeal = v end })
AutoTab:AddToggle({ Name = "Tự động tiếp tân (Đón khách & Đóng dấu)", Default = false, Callback = function(v) _G.Config.AutoReception = v end })
AutoTab:AddToggle({ Name = "Tự đóng cửa sập (Chống Softlock Shift 11)", Default = false, Callback = function(v) _G.Config.AutoShutter = v end })
AutoTab:AddToggle({ Name = "Tự động uống Cà phê (Giữ Sanity)", Default = false, Callback = function(v) _G.Config.AutoSanity = v end })
AutoTab:AddToggle({ Name = "Tự động dọn Slime & Dập Lửa", Default = false, Callback = function(v) _G.Config.AutoClean = v end })

AutoTab:AddToggle({
    Name = "Tương tác tức thì (0s Hold Delay)",
    Default = false,
    Callback = function(v)
        _G.Config.InstantInteract = v
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if v then
                    if not OriginalDurations[obj] then OriginalDurations[obj] = obj.HoldDuration end
                    obj.HoldDuration = 0
                else
                    if OriginalDurations[obj] then obj.HoldDuration = OriginalDurations[obj] end
                end
            end
        end
    end
})

-- ==================== TAB: PHÒNG ĐẶC BIỆT ====================
local RoomsTab = Window:MakeTab({ Name = "Phòng Minigame", Icon = "rbxassetid://4483345998", PremiumOnly = false })
RoomsTab:AddToggle({ Name = "Giải X-Ray (Phòng 6)", Default = false, Callback = function(v) _G.Config.AutoRoom6 = v end })
RoomsTab:AddToggle({ Name = "Giải Nhịp Tim (Phòng 7)", Default = false, Callback = function(v) _G.Config.AutoRoom7 = v end })
RoomsTab:AddToggle({ Name = "Phẫu Thuật & Xúc Tu (Phòng 8)", Default = false, Callback = function(v) _G.Config.AutoRoom8 = v end })

-- ==================== CÁC VÒNG LẶP CHỨC NĂNG (TỐI ƯU ĐA LUỒNG) ====================

-- Auto Heal (Giữ nguyên logic kiểm tra balo an toàn của bạn)
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
                    if action:find("chữa") or action:find("heal") or action:find("treat") then
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
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if bestDist > bestPrompt.MaxActivationDistance then hum:MoveTo(pos) else fireproximityprompt(bestPrompt) end
                end
            end
        end)
    end
end)

-- Auto Shutter (Nâng cấp thêm IsPatient == false)
task.spawn(function()
    while task.wait(0.3) do
        if not _G.Config.AutoShutter then continue end
        pcall(function()
            local hasAnomaly = false
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    if obj.Name == "Ratthew" or obj.Name == "Barney" then continue end
                    -- Đã bổ sung thêm kiểm tra IsPatient
                    if obj:GetAttribute("Skinwalker") or obj:GetAttribute("IsAnomaly") or obj:GetAttribute("IsPatient") == false then
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
    while task.wait(0.5) do
        if not _G.Config.AutoReception then continue end
        pcall(function()
            for _, prompt in ipairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local act = prompt.ActionText:lower()
                    if act:find("stamp") or act:find("đóng dấu") or act:find("register") or act:find("nhận") or act:find("chụp") then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end)
    end
end)

-- Khởi chạy giao diện Orion
OrionLib:Init()
