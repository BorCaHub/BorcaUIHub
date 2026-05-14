--[[
    BorcaUIHub — Sections/Sections.lua
    Membagi isi tab menjadi blok-blok terorganisir.
    Setiap section punya judul, deskripsi opsional, dan area konten.
]]

local Sections = {}

local Theme     = require(script.Parent.Parent.UI.Theme)
local Config    = require(script.Parent.Parent.UI.Config)
local Functions = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- SECTION REGISTRY
-- Menyimpan semua section yang sudah dibuat { [sectionId] = sectionObj }
-- ============================================================

Sections._registry = {}

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Sections.Create(parent, options) → sectionObject
    Buat sebuah section baru di dalam parent frame (biasanya frame tab).

    @param parent   Frame
    @param options {
        Id:           string   -- ID unik section (opsional, auto-generate jika kosong)
        Title:        string   -- Judul section
        Description:  string   -- Deskripsi singkat di bawah judul (opsional)
        Collapsible:  boolean  -- Bisa di-collapse/expand (default false)
        Collapsed:    boolean  -- Default collapsed saat pertama dibuat
        LayoutOrder:  number   -- Urutan tampil
        ShowStroke:   boolean  -- Tampilkan border stroke (default true)
        Icon:         string   -- Ikon di sebelah judul (opsional)
        RightLabel:   string   -- Label kecil di kanan header (opsional, misal "3 fitur")
    }
    @return sectionObject {
        Frame:        Frame     -- container utama section
        Header:       Frame     -- header (judul + kontrol)
        Content:      Frame     -- area konten (tempat komponen dimasukkan)
        Id:           string
        Toggle:       function  -- toggle collapse/expand
        SetTitle:     function
        SetVisible:   function
        AddComponent: function  -- shortcut menambah child ke Content
    }
]]
function Sections.Create(parent, options)
    options = options or {}

    local sectionId = options.Id or ("section_" .. tostring(#Sections._registry + 1) .. "_" .. tostring(tick()):sub(-5))
    local title       = options.Title       or "Section"
    local description = options.Description or ""
    local collapsible = options.Collapsible or false
    local collapsed   = options.Collapsed   or false
    local showStroke  = options.ShowStroke  ~= false
    local layoutOrder = options.LayoutOrder or 0
    local icon        = options.Icon        or ""
    local rightLabel  = options.RightLabel  or ""

    -- ── OUTER FRAME ────────────────────────────────────────
    local outerFrame = Functions.CreateFrame({
        Name                   = "Section_" .. sectionId,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor        = Theme.Get("CardBackground"),
        BackgroundTransparency = 0,
        CornerRadius           = UDim.new(0, Config.UI.CardRadius),
        LayoutOrder            = layoutOrder,
    })

    if showStroke then
        Functions.ApplyStroke(outerFrame, {
            Color        = Theme.Get("Stroke"),
            Thickness    = 1,
            Transparency = 0.55,
        })
    end

    -- Layout vertikal di dalam outer
    Functions.ApplyListLayout(outerFrame, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 0),
    })

    -- ── HEADER ─────────────────────────────────────────────
    local headerHeight = description ~= "" and 52 or 40

    local header = Functions.CreateFrame({
        Name            = "SectionHeader",
        Parent          = outerFrame,
        Size            = UDim2.new(1, 0, 0, headerHeight),
        BackgroundTransparency = 1,
        LayoutOrder     = 0,
    })

    -- Left accent bar
    local accentBar = Functions.CreateFrame({
        Name            = "AccentBar",
        Parent          = header,
        Size            = UDim2.new(0, 3, 0, description ~= "" and 28 or 20),
        Position        = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius    = UDim.new(0, 2),
    })

    -- Ikon (jika ada)
    local iconOffset = 24
    if icon ~= "" then
        Functions.CreateLabel({
            Name      = "SectionIcon",
            Parent    = header,
            Text      = icon,
            Size      = UDim2.new(0, 18, 0, 18),
            Position  = UDim2.new(0, 22, 0.5, description ~= "" and -9 or 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Font      = Enum.Font.GothamBold,
            TextSize  = 13,
            TextColor = Theme.Get("Accent"),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 3,
        })
        iconOffset = 44
    end

    -- Title
    local titleLabel = Functions.CreateLabel({
        Name      = "SectionTitle",
        Parent    = header,
        Text      = title,
        Size      = UDim2.new(1, -120, 0, 18),
        Position  = UDim2.new(0, iconOffset, description ~= "" and 0.5 or 0.5, description ~= "" and -10 or 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentLabel + 1,
        TextColor = Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    -- Description (jika ada)
    local descLabel = nil
    if description ~= "" then
        descLabel = Functions.CreateLabel({
            Name      = "SectionDesc",
            Parent    = header,
            Text      = description,
            Size      = UDim2.new(1, -120, 0, 14),
            Position  = UDim2.new(0, iconOffset, 0.5, 8),
            AnchorPoint = Vector2.new(0, 0.5),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- Right label (opsional)
    if rightLabel ~= "" then
        local rlFrame = Functions.CreateFrame({
            Name            = "RightLabel",
            Parent          = header,
            Size            = UDim2.new(0, 0, 0, 20),
            AutomaticSize   = Enum.AutomaticSize.X,
            Position        = UDim2.new(1, collapsible and -52 or -14, 0.5, 0),
            AnchorPoint     = Vector2.new(1, 0.5),
            BackgroundColor = Theme.Get("ButtonSecondary"),
            CornerRadius    = UDim.new(0, 5),
        })

        Functions.ApplyPadding(rlFrame, { Left = 7, Right = 7 })

        Functions.CreateLabel({
            Name      = "RightLabelText",
            Parent    = rlFrame,
            Text      = rightLabel,
            Size      = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.BadgeText,
            TextColor = Theme.Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 4,
        })
    end

    -- Collapse toggle button (jika collapsible)
    local collapseBtn = nil
    if collapsible then
        collapseBtn = Functions.CreateButton({
            Name            = "CollapseBtn",
            Parent          = header,
            Size            = UDim2.new(0, 28, 0, 28),
            Position        = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint     = Vector2.new(1, 0.5),
            Text            = collapsed and "▸" or "▾",
            Font            = Enum.Font.GothamBold,
            TextSize        = 11,
            TextColor       = Theme.Get("TextSecondary"),
            BackgroundColor = Theme.Get("ButtonSecondary"),
            BackgroundTransparency = 0.5,
            CornerRadius    = UDim.new(0, 6),
            ZIndex          = 4,
        })

        -- Hover
        Animations.ApplyHoverEffect(collapseBtn, Theme.Get("ButtonHover"))
    end

    -- Separator bawah header
    local headerSep = Functions.CreateFrame({
        Name            = "HeaderSeparator",
        Parent          = outerFrame,
        Size            = UDim2.new(1, -24, 0, 1),
        BackgroundColor = Theme.Get("Separator"),
        BackgroundTransparency = 0.4,
        LayoutOrder     = 1,
    })

    -- Align separator ke tengah horizontal
    headerSep.Position = UDim2.new(0.5, 0, 0, 0)
    headerSep.AnchorPoint = Vector2.new(0.5, 0)

    -- ── CONTENT AREA ───────────────────────────────────────
    local contentWrapper = Functions.CreateFrame({
        Name                   = "ContentWrapper",
        Parent                 = outerFrame,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipDescendants        = true,
        LayoutOrder            = 2,
    })

    local content = Functions.CreateFrame({
        Name                   = "SectionContent",
        Parent                 = contentWrapper,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })

    Functions.ApplyListLayout(content, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, Config.UI.ComponentGap),
    })

    Functions.ApplyPadding(content, {
        Top    = 10,
        Bottom = 10,
        Left   = Config.UI.SectionPadding,
        Right  = Config.UI.SectionPadding,
    })

    -- ── COLLAPSE LOGIC ─────────────────────────────────────
    local isCollapsed = collapsed

    -- Sembunyikan content jika mulai collapsed
    if collapsed then
        contentWrapper.Visible = false
        headerSep.Visible      = false
    end

    local function ToggleCollapse()
        if not collapsible then return end
        isCollapsed = not isCollapsed

        local ts   = game:GetService("TweenService")
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        if isCollapsed then
            -- Collapse: sembunyikan content
            ts:Create(contentWrapper, info, { Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.delay(0.2, function()
                contentWrapper.Visible = false
                headerSep.Visible      = false
            end)
            if collapseBtn then
                collapseBtn.Text = "▸"
            end
        else
            -- Expand: tampilkan content
            contentWrapper.Visible = true
            headerSep.Visible      = true
            ts:Create(contentWrapper, info, {
                Size = UDim2.new(1, 0, 0, content.AbsoluteSize.Y + 20),
            }):Play()
            task.delay(0.2, function()
                contentWrapper.AutomaticSize = Enum.AutomaticSize.Y
            end)
            if collapseBtn then
                collapseBtn.Text = "▾"
            end
        end
    end

    -- Klik collapse button
    if collapseBtn then
        collapseBtn.MouseButton1Click:Connect(ToggleCollapse)
    end

    -- Klik header juga bisa toggle (jika collapsible)
    if collapsible then
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                ToggleCollapse()
            end
        end)
    end

    -- ── SECTION OBJECT ─────────────────────────────────────
    local sectionObj = {
        Id      = sectionId,
        Frame   = outerFrame,
        Header  = header,
        Content = content,

        -- Toggle collapse/expand
        Toggle = ToggleCollapse,

        -- Ubah judul section
        SetTitle = function(newTitle)
            titleLabel.Text = newTitle
        end,

        -- Ubah deskripsi section
        SetDescription = function(newDesc)
            if descLabel then
                descLabel.Text = newDesc
            end
        end,

        -- Tampilkan / sembunyikan section
        SetVisible = function(visible)
            outerFrame.Visible = visible
        end,

        -- Shortcut: tambah komponen ke content
        AddComponent = function(component)
            if typeof(component) == "Instance" then
                component.Parent = content
            end
        end,

        -- Kembalikan apakah collapsed
        IsCollapsed = function()
            return isCollapsed
        end,
    }

    Sections._registry[sectionId] = sectionObj
    return sectionObj
end

-- ============================================================
-- UTILITY
-- ============================================================

--[[
    Sections.Get(sectionId) → sectionObject | nil
    Ambil section berdasarkan ID.
]]
function Sections.Get(sectionId)
    return Sections._registry[sectionId]
end

--[[
    Sections.Remove(sectionId)
    Hapus section dari UI dan registry.
]]
function Sections.Remove(sectionId)
    local section = Sections._registry[sectionId]
    if section then
        Functions.SafeDestroy(section.Frame)
        Sections._registry[sectionId] = nil
    end
end

--[[
    Sections.Clear(parent)
    Hapus semua section yang ada di dalam parent frame.
]]
function Sections.Clear(parent)
    if not parent then return end
    for id, section in pairs(Sections._registry) do
        if Functions.IsValid(section.Frame) and section.Frame:IsDescendantOf(parent) then
            Functions.SafeDestroy(section.Frame)
            Sections._registry[id] = nil
        end
    end
end

--[[
    Sections.UpdateTheme()
    Perbarui warna semua section setelah tema berubah.
]]
function Sections.UpdateTheme()
    for _, section in pairs(Sections._registry) do
        if Functions.IsValid(section.Frame) then
            section.Frame.BackgroundColor3 = Theme.Get("CardBackground")

            -- Update accent bar
            local bar = section.Header:FindFirstChild("AccentBar")
            if bar then bar.BackgroundColor3 = Theme.Get("Accent") end

            -- Update title
            local titleLbl = section.Header:FindFirstChild("SectionTitle")
            if titleLbl then titleLbl.TextColor3 = Theme.Get("TextPrimary") end

            -- Update desc
            local descLbl = section.Header:FindFirstChild("SectionDesc")
            if descLbl then descLbl.TextColor3 = Theme.Get("TextSecondary") end
        end
    end
end

-- Auto-update saat tema berubah
Theme.OnChanged(function()
    Sections.UpdateTheme()
end)

return Sections
