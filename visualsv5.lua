--=============================================================
-- AURA VISUALS v3 | Part 1: Core + Window + Tabs
-- Стиль: Dark Fluent (как референс)
--=============================================================

--========== SERVICES ==========
local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local CoreGui      = game:GetService("CoreGui")
local StarterGui   = game:GetService("StarterGui")

local plr  = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local cam  = workspace.CurrentCamera

--========== CONFIG ==========
local C = {
    Title      = "Aura",
    Bg         = Color3.fromRGB(12, 12, 18),
    Bg2        = Color3.fromRGB(18, 18, 26),
    Panel      = Color3.fromRGB(24, 24, 34),
    PanelHi    = Color3.fromRGB(34, 34, 48),
    Border     = Color3.fromRGB(42, 42, 58),
    Text       = Color3.fromRGB(240, 240, 250),
    SubText    = Color3.fromRGB(110, 110, 130),
    Accent     = Color3.fromRGB(139, 108, 255),
    Accent2    = Color3.fromRGB(176, 156, 255),
    ToggleOff  = Color3.fromRGB(48, 48, 62),
    Font       = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
}

--========== UTILS ==========
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function tw(o, t, p, style)
    local a = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint), p)
    a:Play(); return a
end

local function corner(o, r)
    return new("UICorner", { CornerRadius = r or UDim.new(0, 12) }, o)
end

local function stroke(o, col, th, tr)
    return new("UIStroke", { Color = col or C.Border, Thickness = th or 1, Transparency = tr or 0.4 }, o)
end

local function padding(o, t, b, l, r)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
    }, o)
end

--========== ORIGINALS (для правильного сброса) ==========
-- Сохраняем оригинальные значения ОДИН раз, восстанавливаем при выключении
local Originals = {}

local function saveOrig(key, values)
    if Originals[key] == nil then
        Originals[key] = values
    end
end

local function restoreOrig(key, applyFn)
    if Originals[key] then
        applyFn(Originals[key])
        Originals[key] = nil
    end
end

_G.AuraOriginals = Originals
_G.AuraSaveOrig = saveOrig
_G.AuraRestoreOrig = restoreOrig

--========== CLEANUP ==========
pcall(function() if _G.AuraGui then _G.AuraGui:Destroy() end end)
pcall(function() if _G.AuraToggle then _G.AuraToggle:Destroy() end end)

--========== GUI ROOT ==========
local gui = new("ScreenGui", {
    Name = "AuraVisuals",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})
if gethui then gui.Parent = gethui()
elseif CoreGui then gui.Parent = CoreGui
else gui.Parent = plr:WaitForChild("PlayerGui") end
_G.AuraGui = gui

--========== FLOATING TOGGLE (открытие меню) ==========
local toggle = new("TextButton", {
    Name = "AuraToggle",
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 16, 0.5, -23),
    BackgroundColor3 = C.Bg,
    Text = "✦",
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.Accent,
    AutoButtonColor = false,
    Draggable = true,
}, gui)
corner(toggle, UDim.new(1, 0))
stroke(toggle, C.Accent, 1.5, 0.5)
_G.AuraToggle = toggle

-- мягкая пульсация
task.spawn(function()
    while toggle.Parent do
        tw(toggle, 1.6, { TextColor3 = C.Accent2 })
        task.wait(1.6)
        tw(toggle, 1.6, { TextColor3 = C.Accent })
        task.wait(1.6)
    end
end)

--========== MAIN WINDOW ==========
local win = new("Frame", {
    Name = "Window",
    Size = UDim2.new(0, 560, 0, 380),
    Position = UDim2.new(0.5, -280, 0.5, -190),
    BackgroundColor3 = C.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    Active = true,
}, gui)
corner(win, UDim.new(0, 18))
stroke(win, C.Border, 1, 0.3)
_G.AuraWindow = win

--========== DRAG ==========
do
    local dragging, dragStart, startPos
    win.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = win.Position
        end
    end)
    win.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    win.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--========== HEADER (табы сверху, как на скрине) ==========
local header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundTransparency = 1,
}, win)

-- левая часть — название + табы
local titleLbl = new("TextLabel", {
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1,
    Text = C.Title,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- табы-контейнер
local tabBar = new("Frame", {
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(0, 110, 0, 0),
    BackgroundTransparency = 1,
}, header)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 18),
}, tabBar)

-- поиск справа (визуал, не функциональный — но выглядит как на скрине)
local searchBox = new("Frame", {
    Size = UDim2.new(0, 160, 0, 32),
    Position = UDim2.new(1, -200, 0.5, -16),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, header)
corner(searchBox, UDim.new(0, 8))
stroke(searchBox, C.Border, 1, 0.6)

new("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 26, 0, 0),
    BackgroundTransparency = 1,
    Text = "Search",
    Font = C.Font,
    TextSize = 12,
    TextColor3 = C.SubText,
    TextXAlignment = Enum.TextXAlignment.Left,
}, searchBox)

new("TextLabel", {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(0, 8, 0.5, -8),
    BackgroundTransparency = 1,
    Text = "⌕",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = C.SubText,
}, searchBox)

-- кнопка закрытия
local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 32, 0, 32),
    Position = UDim2.new(1, -40, 0.5, -16),
    BackgroundColor3 = C.Panel,
    Text = "✕",
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.SubText,
    AutoButtonColor = false,
}, header)
corner(closeBtn, UDim.new(0, 8))

--========== TABS SYSTEM ==========
local Tabs = {}         -- {name = page}
local TabButtons = {}   -- {name = button}
local TabOrder = {}

local function selectTab(name)
    for n, btn in pairs(TabButtons) do
        local active = (n == name)
        tw(btn, 0.2, {
            TextColor3 = active and C.Text or C.SubText,
        })
        if btn.Indicator then
            btn.Indicator.Visible = active
        end
    end
    for n, page in pairs(Tabs) do
        page.Visible = (n == name)
    end
end

local function makeTab(name)
    local btn = new("TextButton", {
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = C.Font,
        TextSize = 13,
        TextColor3 = C.SubText,
        AutoButtonColor = false,
    }, tabBar)

    -- тонкая полоска под активным табом
    local indicator = new("Frame", {
        Name = "Indicator",
        Size = UDim2.new(0.7, 0, 0, 2),
        Position = UDim2.new(0.15, 0, 1, -8),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, btn)
    corner(indicator, UDim.new(1, 0))
    btn.Indicator = indicator

    -- страница (содержимое таба)
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -44, 1, -80),
        Position = UDim2.new(0, 22, 0, 68),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, win)

    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    new("UIPadding", {
        PaddingBottom = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 8),
    }, page)

    Tabs[name] = page
    TabButtons[name] = btn
    table.insert(TabOrder, name)

    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    return page
end

-- создаём вкладки
makeTab("Visuals")
makeTab("Player")
makeTab("World")
makeTab("Particles")
makeTab("HUD")
makeTab("Settings")

--========== TOGGLE / CLOSE LOGIC ==========
local function openMenu()
    win.Visible = true
    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, 0, 0.5, 0)
    tw(win, 0.3, {
        Size = UDim2.new(0, 560, 0, 380),
        Position = UDim2.new(0.5, -280, 0.5, -190),
    }, Enum.EasingStyle.Back)
end

local function closeMenu()
    tw(win, 0.22, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    task.wait(0.22)
    win.Visible = false
end

toggle.MouseButton1Click:Connect(function()
    if win.Visible then closeMenu() else openMenu() end
end)

closeBtn.MouseButton1Click:Connect(function()
    closeMenu()
end)

selectTab("Visuals")

--========== ПЕРЕМЕННЫЕ ДЛЯ ЧАСТИ 2 ==========
_G.AuraC = C
_G.AuraNew = new
_G.AuraTw = tw
_G.AuraCorner = corner
_G.AuraStroke = stroke
_G.AuraPadding = padding
_G.AuraTabs = Tabs
_G.AuraMakeTab = makeTab
_G.AuraSelectTab = selectTab

print("[Aura Visuals v3] Part 1 loaded ✔ (Core + Window + Tabs)")
--=============================================================
-- AURA VISUALS v3 | Part 2: UI Components
--=============================================================

local C = _G.AuraC
local new = _G.AuraNew
local tw = _G.AuraTw
local corner = _G.AuraCorner
local stroke = _G.AuraStroke

--========== КОНТЕЙНЕР-СЕТКА (2 колонки) ==========
-- Каждая страница таба имеет свой grid, куда кладём карточки
local function makeGrid(parent)
    local grid = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 56),
        CellPadding = UDim2.new(0, 10, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    return grid
end

--========== СЕКЦИЯ (заголовок) ==========
local function makeSection(parent, text)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = C.FontBold,
        TextSize = 11,
        TextColor3 = C.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    return f
end

--========== КАРТОЧКА-ТУМБЛЕР (iOS style) ==========
-- выглядит как на скрине: слева текст, справа тумблер
local function makeToggle(parent, text, default, callback)
    local card = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Panel,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = false,
    }, parent)
    corner(card, UDim.new(0, 12))
    local cardStroke = stroke(card, C.Border, 1, 0.6)

    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = C.Font,
        TextSize = 13,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    -- сам тумблер
    local track = new("Frame", {
        Size = UDim2.new(0, 38, 0, 22),
        Position = UDim2.new(1, -50, 0.5, -11),
        BackgroundColor3 = default and C.Accent or C.ToggleOff,
        BorderSizePixel = 0,
    }, card)
    corner(track, UDim.new(1, 0))

    local knob = new("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    corner(knob, UDim.new(1, 0))

    local state = default or false

    local function apply(s, animate)
        state = s
        if animate then
            tw(knob, 0.2, {
                Position = s and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            })
            tw(track, 0.2, {
                BackgroundColor3 = s and C.Accent or C.ToggleOff,
            })
        else
            knob.Position = s and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            track.BackgroundColor3 = s and C.Accent or C.ToggleOff
        end
    end

    card.MouseButton1Click:Connect(function()
        apply(not state, true)
        -- подсветка карточки при клике
        tw(card, 0.1, { BackgroundColor3 = C.PanelHi })
        task.delay(0.15, function()
            tw(card, 0.2, { BackgroundColor3 = C.Panel })
        end)
        if callback then
            local ok, err = pcall(callback, state)
            if not ok then warn("[Aura] " .. tostring(err)) end
        end
    end)

    -- для внешнего управления (например "Сбросить всё")
    card.SetState = function(s, anim) apply(s, anim) end

    return card
end

--========== КАРТОЧКА-СЛАЙДЕР ==========
local function makeSlider(parent, text, min, max, default, callback)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(card, UDim.new(0, 12))
    stroke(card, C.Border, 1, 0.6)

    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.new(0, 16, 0, 8),
        BackgroundTransparency = 1,
        Text = text,
        Font = C.Font,
        TextSize = 12,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    local valLbl = new("TextLabel", {
        Size = UDim2.new(0, 60, 0, 18),
        Position = UDim2.new(1, -76, 0, 8),
        BackgroundTransparency = 1,
        Text = tostring(default),
        Font = C.FontBold,
        TextSize = 12,
        TextColor3 = C.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, card)

    -- трек слайдера
    local track = new("Frame", {
        Size = UDim2.new(1, -32, 0, 4),
        Position = UDim2.new(0, 16, 1, -14),
        BackgroundColor3 = C.ToggleOff,
        BorderSizePixel = 0,
    }, card)
    corner(track, UDim.new(1, 0))

    local fill = new("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, UDim.new(1, 0))

    local dragging = false

    local function update(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        fill.Size = UDim2.new(rel, 0, 1, 0)
        if max - min >= 10 then
            valLbl.Text = string.format("%d", math.floor(val))
        else
            valLbl.Text = string.format("%.2f", val)
        end
        if callback then
            local ok, err = pcall(callback, val)
            if not ok then warn("[Aura] " .. tostring(err)) end
        end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(i)
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            update(i)
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return card
end

--========== КАРТОЧКА ВЫБОРА ЦВЕТА ==========
local function makeColorPicker(parent, text, defaultColor, callback)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(card, UDim.new(0, 12))
    stroke(card, C.Border, 1, 0.6)

    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = C.Font,
        TextSize = 13,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    -- пресеты цветов (8 штук)
    local presets = {
        Color3.fromRGB(139, 108, 255), -- фиолет
        Color3.fromRGB(255, 130, 200), -- розовый
        Color3.fromRGB(130, 220, 255), -- голубой
        Color3.fromRGB(150, 255, 180), -- зелёный
        Color3.fromRGB(255, 210, 120), -- жёлтый
        Color3.fromRGB(255, 120, 120), -- красный
        Color3.fromRGB(255, 255, 255), -- белый
        Color3.fromRGB(60, 60, 80),    -- тёмный
    }

    local swatch = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -38, 0.5, -13),
        BackgroundColor3 = defaultColor,
        Text = "",
        AutoButtonColor = false,
    }, card)
    corner(swatch, UDim.new(0, 8))
    stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.7)

    local idx = 0
    -- найти индекс текущего цвета, если он в пресетах
    for i, p in ipairs(presets) do
        if p == defaultColor then idx = i break end
    end

    swatch.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #presets then idx = 1 end
        local c = presets[idx]
        tw(swatch, 0.15, { BackgroundColor3 = c })
        if callback then
            local ok, err = pcall(callback, c)
            if not ok then warn("[Aura] " .. tostring(err)) end
        end
    end)

    return card
end

--========== КНОПКА (одноразовая, без тумблера) ==========
local function makeButton(parent, text, callback)
    local card = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Panel,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    corner(card, UDim.new(0, 12))
    stroke(card, C.Border, 1, 0.6)

    new("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = C.Font,
        TextSize = 13,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    card.MouseButton1Click:Connect(function()
        tw(card, 0.1, { BackgroundColor3 = C.Accent })
        task.delay(0.15, function()
            tw(card, 0.25, { BackgroundColor3 = C.Panel })
        end)
        if callback then
            local ok, err = pcall(callback)
            if not ok then warn("[Aura] " .. tostring(err)) end
        end
    end)

    return card
end

--========== СОХРАНЯЕМ ССЫЛКИ ДЛЯ ЧАСТИ 3+ ==========
_G.AuraMakeGrid = makeGrid
_G.AuraMakeSection = makeSection
_G.AuraMakeToggle = makeToggle
_G.AuraMakeSlider = makeSlider
_G.AuraMakeColorPicker = makeColorPicker
_G.AuraMakeButton = makeButton

print("[Aura Visuals v3] Part 2 loaded ✔ (Components ready)")
--=============================================================
-- AURA VISUALS v3 | Part 3: Player + Visuals Tabs
--=============================================================

local C = _G.AuraC
local new = _G.AuraNew
local tw = _G.AuraTw
local corner = _G.AuraCorner
local stroke = _G.AuraStroke
local Originals = _G.AuraOriginals

local makeGrid = _G.AuraMakeGrid
local makeSection = _G.AuraMakeSection
local makeToggle = _G.AuraMakeToggle
local makeSlider = _G.AuraMakeSlider
local makeColorPicker = _G.AuraMakeColorPicker
local makeButton = _G.AuraMakeButton

local Tabs = _G.AuraTabs

--========== ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ ==========
local function onChar(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
end
plr.CharacterAdded:Connect(onChar)

--========== ССЫЛКИ ДЛЯ ЭФФЕКТОВ ==========
local FX = {
    highlight = nil,
    trail = nil,
    auraEmitter = nil,
    auraLight = nil,
}
_G.AuraFX = FX

--=============================================================
-- ВКЛАДКА "VISUALS" (общие визуалы)
--=============================================================
local pVisuals = Tabs["Visuals"]

makeSection(pVisuals, "ОСВЕЩЕНИЕ")
local gVis1 = makeGrid(pVisuals)

-- Full Bright (с правильным сбросом)
makeToggle(gVis1, "Full Bright", false, function(on)
    if on then
        if Originals.FB == nil then
            Originals.FB = {
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        Lighting.Brightness = 5
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    else
        if Originals.FB then
            Lighting.Brightness = Originals.FB.Brightness
            Lighting.Ambient = Originals.FB.Ambient
            Lighting.OutdoorAmbient = Originals.FB.OutdoorAmbient
            Originals.FB = nil
        end
    end
end)

-- Neon тело
makeToggle(gVis1, "Neon тело", false, function(on)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Material = on and Enum.Material.Neon or Enum.Material.Plastic
        end
    end
end)

makeSection(pVisuals, "ЭФФЕКТЫ")
local gVis2 = makeGrid(pVisuals)

-- Highlight игрока
makeToggle(gVis2, "Highlight", false, function(on)
    if on then
        if FX.highlight then return end
        FX.highlight = new("Highlight", {
            FillColor = C.Accent,
            OutlineColor = C.Accent2,
            FillTransparency = 0.6,
            OutlineTransparency = 0.2,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        }, char)
    else
        if FX.highlight then FX.highlight:Destroy(); FX.highlight = nil end
    end
end)

-- Trail за игроком
makeToggle(gVis2, "Trail", false, function(on)
    if on then
        if FX.trail then return end
        local a0 = new("Attachment", { Name = "TrailA0", Position = Vector3.new(0, 1, 0.4) }, root)
        local a1 = new("Attachment", { Name = "TrailA1", Position = Vector3.new(0, -1, 0.4) }, root)
        FX.trail = new("Trail", {
            Attachment0 = a0,
            Attachment1 = a1,
            Color = ColorSequence.new(C.Accent, C.Accent2),
            Lifetime = 0.6,
            MinLength = 0.1,
            FaceCamera = true,
            LightEmission = 1,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, root)
    else
        if FX.trail then FX.trail:Destroy(); FX.trail = nil end
        for _, n in pairs({ "TrailA0", "TrailA1" }) do
            local a = root:FindFirstChild(n)
            if a then a:Destroy() end
        end
    end
end)

-- Аура игрока (частицы вокруг)
makeToggle(gVis2, "Аура (искры)", false, function(on)
    if on then
        if FX.auraEmitter then FX.auraEmitter.Enabled = true; return end
        local att = new("Attachment", { Name = "AuraAtt" }, root)
        FX.auraEmitter = new("ParticleEmitter", {
            Rate = 30,
            Lifetime = NumberRange.new(1, 1.8),
            Speed = NumberRange.new(0.5, 2),
            SpreadAngle = Vector2.new(180, 180),
            Size = NumberSequence.new(0.35),
            Color = ColorSequence.new(C.Accent),
            LightEmission = 1,
            Texture = "rbxasset://textures/particles/sparkles_main.dds",
        }, att)
        FX.auraEmitter.Enabled = true
    else
        if FX.auraEmitter then FX.auraEmitter.Enabled = false end
    end
end)

-- PointLight вокруг игрока
makeToggle(gVis2, "Свечение (PointLight)", false, function(on)
    if on then
        if FX.auraLight then return end
        FX.auraLight = new("PointLight", {
            Color = C.Accent,
            Range = 14,
            Brightness = 3,
        }, root)
    else
        if FX.auraLight then FX.auraLight:Destroy(); FX.auraLight = nil end
    end
end)

-- Радужный режим
local rainbowOn = false
local rainbowConn
_G.AuraRainbow = function(v) rainbowOn = v end
makeToggle(gVis2, "Радужный режим", false, function(on)
    rainbowOn = on
end)

RunService.Heartbeat:Connect(function()
    if not rainbowOn then return end
    local t = tick()
    local c1 = Color3.fromHSV((t * 0.3) % 1, 0.7, 1)
    local c2 = Color3.fromHSV((t * 0.3 + 0.3) % 1, 0.7, 1)

    if FX.trail then FX.trail.Color = ColorSequence.new(c1, c2) end
    if FX.highlight then
        FX.highlight.FillColor = c1
        FX.highlight.OutlineColor = c2
    end
    if FX.auraEmitter then FX.auraEmitter.Color = ColorSequence.new(c1) end
    if FX.auraLight then FX.auraLight.Color = c1 end
end)

--=============================================================
-- ВКЛАДКА "PLAYER" (настройки игрока)
--=============================================================
local pPlayer = Tabs["Player"]

makeSection(pPlayer, "ПЕРСОНАЖ")
local gPl1 = makeGrid(pPlayer)

-- Размер персонажа (слайдер)
makeSlider(gPl1, "Размер", 0.5, 2, 1, function(v)
    if hum then
        hum.BodyDepthScale.Value = v
        hum.BodyWidthScale.Value = v
        hum.BodyHeightScale.Value = v
        hum.HeadScale.Value = v
    end
end)

-- Прозрачность
makeSlider(gPl1, "Прозрачность", 0, 1, 0, function(v)
    for _, p in pairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.Transparency = v
        end
    end
    for _, acc in pairs(char:GetDescendants()) do
        if acc:IsA("BasePart") then acc.Transparency = v end
    end
end)

-- Скорость ходьбы
makeSlider(gPl1, "Скорость", 8, 60, 16, function(v)
    if hum then hum.WalkSpeed = v end
end)

-- Сила прыжка
makeSlider(gPl1, "Прыжок", 50, 200, 50, function(v)
    if hum then hum.JumpPower = v; hum.UseJumpPower = true end
end)

-- Цвет тела
makeColorPicker(gPl1, "Цвет тела", Color3.fromRGB(255, 220, 180), function(c)
    local bc = char:FindFirstChild("BodyColors")
    if bc then
        bc.HeadColor3 = c
        bc.TorsoColor3 = c
        bc.LeftArmColor3 = c
        bc.RightArmColor3 = c
        bc.LeftLegColor3 = c
        bc.RightLegColor3 = c
    end
end)

makeSection(pPlayer, "ВНЕШНИЙ ВИД")
local gPl2 = makeGrid(pPlayer)

-- Убрать аксессуары
makeToggle(gPl2, "Убрать аксессуары", false, function(on)
    for _, acc in pairs(char:GetChildren()) do
        if acc:IsA("Accessory") or acc:IsA("Hat") then
            acc.Visible = not on
            for _, d in pairs(acc:GetDescendants()) do
                if d:IsA("BasePart") then d.Transparency = on and 1 or 0 end
            end
        end
    end
end)

-- Убрать одежду
makeToggle(gPl2, "Убрать одежду", false, function(on)
    for _, n in pairs({ "Shirt", "Pants", "ShirtGraphic" }) do
        local it = char:FindFirstChild(n)
        if it then it.Transparency = on and 1 or 0 end
    end
    local d = char:FindFirstChildOfClass("Shirt")
    if d then d.Transparency = on and 1 or 0 end
    local p = char:FindFirstChildOfClass("Pants")
    if p then p.Transparency = on and 1 or 0 end
end)

-- Голова-шар
makeToggle(gPl2, "Голова-шар", false, function(on)
    local head = char:FindFirstChild("Head")
    if not head then return end
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if on then
        if not mesh then
            mesh = new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = Vector3.new(1.3, 1.3, 1.3) }, head)
        end
        head:SetAttribute("OriginalMesh", "saved")
    else
        if mesh then mesh:Destroy() end
    end
end)

--=============================================================
-- ВКЛАДКА "CAMERA" (FOV + плечо)
--=============================================================
local pCam = Tabs["HUD"] -- используем HUD для камеры и HUD вместе

makeSection(pCam, "КАМЕРА")
local gCam = makeGrid(pCam)

makeSlider(gCam, "FOV", 40, 120, 70, function(v)
    cam.FieldOfView = v
end)

-- Тряска камеры
local shakeOn = false
makeToggle(gCam, "Тряска камеры", false, function(on)
    shakeOn = on
end)

RunService.RenderStepped:Connect(function()
    if not shakeOn then return end
    local x = (math.random() - 0.5) * 0.05
    local y = (math.random() - 0.5) * 0.05
    cam.CFrame = cam.CFrame * CFrame.Angles(x, y, 0)
end)

print("[Aura Visuals v3] Part 3 loaded ✔ (Player + Visuals working)")
--=============================================================
-- AURA VISUALS v3 | Part 4: World + Post-FX
--=============================================================

local C = _G.AuraC
local new = _G.AuraNew
local tw = _G.AuraTw
local corner = _G.AuraCorner
local stroke = _G.AuraStroke
local Originals = _G.AuraOriginals

local makeGrid = _G.AuraMakeGrid
local makeSection = _G.AuraMakeSection
local makeToggle = _G.AuraMakeToggle
local makeSlider = _G.AuraMakeSlider
local makeColorPicker = _G.AuraMakeColorPicker
local makeButton = _G.AuraMakeButton

local Tabs = _G.AuraTabs
local pWorld = Tabs["World"]

--========== ПОСТ-ЭФФЕКТЫ (создание/удаление) ==========
local function getOrCreate(class, name)
    local f = Lighting:FindFirstChild(name)
    if f and f.ClassName == class then return f end
    if f then f:Destroy() end
    local o = Instance.new(class)
    o.Name = name
    return o
end

local PostFX = {
    Bloom = nil,
    Blur = nil,
    SunRays = nil,
    CC = nil,
    DOF = nil,
    CA = nil,
    Vignette = nil,
}

--=============================================================
-- СЕКЦИЯ: СВЕТ И ВРЕМЯ
--=============================================================
makeSection(pWorld, "СВЕТ И ВРЕМЯ")
local gW1 = makeGrid(pWorld)

-- Слайдер времени суток
makeSlider(gW1, "Время суток (0-24)", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)

-- Цикл дня/ночи
local cycleOn = false
makeToggle(gW1, "Цикл дня/ночи", false, function(on)
    cycleOn = on
end)

RunService.Heartbeat:Connect(function(dt)
    if not cycleOn then return end
    Lighting.ClockTime = (Lighting.ClockTime + dt * 0.5) % 24
end)

-- Ambient цвет
makeColorPicker(gW1, "Ambient цвет", Color3.fromRGB(70, 70, 70), function(c)
    if Originals.Ambient == nil then
        Originals.Ambient = { Ambient = Lighting.Ambient }
    end
    Lighting.Ambient = c
end)

--=============================================================
-- СЕКЦИЯ: ТУМАН
--=============================================================
makeSection(pWorld, "ТУМАН")
local gW2 = makeGrid(pWorld)

-- Вкл/выкл тумана (с правильным сбросом!)
makeToggle(gW2, "Туман", false, function(on)
    if on then
        if Originals.Fog == nil then
            Originals.Fog = {
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                FogColor = Lighting.FogColor,
            }
        end
        Lighting.FogEnd = 250
        Lighting.FogStart = 20
    else
        if Originals.Fog then
            Lighting.FogEnd = Originals.Fog.FogEnd
            Lighting.FogStart = Originals.Fog.FogStart
            Lighting.FogColor = Originals.Fog.FogColor
            Originals.Fog = nil
        end
    end
end)

-- Плотность тумана
makeSlider(gW2, "Плотность", 50, 2000, 250, function(v)
    if Originals.Fog then
        Lighting.FogEnd = v
    end
end)

-- Цвет тумана
makeColorPicker(gW2, "Цвет тумана", Color3.fromRGB(200, 200, 255), function(c)
    if Originals.Fog then
        Lighting.FogColor = c
    end
end)

--=============================================================
-- СЕКЦИЯ: ПОСТ-ОБРАБОТКА
--=============================================================
makeSection(pWorld, "ПОСТ-ЭФФЕКТЫ")
local gW3 = makeGrid(pWorld)

-- Bloom
makeToggle(gW3, "Bloom", false, function(on)
    if on then
        if not PostFX.Bloom then
            PostFX.Bloom = getOrCreate("BloomEffect", "AuraBloom")
            PostFX.Bloom.Intensity = 0.8
            PostFX.Bloom.Size = 24
            PostFX.Bloom.Threshold = 0.9
            PostFX.Bloom.Parent = Lighting
        end
        PostFX.Bloom.Enabled = true
    elseif PostFX.Bloom then
        PostFX.Bloom.Enabled = false
    end
end)

-- Blur
makeToggle(gW3, "Blur", false, function(on)
    if on then
        if not PostFX.Blur then
            PostFX.Blur = getOrCreate("BlurEffect", "AuraBlur")
            PostFX.Blur.Size = 12
            PostFX.Blur.Parent = Lighting
        end
        PostFX.Blur.Enabled = true
    elseif PostFX.Blur then
        PostFX.Blur.Enabled = false
    end
end)

-- SunRays
makeToggle(gW3, "SunRays", false, function(on)
    if on then
        if not PostFX.SunRays then
            PostFX.SunRays = getOrCreate("SunRaysEffect", "AuraSunRays")
            PostFX.SunRays.Intensity = 0.15
            PostFX.SunRays.Spread = 1
            PostFX.SunRays.Parent = Lighting
        end
        PostFX.SunRays.Enabled = true
    elseif PostFX.SunRays then
        PostFX.SunRays.Enabled = false
    end
end)

-- ColorCorrection
makeToggle(gW3, "ColorCorrection", false, function(on)
    if on then
        if not PostFX.CC then
            PostFX.CC = getOrCreate("ColorCorrectionEffect", "AuraCC")
            PostFX.CC.Brightness = 0.05
            PostFX.CC.Contrast = 0.15
            PostFX.CC.Saturation = 0.2
            PostFX.CC.TintColor = Color3.fromRGB(255, 240, 250)
            PostFX.CC.Parent = Lighting
        end
        PostFX.CC.Enabled = true
    elseif PostFX.CC then
        PostFX.CC.Enabled = false
    end
end)

-- DepthOfField
makeToggle(gW3, "DepthOfField", false, function(on)
    if on then
        if not PostFX.DOF then
            PostFX.DOF = getOrCreate("DepthOfFieldEffect", "AuraDOF")
            PostFX.DOF.FarIntensity = 0.8
            PostFX.DOF.FocusDistance = 30
            PostFX.DOF.InFocusRadius = 20
            PostFX.DOF.NearIntensity = 0
            PostFX.DOF.Parent = Lighting
        end
        PostFX.DOF.Enabled = true
    elseif PostFX.DOF then
        PostFX.DOF.Enabled = false
    end
end)

-- ChromaticAberration
makeToggle(gW3, "ChromaticAberration", false, function(on)
    if on then
        if not PostFX.CA then
            PostFX.CA = getOrCreate("ChromaticAberrationEffect", "AuraCA")
            PostFX.CA.Intensity = 0.3
            PostFX.CA.Parent = Lighting
        end
        PostFX.CA.Enabled = true
    elseif PostFX.CA then
        PostFX.CA.Enabled = false
    end
end)

-- Vignette (эмулируем через ImageLabel на экране)
local vignetteFrame
makeToggle(gW3, "Vignette", false, function(on)
    if on then
        if not vignetteFrame then
            vignetteFrame = new("Frame", {
                Name = "AuraVignette",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 0,
                Active = false,
            }, _G.AuraGui)
            -- 4 затемнения по краям
            for _, data in ipairs({
                { Size = UDim2.new(1, 0, 0, 80), Pos = UDim2.new(0, 0, 0, 0) },
                { Size = UDim2.new(1, 0, 0, 80), Pos = UDim2.new(0, 0, 1, -80) },
                { Size = UDim2.new(0, 80, 1, 0), Pos = UDim2.new(0, 0, 0, 0) },
                { Size = UDim2.new(0, 80, 1, 0), Pos = UDim2.new(1, -80, 0, 0) },
            }) do
                new("Frame", {
                    Size = data.Size,
                    Position = data.Pos,
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                }, vignetteFrame)
            end
        end
        vignetteFrame.Visible = true
    elseif vignetteFrame then
        vignetteFrame.Visible = false
    end
end)

--=============================================================
-- СЕКЦИЯ: ПРЕСЕТЫ АТМОСФЕРЫ
--=============================================================
makeSection(pWorld, "ПРЕСЕТЫ")
local gW4 = makeGrid(pWorld)

local function applyPreset(name)
    -- сброс сначала
    Lighting.ClockTime = 14
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogEnd = Originals.Fog and Originals.Fog.FogEnd or 100000
    Lighting.FogStart = Originals.Fog and Originals.Fog.FogStart or 0
    Lighting.FogColor = Originals.Fog and Originals.Fog.FogColor or Color3.fromRGB(192, 192, 192)

    if name == "Ночь" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 60)
        Lighting.FogEnd = 300
        Lighting.FogColor = Color3.fromRGB(20, 20, 50)
    elseif name == "Закат" then
        Lighting.ClockTime = 18
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 120, 80)
        Lighting.FogEnd = 400
        Lighting.FogColor = Color3.fromRGB(255, 150, 100)
    elseif name == "День" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 3
    elseif name == "Утро" then
        Lighting.ClockTime = 7
        Lighting.Brightness = 2
        Lighting.FogColor = Color3.fromRGB(255, 200, 220)
    elseif name == "Киберпанк" then
        Lighting.ClockTime = 1
        Lighting.Brightness = 0.8
        Lighting.OutdoorAmbient = Color3.fromRGB(60, 20, 100)
        Lighting.FogEnd = 250
        Lighting.FogColor = Color3.fromRGB(255, 50, 180)
        Lighting.Ambient = Color3.fromRGB(40, 20, 80)
    elseif name == "Зима" then
        Lighting.ClockTime = 10
        Lighting.Brightness = 2.5
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 200, 255)
        Lighting.FogEnd = 400
        Lighting.FogColor = Color3.fromRGB(220, 230, 255)
    elseif name == "Космос" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.1
        Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 30)
        Lighting.FogEnd = 500
        Lighting.FogColor = Color3.fromRGB(5, 5, 20)
    elseif name == "Ад" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 1.5
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 30, 20)
        Lighting.FogEnd = 200
        Lighting.FogColor = Color3.fromRGB(180, 40, 20)
    elseif name == "Хэллоуин" then
        Lighting.ClockTime = 19
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 90, 20)
        Lighting.FogEnd = 300
        Lighting.FogColor = Color3.fromRGB(255, 130, 40)
    elseif name == "Аниме" then
        Lighting.ClockTime = 15
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 200, 220)
        Lighting.FogEnd = 800
        Lighting.FogColor = Color3.fromRGB(255, 220, 240)
    elseif name == "Неон" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(80, 20, 120)
        Lighting.FogEnd = 300
        Lighting.FogColor = Color3.fromRGB(180, 50, 255)
    end
end

for _, preset in ipairs({ "Ночь", "Закат", "День", "Утро", "Киберпанк", "Зима", "Космос", "Ад", "Хэллоуин", "Аниме", "Неон" }) do
    makeButton(gW4, preset, function()
        applyPreset(preset)
    end)
end

--=============================================================
-- СЕКЦИЯ: ПОГОДА (частицы в мире)
--=============================================================
makeSection(pWorld, "ПОГОДА")
local gW5 = makeGrid(pWorld)

local weatherFX = {}

local weatherPresets = {
    Snow = {
        Texture = "rbxasset://textures/particles/snowflake.dds",
        Rate = 30,
        Lifetime = NumberRange.new(3, 5),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(20, 20),
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1) }),
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
        LightEmission = 0.3,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-50, 50),
    },
    Rain = {
        Texture = "rbxasset://textures/particles/waterfall.dds",
        Rate = 60,
        Lifetime = NumberRange.new(0.5, 1),
        Speed = NumberRange.new(20, 30),
        SpreadAngle = Vector2.new(5, 5),
        Size = NumberSequence.new(0.15),
        Color = ColorSequence.new(Color3.fromRGB(150, 200, 255)),
        LightEmission = 0.5,
        Transparency = NumberSequence.new(0.4),
        Acceleration = Vector3.new(0, -30, 0),
    },
    Thunder = {
        Texture = "rbxasset://textures/particles/waterfall.dds",
        Rate = 80,
        Lifetime = NumberRange.new(0.5, 1),
        Speed = NumberRange.new(25, 35),
        SpreadAngle = Vector2.new(5, 5),
        Size = NumberSequence.new(0.18),
        Color = ColorSequence.new(Color3.fromRGB(180, 220, 255)),
        LightEmission = 0.7,
        Transparency = NumberSequence.new(0.3),
        Acceleration = Vector3.new(0, -35, 0),
    },
    Sakura = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 20,
        Lifetime = NumberRange.new(4, 6),
        Speed = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 1) }),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new(0.4),
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 220)),
        LightEmission = 0.4,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-100, 100),
    },
    Confetti = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 40,
        Lifetime = NumberRange.new(3, 5),
        Speed = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 2) }),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new(0.35),
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 150)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(100, 255, 180)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(150, 180, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 100)),
        }),
        LightEmission = 0.7,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-200, 200),
    },
    Bubbles = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 25,
        Lifetime = NumberRange.new(2, 3),
        Speed = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 1) }),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.5) }),
        Color = ColorSequence.new(Color3.fromRGB(180, 220, 255)),
        LightEmission = 0.6,
        Transparency = NumberSequence.new(0.3),
        Acceleration = Vector3.new(0, 3, 0),
    },
}

local function startWeather(name, on)
    if on then
        if weatherFX[name] then return end
        local preset = weatherPresets[name]
        if not preset then return end

        local att = new("Attachment", { Name = "WeatherAtt_" .. name }, root)
        att.WorldPosition = root.Position + Vector3.new(0, 10, 0)

        local props = {
            Rate = preset.Rate,
            Lifetime = preset.Lifetime,
            Speed = preset.Speed,
            SpreadAngle = preset.SpreadAngle,
            Size = preset.Size,
            Color = preset.Color,
            LightEmission = preset.LightEmission,
            Texture = preset.Texture,
        }
        if preset.Transparency then props.Transparency = preset.Transparency end
        if preset.Rotation then props.Rotation = preset.Rotation end
        if preset.RotSpeed then props.RotSpeed = preset.RotSpeed end
        if preset.Acceleration then props.Acceleration = preset.Acceleration end

        local emitter = new("ParticleEmitter", props, att)
        weatherFX[name] = { emitter = emitter, att = att }
    else
        local d = weatherFX[name]
        if d then
            d.emitter.Enabled = false
            task.delay(4, function()
                if d.emitter then d.emitter:Destroy() end
                if d.att then d.att:Destroy() end
            end)
            weatherFX[name] = nil
        end
    end
end

makeToggle(gW5, "❄ Снег", false, function(s) startWeather("Snow", s) end)
makeToggle(gW5, "🌧 Дождь", false, function(s) startWeather("Rain", s) end)
makeToggle(gW5, "⛈ Гроза", false, function(s) startWeather("Thunder", s) end)
makeToggle(gW5, "🌸 Сакура", false, function(s) startWeather("Sakura", s) end)
makeToggle(gW5, "🎉 Конфетти", false, function(s) startWeather("Confetti", s) end)
makeToggle(gW5, "💧 Пузыри", false, function(s) startWeather("Bubbles", s) end)

print("[Aura Visuals v3] Part 4 loaded ✔ (World + Post-FX working)")
--=============================================================
-- AURA VISUALS v3 | Part 5: HUD + Cosmetic + Final
--=============================================================

local C = _G.AuraC
local new = _G.AuraNew
local tw = _G.AuraTw
local corner = _G.AuraCorner
local stroke = _G.AuraStroke
local Originals = _G.AuraOriginals

local makeGrid = _G.AuraMakeGrid
local makeSection = _G.AuraMakeSection
local makeToggle = _G.AuraMakeToggle
local makeSlider = _G.AuraMakeSlider
local makeColorPicker = _G.AuraMakeColorPicker
local makeButton = _G.AuraMakeButton

local Tabs = _G.AuraTabs
local pPlayer = Tabs["Player"]
local pHUD = Tabs["HUD"]
local pParticles = Tabs["Particles"]
local pSettings = Tabs["Settings"]

--=============================================================
-- СИСТЕМА КОСМЕТИКИ (крылья, ореол, рога)
--=============================================================
local Cosmetic = {
    wings = nil,
    halo = nil,
    horns = nil,
    bodyAura = nil,
}
_G.AuraCosmetic = Cosmetic

-- функция поиска torso
local function getTorso()
    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

--========== КРЫЛЬЯ ==========
local function buildWings(color)
    if Cosmetic.wings then Cosmetic.wings:Destroy() end
    local torso = getTorso()
    if not torso then return end

    local model = new("Model", { Name = "AuraWings" }, char)

    local function wingPart(name, size, pos, rot, col)
        local p = new("Part", {
            Name = name,
            Size = size,
            Color = col,
            Material = Enum.Material.Neon,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Anchored = false,
            Massless = true,
            CastShadow = false,
        }, model)
        local weld = new("WeldConstraint", {}, p)
        weld.Part0 = torso
        weld.Part1 = p
        p.CFrame = torso.CFrame * CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
        return p
    end

    local c = color or Color3.fromRGB(255, 255, 255)
    local wL1 = wingPart("WL1", Vector3.new(0.2, 1.5, 0.8), Vector3.new(-0.9, 0.5, 0.5), Vector3.new(0, 0, math.rad(-25)), c)
    local wL2 = wingPart("WL2", Vector3.new(0.15, 1.2, 0.7), Vector3.new(-1.6, 0.3, 0.5), Vector3.new(0, 0, math.rad(-40)), c)
    local wL3 = wingPart("WL3", Vector3.new(0.12, 0.9, 0.6), Vector3.new(-2.2, 0.1, 0.5), Vector3.new(0, 0, math.rad(-55)), c)

    local wR1 = wingPart("WR1", Vector3.new(0.2, 1.5, 0.8), Vector3.new(0.9, 0.5, 0.5), Vector3.new(0, 0, math.rad(25)), c)
    local wR2 = wingPart("WR2", Vector3.new(0.15, 1.2, 0.7), Vector3.new(1.6, 0.3, 0.5), Vector3.new(0, 0, math.rad(40)), c)
    local wR3 = wingPart("WR3", Vector3.new(0.12, 0.9, 0.6), Vector3.new(2.2, 0.1, 0.5), Vector3.new(0, 0, math.rad(55)), c)

    -- частицы на крыльях
    local emitter = new("ParticleEmitter", {
        Rate = 15,
        Lifetime = NumberRange.new(1, 2),
        Speed = NumberRange.new(0.5, 1.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new(0.3),
        Color = ColorSequence.new(c),
        LightEmission = 1,
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
    }, wL1)

    Cosmetic.wings = model
    Cosmetic.wingsParts = { wL1, wL2, wL3, wR1, wR2, wR3, emitter = emitter, torso = torso }
end

local wingsOn = false
local wingTime = 0
RunService.Heartbeat:Connect(function(dt)
    if not wingsOn or not Cosmetic.wings or not Cosmetic.wingsParts then return end
    wingTime = wingTime + dt
    local flap = math.sin(wingTime * 3) * 0.4
    local parts = Cosmetic.wingsParts
    if parts.torso and parts.torso.Parent then
        local base = parts.torso.CFrame
        parts[1].CFrame = base * CFrame.new(-0.9, 0.5, 0.5) * CFrame.Angles(0, 0, math.rad(-25 + flap * 30))
        parts[2].CFrame = base * CFrame.new(-1.6, 0.3, 0.5) * CFrame.Angles(0, 0, math.rad(-40 + flap * 40))
        parts[3].CFrame = base * CFrame.new(-2.2, 0.1, 0.5) * CFrame.Angles(0, 0, math.rad(-55 + flap * 50))
        parts[4].CFrame = base * CFrame.new(0.9, 0.5, 0.5) * CFrame.Angles(0, 0, math.rad(25 - flap * 30))
        parts[5].CFrame = base * CFrame.new(1.6, 0.3, 0.5) * CFrame.Angles(0, 0, math.rad(40 - flap * 40))
        parts[6].CFrame = base * CFrame.new(2.2, 0.1, 0.5) * CFrame.Angles(0, 0, math.rad(55 - flap * 50))
    end
end)

--========== ОРЕОЛ ==========
local function buildHalo(color)
    if Cosmetic.halo then Cosmetic.halo:Destroy() end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local halo = new("Part", {
        Name = "AuraHalo",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.1, 2, 2),
        Color = color or Color3.fromRGB(255, 220, 100),
        Material = Enum.Material.Neon,
        CanCollide = false,
        CanQuery = false,
        Anchored = false,
        Massless = true,
        CastShadow = false,
    }, char)

    halo.CFrame = head.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
    local weld = new("WeldConstraint", {}, halo)
    weld.Part0 = head
    weld.Part1 = halo

    local emitter = new("ParticleEmitter", {
        Rate = 10,
        Lifetime = NumberRange.new(0.5, 1),
        Speed = NumberRange.new(1, 2),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new(0.2),
        Color = ColorSequence.new(color or Color3.fromRGB(255, 220, 100)),
        LightEmission = 1,
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
    }, halo)

    Cosmetic.halo = halo
end

--========== РОГА ==========
local function buildHorns(color)
    if Cosmetic.horns then Cosmetic.horns:Destroy() end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local model = new("Model", { Name = "AuraHorns" }, char)
    local function hornPart(name, pos, size, rot)
        local p = new("Part", {
            Name = name,
            Size = size,
            Color = color or Color3.fromRGB(40, 20, 40),
            Material = Enum.Material.Neon,
            CanCollide = false,
            CanQuery = false,
            Anchored = false,
            Massless = true,
            CastShadow = false,
        }, model)
        p.CFrame = head.CFrame * CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
        local weld = new("WeldConstraint", {}, p)
        weld.Part0 = head
        weld.Part1 = p
        return p
    end

    hornPart("HL1", Vector3.new(-0.35, 0.7, 0), Vector3.new(0.15, 0.5, 0.15), Vector3.new(math.rad(-20), 0, math.rad(-15)))
    hornPart("HL2", Vector3.new(-0.5, 1.1, -0.1), Vector3.new(0.12, 0.4, 0.12), Vector3.new(math.rad(-40), 0, math.rad(-30)))
    hornPart("HR1", Vector3.new(0.35, 0.7, 0), Vector3.new(0.15, 0.5, 0.15), Vector3.new(math.rad(-20), 0, math.rad(15)))
    hornPart("HR2", Vector3.new(0.5, 1.1, -0.1), Vector3.new(0.12, 0.4, 0.12), Vector3.new(math.rad(-40), 0, math.rad(30)))

    Cosmetic.horns = model
end

--========== АУРА ТЕЛА (кольцо частиц) ==========
local function buildBodyAura(color)
    if Cosmetic.bodyAura then Cosmetic.bodyAura:Destroy() end
    local torso = getTorso()
    if not torso then return end

    local att = new("Attachment", { Name = "BodyAuraAtt" }, torso)
    local emitter = new("ParticleEmitter", {
        Rate = 50,
        Lifetime = NumberRange.new(1, 2),
        Speed = NumberRange.new(2, 4),
        SpreadAngle = Vector2.new(180, 180),
        Size = NumberSequence.new(0.4),
        Color = ColorSequence.new(color or C.Accent),
        LightEmission = 1,
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
    }, att)

    Cosmetic.bodyAura = emitter
end

--=============================================================
-- ВКЛАДКА PLAYER → КОСМЕТИКА
--=============================================================
makeSection(pPlayer, "КОСМЕТИКА")
local gCosm = makeGrid(pPlayer)

makeToggle(gCosm, "🪽 Крылья", false, function(on)
    wingsOn = on
    if on then buildWings(C.Accent) else
        if Cosmetic.wings then Cosmetic.wings:Destroy(); Cosmetic.wings = nil end
        Cosmetic.wingsParts = nil
    end
end)

makeToggle(gCosm, "👑 Ореол", false, function(on)
    if on then buildHalo(Color3.fromRGB(255, 220, 100))
    else
        if Cosmetic.halo then Cosmetic.halo:Destroy(); Cosmetic.halo = nil end
    end
end)

makeToggle(gCosm, "😈 Рога", false, function(on)
    if on then buildHorns(Color3.fromRGB(200, 40, 60))
    else
        if Cosmetic.horns then Cosmetic.horns:Destroy(); Cosmetic.horns = nil end
    end
end)

makeToggle(gCosm, "✨ Аура тела", false, function(on)
    if on then buildBodyAura(C.Accent)
    else
        if Cosmetic.bodyAura then Cosmetic.bodyAura:Destroy(); Cosmetic.bodyAura = nil end
    end
end)

--=============================================================
-- ВКЛАДКА PARTICLES → ЧАСТИЦЫ ВОКРУГ ИГРОКА
--=============================================================
makeSection(pParticles, "ЧАСТИЦЫ ВОКРУГ ИГРОКА")
local gPart = makeGrid(pParticles)

local particleFX = {}

local function startParticle(name, on)
    if on then
        if particleFX[name] then return end
        local att = new("Attachment", { Name = "PFX_" .. name }, root)
        att.WorldPosition = root.Position + Vector3.new(0, 5, 0)
        local e = new("ParticleEmitter", {
            Name = "P_" .. name,
            Rate = 30,
            Lifetime = NumberRange.new(1, 2),
            Speed = NumberRange.new(0.5, 3),
            SpreadAngle = Vector2.new(180, 180),
            Size = NumberSequence.new(0.4),
            Color = ColorSequence.new(C.Accent),
            LightEmission = 1,
            Texture = "rbxasset://textures/particles/sparkles_main.dds",
        }, att)
        particleFX[name] = { e = e, a = att }
    else
        local d = particleFX[name]
        if d then
            d.e.Enabled = false
            task.delay(3, function()
                if d.e then d.e:Destroy() end
                if d.a then d.a:Destroy() end
            end)
            particleFX[name] = nil
        end
    end
end

makeToggle(gPart, "❄ Снег", false, function(s) startParticle("Snow", s) end)
makeToggle(gPart, "🌧 Дождь", false, function(s) startParticle("Rain", s) end)
makeToggle(gPart, "⭐ Звёзды", false, function(s) startParticle("Stars", s) end)
makeToggle(gPart, "🔥 Огонь", false, function(s) startParticle("Fire", s) end)
makeToggle(gPart, "🌸 Лепестки", false, function(s) startParticle("Petals", s) end)
makeToggle(gPart, "💧 Пузыри", false, function(s) startParticle("Bubbles", s) end)
makeToggle(gPart, "✨ Искры", false, function(s) startParticle("Sparks", s) end)
makeToggle(gPart, "🎉 Конфетти", false, function(s) startParticle("Confetti", s) end)

--=============================================================
-- ВКЛАДКА HUD
--=============================================================
makeSection(pHUD, "ИНФО НА ЭКРАНЕ")
local gHUD1 = makeGrid(pHUD)

-- FPS / Пинг / Координаты
local hudFrame = new("Frame", {
    Name = "AuraHUD",
    Size = UDim2.new(0, 180, 0, 90),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = C.Bg,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Visible = false,
}, _G.AuraGui)
corner(hudFrame, UDim.new(0, 10))
stroke(hudFrame, C.Border, 1, 0.5)

local fpsLbl = new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 20),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "FPS: --",
    Font = C.Font,
    TextSize = 12,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hudFrame)

local pingLbl = new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 20),
    Position = UDim2.new(0, 12, 0, 28),
    BackgroundTransparency = 1,
    Text = "Ping: --",
    Font = C.Font,
    TextSize = 12,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hudFrame)

local coordLbl = new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 20),
    Position = UDim2.new(0, 12, 0, 48),
    BackgroundTransparency = 1,
    Text = "XYZ: 0, 0, 0",
    Font = C.Font,
    TextSize = 11,
    TextColor3 = C.SubText,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hudFrame)

local clockLbl = new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 16),
    Position = UDim2.new(0, 12, 0, 68),
    BackgroundTransparency = 1,
    Text = "🕐 --:--:--",
    Font = C.Font,
    TextSize = 11,
    TextColor3 = C.Accent,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hudFrame)

makeToggle(gHUD1, "HUD (FPS/Ping/XYZ)", false, function(on)
    hudFrame.Visible = on
end)

makeToggle(gHUD1, "Watermark", false, function(on)
    if on then
        if _G.AuraWM then _G.AuraWM:Destroy() end
        _G.AuraWM = new("TextLabel", {
            Name = "Watermark",
            Size = UDim2.new(0, 200, 0, 28),
            Position = UDim2.new(1, -220, 0, 20),
            BackgroundColor3 = C.Bg,
            BackgroundTransparency = 0.3,
            Text = "  ✦ Aura Visuals",
            Font = C.FontBold,
            TextSize = 12,
            TextColor3 = C.Accent,
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, _G.AuraGui)
        corner(_G.AuraWM, UDim.new(0, 8))
        stroke(_G.AuraWM, C.Accent, 1, 0.5)
    else
        if _G.AuraWM then _G.AuraWM:Destroy(); _G.AuraWM = nil end
    end
end)

-- FPS/Ping цикл
local fpsCount = 0
local fpsTime = 0
RunService.RenderStepped:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsTime = fpsTime + dt
    if fpsTime >= 1 then
        fpsLbl.Text = "FPS: " .. fpsCount
        local ping = math.floor(plr:GetNetworkPing() * 1000)
        pingLbl.Text = "Ping: " .. ping .. "ms"
        fpsCount = 0
        fpsTime = 0
    end

    if root and root.Parent then
        local p = root.Position
        coordLbl.Text = string.format("XYZ: %d, %d, %d", p.X, p.Y, p.Z)
    end

    local t = os.date("*t")
    clockLbl.Text = string.format("🕐 %02d:%02d:%02d", t.hour, t.min, t.sec)
end)

--=============================================================
-- ВКЛАДКА SETTINGS
--=============================================================
makeSection(pSettings, "МЕНЮ")
local gSet1 = makeGrid(pSettings)

makeSlider(gSet1, "Прозрачность меню", 0, 1, 0, function(v)
    if _G.AuraWindow then
        _G.AuraWindow.BackgroundTransparency = v * 0.5
    end
end)

makeColorPicker(gSet1, "Цвет акцента", C.Accent, function(c)
    C.Accent = c
    -- перекрашиваем все UIStroke
    for _, o in pairs(_G.AuraGui:GetDescendants()) do
        if o:IsA("UIStroke") and o.Transparency and o.Transparency < 0.5 then
            o.Color = c
        end
        if o:IsA("TextLabel") and o.TextColor3 == Color3.fromRGB(139, 108, 255) then
            o.TextColor3 = c
        end
    end
end)

makeSection(pSettings, "ДЕЙСТВИЯ")
local gSet2 = makeGrid(pSettings)

makeButton(gSet2, "🔄 Перезагрузить скрипт", function()
    StarterGui:SetCore("SendNotification", {
        Title = "Aura Visuals",
        Text = "Перезагрузка... запусти скрипт заново",
        Duration = 3,
    })
end)

makeButton(gSet2, "❌ Сбросить всё", function()
    -- сброс Full Bright
    if Originals.FB then
        Lighting.Brightness = Originals.FB.Brightness
        Lighting.Ambient = Originals.FB.Ambient
        Lighting.OutdoorAmbient = Originals.FB.OutdoorAmbient
        Originals.FB = nil
    end
    -- сброс тумана
    if Originals.Fog then
        Lighting.FogEnd = Originals.Fog.FogEnd
        Lighting.FogStart = Originals.Fog.FogStart
        Lighting.FogColor = Originals.Fog.FogColor
        Originals.Fog = nil
    end
    -- сброс пост-эффектов
    for _, name in pairs({ "AuraBloom", "AuraBlur", "AuraSunRays", "AuraCC", "AuraDOF", "AuraCA" }) do
        local f = Lighting:FindFirstChild(name)
        if f then f.Enabled = false end
    end
    -- сброс камеры
    cam.FieldOfView = 70
    -- сброс скорости
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    -- уведомление
    StarterGui:SetCore("SendNotification", {
        Title = "Aura Visuals",
        Text = "Все эффекты сброшены",
        Duration = 3,
    })
end)

--========== ФИНАЛЬНОЕ УВЕДОМЛЕНИЕ ==========
task.wait(0.5)
local notif = new("Frame", {
    Size = UDim2.new(0, 260, 0, 44),
    Position = UDim2.new(0.5, -130, 1, 20),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, _G.AuraGui)
corner(notif, UDim.new(0, 12))
stroke(notif, C.Accent, 1.5, 0.4)

new("TextLabel", {
    Size = UDim2.new(1, -16, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "✦  Aura Visuals загружен!",
    Font = C.FontBold,
    TextSize = 13,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, notif)

tw(notif, 0.4, { Position = UDim2.new(0.5, -130, 1, -60) }, Enum.EasingStyle.Back)
task.delay(3, function()
    tw(notif, 0.3, { Position = UDim2.new(0.5, -130, 1, 20) })
    task.wait(0.4)
    notif:Destroy()
end)

--========== ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ ==========
plr.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = newChar:WaitForChild("Humanoid")
    root = newChar:WaitForChild("HumanoidRootPart")
    -- пересоздаём косметику если была включена
    if wingsOn then task.wait(0.5); buildWings(C.Accent) end
end)

print("===========================================")
print("  AURA VISUALS v3 — УСПЕШНО ЗАГРУЖЕН ✔")
print("  Все 5 частей активны")
print("  Стиль: Dark Fluent")
print("===========================================")