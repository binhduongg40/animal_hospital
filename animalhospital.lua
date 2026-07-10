-- TRÌNH NẠP ANIMAL HOSPITAL VIP HUB
local rawUrl = "https://raw.githubusercontent.com/binhduongg40/animal_hospital/refs/heads/main/animal.lua"  -- THAY URL CỦA BẠN

local success, result = pcall(function()
    return game:HttpGet(rawUrl, true)
end)

if success and type(result) == "string" and result ~= "" then
    local func, err = loadstring(result)
    if func then
        func()
    else
        warn("Lỗi biên dịch: " .. tostring(err))
    end
else
    warn("Không thể tải script từ GitHub!")
end
