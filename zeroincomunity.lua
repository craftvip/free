-- =========================================================================
--   🎯 KEY STEAM ZEROIN HUB - STEAL AN EGG 🥚 (PHẦN 1/4)
--   TÍCH HỢP NÚT HƯỚNG DẪN GETKEY · CHU KỲ 24H · DÙNG THỬ 2 PHÚT
-- =========================================================================

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/HK1eqb9Q"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/zero.lua"

local KeyFileName = "ZeroIn_KeyData.json"
local TrialFileName = "ZeroIn_TrialData.json"
local TRIAL_DURATION = 120 -- Thời hạn dùng thử đúng 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

-- MODULE MÃ HÓA BẢO MẬT HEX-XOR
local CIPHER_KEY = 113

local function EncryptData(str: string): string
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr: string): string?
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function LoadTrialData()
    if isfile and readfile and isfile(TrialFileName) then
        local ok, raw = pcall(readfile, TrialFileName)
        if ok and raw and raw ~= "" then
            local dec = DecryptData(raw)
            if dec then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
                if parseOk and type(data) == "table" and data.StartTime and data.LastSeen then
                    if os.time() < data.LastSeen then
                        return { StartTime = 0, LastSeen = os.time(), Tampered = true }
                    end
                    return data
                end
            end
        end
    end
    return nil
end

local function SaveTrialData(startTime: number, lastSeen: number?)
    if writefile then
        pcall(function()
            local data = { StartTime = startTime, LastSeen = lastSeen or os.time(), Duration = TRIAL_DURATION }
            writefile(TrialFileName, EncryptData(HttpService:JSONEncode(data)))
        end)
    end
end

local function GetKeyRemainingTime(): number?
    if isfile and readfile and isfile(KeyFileName) then
        local ok, content = pcall(readfile, KeyFileName)
        if ok and content and content ~= "" then
            local decOk, data = pcall(function() return HttpService:JSONDecode(content) end)
            if decOk and type(data) == "table" and data.ExpireTimestamp then
                local left = data.ExpireTimestamp - os.time()
                if left > 0 then return left end
            end
        end
    end
    return nil
end

local function Save24hKey()
    if writefile then
        pcall(function()
            writefile(KeyFileName, HttpService:JSONEncode({ ExpireTimestamp = os.time() + 86400 }))
        end)
    end
end

-- THUẬT TOÁN ĐỐI SOÁT KEY 24H (GMT+7)
local function VerifyZeroInKey(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^zeroinfree%-", ""):gsub("^zeroin%-", "")

    local vnTime = os.time() + (7 * 3600)
    local testTimes = { vnTime, vnTime - 86400, vnTime + 3600 }

    for _, t in ipairs(testTimes) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 4127 + d.month * 3389 + d.year * 163) % 65535
        local v2 = (d.day * 6781 + d.month * 5107 + d.year * 281) % 65535
        local v3 = (d.day * 8329 + d.month * 7219 + d.year * 401) % 65535
        local target = string.format("%04x-%04x-%04x", v1, v2, v3)

        if clean == target then
            return true
        end
    end
    return false
end
-- =========================================================================
--   🎯 KEY STEAM ZEROIN HUB - STEAL AN EGG 🥚 (PHẦN 2/4)
--   SNAPSHOT UI · KHÓA MÀN HÌNH CHẶT CHẼ · LIVE COUNTDOWN TOAST
-- =========================================================================

local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                InitialGuis[child] = true
            end
        end
    end
end

local function ApplyScreenLockdown()
    if not ActiveBlurEffect then
        ActiveBlurEffect = Instance.new("BlurEffect")
        ActiveBlurEffect.Name = "ZeroIn_LockdownBlur"
        ActiveBlurEffect.Size = 28
        ActiveBlurEffect.Parent = Lighting
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true
        end
    end

    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "ZeroIn_InputBlocker"
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(0, 4, 8)
        shield.BackgroundTransparency = 0.45
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then
        ActiveBlurEffect:Destroy()
        ActiveBlurEffect = nil
    end
    if InputBlockerScreen then
        InputBlockerScreen:Destroy()
        InputBlockerScreen = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        if hrp then
            hrp.Anchored = false
        end
    end
end

local function TerminateTargetScript()
    getgenv().ZeroIn_Active = false
    getgenv().ZeroIn_TrialExpired = true

    for _, conn in ipairs(ScriptConnections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(ScriptConnections)

    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child] and child.Name ~= "ZeroIn_GetKeyUI" and child.Name ~= "ZeroIn_ToastUI" and child.Name ~= "ZeroIn_InputBlocker" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function LaunchTargetScriptWithWatcher()
    TakeGuiSnapshot()
    getgenv().ZeroIn_Active = true

    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet(TargetScriptUrl))()
        end)
    end)
end

local function FormatTime(seconds: number): string
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d phút %02d giây", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, color: Color3)
    if CoreGui:FindFirstChild("ZeroIn_ToastUI") then CoreGui.ZeroIn_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ZeroIn_ToastUI") then
        LocalPlayer.PlayerGui.ZeroIn_ToastUI:Destroy()
    end

    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "ZeroIn_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 385, 0, 74)
    ToastFrame.Position = UDim2.new(0.5, -192, 0, -100)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(3, 10, 16)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 16)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.6
    Stroke.Color = color or Color3.fromRGB(6, 182, 212)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 42, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🎯"
    Icon.TextSize = 22
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -65, 0, 20)
    Title.Position = UDim2.new(0, 52, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = color or Color3.fromRGB(165, 243, 252)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBlack
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -65, 0, 20)
    Msg.Position = UDim2.new(0, 52, 0, 32)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời gian trải nghiệm: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(241, 245, 249)
    Msg.TextSize = 11
    Msg.Font = Enum.Font.GothamBold
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -24, 0, 3)
    BarBg.Position = UDim2.new(0, 12, 1, -6)
    BarBg.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
    BarBg.BorderSizePixel = 0
    BarBg.ZIndex = 51
    BarBg.Parent = ToastFrame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = color or Color3.fromRGB(6, 182, 212)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 52
    Bar.Parent = BarBg

    TweenService:Create(ToastFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -192, 0, 24) }):Play()
    TweenService:Create(Bar, TweenInfo.new(10, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -192, 0, -100), BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   🎯 KEY STEAM ZEROIN HUB - STEAL AN EGG 🥚 (PHẦN 3/4)
--   BỔ SUNG NÚT HƯỚNG DẪN GETKEY · LAYOUT CYBER TITAN 415PX
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VN ▾",
        SelectLangTitle = "🎯 CHỌN NGÔN NGỮ / LANGUAGE",
        Title = "Key Steam Zeroin Hub-steal an egg 🥚",
        Subtitle = "Cyber Edition · Phiên Bản 24 Giờ",
        CenterTitle = "ZEROIN HUB CYBER SYSTEM",
        CenterSub = "Trò chơi: Lấy trộm một quả trứng (Steal An Egg)",
        Placeholder = "Nhập mã key tại đây (zeroinfree-...)...",
        GetKey = "⚡ LẤY KEY (24 TIẾNG)",
        CheckKey = "🎯 KÍCH HOẠT KEY",
        Tutorial = "📖 HƯỚNG DẪN VƯỢT LINK GETKEY",
        Notice = "📌 Lưu ý: Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút vượt link). Mỗi key có hạn sử dụng đúng 24 giờ kể từ khi kích hoạt.",
        CopiedLink = "📋 ĐÃ SAO CHÉP LINK GETKEY 24 TIẾNG VÀO CLIPBOARD!",
        CopiedTutorial = "📖 ĐÃ SAO CHÉP LINK HƯỚNG DẪN VÀO CLIPBOARD!",
        Checking = "ĐANG XÁC THỰC...",
        CheckingMsg = "⏳ Đang đối soát chứng chỉ mã hóa trên máy chủ Zero In...",
        Success = "✔ Xác thực thành công! Đang khởi động Zero In Script...",
        Error = "✖ Mã Key không chính xác hoặc phiên 24 giờ đã hết hạn!"
    },
    EN = {
        LangBtnText = "🇺🇸 EN ▾",
        SelectLangTitle = "🎯 SELECT LANGUAGE / NGÔN NGỮ",
        Title = "Key Steam Zeroin Hub-steal an egg 🥚",
        Subtitle = "Cyber Edition · 24-Hour License",
        CenterTitle = "ZEROIN HUB CYBER SYSTEM",
        CenterSub = "Game: Steal An Egg",
        Placeholder = "Enter license key (zeroinfree-...)...",
        GetKey = "⚡ GET KEY (24 HOURS)",
        CheckKey = "🎯 ACTIVATE KEY",
        Tutorial = "📖 GETKEY TUTORIAL / GUIDE",
        Notice = "📌 Notice: 24-hour key link is fast and easy (takes only 1 min). Each key remains valid for exactly 24 hours.",
        CopiedLink = "📋 24-HOUR KEY LINK COPIED TO CLIPBOARD!",
        CopiedTutorial = "📖 TUTORIAL LINK COPIED TO CLIPBOARD!",
        Checking = "AUTHENTICATING...",
        CheckingMsg = "⏳ Verifying cyber credentials with Zero In server...",
        Success = "✔ License verified! Launching Zero In Script...",
        Error = "✖ Invalid key or expired 24-hour license!"
    }
}
local CurrentLang = "VI"

local function PlayDeepBounce(btn: TextButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 6, origSize.Y.Scale, origSize.Y.Offset - 4)
    local shrinkPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 3, origPos.Y.Scale, origPos.Y.Offset + 2)
    
    local t1 = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

OpenKeySystemUI = function()
    if CoreGui:FindFirstChild("ZeroIn_GetKeyUI") then CoreGui.ZeroIn_GetKeyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZeroIn_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Khung Chính Mở Rộng Thêm Không Gian Cho Nút Hướng Dẫn (440 x 415)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 440, 0, 415)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(4, 12, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.5

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.6
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(6, 182, 212)

    RunService.RenderStepped:Connect(function()
        local val = (math.sin(tick() * 2.5) + 1) / 2
        local r = (6 + math.floor(val * 28)) / 255
        local g = (182 + math.floor(val * 40)) / 255
        local b = (212 + math.floor(val * 43)) / 255
        MainStroke.Color = Color3.new(r, g, b)
    end)

    -- HEADER TOP BAR
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -24, 0, 40)
    HeaderBar.Position = UDim2.new(0, 12, 0, 10)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 28, 0, 28)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -14)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(8, 26, 38)
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(6, 182, 212)

    local MiniLogoTxt = Instance.new("TextLabel")
    MiniLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoTxt.BackgroundTransparency = 1
    MiniLogoTxt.Text = "🎯"
    MiniLogoTxt.TextSize = 13
    MiniLogoTxt.ZIndex = 33
    MiniLogoTxt.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -110, 0, 18)
    TitleLabel.Position = UDim2.new(0, 36, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
    TitleLabel.TextSize = 11.5
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -110, 0, 14)
    SubTitleLabel.Position = UDim2.new(0, 36, 0, 20)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(34, 211, 238)
    SubTitleLabel.TextSize = 9.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 78, 0, 26)
    OpenLangBtn.Position = UDim2.new(1, -78, 0.5, -13)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(165, 243, 252)
    OpenLangBtn.TextSize = 11
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 8)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(6, 182, 212)
    LangStroke.Thickness = 1

    -- LOGO TRUNG TÂM
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 54, 0, 54)
    CenterLogoBox.Position = UDim2.new(0.5, -27, 0, 48)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(6, 20, 30)
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 16)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(6, 182, 212)
    CenterLogoStroke.Thickness = 1.4

    local CenterLogoTxt = Instance.new("TextLabel")
    CenterLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    CenterLogoTxt.BackgroundTransparency = 1
    CenterLogoTxt.Text = "🥚"
    CenterLogoTxt.TextSize = 26
    CenterLogoTxt.ZIndex = 32
    CenterLogoTxt.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 20)
    CenterTitle.Position = UDim2.new(0, 15, 0, 108)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    CenterTitle.TextSize = 13.5
    CenterTitle.Font = Enum.Font.GothamBlack
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 16)
    CenterSub.Position = UDim2.new(0, 15, 0, 128)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(34, 211, 238)
    CenterSub.TextSize = 10
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- Ô NHẬP KEY
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -36, 0, 38)
    InputBox.Position = UDim2.new(0, 18, 0, 150)
    InputBox.BackgroundColor3 = Color3.fromRGB(5, 16, 24)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 130, 150)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11.5
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 31
    InputBox.Parent = MainFrame
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 10)
    local InputStroke = Instance.new("UIStroke", InputBox)
    InputStroke.Color = Color3.fromRGB(20, 50, 70)

    -- HÀNG NÚT CHÍNH: LẤY KEY 24 TIẾNG & KÍCH HOẠT KEY
    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 40)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 194)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(2, 10, 16)
    GetKeyBtn.TextSize = 11.5
    GetKeyBtn.Font = Enum.Font.GothamBlack
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)
    local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
    GetKeyStroke.Color = Color3.fromRGB(34, 211, 238)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 6, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(165, 243, 252)
    CheckKeyBtn.TextSize = 11.5
    CheckKeyBtn.Font = Enum.Font.GothamBlack
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 10)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(6, 182, 212)
    CheckStroke.Thickness = 1.4

    -- NÚT HƯỚNG DẪN GETKEY MỚI (CYBER GLASS HOVER)
    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 34)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 240)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(6, 22, 34)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(125, 211, 252)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 10)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(14, 116, 144)
    TutorialStroke.Thickness = 1.2

    -- BẢNG THÔNG BÁO 24 TIẾNG
    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 68)
    NoticeCard.Position = UDim2.new(0, 18, 0, 282)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(5, 16, 24)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 10)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(18, 45, 65)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -10)
    NoticeText.Position = UDim2.new(0, 8, 0, 5)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(224, 242, 254)
    NoticeText.TextSize = 10.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 22)
    StatusMsg.Position = UDim2.new(0, 18, 0, 360)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Zero In Engine · 24-Hour Cycle Online"
    StatusMsg.TextColor3 = Color3.fromRGB(100, 140, 170)
    StatusMsg.TextSize = 9.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame
    -- =========================================================================
--   🎯 KEY STEAM ZEROIN HUB - STEAL AN EGG 🥚 (PHẦN 4/4)
--   SỰ KIỆN SAO CHÉP HƯỚNG DẪN · BILINGUAL MODAL · ĐẾM NGƯỢC 2 PHÚT
-- =========================================================================

    local LangModal = Instance.new("Frame")
    LangModal.Name = "LangModal"
    LangModal.Size = UDim2.new(1, 0, 1, 0)
    LangModal.Position = UDim2.new(0, 0, 1, 0)
    LangModal.BackgroundColor3 = Color3.fromRGB(3, 8, 12)
    LangModal.BackgroundTransparency = 0.02
    LangModal.ZIndex = 40
    LangModal.Parent = MainFrame
    Instance.new("UICorner", LangModal).CornerRadius = UDim.new(0, 20)

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Size = UDim2.new(1, -60, 0, 30)
    ModalTitle.Position = UDim2.new(0, 20, 0, 18)
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Text = Languages[CurrentLang].SelectLangTitle
    ModalTitle.TextColor3 = Color3.fromRGB(6, 182, 212)
    ModalTitle.TextSize = 12
    ModalTitle.Font = Enum.Font.GothamBlack
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
    ModalTitle.ZIndex = 41
    ModalTitle.Parent = LangModal

    local CloseModalBtn = Instance.new("TextButton")
    CloseModalBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseModalBtn.Position = UDim2.new(1, -40, 0, 18)
    CloseModalBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)
    CloseModalBtn.Text = "✕"
    CloseModalBtn.TextColor3 = Color3.fromRGB(239, 68, 68)
    CloseModalBtn.TextSize = 12
    CloseModalBtn.Font = Enum.Font.GothamBold
    CloseModalBtn.ZIndex = 41
    CloseModalBtn.Parent = LangModal
    Instance.new("UICorner", CloseModalBtn).CornerRadius = UDim.new(0, 6)

    local LangList = Instance.new("Frame")
    LangList.Size = UDim2.new(1, -40, 0, 150)
    LangList.Position = UDim2.new(0, 20, 0, 65)
    LangList.BackgroundTransparency = 1
    LangList.ZIndex = 41
    LangList.Parent = LangModal

    local OptViBtn = Instance.new("TextButton")
    OptViBtn.Size = UDim2.new(1, 0, 0, 56)
    OptViBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)
    OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
    OptViBtn.TextColor3 = Color3.fromRGB(165, 243, 252)
    OptViBtn.TextSize = 13
    OptViBtn.Font = Enum.Font.GothamBlack
    OptViBtn.ZIndex = 42
    OptViBtn.AutoButtonColor = false
    OptViBtn.Parent = LangList
    Instance.new("UICorner", OptViBtn).CornerRadius = UDim.new(0, 12)
    local OptViStroke = Instance.new("UIStroke", OptViBtn)
    OptViStroke.Color = Color3.fromRGB(6, 182, 212)
    OptViStroke.Thickness = 1.5

    local OptEnBtn = Instance.new("TextButton")
    OptEnBtn.Size = UDim2.new(1, 0, 0, 56)
    OptEnBtn.Position = UDim2.new(0, 0, 0, 68)
    OptEnBtn.BackgroundColor3 = Color3.fromRGB(5, 16, 24)
    OptEnBtn.Text = "🇺🇸  English (Global)"
    OptEnBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    OptEnBtn.TextSize = 13
    OptEnBtn.Font = Enum.Font.GothamMedium
    OptEnBtn.ZIndex = 42
    OptEnBtn.AutoButtonColor = false
    OptEnBtn.Parent = LangList
    Instance.new("UICorner", OptEnBtn).CornerRadius = UDim.new(0, 12)
    local OptEnStroke = Instance.new("UIStroke", OptEnBtn)
    OptEnStroke.Color = Color3.fromRGB(20, 50, 70)

    local function SetLanguage(code: string)
        CurrentLang = code
        local data = Languages[code]
        OpenLangBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        CenterTitle.Text = data.CenterTitle
        CenterSub.Text = data.CenterSub
        InputBox.PlaceholderText = data.Placeholder
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        NoticeText.Text = data.Notice
        ModalTitle.Text = data.SelectLangTitle

        if code == "VI" then
            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
            OptViBtn.TextColor3 = Color3.fromRGB(165, 243, 252)
            OptViBtn.Font = Enum.Font.GothamBlack
            OptViStroke.Color = Color3.fromRGB(6, 182, 212)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)

            OptEnBtn.Text = "🇺🇸  English (Global)"
            OptEnBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
            OptEnBtn.Font = Enum.Font.GothamMedium
            OptEnStroke.Color = Color3.fromRGB(20, 50, 70)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(5, 16, 24)
        else
            OptEnBtn.Text = "🇺🇸  English (Global)  ✓"
            OptEnBtn.TextColor3 = Color3.fromRGB(165, 243, 252)
            OptEnBtn.Font = Enum.Font.GothamBlack
            OptEnStroke.Color = Color3.fromRGB(6, 182, 212)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(8, 26, 38)

            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)"
            OptViBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
            OptViBtn.Font = Enum.Font.GothamMedium
            OptViStroke.Color = Color3.fromRGB(20, 50, 70)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(5, 16, 24)
        end
    end

    local function OpenLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end
    local function CloseLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end

    OpenLangBtn.MouseButton1Click:Connect(function() PlayDeepBounce(OpenLangBtn); OpenLangModal() end)
    CloseModalBtn.MouseButton1Click:Connect(function() PlayDeepBounce(CloseModalBtn); CloseLangModal() end)
    OptViBtn.MouseButton1Click:Connect(function() PlayDeepBounce(OptViBtn); SetLanguage("VI"); task.wait(0.15); CloseLangModal() end)
    OptEnBtn.MouseButton1Click:Connect(function() PlayDeepBounce(OptEnBtn); SetLanguage("EN"); task.wait(0.15); CloseLangModal() end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.4
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    -- SỰ KIỆN BẤM LẤY KEY (24 TIẾNG)
    GetKeyBtn.MouseButton1Click:Connect(function()
        PlayDeepBounce(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end
        
        GetKeyBtn.Text = "COPIED LINK (24H)!"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        GetKeyStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
                GetKeyStroke.Color = Color3.fromRGB(34, 211, 238)
                StatusMsg.Text = "Zero In Engine · 24-Hour Cycle Online"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 140, 170)
            end
        end)
    end)

    -- SỰ KIỆN BẤM NÚT HƯỚNG DẪN GETKEY
    TutorialBtn.MouseButton1Click:Connect(function()
        PlayDeepBounce(TutorialBtn)
        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "COPIED TUTORIAL LINK!"
        TutorialBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        TutorialStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.BackgroundColor3 = Color3.fromRGB(6, 22, 34)
                TutorialStroke.Color = Color3.fromRGB(14, 116, 144)
                StatusMsg.Text = "Zero In Engine · 24-Hour Cycle Online"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 140, 170)
            end
        end)
    end)

    -- SỰ KIỆN BẤM KÍCH HOẠT KEY
    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlayDeepBounce(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(165, 243, 252)

        task.wait(0.35)
        local isKeyValid = VerifyZeroInKey(InputBox.Text)

        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "SUCCESS"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 101, 52)
            CheckStroke.Color = Color3.fromRGB(74, 222, 128)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(74, 222, 128)

            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            task.wait(0.4)
            TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.5 }):Play()
            task.wait(0.25)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)

            InputStroke.Color = Color3.fromRGB(239, 68, 68)
            task.wait(0.6)
            InputStroke.Color = Color3.fromRGB(20, 50, 70)
        end
    end)
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & BẢO MẬT KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("ZEROIN HUB • BẢN QUYỀN (24H)", keyTimeLeft, Color3.fromRGB(6, 182, 212))
    LaunchTargetScriptWithWatcher()
    return
end

local trialData = LoadTrialData()

if not trialData then
    trialData = { StartTime = os.time(), LastSeen = os.time() }
    SaveTrialData(trialData.StartTime, trialData.LastSeen)
end

if trialData.Tampered then
    ApplyScreenLockdown()
    ShowLiveToast("⚠️ SECURITY: TAMPER DETECTED", 0, Color3.fromRGB(239, 68, 68))
    OpenKeySystemUI()
    return
end

local targetEndTime = trialData.StartTime + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(239, 68, 68))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("ZEROIN HUB • ĐANG THỬ NGHIỆM (2 PHÚT)", remaining, Color3.fromRGB(6, 182, 212))
    LaunchTargetScriptWithWatcher()

    task.spawn(function()
        local saveInterval = 0

        while true do
            task.wait(1)
            local currentRemaining = targetEndTime - os.time()

            if ActiveToastLabel and ActiveToastLabel.Parent then
                ActiveToastLabel.Text = "Thời gian trải nghiệm: " .. FormatTime(currentRemaining)
            end

            saveInterval = saveInterval + 1
            if saveInterval >= 10 then
                saveInterval = 0
                SaveTrialData(trialData.StartTime, os.time())
            end

            if GetKeyRemainingTime() then return end

            if currentRemaining <= 0 then
                SaveTrialData(trialData.StartTime, os.time())
                TerminateTargetScript()
                ApplyScreenLockdown()
                ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(239, 68, 68))
                task.wait(0.3)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
