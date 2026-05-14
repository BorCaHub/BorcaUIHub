--[[
    BorcaUIHub — Components/Paragraphs.lua
    Komponen teks panjang: deskripsi fitur, tutorial, info update, catatan.
    Mendukung RichText, link-style, collapsible, dan icon header.
]]

local Paragraphs = {}

local Theme     = require(script.Parent.Parent.UI.Theme)
local Config    = require(script.Parent.Parent.UI.Config)
local Functions = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Paragraphs.Create(parent, options) → paragraphObject
    Buat blok teks paragraf.

    @param options {
        Title:        string   -- judul paragraf (opsional)
        Text:         string   -- isi teks
        Icon:         string   -- ikon di sebelah judul (opsional)
        Style:        "default" | "info" | "warning" | "error" | "success" | "tip"
        Collapsible:  boolean  -- bisa dilipat (default false)
        Collapsed:    boolean  -- mulai dalam kondisi lipat
        RichText:     boolean  -- aktifkan RichText formatting
        LayoutOrder:  number
    }
    @return paragraphObject {
        Frame:      Frame
        SetText:    function(string)
        SetTitle:   function(string)
        SetVisible: function(boolean)
        Toggle:     function
    }
]]
function Paragraphs.Create(parent, options)
    options = options or {}

    local title       = options.Title       or ""
    local text        = options.Text        or ""
    local icon        = options.Icon        or ""
    local style       = options.Style       or "default"
    local collapsible = options.Collapsible or false
    local collapsed   = options.Collapsed   or false
    local richText    = options.RichText    or false
    local layoutOrder = options.LayoutOrder or 0

    -- Style config
    local accentColor, bgTransp
    if style == "info" then
        accentColor = Theme.Get("Info")
        bgTransp    = 0.88
    elseif style == "warning" then
        accentColor = Theme.Get("Warning")
        bgTransp    = 0.85
    elseif style == "error" then
        accentColor = Theme.Get("Error")
        bgTransp    = 0.85
    elseif style == "success" then
        accentColor = Theme.Get("Success")
        bgTransp    = 0.88
    elseif style == "tip" then
        accentColor = Theme.Get("Accent")
        bgTransp    = 0.88
    else
        accentColor = Theme.Get("Stroke")
        bgTransp    = 1.0
    end

    -- ── OUTER FRAME ────────────────────────────────────────
    local outer = Functions.CreateFrame({
        Name                   = "Para_" .. (title ~= "" and title or "block"),
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor        = accentColor,
        BackgroundTransparency = bgTransp,
        CornerRadius           = 7,
        LayoutOrder            = layoutOrder,
        ZIndex                 = 3,
    })

    if style ~= "default" then
        Functions.ApplyStroke(outer, {
            Color        = accentColor,
            Thickness    = 1,
            Transparency = 0.5,
        })
    end

    -- Left accent bar (hanya untuk style non-default)
    if style ~= "default" then
        Functions.CreateFrame({
            Name            = "LeftBar",
            Parent          = outer,
            Size            = UDim2.new(0, 3, 1, -8),
            Position        = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint     = Vector2.new(0, 0.5),
            BackgroundColor = accentColor,
            CornerRadius    = UDim.new(0, 2),
            ZIndex          = 4,
        })
    end

    Functions.ApplyPadding(outer, {
        Top    = 10,
        Bottom = 10,
        Left   = style ~= "default" and 14 or 8,
        Right  = 10,
    })

    Functions.ApplyListLayout(outer, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 6),
    })

    -- ── HEADER (judul + collapse btn) ──────────────────────
    local titleLabel = nil
    local collapseBtn = nil
    local contentFrame = nil
    local isCollapsed = collapsed

    if title ~= "" then
        local headerRow = Functions.CreateFrame({
            Name                   = "ParaHeader",
            Parent                 = outer,
            Size                   = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder            = 0,
            ZIndex                 = 4,
        })

        local headerLayout = Instance.new("UIListLayout")
        headerLayout.FillDirection     = Enum.FillDirection.Horizontal
        headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        headerLayout.SortOrder         = Enum.SortOrder.LayoutOrder
        headerLayout.Padding           = UDim.new(0, 6)
        headerLayout.Parent            = headerRow

        if icon ~= "" then
            Functions.CreateLabel({
                Name     = "ParaIcon",
                Parent   = headerRow,
                Text     = icon,
                Size     = UDim2.new(0, 16, 1, 0),
                Font     = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor = accentColor,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex   = 5,
                LayoutOrder = 0,
            })
        end

        titleLabel = Functions.CreateLabel({
            Name      = "ParaTitle",
            Parent    = headerRow,
            Text      = title,
            Size      = UDim2.new(1, collapsible and -24 or 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = Config.Font.Size.ComponentLabel,
            TextColor = style ~= "default" and accentColor or Theme.Get("TextPrimary"),
            ZIndex    = 5,
            LayoutOrder = 1,
        })

        if collapsible then
            collapseBtn = Functions.CreateButton({
                Name            = "ParaCollapse",
                Parent          = headerRow,
                Size            = UDim2.new(0, 18, 0, 18),
                BackgroundTransparency = 1,
                Text            = collapsed and "▸" or "▾",
                Font            = Enum.Font.GothamBold,
                TextSize        = 11,
                TextColor       = Theme.Get("TextSecondary"),
                ZIndex          = 5,
                LayoutOrder     = 2,
            })
        end
    end

    -- ── CONTENT AREA ───────────────────────────────────────
    contentFrame = Functions.CreateFrame({
        Name                   = "ParaContent",
        Parent                 = outer,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = collapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipDescendants        = true,
        Visible                = not collapsed,
        LayoutOrder            = 1,
        ZIndex                 = 4,
    })

    local textLbl = Functions.CreateLabel({
        Name         = "ParaText",
        Parent       = contentFrame,
        Text         = text,
        Size         = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font         = Config.Font.Body,
        TextSize     = Config.Font.Size.ComponentLabel - 1,
        TextColor    = Theme.Get("TextSecondary"),
        RichText     = richText,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex       = 5,
    })
    textLbl.TextWrapped = true

    -- ── COLLAPSE LOGIC ─────────────────────────────────────
    local function Toggle()
        if not collapsible then return end
        isCollapsed = not isCollapsed

        if isCollapsed then
            contentFrame.Visible = false
            if collapseBtn then collapseBtn.Text = "▸" end
        else
            contentFrame.Visible = true
            contentFrame.AutomaticSize = Enum.AutomaticSize.Y
            if collapseBtn then collapseBtn.Text = "▾" end
        end
    end

    if collapsible and collapseBtn then
        collapseBtn.MouseButton1Click:Connect(Toggle)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        textLbl.TextColor3 = Theme.Get("TextSecondary")
        if titleLabel then
            titleLabel.TextColor3 = style ~= "default" and Theme.Get(
                style == "info" and "Info" or
                style == "warning" and "Warning" or
                style == "error" and "Error" or
                style == "success" and "Success" or "Accent"
            ) or Theme.Get("TextPrimary")
        end
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = outer,

        SetText = function(newText)
            textLbl.Text = newText
        end,

        SetTitle = function(newTitle)
            if titleLabel then titleLabel.Text = newTitle end
        end,

        SetVisible = function(v)
            outer.Visible = v
        end,

        Toggle = Toggle,

        IsCollapsed = function()
            return isCollapsed
        end,
    }
end

--[[
    Paragraphs.Info(parent, text, title, options)
    Shortcut: paragraph style info (biru).
]]
function Paragraphs.Info(parent, text, title, options)
    options = options or {}
    options.Text  = text
    options.Title = title or ""
    options.Style = "info"
    options.Icon  = options.Icon or "ℹ"
    return Paragraphs.Create(parent, options)
end

--[[
    Paragraphs.Warning(parent, text, title, options)
    Shortcut: paragraph style warning (kuning).
]]
function Paragraphs.Warning(parent, text, title, options)
    options = options or {}
    options.Text  = text
    options.Title = title or ""
    options.Style = "warning"
    options.Icon  = options.Icon or "⚠"
    return Paragraphs.Create(parent, options)
end

--[[
    Paragraphs.Tip(parent, text, title, options)
    Shortcut: paragraph style tip (accent).
]]
function Paragraphs.Tip(parent, text, title, options)
    options = options or {}
    options.Text  = text
    options.Title = title or ""
    options.Style = "tip"
    options.Icon  = options.Icon or "✦"
    return Paragraphs.Create(parent, options)
end

return Paragraphs
