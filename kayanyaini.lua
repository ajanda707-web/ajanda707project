-- =================================================================
-- Script  : SAMBUNG KATA AUTO PLAY v46.38 (PRAWIRAHUB EDITION)
-- Author  : PrawiraXLIV
-- Update  : PERFECT BLACKLIST (No mid-game reset to 0),
--           Flawless UpdateWordIndex Sniffer (No Pokedex bug),
--           Dual Slider, Kiamat Mode 💀, Zero-Lag Engine.
-- =================================================================

local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM               = game:GetService("VirtualInputManager")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer

local guiParent = (gethui and gethui()) or CoreGui
if guiParent:FindFirstChild("SambungKataGUI") then
    guiParent.SambungKataGUI:Destroy()
end

local scriptConnections = {}

-- ============================================================
-- CONFIG & ZERO-LAG CACHE DATABASES
-- ============================================================
local URLS = {
    "https://raw.githubusercontent.com/Bhuzel/RobloxScript/refs/heads/main/DatabaseBhuzel-KBBI-Indo.txt", 
    "https://raw.githubusercontent.com/sastrawi/sastrawi/master/data/kata-dasar.txt",                
    "https://raw.githubusercontent.com/Bhinneka/indonesian-wordlist/master/indonesian-wordlist.txt", 
    "https://raw.githubusercontent.com/eenvyexe/KBBI/refs/heads/main/words.txt"                      
}

local KamusDict       = {} 
local WordCache       = {} 
local LocalDB         = {} 
local UsedWords       = {}
local TempIgnored     = {} 
local scriptActive    = true
local autoTypeEnabled = false
local mainThread      = nil
local dbLoaded        = false
local isTyping        = false
local totalDuplicates = 0 

local function RegisterWord(w)
    if not w or #w < 1 then return false end
    local wl = string.lower(w)
    if not KamusDict[wl] then
        KamusDict[wl] = true
        for i = 1, math.min(3, #wl) do
            local p = string.sub(wl, 1, i)
            if not WordCache[p] then WordCache[p] = {} end
            table.insert(WordCache[p], wl)
        end
        return true
    end
    return false
end

-- TYPING & DELETE SPEED CONFIG
local TypingSpeed     = 0.05
local MIN_SPEED       = 0.01 
local MAX_SPEED       = 1.00 

local DeleteSpeed     = 0.05
local MIN_DEL_SPEED   = 0.01 
local MAX_DEL_SPEED   = 1.00 

-- FILTER MODES (19 MODES)
local filterModes = {
    "⚙️ Rotasi: KIAMAT (W,X,Z,V,F,Q)",
    "⚙️ Rotasi: 9 JEBAKAN MAUT",
    "⚙️ Rotasi: SME-IF-AH-EX",
    "⚙️ Rotasi: EH-IA-MEO-AEK",
    "⚙️ Rotasi: SME-IF-AH",
    "⚙️ Rotasi: SME-IF-EX",
    "⚙️ Rotasi: SME-AH-EX",
    "⚙️ Rotasi: IF-AH-EX",
    "⚙️ Rotasi: SME & IF",
    "⚙️ Rotasi: SME & AH",
    "⚙️ Rotasi: SME & EX",
    "⚙️ Rotasi: IF & AH",
    "⚙️ Rotasi: IF & EX",
    "⚙️ Rotasi: AH & EX",
    "📏 Urut: Terpanjang",
    "📏 Urut: Terpendek",
    "🩺 Filter: Medis/Kedokteran",
    "🇮🇩 Filter: Nasional/Indo",
    "🎲 Filter: Acak / Random"
}
local currentFilterIndex = 1

local medicalKeywords = {
    "fobia", "ologi", "itis", "oma", "osis", "sindrom", "terapi", "medis", "obat", "virus", 
    "bakteri", "sakit", "nyeri", "luka", "kanker", "tumor", "darah", "jantung", "paru", "hati", 
    "ginjal", "otak", "saraf", "gigi", "tulang", "kulit", "mata", "telinga", "hidung", "klinik", 
    "dokter", "perawat", "bidan", "apotek", "resep", "dosis", "injeksi", "vaksin", "infeksi", 
    "alergi", "imun", "gizi", "vitamin", "protein", "diet", "hamil", "janin", "lahir", "bayi", 
    "bedah", "bius", "pingsan", "koma", "kritis", "pulih", "sembuh", "sehat", "bugar", "pusing", 
    "mual", "muntah", "diare", "demam", "panas", "batuk", "pilek", "flu", "sesak", "asma", 
    "hipertensi", "anemia", "diabetes", "kolesterol", "stroke", "lumpuh", "kista", "polip", 
    "amandel", "ambeien", "wasir", "maag", "lambung", "usus", "hepatitis", "katarak", "glaukoma", 
    "buta", "tuli", "bisu", "eksim", "jerawat", "psikolog", "biologi", "mental", "stres", 
    "depresi", "cemas", "trauma", "autis", "genetik", "sel", "dna", "kapsul", "pil", "sirup", 
    "kuman", "toksin", "racun", "antibiotik", "anatomi", "fisiologi", "patologi", "diagnos", "gejala"
}

local nationalKeywords = {
    "indonesia", "nusantara", "bhinneka", "tunggal", "ika", "pancasila", "merdeka", 
    "republik", "bangsa", "negara", "garuda", "merah", "putih", "bendera", "pusaka", 
    "pertiwi", "proklamasi", "pahlawan", "patriot", "sumpah", "pemuda", "gotong", 
    "royong", "musyawarah", "mufakat", "toleransi", "adat", "suku", "budaya", 
    "jawa", "sumatra", "kalimantan", "sulawesi", "papua", "bali", "maluku", 
    "sabang", "merauke", "tni", "polri", "polisi", "tentara", "rupiah", "monas", 
    "presiden", "menteri", "gubernur", "bupati", "walikota", "rakyat", "adil", 
    "makmur", "sentosa", "jaya", "abadi", "ketuhanan", "kemanusiaan", "persatuan", 
    "kerakyatan", "keadilan", "sosial", "adab", "hikmat", "reformasi", "demokrasi",
    "konstitusi", "uud", "nkri", "soekarno", "hatta", "sudirman", "kartini"
}

local function isMedicalWord(w)
    for _, kw in ipairs(medicalKeywords) do
        if string.find(w, kw) then return true end
    end
    return false
end

local function isNationalWord(w)
    for _, kw in ipairs(nationalKeywords) do
        if string.find(w, kw) then return true end
    end
    return false
end

local DB_FILENAME     = "SambungKata_LocalDB.json"
local EXPORT_FILENAME = "SambungKata_Exported.json"

local LblDBStat, LblInfo, LblStatus, LblTyping, LblJoin, LblPre
local TriggerListRefresh 

local function UpdateInfoUI()
    if LblInfo then
        local modeStr = autoTypeEnabled and "AUTO" or "MANUAL"
        LblInfo.Text = "Mode: " .. modeStr .. " | " .. filterModes[currentFilterIndex]
    end
end

-- ============================================================
-- FILE SYSTEM (AUTO-SAVE / AUTO-LOAD)
-- ============================================================
local function CountLocalDB()
    local c = 0
    for _ in pairs(LocalDB) do c = c + 1 end
    return c
end

local function CountBlacklist()
    local c = 0
    for _ in pairs(UsedWords) do c = c + 1 end
    return c
end

local function UpdateDBStatUI()
    if LblDBStat then
        LblDBStat.Text = "DB: " .. CountLocalDB() .. " | Dup: " .. totalDuplicates .. " | Blk: " .. CountBlacklist()
    end
end

local function SaveLocalDB()
    if writefile then
        pcall(function() writefile(DB_FILENAME, HttpService:JSONEncode(LocalDB)) end)
    end
end

local function LoadLocalDB()
    if readfile and isfile and isfile(DB_FILENAME) then
        local ok, res = pcall(function() return HttpService:JSONDecode(readfile(DB_FILENAME)) end)
        if ok and type(res) == "table" then 
            LocalDB = res 
            for k, _ in pairs(LocalDB) do RegisterWord(k) end
        end
    end
end
LoadLocalDB()

-- ============================================================
-- FLAWLESS SNIFFER & TRUE GAME STATE CLEARER
-- ============================================================
local wordStatus = "waiting"
local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)

if remotes then
    local updateWordIndex = remotes:FindFirstChild("UpdateWordIndex")
    if updateWordIndex then
        table.insert(scriptConnections, updateWordIndex.OnClientEvent:Connect(function(data)
            if type(data) == "table" then
                -- [PERFECT FIX] HANYA MENANGKAP KATA BARU SAAT MATCH (Mengabaikan data.AllWords/Pokedex)
                if data.NewWord and type(data.NewWord) == "string" then
                    local cw = data.NewWord:lower():gsub("[^%a]", "")
                    if #cw > 1 then
                        UsedWords[cw] = true 
                        
                        if RegisterWord(cw) then
                            LocalDB[cw] = true
                            SaveLocalDB()
                        else
                            totalDuplicates = totalDuplicates + 1
                        end
                        
                        UpdateDBStatUI()
                        if TriggerListRefresh then TriggerListRefresh() end
                    end
                end
            end
        end))
    end

    if remotes:FindFirstChild("PlayerCorrect") then
        table.insert(scriptConnections, remotes.PlayerCorrect.OnClientEvent:Connect(function() wordStatus = "correct" end))
    end
    if remotes:FindFirstChild("UsedWordWarn") then
        table.insert(scriptConnections, remotes.UsedWordWarn.OnClientEvent:Connect(function() wordStatus = "wrong" end))
    end
end

-- ============================================================
-- THE TRUE BLACKLIST RESETTER
-- ============================================================
local function ForceClearBlacklist()
    if next(UsedWords) ~= nil or next(TempIgnored) ~= nil then
        UsedWords = {}
        TempIgnored = {}
        UpdateDBStatUI()
        if TriggerListRefresh then TriggerListRefresh() end
        if LblStatus then
            LblStatus.Text = "Ronde Selesai. Blacklist 0!"
            LblStatus.TextColor3 = THEME.Cyan
        end
    end
end

-- Reset ketika player benar-benar berdiri/keluar dari meja
table.insert(scriptConnections, LocalPlayer:GetAttributeChangedSignal("CurrentTable"):Connect(function()
    if not LocalPlayer:GetAttribute("CurrentTable") then
        ForceClearBlacklist()
    end
end))

-- Reset ketika ResultUI Game Over Muncul
if remotes and remotes:FindFirstChild("ResultUI") then
    table.insert(scriptConnections, remotes.ResultUI.OnClientEvent:Connect(function()
        ForceClearBlacklist()
    end))
end

-- ============================================================
-- UI THEME & ANIMATION ENGINE
-- ============================================================
THEME = {
    MainBackground = Color3.fromRGB(20, 20, 25),
    Transparency   = 0.05,
    StrokeColor    = Color3.fromRGB(60, 60, 70),
    TitleColor     = Color3.fromRGB(0, 255, 170),
    TextColor      = Color3.new(1, 1, 1),
    TextWhite      = Color3.fromRGB(255, 255, 255), 
    BtnStart       = Color3.fromRGB(0, 160, 80),
    BtnStop        = Color3.fromRGB(200, 50, 50),
    BtnDelete      = Color3.fromRGB(180, 40, 40),
    BtnExport      = Color3.fromRGB(20, 80, 120),
    BtnImport      = Color3.fromRGB(100, 60, 120),
    BtnReset       = Color3.fromRGB(50, 50, 80),
    BoxBg          = Color3.fromRGB(15, 15, 15),
    SlotBg         = Color3.fromRGB(35, 35, 40),
    Font           = Enum.Font.GothamBold,
    Neon           = Color3.fromRGB(57, 255, 20),
    Cyan           = Color3.fromRGB(50, 220, 255),
    Yellow         = Color3.fromRGB(255, 220, 50),
    Red            = Color3.fromRGB(255, 70, 70),
    Pink           = Color3.fromRGB(255, 100, 180),
    Nasional       = Color3.fromRGB(255, 80, 80),
    Kiamat         = Color3.fromRGB(255, 0, 50) 
}

local tweenBounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast   = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function AddStyle(instance, cornerRadius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, cornerRadius)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Color = THEME.StrokeColor
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function ApplyHover(btn, baseColor, isTransparent)
    local tInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if isTransparent then
        local baseTextColor = btn.TextColor3
        btn.MouseEnter:Connect(function() TweenService:Create(btn, tInfo, {TextColor3 = THEME.TitleColor}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, tInfo, {TextColor3 = baseTextColor}):Play() end)
        btn.MouseButton1Down:Connect(function() TweenService:Create(btn, tInfo, {TextColor3 = Color3.fromRGB(0,200,120)}):Play() end)
        btn.MouseButton1Up:Connect(function() TweenService:Create(btn, tInfo, {TextColor3 = THEME.TitleColor}):Play() end)
    else
        btn.MouseEnter:Connect(function()
            local c = btn.BackgroundColor3
            local h, s, v = Color3.toHSV(c)
            TweenService:Create(btn, tInfo, {BackgroundColor3 = Color3.fromHSV(h, s, math.clamp(v + 0.15, 0, 1))}):Play() 
        end)
        btn.MouseLeave:Connect(function()
            local c = btn.BackgroundColor3
            local h, s, v = Color3.toHSV(c)
            TweenService:Create(btn, tInfo, {BackgroundColor3 = Color3.fromHSV(h, s, math.clamp(v - 0.15, 0, 1))}):Play() 
        end)
    end
end

-- ============================================================
-- MAIN GUI CONSTRUCTION
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SambungKataGUI"
ScreenGui.Parent = guiParent
ScreenGui.ResetOnSpawn = false

local ResponsiveScale = Instance.new("UIScale", ScreenGui)
local camera = workspace.CurrentCamera
local BASE_RES = Vector2.new(1366, 768)
local function UpdateScale()
    if not camera then return end
    local v = camera.ViewportSize
    local scale = math.min(v.X/BASE_RES.X, v.Y/BASE_RES.Y)
    ResponsiveScale.Scale = math.clamp(scale, 0.6, 1.2)
end
table.insert(scriptConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale))
UpdateScale()

local Frame = Instance.new("Frame", ScreenGui)
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 340, 0, 660) 
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.8, 0, 0.5, 0) 
Frame.BackgroundColor3 = THEME.MainBackground
Frame.BackgroundTransparency = THEME.Transparency
Frame.BorderSizePixel = 0
Frame.Visible = true 
Frame.ClipsDescendants = false 
AddStyle(Frame, 12)

local MainScale = Instance.new("UIScale", Frame)
MainScale.Scale = 1

local HeaderFrame = Instance.new("Frame", Frame)
HeaderFrame.Size = UDim2.new(1, -30, 0, 30) 
HeaderFrame.Position = UDim2.new(0, 15, 0, 15)
HeaderFrame.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", HeaderFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.Position = UDim2.new(1, 0, 0, 0) 
CloseBtn.BackgroundColor3 = THEME.BtnStop
CloseBtn.Text = "X"
CloseBtn.Font = THEME.Font
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = THEME.TextColor
AddStyle(CloseBtn, 8)
ApplyHover(CloseBtn, THEME.BtnStop, false)

local MinBtn = Instance.new("TextButton", HeaderFrame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.AnchorPoint = Vector2.new(1, 0)
MinBtn.Position = UDim2.new(1, -38, 0, 0) 
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
MinBtn.Text = "-"
MinBtn.Font = THEME.Font
MinBtn.TextSize = 18
MinBtn.TextColor3 = THEME.TextColor
AddStyle(MinBtn, 8)
ApplyHover(MinBtn, Color3.fromRGB(80, 80, 90), false)

local Title = Instance.new("TextLabel", HeaderFrame)
Title.Size = UDim2.new(1, -80, 1, 0) 
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PrawiraHub - Sambung Kata"
Title.TextColor3 = THEME.TitleColor
Title.Font = THEME.Font
Title.TextSize = 14 
Title.TextXAlignment = Enum.TextXAlignment.Left

local function makeLabel(posY, defaultText, color, size, align)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -30, 0, 20)
    l.Position = UDim2.new(0, 15, 0, posY)
    l.BackgroundTransparency = 1
    l.Text = defaultText
    l.TextColor3 = color
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = size or 12
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.ZIndex = 6
    l.Parent = Frame
    return l
end

LblJoin   = makeLabel(50,  "● Belum join meja", THEME.Red, 12)
LblPre    = makeLabel(70,  "HURUF AWAL: -", THEME.Yellow, 13)
LblTyping = makeLabel(90,  "TARGET: -", THEME.Cyan, 12) 
LblStatus = makeLabel(110, "Status: Booting...", THEME.Yellow, 11)
LblDBStat = makeLabel(130, "DB: 0 | Dup: 0 | Blk: 0", Color3.fromRGB(150, 255, 150), 11)

local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, -30, 0, 1)
Line.Position = UDim2.new(0, 15, 0, 155)
Line.BackgroundColor3 = THEME.Neon
Line.BackgroundTransparency = 0.5
Line.BorderSizePixel = 0
Line.Parent = Frame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -30, 0, 25)
SearchBox.Position = UDim2.new(0, 15, 0, 165)
SearchBox.BackgroundColor3 = THEME.SlotBg
SearchBox.TextColor3 = THEME.Yellow
SearchBox.Font = Enum.Font.GothamSemibold
SearchBox.TextSize = 12
SearchBox.PlaceholderText = "🔍 Cari Awalan Manual (Bantu Teman)..."
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Frame
AddStyle(SearchBox, 6)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -30, 1, -485) 
Scroll.Position = UDim2.new(0, 15, 0, 195)
Scroll.BackgroundColor3 = THEME.BoxBg
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = THEME.TitleColor
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
AddStyle(Scroll, 6)
Scroll.Parent = Frame

local ScrollLayout = Instance.new("UIListLayout", Scroll)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder 
ScrollLayout.Padding = UDim.new(0, 2)

local ScrollPad = Instance.new("UIPadding", Scroll)
ScrollPad.PaddingLeft = UDim.new(0, 5)
ScrollPad.PaddingTop = UDim.new(0, 5)
ScrollPad.PaddingBottom = UDim.new(0, 5)

local function setScrollPlaceholder(text, color)
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
    end
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.LayoutOrder = 0
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
end
setScrollPlaceholder("Menunggu database...", THEME.Neon)

-- ============================================================
-- PERFECT BOTTOM STACKING LAYOUT
-- ============================================================

local ImportBox = Instance.new("TextBox")
ImportBox.Size = UDim2.new(1, -30, 0, 25)
ImportBox.Position = UDim2.new(0, 15, 1, -285)
ImportBox.BackgroundColor3 = THEME.BoxBg
ImportBox.TextColor3 = THEME.TextColor
ImportBox.Font = Enum.Font.Gotham
ImportBox.TextSize = 11
ImportBox.PlaceholderText = "Paste JSON database di sini..."
ImportBox.Text = ""
ImportBox.ClearTextOnFocus = false
ImportBox.Parent = Frame
AddStyle(ImportBox, 6)

local BtnFrame = Instance.new("Frame", Frame)
BtnFrame.Size = UDim2.new(1, -30, 0, 25)
BtnFrame.Position = UDim2.new(0, 15, 1, -250)
BtnFrame.BackgroundTransparency = 1

local BtnLayout = Instance.new("UIListLayout", BtnFrame)
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
BtnLayout.Padding = UDim.new(0, 8)

local function makeSmallBtn(w, text, bg, order)
    local b = Instance.new("TextButton", BtnFrame)
    b.Size = UDim2.new(0, w, 1, 0)
    b.BackgroundColor3 = bg
    b.Text = text
    b.TextColor3 = THEME.TextColor
    b.Font = THEME.Font
    b.TextSize = 11
    b.LayoutOrder = order
    AddStyle(b, 6)
    ApplyHover(b, bg, false)
    return b
end

local BtnExp = makeSmallBtn(95, "Export", THEME.BtnExport, 1)
local BtnImp = makeSmallBtn(95, "Import", THEME.BtnImport, 2)
local BtnDel = makeSmallBtn(104, "Clear DB", THEME.BtnDelete, 3)

-- 3A. TYPING SPEED SLIDER 
local SliderContainer = Instance.new("Frame", Frame)
SliderContainer.Size = UDim2.new(1, -30, 0, 25)
SliderContainer.Position = UDim2.new(0, 15, 1, -215)
SliderContainer.BackgroundTransparency = 1

local SpeedLabel = Instance.new("TextLabel", SliderContainer)
SpeedLabel.Size = UDim2.new(0, 95, 1, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Ketik: " .. string.format("%.2f", TypingSpeed) .. "s"
SpeedLabel.TextColor3 = THEME.TextColor
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.TextSize = 10
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local SliderLine = Instance.new("Frame", SliderContainer)
SliderLine.Size = UDim2.new(1, -95, 0, 6)
SliderLine.Position = UDim2.new(0, 95, 0.5, -3)
SliderLine.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SliderLine.ZIndex = 5
Instance.new("UICorner", SliderLine).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame", SliderLine)
SliderFill.Size = UDim2.new((TypingSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1, 0)
SliderFill.BackgroundColor3 = THEME.TitleColor
SliderFill.ZIndex = 6
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderKnob = Instance.new("Frame", SliderLine)
SliderKnob.Size = UDim2.new(0, 16, 0, 16)
SliderKnob.Position = UDim2.new((TypingSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), -8, 0.5, -8)
SliderKnob.BackgroundColor3 = THEME.TextWhite 
SliderKnob.ZIndex = 7
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local SliderHitbox = Instance.new("TextButton", SliderContainer)
SliderHitbox.Size = UDim2.new(1, -95, 1, 0)
SliderHitbox.Position = UDim2.new(0, 95, 0, 0)
SliderHitbox.BackgroundTransparency = 1
SliderHitbox.Text = ""
SliderHitbox.ZIndex = 10

local draggingSlider = false

local function updateSlider(inputX)
    local relativeX = inputX - SliderLine.AbsolutePosition.X
    local pct = math.clamp(relativeX / SliderLine.AbsoluteSize.X, 0, 1)
    
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderKnob.Position = UDim2.new(pct, -8, 0.5, -8)
    
    TypingSpeed = MIN_SPEED + (pct * (MAX_SPEED - MIN_SPEED))
    SpeedLabel.Text = "Ketik: " .. string.format("%.2f", TypingSpeed) .. "s"
end

SliderHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input.Position.X)
    end
end)

-- 3B. DELETE SPEED SLIDER 
local DelSliderContainer = Instance.new("Frame", Frame)
DelSliderContainer.Size = UDim2.new(1, -30, 0, 25)
DelSliderContainer.Position = UDim2.new(0, 15, 1, -180)
DelSliderContainer.BackgroundTransparency = 1

local DelSpeedLabel = Instance.new("TextLabel", DelSliderContainer)
DelSpeedLabel.Size = UDim2.new(0, 95, 1, 0)
DelSpeedLabel.BackgroundTransparency = 1
DelSpeedLabel.Text = "Hapus: " .. string.format("%.2f", DeleteSpeed) .. "s"
DelSpeedLabel.TextColor3 = THEME.TextColor
DelSpeedLabel.Font = Enum.Font.GothamSemibold
DelSpeedLabel.TextSize = 10
DelSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local DelSliderLine = Instance.new("Frame", DelSliderContainer)
DelSliderLine.Size = UDim2.new(1, -95, 0, 6)
DelSliderLine.Position = UDim2.new(0, 95, 0.5, -3)
DelSliderLine.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
DelSliderLine.ZIndex = 5
Instance.new("UICorner", DelSliderLine).CornerRadius = UDim.new(1, 0)

local DelSliderFill = Instance.new("Frame", DelSliderLine)
DelSliderFill.Size = UDim2.new((DeleteSpeed - MIN_DEL_SPEED) / (MAX_DEL_SPEED - MIN_DEL_SPEED), 0, 1, 0)
DelSliderFill.BackgroundColor3 = THEME.Red 
DelSliderFill.ZIndex = 6
Instance.new("UICorner", DelSliderFill).CornerRadius = UDim.new(1, 0)

local DelSliderKnob = Instance.new("Frame", DelSliderLine)
DelSliderKnob.Size = UDim2.new(0, 16, 0, 16)
DelSliderKnob.Position = UDim2.new((DeleteSpeed - MIN_DEL_SPEED) / (MAX_DEL_SPEED - MIN_DEL_SPEED), -8, 0.5, -8)
DelSliderKnob.BackgroundColor3 = THEME.TextWhite 
DelSliderKnob.ZIndex = 7
Instance.new("UICorner", DelSliderKnob).CornerRadius = UDim.new(1, 0)

local DelSliderHitbox = Instance.new("TextButton", DelSliderContainer)
DelSliderHitbox.Size = UDim2.new(1, -95, 1, 0)
DelSliderHitbox.Position = UDim2.new(0, 95, 0, 0)
DelSliderHitbox.BackgroundTransparency = 1
DelSliderHitbox.Text = ""
DelSliderHitbox.ZIndex = 10

local draggingDelSlider = false

local function updateDelSlider(inputX)
    local relativeX = inputX - DelSliderLine.AbsolutePosition.X
    local pct = math.clamp(relativeX / DelSliderLine.AbsoluteSize.X, 0, 1)
    
    DelSliderFill.Size = UDim2.new(pct, 0, 1, 0)
    DelSliderKnob.Position = UDim2.new(pct, -8, 0.5, -8)
    
    DeleteSpeed = MIN_DEL_SPEED + (pct * (MAX_DEL_SPEED - MIN_DEL_SPEED))
    DelSpeedLabel.Text = "Hapus: " .. string.format("%.2f", DeleteSpeed) .. "s"
end

DelSliderHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingDelSlider = true
        updateDelSlider(input.Position.X)
    end
end)


-- 4. DROPDOWN FILTER MENU
local FilterContainer = Instance.new("Frame", Frame)
FilterContainer.Size = UDim2.new(1, -30, 0, 25)
FilterContainer.Position = UDim2.new(0, 15, 1, -145)
FilterContainer.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
FilterContainer.ZIndex = 10
AddStyle(FilterContainer, 6)

local FilterDisplay = Instance.new("TextLabel", FilterContainer)
FilterDisplay.Size = UDim2.new(1, -30, 1, 0)
FilterDisplay.Position = UDim2.new(0, 10, 0, 0)
FilterDisplay.BackgroundTransparency = 1
FilterDisplay.Text = filterModes[currentFilterIndex]
FilterDisplay.TextColor3 = THEME.TitleColor
FilterDisplay.Font = THEME.Font
FilterDisplay.TextSize = 11
FilterDisplay.TextXAlignment = Enum.TextXAlignment.Left
FilterDisplay.ZIndex = 11

local DropdownArrow = Instance.new("TextLabel", FilterContainer)
DropdownArrow.Size = UDim2.new(0, 25, 1, 0)
DropdownArrow.Position = UDim2.new(1, -25, 0, 0)
DropdownArrow.BackgroundTransparency = 1
DropdownArrow.Text = "▼"
DropdownArrow.TextColor3 = THEME.TextColor
DropdownArrow.Font = THEME.Font
DropdownArrow.TextSize = 12
DropdownArrow.ZIndex = 11

local InvisBtn = Instance.new("TextButton", FilterContainer)
InvisBtn.Size = UDim2.new(1, 0, 1, 0)
InvisBtn.BackgroundTransparency = 1
InvisBtn.Text = ""
InvisBtn.ZIndex = 12

local DropdownScroll = Instance.new("ScrollingFrame", Frame)
DropdownScroll.Size = UDim2.new(1, -30, 0, 0) 
DropdownScroll.Position = UDim2.new(0, 15, 1, -150) 
DropdownScroll.AnchorPoint = Vector2.new(0, 1) 
DropdownScroll.BackgroundColor3 = THEME.SlotBg
DropdownScroll.ScrollBarThickness = 4
DropdownScroll.ZIndex = 50
DropdownScroll.Visible = false
AddStyle(DropdownScroll, 6)

local DropLayout = Instance.new("UIListLayout", DropdownScroll)
DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
DropLayout.Padding = UDim.new(0, 2)

local isDropOpen = false
local isDropAnimating = false
local tweenDropInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function ToggleDropdown(forceClose)
    if isDropAnimating then return end
    if forceClose and not isDropOpen then return end
    
    isDropAnimating = true
    isDropOpen = forceClose and false or not isDropOpen

    if isDropOpen then
        DropdownScroll.Visible = true
        DropdownArrow.Text = "▲"
        local t = TweenService:Create(DropdownScroll, tweenDropInfo, {Size = UDim2.new(1, -30, 0, 250)}) 
        t:Play()
        t.Completed:Connect(function() isDropAnimating = false end)
    else
        DropdownArrow.Text = "▼"
        local t = TweenService:Create(DropdownScroll, tweenDropInfo, {Size = UDim2.new(1, -30, 0, 0)})
        t:Play()
        t.Completed:Connect(function() 
            DropdownScroll.Visible = false
            isDropAnimating = false 
        end)
    end
end

InvisBtn.MouseButton1Click:Connect(function() ToggleDropdown() end)

for i, mode in ipairs(filterModes) do
    local opt = Instance.new("TextButton", DropdownScroll)
    opt.Size = UDim2.new(1, -10, 0, 25)
    opt.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
    opt.Text = "  " .. mode
    opt.TextColor3 = THEME.TextColor
    opt.Font = THEME.Font
    opt.TextSize = 11
    opt.TextXAlignment = Enum.TextXAlignment.Left
    opt.ZIndex = 51
    AddStyle(opt, 4)
    ApplyHover(opt, Color3.fromRGB(50, 40, 70), false)

    opt.MouseButton1Click:Connect(function()
        currentFilterIndex = i
        FilterDisplay.Text = filterModes[i]
        UpdateInfoUI()
        ToggleDropdown(true)
        if TriggerListRefresh then TriggerListRefresh() end
    end)
end
DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, #filterModes * 27)

local function makeBtnDown(posY, h, text, bg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -30, 0, h)
    b.Position = UDim2.new(0, 15, 1, posY)
    b.BackgroundColor3 = bg
    b.Text = text
    b.TextColor3 = THEME.TextColor
    b.Font = THEME.Font
    b.TextSize = 11
    b.Parent = Frame
    AddStyle(b, 6)
    ApplyHover(b, bg, false)
    return b
end

local BtnPlay  = makeBtnDown(-110, 35, "▶  AUTO PLAY: OFF", THEME.BtnStart)
BtnPlay.TextSize = 12
local BtnPlayBaseColor = THEME.BtnStart 

local BtnReset = makeBtnDown(-65, 25, "⟳ Kosongkan Blacklist Manual", THEME.BtnReset)

LblInfo = Instance.new("TextLabel", Frame)
LblInfo.Size = UDim2.new(1, -30, 0, 15)
LblInfo.Position = UDim2.new(0, 15, 1, -30)
LblInfo.BackgroundTransparency = 1
LblInfo.Text = "Mode: MANUAL | Auto-Save DB Aktif"
LblInfo.TextColor3 = Color3.fromRGB(120, 120, 120)
LblInfo.Font = Enum.Font.GothamSemibold
LblInfo.TextSize = 10
LblInfo.TextXAlignment = Enum.TextXAlignment.Center

UpdateInfoUI()

-- ============================================================
-- GLOBAL DRAG LOGIC
-- ============================================================
local draggingFrame, dragStart, startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isDropOpen and input.Position.Y > DropdownScroll.AbsolutePosition.Y and input.Position.Y < DropdownScroll.AbsolutePosition.Y + DropdownScroll.AbsoluteSize.Y then
            return
        end
        if draggingSlider or draggingDelSlider then return end 
        
        draggingFrame = true
        dragStart = input.Position
        startPos = Frame.Position 
    end
end)

table.insert(scriptConnections, UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFrame then
            local delta = (input.Position - dragStart) / ResponsiveScale.Scale
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        if draggingSlider then
            updateSlider(input.Position.X) 
        end
        if draggingDelSlider then
            updateDelSlider(input.Position.X) 
        end
    end
end))

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = false
        draggingSlider = false
        draggingDelSlider = false
    end
end)

-- ============================================================
-- MINIMIZED CIRCLE
-- ============================================================
local MinCircle = Instance.new("TextButton", ScreenGui)
MinCircle.Size = UDim2.new(0, 50, 0, 50)
MinCircle.AnchorPoint = Vector2.new(0.5, 0.5)
MinCircle.Position = UDim2.new(0.5, 0, 0, 45)
MinCircle.BackgroundColor3 = THEME.MainBackground
MinCircle.Text = "PH"
MinCircle.Font = Enum.Font.GothamBlack
MinCircle.TextSize = 20
MinCircle.TextColor3 = THEME.TitleColor
MinCircle.Visible = false
local CircleCorner = Instance.new("UICorner", MinCircle)
CircleCorner.CornerRadius = UDim.new(1, 0)
local CircleStroke = Instance.new("UIStroke", MinCircle)
CircleStroke.Color = THEME.TitleColor
CircleStroke.Thickness = 3
CircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ApplyHover(MinCircle, THEME.MainBackground, false)

local MinCircleScale = Instance.new("UIScale", MinCircle)
MinCircleScale.Scale = 0

local isAnimating = false
MinBtn.MouseButton1Click:Connect(function()
    if isAnimating then return end
    isAnimating = true
    local tOut = TweenService:Create(MainScale, tweenFast, {Scale = 0})
    tOut:Play()
    tOut.Completed:Connect(function()
        Frame.Visible = false
        MinCircle.Visible = true
        TweenService:Create(MinCircleScale, tweenBounce, {Scale = 1}):Play()
        isAnimating = false
    end)
end)

local draggingCircle, dragStartCircle, startPosCircle
local hasMovedCircle = false
MinCircle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingCircle = true
        hasMovedCircle = false
        dragStartCircle = input.Position
        startPosCircle = MinCircle.Position
    end
end)

table.insert(scriptConnections, UserInputService.InputChanged:Connect(function(input)
    if draggingCircle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = (input.Position - dragStartCircle) / ResponsiveScale.Scale
        if delta.Magnitude > 5 then hasMovedCircle = true end
        if hasMovedCircle then
            MinCircle.Position = UDim2.new(startPosCircle.X.Scale, startPosCircle.X.Offset + delta.X, startPosCircle.Y.Scale, startPosCircle.Y.Offset + delta.Y)
        end
    end
end))

MinCircle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingCircle = false
        if not hasMovedCircle then
            if isAnimating then return end
            isAnimating = true
            local tOut = TweenService:Create(MinCircleScale, tweenFast, {Scale = 0})
            tOut:Play()
            tOut.Completed:Connect(function()
                MinCircle.Visible = false
                Frame.Visible = true
                TweenService:Create(MainScale, tweenBounce, {Scale = 1}):Play()
                isAnimating = false
            end)
        end
    end
end)

-- ============================================================
-- OVERLAYS (CONFIRMATION DELETE & TOTAL SHUTDOWN)
-- ============================================================
local function createOverlay(titleText, confirmCallback)
    local Overlay = Instance.new("Frame", ScreenGui)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.Visible = false
    Overlay.ZIndex = 100

    local Box = Instance.new("Frame", Overlay)
    Box.Size = UDim2.new(0, 260, 0, 120)
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Box.BackgroundColor3 = THEME.MainBackground
    Box.ZIndex = 101
    AddStyle(Box, 12)

    local Scale = Instance.new("UIScale", Box)
    Scale.Scale = 0

    local Text = Instance.new("TextLabel", Box)
    Text.Size = UDim2.new(1, 0, 0, 60)
    Text.BackgroundTransparency = 1
    Text.Text = titleText
    Text.Font = THEME.Font
    Text.TextColor3 = THEME.TextColor
    Text.TextSize = 13
    Text.ZIndex = 102

    local BtnYes = Instance.new("TextButton", Box)
    BtnYes.Size = UDim2.new(0, 100, 0, 35)
    BtnYes.Position = UDim2.new(0, 20, 1, -50)
    BtnYes.BackgroundColor3 = THEME.BtnStop
    BtnYes.Text = "YES"
    BtnYes.Font = THEME.Font
    BtnYes.TextColor3 = THEME.TextColor
    BtnYes.TextSize = 14
    BtnYes.ZIndex = 102
    AddStyle(BtnYes, 8)
    ApplyHover(BtnYes, THEME.BtnStop, false)

    local BtnNo = Instance.new("TextButton", Box)
    BtnNo.Size = UDim2.new(0, 100, 0, 35)
    BtnNo.Position = UDim2.new(1, -120, 1, -50)
    BtnNo.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    BtnNo.Text = "NO"
    BtnNo.Font = THEME.Font
    BtnNo.TextColor3 = THEME.TextColor
    BtnNo.TextSize = 14
    BtnNo.ZIndex = 102
    AddStyle(BtnNo, 8)
    ApplyHover(BtnNo, Color3.fromRGB(100, 100, 100), false)

    local function HideOverlay()
        TweenService:Create(Scale, tweenFast, {Scale = 0}):Play()
        local fade = TweenService:Create(Overlay, tweenFast, {BackgroundTransparency = 1})
        fade:Play()
        fade.Completed:Connect(function() Overlay.Visible = false end)
    end

    BtnNo.MouseButton1Click:Connect(HideOverlay)
    BtnYes.MouseButton1Click:Connect(function()
        confirmCallback()
        HideOverlay()
    end)

    return Overlay, Scale
end

local DelOverlay, DelScale = createOverlay("Are you sure delete Local DB?", function()
    LocalDB = {}
    if delfile and isfile and isfile(DB_FILENAME) then
        pcall(function() delfile(DB_FILENAME) end)
    end
    SaveLocalDB()
    UpdateDBStatUI()
end)

local CloseOverlay, CloseScale = createOverlay("Are you sure you want to close?", function()
    scriptActive = false
    autoTypeEnabled = false
    if mainThread then task.cancel(mainThread) end
    for _, conn in ipairs(scriptConnections) do 
        if conn.Connected then conn:Disconnect() end 
    end
    
    -- MEMORY CLEANER PADA SAAT EXIT 
    KamusData = {}
    KamusDict = {}
    WordCache = {}
    UsedWords = {}
    TempIgnored = {}
    totalDuplicates = 0
    -- LocalDB TIDAK DIHAPUS agar aman di file JSON
    
    ScreenGui:Destroy()
end)

BtnDel.MouseButton1Click:Connect(function()
    DelOverlay.Visible = true
    TweenService:Create(DelOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(DelScale, tweenBounce, {Scale = 1}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    CloseOverlay.Visible = true
    TweenService:Create(CloseOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(CloseScale, tweenBounce, {Scale = 1}):Play()
end)

-- ============================================================
-- CORE LOGIC (FAST DETECTION)
-- ============================================================
local function getPrefix()
    local prefix = nil
    pcall(function()
        local mUI = LocalPlayer.PlayerGui:FindFirstChild("MatchUI")
        if not mUI then return end
        
        local bUI = mUI:FindFirstChild("BottomUI")
        if not bUI or not bUI.Visible then return end
        
        for _, v in ipairs(mUI:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                local match = v.Text:match("[Hh]uruf.*:%s*(%a+)")
                if match then prefix = match; return end
            end
        end
        
        if not prefix then
            for _, v in ipairs(mUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "WordServer" and v.Visible then
                    local t = v.Text:gsub("%s+", "") 
                    if t:match("^%a+$") and #t <= 3 then prefix = t; return end
                end
            end
        end

        if not prefix then
            for _, v in ipairs(mUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local t = v.Text:gsub("%s+", "") 
                    if t:match("^%u+$") and #t <= 3 and t ~= "UI" then 
                        local vName = string.lower(v.Name)
                        if not vName:match("close") and not vName:match("exit") then
                            prefix = t; return
                        end
                    end
                end
            end
        end
    end)
    return prefix and string.lower(prefix) or nil
end

local function TypeSingleWord(kata, prefix)
    LblTyping.Text = "TARGET: " .. string.upper(kata)
    
    LblStatus.Text = "Menghapus sisa teks..."
    LblStatus.TextColor3 = THEME.Yellow
    
    -- HAPUS PERSIAPAN INSTAN (0.01 detik agar sangat responsif saat diklik)
    for b = 1, 15 do
        if getPrefix() == nil then return false end
        VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
        task.wait(0.01) 
        VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
    end
    task.wait(0.05) 

    LblStatus.Text = "Mencoba: " .. string.upper(kata)
    LblStatus.TextColor3 = THEME.Cyan

    local sisaKata = string.sub(kata, #prefix + 1)
    for i = 1, #sisaKata do
        if getPrefix() == nil then return false end
        local charStr = string.sub(sisaKata, i, i)
        local kc = Enum.KeyCode[string.upper(charStr)]
        if kc then
            VIM:SendKeyEvent(true, kc, false, game)
            task.wait(0.02) 
            VIM:SendKeyEvent(false, kc, false, game)
        end
        task.wait(TypingSpeed)
    end

    wordStatus = "waiting"
    task.wait(0.05)
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05) 
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    
    local timeout = tick() + 1.5
    local isAccepted = false
    
    while tick() < timeout and scriptActive do
        task.wait(0.05)
        if wordStatus == "correct" or getPrefix() ~= prefix then
            isAccepted = true
            break
        end
        if wordStatus == "wrong" then break end
    end

    if isAccepted then
        UsedWords[kata] = true
        LblStatus.Text = "✓ BENAR: " .. string.upper(kata)
        LblStatus.TextColor3 = THEME.Neon
        
        if RegisterWord(kata) then
            LocalDB[kata] = true
            SaveLocalDB()
        else
            totalDuplicates = totalDuplicates + 1
        end
        UpdateDBStatUI()
        
        if TriggerListRefresh then TriggerListRefresh() end
        return true 
    else
        TempIgnored[kata] = true 
        LblStatus.Text = "❌ DITOLAK SERVER"
        LblStatus.TextColor3 = THEME.Red
        
        -- HAPUS KATA SALAH (ROLLBACK) MENGGUNAKAN SLIDER MERAH
        for _ = 1, #sisaKata do
            VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.015) 
            VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
            task.wait(DeleteSpeed)
        end
        
        UpdateDBStatUI()
        if TriggerListRefresh then TriggerListRefresh() end
        
        task.wait(0.1) 
        return false
    end
end

-- ============================================================
-- ZERO-LAG FILTERING ENGINE (19 MODES)
-- ============================================================
local function getSortedPool(prefix)
    local listSME      = {}
    local listIF       = {}
    local listAH       = {}
    local listEX       = {}
    local listEH       = {} 
    local listIA       = {} 
    local listMEO      = {}
    local listAEK      = {} 
    local listMedis    = {}
    local listNasional = {}
    local listKiamat   = {} -- W, X, Z, V, F, Q
    local nList        = {}
    local allValid     = {}
    local added        = {}
    
    local poolCache = WordCache[prefix]
    if not poolCache then return {} end

    for _, kata in ipairs(poolCache) do
        if not UsedWords[kata] and not TempIgnored[kata] then
            if not added[kata] then
                added[kata] = true
                table.insert(allValid, kata)
                local w = string.lower(kata)
                
                local isMed = false
                local isNas = false
                local isKiamat = false
                
                if currentFilterIndex == 17 then isMed = isMedicalWord(w) end
                if currentFilterIndex == 18 then isNas = isNationalWord(w) end
                
                -- Cek akhiran mematikan W, X, Z, V, F, Q
                if string.match(w, "[wxzvfq]$") then isKiamat = true end
                
                if currentFilterIndex == 1 and isKiamat then
                    table.insert(listKiamat, kata)
                elseif currentFilterIndex == 17 and isMed then
                    table.insert(listMedis, kata)
                elseif currentFilterIndex == 18 and isNas then
                    table.insert(listNasional, kata)
                elseif string.sub(w, -3) == "sme" then
                    table.insert(listSME, kata)
                elseif string.sub(w, -2) == "if" then
                    table.insert(listIF, kata)
                elseif string.sub(w, -2) == "ah" then
                    table.insert(listAH, kata)
                elseif string.sub(w, -2) == "ex" or string.sub(w, -3) == "eks" then
                    table.insert(listEX, kata)
                elseif string.sub(w, -2) == "eh" then
                    table.insert(listEH, kata)
                elseif string.sub(w, -2) == "ia" then
                    table.insert(listIA, kata)
                elseif string.sub(w, -3) == "meo" then
                    table.insert(listMEO, kata)
                elseif string.sub(w, -3) == "aek" then
                    table.insert(listAEK, kata)
                else
                    table.insert(nList, kata)
                end
            end
        end
    end

    local finalPool = {}

    local function interleave(...)
        local lists = {...}
        local maxLen = 0
        for _, l in ipairs(lists) do if #l > maxLen then maxLen = #l end end
        for i = 1, maxLen do
            for _, l in ipairs(lists) do
                if l[i] then table.insert(finalPool, l[i]) end
            end
        end
    end

    local function addResiduals(...)
        for _, l in ipairs({...}) do
            for _, k in ipairs(l) do table.insert(finalPool, k) end
        end
    end

    if currentFilterIndex == 1 then 
        addResiduals(listKiamat, listSME, listIF, listAH, listEX, listEH, listIA, listMEO, listAEK, nList)
        return finalPool
    elseif currentFilterIndex == 2 then interleave(listSME, listIF, listAH, listEX, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 3 then interleave(listSME, listIF, listAH, listEX); addResiduals(listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 4 then interleave(listEH, listIA, listMEO, listAEK); addResiduals(listSME, listIF, listAH, listEX)
    elseif currentFilterIndex == 5 then interleave(listSME, listIF, listAH); addResiduals(listEX, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 6 then interleave(listSME, listIF, listEX); addResiduals(listAH, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 7 then interleave(listSME, listAH, listEX); addResiduals(listIF, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 8 then interleave(listIF, listAH, listEX); addResiduals(listSME, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 9 then interleave(listSME, listIF); addResiduals(listAH, listEX, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 10 then interleave(listSME, listAH); addResiduals(listIF, listEX, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 11 then interleave(listSME, listEX); addResiduals(listIF, listAH, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 12 then interleave(listIF, listAH); addResiduals(listSME, listEX, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 13 then interleave(listIF, listEX); addResiduals(listSME, listAH, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 14 then interleave(listAH, listEX); addResiduals(listSME, listIF, listEH, listIA, listMEO, listAEK)
    elseif currentFilterIndex == 15 then 
        table.sort(allValid, function(a, b) return #a > #b end)
        return allValid 
    elseif currentFilterIndex == 16 then
        table.sort(allValid, function(a, b) return #a < #b end)
        return allValid 
    elseif currentFilterIndex == 17 then
        addResiduals(listMedis, listSME, listIF, listAH, listEX, listEH, listIA, listMEO, listAEK, nList)
        return finalPool
    elseif currentFilterIndex == 18 then
        addResiduals(listNasional, listSME, listIF, listAH, listEX, listEH, listIA, listMEO, listAEK, nList)
        return finalPool
    elseif currentFilterIndex == 19 then 
        for _, k in ipairs(allValid) do table.insert(finalPool, k) end
        for i = #finalPool, 2, -1 do
            local j = math.random(1, i)
            finalPool[i], finalPool[j] = finalPool[j], finalPool[i]
        end
        return finalPool
    end

    for _, k in ipairs(nList) do table.insert(finalPool, k) end
    return finalPool
end

-- ============================================================
-- UI LIST UPDATER (CLICKABLE & HELPER MODE)
-- ============================================================
local function updateListUI(prefix)
    local pool = getSortedPool(prefix)
    
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
    end

    local MAX_DISPLAY = 300 
    
    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, -10, 0, 20)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Font = Enum.Font.GothamBold
    headerLbl.TextSize = 11
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.LayoutOrder = 0 
    headerLbl.Parent = Scroll

    if #pool > 0 then
        headerLbl.Text = "[" .. #pool .. " kata] Klik utk Ketik/Salin:"
        headerLbl.TextColor3 = THEME.Neon
        
        for i, kata in ipairs(pool) do
            if i > MAX_DISPLAY then break end
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 18)
            btn.BackgroundTransparency = 1
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i 
            btn.Parent = Scroll
            
            local w = string.lower(kata)
            local iconStr = ""
            local txtColor = THEME.TextColor

            if string.match(w, "[wxzvfq]$") then
                iconStr = "💀 "
                txtColor = THEME.Kiamat
            elseif currentFilterIndex == 17 and isMedicalWord(w) then
                iconStr = "🏥 "
                txtColor = THEME.Pink
            elseif currentFilterIndex == 18 and isNationalWord(w) then
                iconStr = "🇮🇩 "
                txtColor = THEME.Nasional
            elseif string.sub(w, -3) == "sme" then
                iconStr = "☠️ "
                txtColor = Color3.fromRGB(180, 100, 255)
            elseif string.sub(w, -2) == "if" then
                iconStr = "🔥 "
                txtColor = THEME.Neon
            elseif string.sub(w, -2) == "ah" then
                iconStr = "⚡ "
                txtColor = Color3.fromRGB(200, 255, 100)
            elseif string.sub(w, -2) == "ex" or string.sub(w, -3) == "eks" then
                iconStr = "💥 "
                txtColor = Color3.fromRGB(255, 120, 120)
            elseif string.sub(w, -2) == "eh" then
                iconStr = "💨 "
                txtColor = Color3.fromRGB(150, 255, 255)
            elseif string.sub(w, -2) == "ia" then
                iconStr = "🌀 "
                txtColor = Color3.fromRGB(100, 150, 255)
            elseif string.sub(w, -3) == "meo" then
                iconStr = "🐱 "
                txtColor = Color3.fromRGB(255, 170, 50)
            elseif string.sub(w, -3) == "aek" then
                iconStr = "🦠 "
                txtColor = Color3.fromRGB(150, 255, 50)
            end
            
            if currentFilterIndex == 19 then
                iconStr = "🎲 " 
            end
            
            btn.Text = i .. ". " .. iconStr .. string.upper(kata)
            btn.TextColor3 = txtColor

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, tweenFast, {BackgroundTransparency = 0.8, BackgroundColor3 = THEME.TitleColor}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, tweenFast, {BackgroundTransparency = 1}):Play()
            end)

            btn.MouseButton1Click:Connect(function()
                if isTyping then return end
                
                local searchTxt = SearchBox.Text:lower():gsub("[^%a]", "")
                local p = getPrefix()
                
                if p and string.sub(kata, 1, #p) == p and searchTxt == "" then
                    task.spawn(function()
                        isTyping = true
                        TypeSingleWord(kata, p)
                        isTyping = false
                    end)
                else
                    if setclipboard then
                        setclipboard(string.upper(kata))
                        LblStatus.Text = "📋 TERSALIN: " .. string.upper(kata)
                        LblStatus.TextColor3 = THEME.Cyan
                    else
                        LblStatus.Text = "Bukan giliranmu! (Gagal Salin)"
                        LblStatus.TextColor3 = THEME.Red
                    end
                end
            end)
        end
    else
        headerLbl.Text = ">> KATA HABIS <<"
        headerLbl.TextColor3 = THEME.Red
    end
end

function TriggerListRefresh()
    local searchTxt = SearchBox.Text:lower():gsub("[^%a]", "")
    if searchTxt ~= "" then
        updateListUI(searchTxt)
    else
        local p = getPrefix()
        if p then updateListUI(p) end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if isTyping then return end
    local searchTxt = SearchBox.Text:lower():gsub("[^%a]", "")
    if searchTxt ~= "" then
        if autoTypeEnabled then
            autoTypeEnabled = false
            BtnPlay.Text = "▶  START AUTO PLAY"
            TweenService:Create(BtnPlay, TweenInfo.new(0.2), {BackgroundColor3 = THEME.BtnStart}):Play()
            UpdateInfoUI()
        end
        TriggerListRefresh()
    end
end)

-- ============================================================
-- AUTO-TYPE EXECUTION
-- ============================================================
local function ExecuteAutoType(prefix, searchPool)
    local strikeCount = 0 
    for _, kata in ipairs(searchPool) do
        if not autoTypeEnabled or not scriptActive then break end
        if strikeCount >= 3 then
            LblStatus.Text = "BAHAYA! 3x Ditolak, Manual!"
            LblStatus.TextColor3 = THEME.Red
            task.wait(2)
            break 
        end
        
        local success = TypeSingleWord(kata, prefix)
        if success then
            break 
        else
            strikeCount = strikeCount + 1
        end
    end
end

-- ============================================================
-- MAIN LOOP (ALWAYS-ON DETECTION)
-- ============================================================
mainThread = task.spawn(function()
    local lastPrefix = nil
    local lastSearch = nil
    
    while scriptActive do
        task.wait(0.1)
        if not dbLoaded then continue end

        local searchTxt = SearchBox.Text:lower():gsub("[^%a]", "")

        if searchTxt ~= "" then
            LblJoin.Text = "🔍 MODE PENCARIAN MANUAL"
            LblJoin.TextColor3 = THEME.Cyan
            LblPre.Text = "CARI AWALAN: " .. string.upper(searchTxt)
            LblTyping.Text = "Klik kata untuk COPY 📋"
            LblStatus.Text = "Membantu teman..."
            LblStatus.TextColor3 = THEME.Yellow
            
            if searchTxt ~= lastSearch then
                lastSearch = searchTxt
                updateListUI(searchTxt)
            end
            
            isTyping = false
            continue
        else
            lastSearch = nil
        end

        local function isJoinedFast()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                if char.Humanoid.Sit == false then return false end
            end
            local ok, r = pcall(function()
                local m = LocalPlayer.PlayerGui:FindFirstChild("MatchUI")
                return m and m.Enabled and m:FindFirstChild("BottomUI") and m.BottomUI.Visible
            end)
            return ok and r
        end

        if not isJoinedFast() then
            LblJoin.Text  = "● Belum join meja"
            LblJoin.TextColor3 = THEME.Red
            LblPre.Text   = "HURUF AWAL: -"
            LblStatus.Text = "Menunggu join meja..."
            LblTyping.Text = "TARGET: -"
            if lastPrefix ~= nil then
                lastPrefix = nil
                setScrollPlaceholder("Silakan Join Meja.", THEME.Neon)
            end
            continue
        end

        LblJoin.Text = "● Sudah join meja"
        LblJoin.TextColor3 = THEME.Neon

        local prefix = getPrefix()
        
        if prefix then
            if prefix ~= lastPrefix then
                lastPrefix = prefix
                TempIgnored = {} 
                LblPre.Text = "HURUF AWAL: " .. string.upper(prefix)
                updateListUI(prefix)
            end

            if not isTyping then
                if autoTypeEnabled then
                    isTyping = true
                    LblStatus.Text = "Mendeteksi & Mengetik..."
                    LblStatus.TextColor3 = THEME.Yellow
                    
                    local searchPool = getSortedPool(prefix)
                    ExecuteAutoType(prefix, searchPool)
                    
                    isTyping = false
                else
                    LblStatus.Text = "Giliranmu! (Ketik Manual / Klik List)"
                    LblStatus.TextColor3 = THEME.Cyan
                    LblTyping.Text = "Pilih dari list di atas"
                end
            end
        else
            lastPrefix = nil
            LblPre.Text = "HURUF AWAL: -"
            if autoTypeEnabled then
                LblStatus.Text = "Menunggu giliran (AUTO)..."
                LblStatus.TextColor3 = THEME.Yellow
            else
                LblStatus.Text = "Menunggu giliran (MANUAL)..."
                LblStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            end
            LblTyping.Text = "TARGET: -"
            isTyping = false
        end
    end
end)

-- ============================================================
-- BUTTON EVENTS
-- ============================================================
BtnPlay.MouseButton1Click:Connect(function()
    if not dbLoaded then return end
    
    local searchTxt = SearchBox.Text:lower():gsub("[^%a]", "")
    if searchTxt ~= "" then
        LblStatus.Text = "Hapus teks pencarian dulu!"
        LblStatus.TextColor3 = THEME.Red
        return
    end

    autoTypeEnabled = not autoTypeEnabled
    
    if autoTypeEnabled then
        BtnPlay.Text = "■  STOP AUTO PLAY"
        BtnPlayBaseColor = THEME.BtnStop
        TweenService:Create(BtnPlay, TweenInfo.new(0.2), {BackgroundColor3 = BtnPlayBaseColor}):Play()
    else
        BtnPlay.Text = "▶  START AUTO PLAY"
        BtnPlayBaseColor = THEME.BtnStart
        TweenService:Create(BtnPlay, TweenInfo.new(0.2), {BackgroundColor3 = BtnPlayBaseColor}):Play()
    end
    UpdateInfoUI()
end)

BtnReset.MouseButton1Click:Connect(function()
    ForceClearBlacklist()
end)

BtnExp.MouseButton1Click:Connect(function()
    if setclipboard then
        local jsonString = HttpService:JSONEncode(LocalDB)
        setclipboard(jsonString)
        LblStatus.Text = "DB Disalin ke Clipboard!"
        LblStatus.TextColor3 = THEME.Neon
    else
        LblStatus.Text = "Executor tidak support Copy!"
        LblStatus.TextColor3 = THEME.Red
    end
end)

BtnImp.MouseButton1Click:Connect(function()
    local jsonText = ImportBox.Text
    if jsonText == "" then
        LblStatus.Text = "Paste JSON dulu di kotak!"
        LblStatus.TextColor3 = THEME.Red
        return
    end
    
    local success, decodedData = pcall(function() return HttpService:JSONDecode(jsonText) end)
    
    if success and type(decodedData) == "table" then
        local addedCount = 0
        for k, v in pairs(decodedData) do
            if not LocalDB[k] and not KamusDict[k] then
                LocalDB[k] = v
                addedCount = addedCount + 1
            else
                totalDuplicates = totalDuplicates + 1
            end
        end
        SaveLocalDB()
        UpdateDBStatUI()
        LblStatus.Text = "Imported " .. addedCount .. " kata baru!"
        LblStatus.TextColor3 = THEME.Neon
        ImportBox.Text = "" 
    else
        LblStatus.Text = "Format JSON Tidak Valid!"
        LblStatus.TextColor3 = THEME.Red
    end
end)

-- ============================================================
-- MULTI-DB DOWNLOADER (GITHUB) & AUTO-CLEANER LOCAL DB
-- ============================================================
task.spawn(function()
    local totalKata = 0
    for i, url in ipairs(URLS) do
        Title.Text = "Loading DB " .. i .. "/4..."
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then
            for line in string.gmatch(res, "[^\r\n]+") do
                local w = string.match(line, "([%a]+)")
                if w and #w > 1 then
                    if RegisterWord(w) then
                        totalKata = totalKata + 1
                    end
                end
            end
        end
    end
    
    local cleaned = 0
    for k, _ in pairs(LocalDB) do
        if not RegisterWord(k) then
            -- Internal safety check
        end
    end
    
    dbLoaded = true
    Title.Text = "PrawiraHub - Sambung Kata"
    LblStatus.Text = "Siap digunakan! (" .. math.floor(totalKata/1000) .. "k+ kata)"
    LblStatus.TextColor3 = THEME.Neon
    UpdateDBStatUI()
    setScrollPlaceholder("Silakan Join Meja.", THEME.Neon)
end)

-- Entry Animation
MainScale.Scale = 0
TweenService:Create(MainScale, tweenBounce, {Scale = 1}):Play()
