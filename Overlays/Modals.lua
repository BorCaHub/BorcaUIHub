-- // Modals.lua
-- // BorcaScriptHub - Modal / Confirmation Dialog
-- // Jendela konfirmasi yang muncul di atas UI utama.
-- // Mendukung: confirm/cancel, custom buttons, input modal, alert.

local Modals = {}
local Functions, Theme, Config
local TweenService = game:GetService("TweenService")

function Modals.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // STATE — hanya 1 modal aktif sekaligus
-- ========================
local activeModal = nil

local function destroyActive()
    if activeModal and activeModal.Parent then
        activeModal:Destroy()
    end
    activeModal = nil
end

-- ========================
-- // INTERNAL: Buat ScreenGui modal (overlay + card)
-- ========================
local function buildBase(title, subtitle, iconText, iconColor)
    -- Tutup modal sebelumnya jika ada
    destroyActive()

    -- ── ScreenGui ──
    local sg = Instance.new("ScreenGui")
    sg.Name           = "BorcaModal"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9998
    sg.IgnoreGuiInset = true

    local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok then
        sg.Parent = game:GetService("Players").LocalPlayer
            :WaitForChild("PlayerGui", 5)
    end
    activeModal = sg

    -- ── Dim overlay ──
    local overlay = Instance.new("Frame")
    overlay.Name                   = "Overlay"
    overlay.Size                   = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3       = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel        = 0
    overlay.Parent                 = sg
    -- Fade in overlay
    Functions.Tween(overlay, {BackgroundTransparency = 0.5}, 0.2)

    -- ── Card ──
    local card = Functions.Create("Frame", {
        Name             = "ModalCard",
        Size             = UDim2.fromOffset(360, 10),   -- height auto
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Get("SecondaryBG"),
        BorderSizePixel  = 0,
        BackgroundTransparency = 1,
    }, sg)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
    Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, card)
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 18),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft   = UDim.new(0, 18),
        PaddingRight  = UDim.new(0, 18),
    }, card)
    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 10),
    }, card)

    -- Fade in card
    Functions.Tween(card, {BackgroundTransparency = 0}, 0.2)

    -- Accent top bar
    local accentBar = Functions.Create("Frame", {
        Name             = "AccentBar",
        Size             = UDim2.new(1, 36, 0, 3),
        Position         = UDim2.fromOffset(-18, 0),
        BackgroundColor3 = iconColor or Theme.Get("Accent"),
        BorderSizePixel  = 0,
        LayoutOrder      = 0,
    }, card)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 3)}, accentBar)

    -- ── Icon + Title row ──
    local headerRow = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
    }, card)
    Functions.Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 8),
    }, headerRow)

    if iconText and iconText ~= "" then
        local iconBg = Functions.Create("Frame", {
            Size             = UDim2.fromOffset(32, 32),
            BackgroundColor3 = iconColor or Theme.Get("Accent"),
            BackgroundTransparency = 0.7,
            BorderSizePixel  = 0,
            LayoutOrder      = 1,
        }, headerRow)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0, 8)}, iconBg)
        Functions.Create("TextLabel", {
            Size                   = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text                   = iconText,
            TextSize               = 16,
            Font                   = Enum.Font.GothamMedium,
        }, iconBg)
    end

    local titleLabel = Functions.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, -46, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text                   = title or "Konfirmasi",
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.FontSize + 1,
        Font                   = Config.UI.TitleFont,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        LayoutOrder            = 2,
    }, headerRow)

    -- ── Divider ──
    Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Get("Divider"),
        BorderSizePixel  = 0,
        LayoutOrder      = 2,
    }, card)

    -- ── Subtitle / body ──
    local bodyLabel = nil
    if subtitle and subtitle ~= "" then
        bodyLabel = Functions.Create("TextLabel", {
            Name                   = "Body",
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text                   = subtitle,
            TextColor3             = Theme.Get("TextSecondary"),
            TextSize               = Config.UI.FontSize - 1,
            Font                   = Config.UI.SmallFont,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            RichText               = true,
            LayoutOrder            = 3,
        }, card)
    end

    return sg, card, overlay, titleLabel, bodyLabel, accentBar
end

-- ========================
-- // INTERNAL: Baris tombol bawah
-- ========================
local function makeButtonRow(parent, order)
    local row = Functions.Create("Frame", {
        Name             = "BtnRow",
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = order or 10,
    }, parent)
    Functions.Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 8),
    }, row)
    return row
end

local function makeBtn(parent, text, bgColor, textColor, layoutOrder, callback)
    local btn = Functions.Create("TextButton", {
        Name             = "Btn_" .. text,
        Size             = UDim2.fromOffset(90, 30),
        BackgroundColor3 = bgColor,
        Text             = text,
        TextColor3       = textColor,
        TextSize         = Config.UI.FontSize - 1,
        Font             = Config.UI.Font,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
        LayoutOrder      = layoutOrder,
    }, parent)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    btn.MouseEnter:Connect(function()
        Functions.Tween(btn, {BackgroundTransparency = 0.2}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        Functions.Tween(btn, {BackgroundTransparency = 0}, 0.1)
    end)
    btn.MouseButton1Click:Connect(function()
        Functions.SafeCall(callback)
    end)
    return btn
end

-- ========================
-- // CLOSE ANIMATION
-- ========================
local function closeModal(sg, card, overlay, delay)
    delay = delay or 0
    task.delay(delay, function()
        if not (sg and sg.Parent) then return end
        Functions.Tween(card,    {BackgroundTransparency = 1}, 0.18)
        Functions.Tween(overlay, {BackgroundTransparency = 1}, 0.18)
        task.wait(0.2)
        if sg and sg.Parent then sg:Destroy() end
        if activeModal == sg then activeModal = nil end
    end)
end

-- ========================
-- // PUBLIC API
-- ========================

-- ── CONFIRM MODAL ──
-- Tombol Konfirmasi + Batal
function Modals.Confirm(options)
    options = options or {}
    local title      = options.Title      or "Konfirmasi"
    local body       = options.Body       or "Yakin ingin melanjutkan?"
    local confirmTxt = options.ConfirmText or "Ya, Lanjutkan"
    local cancelTxt  = options.CancelText  or "Batal"
    local icon       = options.Icon        or "⚠"
    local iconColor  = options.IconColor   or Theme.Get("Warning")
    local onConfirm  = options.OnConfirm   or function() end
    local onCancel   = options.OnCancel    or function() end

    local sg, card, overlay = buildBase(title, body, icon, iconColor)

    local btnRow = makeButtonRow(card, 10)

    makeBtn(btnRow, cancelTxt, Theme.Get("ElementBG"), Theme.Get("TextSecondary"), 1, function()
        closeModal(sg, card, overlay)
        Functions.SafeCall(onCancel)
    end)

    makeBtn(btnRow, confirmTxt, iconColor, Color3.new(1, 1, 1), 2, function()
        closeModal(sg, card, overlay)
        Functions.SafeCall(onConfirm)
    end)

    return {
        Close = function() closeModal(sg, card, overlay) end
    }
end

-- ── ALERT MODAL ──
-- Hanya tombol Tutup
function Modals.Alert(options)
    options = options or {}
    local title     = options.Title    or "Peringatan"
    local body      = options.Body     or ""
    local icon      = options.Icon     or "ℹ"
    local iconColor = options.IconColor or Theme.Get("Info")
    local closeTxt  = options.CloseText or "Tutup"
    local onClose   = options.OnClose   or function() end

    local sg, card, overlay = buildBase(title, body, icon, iconColor)

    local btnRow = makeButtonRow(card, 10)
    makeBtn(btnRow, closeTxt, Theme.Get("Accent"), Color3.new(1, 1, 1), 1, function()
        closeModal(sg, card, overlay)
        Functions.SafeCall(onClose)
    end)

    return {
        Close = function() closeModal(sg, card, overlay) end
    }
end

-- ── INPUT MODAL ──
-- Dialog dengan TextBox untuk input teks
function Modals.Input(options)
    options = options or {}
    local title       = options.Title       or "Input"
    local body        = options.Body        or ""
    local placeholder = options.Placeholder or "Ketik di sini..."
    local defaultVal  = options.Default     or ""
    local confirmTxt  = options.ConfirmText  or "OK"
    local cancelTxt   = options.CancelText   or "Batal"
    local icon        = options.Icon         or "✏"
    local iconColor   = options.IconColor    or Theme.Get("Accent")
    local onConfirm   = options.OnConfirm    or function(_val) end
    local onCancel    = options.OnCancel     or function() end

    local sg, card, overlay = buildBase(title, body, icon, iconColor)

    -- TextBox area
    local inputBG = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Get("ElementBG"),
        BorderSizePixel  = 0,
        LayoutOrder      = 5,
    }, card)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 6)}, inputBG)
    local inputStroke = Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inputBG)

    local textBox = Functions.Create("TextBox", {
        Size                   = UDim2.new(1, -16, 1, 0),
        Position               = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text                   = defaultVal,
        PlaceholderText        = placeholder,
        PlaceholderColor3      = Theme.Get("TextDisabled"),
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.FontSize,
        Font                   = Config.UI.Font,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = false,
        BorderSizePixel        = 0,
    }, inputBG)

    textBox.Focused:Connect(function()
        Functions.Tween(inputStroke, {Color = Theme.Get("Accent")}, 0.12)
    end)
    textBox.FocusLost:Connect(function()
        Functions.Tween(inputStroke, {Color = Theme.Get("Border")}, 0.12)
    end)

    local btnRow = makeButtonRow(card, 10)

    makeBtn(btnRow, cancelTxt, Theme.Get("ElementBG"), Theme.Get("TextSecondary"), 1, function()
        closeModal(sg, card, overlay)
        Functions.SafeCall(onCancel)
    end)

    makeBtn(btnRow, confirmTxt, Theme.Get("Accent"), Color3.new(1, 1, 1), 2, function()
        local val = textBox.Text or ""
        closeModal(sg, card, overlay)
        Functions.SafeCall(onConfirm, val)
    end)

    -- Enter key submit
    textBox.FocusLost:Connect(function(enter)
        if enter then
            local val = textBox.Text or ""
            closeModal(sg, card, overlay)
            Functions.SafeCall(onConfirm, val)
        end
    end)

    return {
        Close    = function() closeModal(sg, card, overlay) end,
        TextBox  = textBox,
    }
end

-- ── DESTROY ACTIVE ──
function Modals.Close()
    destroyActive()
end

return Modals
