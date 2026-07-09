-- TRÌNH NẠP BẢN HỖ TRỢ ANIMAL HOSPITAL VIỆT HUB CHÍNH CHỦ
local rawUrl = "https://raw.githubusercontent.com/binhduongg40/animal_hospital/refs/heads/main/animal.lua"
local success, result = pcall(function()
    return game:HttpGet(rawUrl, true)
end)

if success and type(result) == "string" and result ~= "" then
    local executable, loadErr = loadstring(result)
    if executable then
        executable()
    else
        warn("Lỗi biên dịch mã nguồn từ xa: ".. tostring(loadErr))
    end
else
    warn("Lỗi: Không thể kết nối hoặc tải tệp dữ liệu thô từ GitHub!")
end
