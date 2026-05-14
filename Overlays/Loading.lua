-- // Loading.lua
-- // BorcaScriptHub - Loading Screen System
-- // Transisi halus sebelum UI utama muncul.
-- // Mendukung: progress bar, step text, animasi logo, callback selesai.

local Loading = {}
local Functions, Theme, Config
local TweenService = game:GetService("TweenService")

function Loading.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // CREATE LOADING SCREEN
-- ========================
--[[
options = {
    Title      = "BorcaScriptHub",   -- judul besar
    Subtitle   = "v1.0.0",           -- versi / subtitle
    Steps      = {                   -- daftar langkah loading (opsional)
        "Memuat library...",
        "Menyiapkan UI...",
        "Selesai!",
    },
    StepDelay  = 0.6,                -- detik per step (default 0.6)
    LogoText   = "B",               -- karakter logo (default "B")
    LogoColor  = nil,               -- Color3 override accent
    OnFinish   = function() end,    -- dipanggil setelah fade-out selesai
    AutoFinish = true,              -- otomatis selesai setelah semua steps
    ShowProgress = true,            -- tampilkan progress bar
}
]]
function Loading.Show(options)
    options = options or {}

    local title       = options.Title        or Config.Name or "BorcaScriptHub"
    local subtitle    = options.Subtitle     or ("v" .. (Config.Version or "1.0.0"))
    local steps       = type(options.Steps) == "table" and options.Steps or {}
    local stepDelay   = tonumber(options.StepDelay)  or 0.6
    local logoText    = options.LogoText     or "B"
    local logoColor   = options.LogoColor    or Theme.Get("Accent")
    local onFinish    = options.OnFinish     or function() end
    local autoFinish  = options.AutoFinish   ~= false
    local showProg    = options.ShowProgress ~= false

    -- ========================
    -- // SCREEN GUI
    -- ========================
    local sg = Instance.new("ScreenGui")
    sg.Name           = "BorcaLoading"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9999
    sg.IgnoreGuiInset = true

    local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok then
        sg.Parent = game:GetService("Players").LocalPlayer
            :WaitForChild("PlayerGui", 5)
    end

    -- ========================
    -- // BG FULL
    -- ========================
    local bg = Functions.Create("Frame", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Get("Background"),
        BorderSizePixel  = 0,
    }, sg)

    -- Noise texture subtle (overlay tipis)
    Functions.Create("Frame", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.88,
        BorderSizePixel  = 0,
    }, bg)

    -- ========================
    -- // CARD TENGAH
    -- ========================
    local card = Functions.Create("Frame", {
        Name             = "LoadCard",
        Size             = UDim2.fromOffset(380, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Get("SecondaryBG"),
        BackgroundTransparency = 0.04,
        BorderSizePixel  = 0,
    }, sg)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 12)}, card)
    Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, card)
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 28),
        PaddingBottom = UDim.new(0, 24),
        PaddingLeft   = UDim.new(0, 28),
        PaddingRight  = UDim.new(0, 28),
    }, card)
    Functions.Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 8),
    }, card)

    -- Accent top bar
    local accentBar = Functions.Create("Frame", {
        Size             = UDim2.new(1, 56, 0, 3),
        Position         = UDim2.fromOffset(-28, 0),
        BackgroundColor3 = logoColor,
        BorderSizePixel  = 0,
        LayoutOrder      = 0,
    }, card)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 3)}, accentBar)

    -- ========================
    -- // LOGO CIRCLE
    -- ========================
    local logoOuter = Functions.Create("Frame", {
        Name             = "LogoOuter",
        Size             = UDim2.fromOffset(60, 60),
        BackgroundColor3 = logoColor,
        BackgroundTransparency = 0.75,
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
    }, card)
    Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, logoOuter)

    local logoInner = Functions.Create("Frame", {
        Size             = UDim2.fromOffset(44, 44),
        Position         = UDim2.fromOffset(8, 8),
        BackgroundColor3 = logoColor,
        BorderSizePixel  = 0,
    }, logoOuter)
    Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, logoInner)

    Functions.Create("TextLabel", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = logoText,
        TextColor3             = Color3.new(1, 1, 1),
        TextSize               = 22,
        Font                   = Config.UI.TitleFont,
        ZIndex                 = 2,
    }, logoInner)

    -- Pulse animasi logo
    local pulsing = true
    task.spawn(function()
        while pulsing do
            Functions.Tween(logoOuter, {BackgroundTransparency = 0.55}, 0.7)
            task.wait(0.7)
            if not pulsing then break end
            Functions.Tween(logoOuter, {BackgroundTransparency = 0.80}, 0.7)
            task.wait(0.7)
        end
    end)

    -- ========================
    -- // TITLE & SUBTITLE
    -- ========================
    Functions.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.TitleSize + 3,
        Font                   = Config.UI.TitleFont,
        TextXAlignment         = Enum.TextXAlignment.Center,
        LayoutOrder            = 2,
    }, card)

    local subtitleBadge = Functions.Create("Frame", {
        Name             = "SubBadge",
        Size             = UDim2.fromOffset(0, 20),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = logoColor,
        BackgroundTransparency = 0.78,
        BorderSizePixel  = 0,
        LayoutOrder      = 3,
    }, card)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 10)}, subtitleBadge)
    Functions.Create("UIStroke", {
        Color           = logoColor,
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, subtitleBadge)
    Functions.Create("TextLabel", {
        Size                   = UDim2.fromScale(1, 1),
        AutomaticSize          = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text                   = "  " .. subtitle .. "  ",
        TextColor3             = logoColor,
        TextSize               = 11,
        Font                   = Config.UI.TitleFont,
        TextXAlignment         = Enum.TextXAlignment.Center,
        Padding                = UDim.new(0, 8),
    }, subtitleBadge)

    -- ========================
    -- // PROGRESS BAR
    -- ========================
    local fillBar = nil
    if showProg then
        local trackBG = Functions.Create("Frame", {
            Name             = "Track",
            Size             = UDim2.new(1, 0, 0, 5),
            BackgroundColor3 = Theme.Get("SliderBackground"),
            BorderSizePixel  = 0,
            LayoutOrder      = 4,
        }, card)
        Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, trackBG)

        fillBar = Functions.Create("Frame", {
            Size             = UDim2.fromScale(0, 1),
            BackgroundColor3 = logoColor,
            BorderSizePixel  = 0,
        }, trackBG)
        Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, fillBar)
    end

    -- ========================
    -- // STATUS LABEL
    -- ========================
    local statusLabel = Functions.Create("TextLabel", {
        Name                   = "Status",
        Size                   = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text                   = #steps > 0 and steps[1] or "Memuat...",
        TextColor3             = Theme.Get("TextSecondary"),
        TextSize               = Config.UI.FontSize - 1,
        Font                   = Config.UI.SmallFont,
        TextXAlignment         = Enum.TextXAlignment.Center,
        LayoutOrder            = 5,
    }, card)

    -- ========================
    -- // LOADING OBJECT (return)
    -- ========================
    local finished = false

    local Screen = {}

    -- Update progress manual (0-1)
    function Screen:SetProgress(pct)
        if not fillBar then return end
        pct = math.clamp(tonumber(pct) or 0, 0, 1)
        Functions.Tween(fillBar, {Size = UDim2.fromScale(pct, 1)}, 0.3)
    end

    -- Update teks status
    function Screen:SetStatus(text)
        if statusLabel and statusLabel.Parent then
            statusLabel.Text = tostring(text or "")
        end
    end

    -- Fade out dan destroy
    function Screen:Finish()
        if finished then return end
        finished = true
        pulsing  = false
        Functions.Tween(bg,   {BackgroundTransparency = 1}, 0.4)
        Functions.Tween(card, {BackgroundTransparency = 1}, 0.4)
        task.wait(0.45)
        if sg and sg.Parent then sg:Destroy() end
        Functions.SafeCall(onFinish)
    end

    -- ========================
    -- // AUTO STEP RUNNER
    -- ========================
    if autoFinish and #steps > 0 then
        task.spawn(function()
            local total = #steps
            for i, step in ipairs(steps) do
                if statusLabel and statusLabel.Parent then
                    statusLabel.Text = step
                end
                if fillBar then
                    Functions.Tween(fillBar,
                        {Size = UDim2.fromScale(i / total, 1)}, stepDelay * 0.8)
                end
                task.wait(stepDelay)
            end
            task.wait(0.2)
            Screen:Finish()
        end)
    elseif autoFinish and #steps == 0 then
        -- Tanpa steps: animasi indeterminate singkat lalu selesai
        if fillBar then
            Functions.Tween(fillBar, {Size = UDim2.fromScale(1, 1)}, 1.2)
        end
        task.delay(1.4, function() Screen:Finish() end)
    end

    return Screen
end

return Loading
