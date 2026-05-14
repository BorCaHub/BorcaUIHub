-- // Tooltips.lua
-- // BorcaScriptHub - Tooltip System
-- // Penjelasan singkat yang muncul saat hover di atas elemen.
-- // Tooltip otomatis menyesuaikan posisi agar tidak keluar layar.

local Tooltips = {}
local Functions, Theme, Config
local UIS = game:GetService("UserInputService")

function Tooltips.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // STATE
-- ========================
local tooltipGui    = nil
local tooltipFrame  = nil
local tooltipLabel  = nil
local tooltipSub    = nil
local currentConn   = {}
local visible       = false
local PADDING       = 10
local OFFSET_Y      = 16    -- jarak di bawah cursor

-- ========================
-- // ENSURE GUI
-- ========================
local function ensureGui()
    if tooltipGui and tooltipGui.Parent then return end

    tooltipGui = Instance.new("ScreenGui")
    tooltipGui.Name           = "BorcaTooltips"
    tooltipGui.ResetOnSpawn   = false
    tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    tooltipGui.DisplayOrder   = 9997
    tooltipGui.IgnoreGuiInset = true

    local ok = pcall(function() tooltipGui.Parent = game:GetService("CoreGui") end)
    if not ok then
        tooltipGui.Parent = game:GetService("Players").LocalPlayer
            :WaitForChild("PlayerGui", 5)
    end

    -- ── Tooltip frame (AutomaticSize) ──
    tooltipFrame = Functions.Create("Frame", {
        Name             = "TooltipFrame",
        Size             = UDim2.fromOffset(0, 0),
        AutomaticSize    = Enum.AutomaticSize.XY,
        BackgroundColor3 = Theme.Get("TertiaryBG"),
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 50,
    }, tooltipGui)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 5)}, tooltipFrame)
    Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, tooltipFrame)
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
    }, tooltipFrame)
    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 2),
    }, tooltipFrame)

    -- Teks utama
    tooltipLabel = Functions.Create("TextLabel", {
        Name                   = "Label",
        Size                   = UDim2.fromOffset(0, 0),
        AutomaticSize          = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.FontSize - 1,
        Font                   = Config.UI.Font,
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = true,
        ZIndex                 = 51,
        LayoutOrder            = 1,
    }, tooltipFrame)

    -- Sub-teks (opsional, lebih kecil)
    tooltipSub = Functions.Create("TextLabel", {
        Name                   = "Sub",
        Size                   = UDim2.fromOffset(0, 0),
        AutomaticSize          = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = Theme.Get("TextMuted"),
        TextSize               = 9,
        Font                   = Config.UI.SmallFont,
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = true,
        ZIndex                 = 51,
        LayoutOrder            = 2,
        Visible                = false,
    }, tooltipFrame)
end

-- ========================
-- // SHOW / HIDE
-- ========================
local mouseConn = nil

local function startFollowing()
    if mouseConn then return end
    mouseConn = UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if not (tooltipFrame and tooltipFrame.Parent) then return end

        local mx = inp.Position.X
        local my = inp.Position.Y
        local vp = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)

        -- Ukuran frame setelah AutomaticSize
        local fw = tooltipFrame.AbsoluteSize.X
        local fh = tooltipFrame.AbsoluteSize.Y

        -- Sesuaikan agar tidak keluar layar
        local px = mx + PADDING
        local py = my + OFFSET_Y
        if px + fw > vp.X - 4 then px = mx - fw - PADDING end
        if py + fh > vp.Y - 4 then py = my - fh - PADDING end

        tooltipFrame.Position = UDim2.fromOffset(px, py)
    end)
end

local function stopFollowing()
    if mouseConn then
        pcall(function() mouseConn:Disconnect() end)
        mouseConn = nil
    end
end

local function showTooltip(text, sub)
    ensureGui()
    tooltipLabel.Text    = tostring(text or "")
    tooltipSub.Text      = tostring(sub  or "")
    tooltipSub.Visible   = (sub and sub ~= "")
    tooltipFrame.Visible = true
    visible              = true
    startFollowing()
end

local function hideTooltip()
    if tooltipFrame then
        tooltipFrame.Visible = false
    end
    visible = false
    stopFollowing()
end

-- ========================
-- // ATTACH TOOLTIP KE INSTANCE
-- // Mengembalikan { Detach = fn } untuk membersihkan koneksi
-- ========================
function Tooltips.Attach(instance, text, sub)
    if not instance then return { Detach = function() end } end

    local conns = {}

    local function track(c) table.insert(conns, c) end

    track(instance.MouseEnter:Connect(function()
        showTooltip(text, sub)
    end))

    track(instance.MouseLeave:Connect(function()
        hideTooltip()
    end))

    -- Jika instance dihancurkan, bersihkan
    track(instance.AncestryChanged:Connect(function()
        if not instance.Parent then
            hideTooltip()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns = {}
        end
    end))

    return {
        Detach = function()
            hideTooltip()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns = {}
        end,
        SetText = function(_, newText, newSub)
            text = newText
            sub  = newSub
        end,
    }
end

-- ========================
-- // MANUAL SHOW / HIDE
-- ========================
function Tooltips.Show(text, sub)
    showTooltip(text, sub)
end

function Tooltips.Hide()
    hideTooltip()
end

function Tooltips.IsVisible()
    return visible
end

return Tooltips
