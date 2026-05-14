--[[
    BorcaUIHub — Feedback/FeedbackUI.lua
    Tampilan UI yang dipakai user untuk mengirim masukan.
    Mendukung: bug report, suggestion, general feedback.
    Terhubung ke FeedbackManager untuk validasi dan pengiriman.
    Dipanggil dari tab Settings atau tombol feedback di sidebar.
]]

local FeedbackUI = {}

local Theme          = require(script.Parent.Parent.UI.Theme)
local Config         = require(script.Parent.Parent.UI.Config)
local Functions      = require(script.Parent.Parent.UI.Functions)
local Animations     = require(script.Parent.Parent.UI.Animations)
local FeedbackManager = require(script.Parent.FeedbackManager)
local Notifications  = require(script.Parent.Parent.Overlays.Notifications)

-- ============================================================
-- STATE
-- ============================================================

FeedbackUI._frame     = nil   -- frame container utama
FeedbackUI._visible   = false
FeedbackUI._activeTab = "Bug Report"

-- Komponen input internal
local _categoryDropdown = nil
local _titleInput       = nil
local _descInput        = nil
local _severityGroup    = nil
local _selectedSeverity = "Medium"
local _submitBtn        = nil
local _cooldownLabel    = nil
local _charCountLabel   = nil

-- ============================================================
-- BUILD
-- ============================================================

--[[
    FeedbackUI.Build(parent, options)
    Bangun panel feedback dan pasang ke parent frame.
    Biasanya dipanggil di dalam section "Feedback" di tab Settings.

    @param parent   Frame
    @param options {
        Compact:   boolean  -- mode ringkas tanpa header besar (default false)
        OnSent:    function(feedback)  -- callback setelah berhasil terkirim
    }
    @return frame
]]
function FeedbackUI.Build(parent, options)
    options = options or {}

    local compact = options.Compact or false
    local onSent  = options.OnSent  or function() end

    -- ── CONTAINER UTAMA ────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "FeedbackUI",
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor        = Theme.Get("CardBackground"),
        CornerRadius           = Config.UI.CardRadius,
        ZIndex                 = 3,
    })

    Functions.ApplyStroke(container, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.5,
    })

    Functions.ApplyPadding(container, { Top = 14, Bottom = 16, Left = 14, Right = 14 })
    Functions.ApplyListLayout(container, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 10),
    })

    FeedbackUI._frame = container

    -- ── HEADER (jika tidak compact) ────────────────────────
    if not compact then
        local headerRow = Functions.CreateFrame({
            Name                   = "FBHeader",
            Parent                 = container,
            Size                   = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            LayoutOrder            = 0,
        })

        Functions.CreateLabel({
            Name      = "FBTitle",
            Parent    = headerRow,
            Text      = "✉  Kirim Feedback",
            Size      = UDim2.new(1, 0, 0, 20),
            Position  = UDim2.new(0, 0, 0, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = Config.Font.Size.ComponentLabel + 1,
            TextColor = Theme.Get("TextPrimary"),
            ZIndex    = 4,
        })

        Functions.CreateLabel({
            Name      = "FBSubtitle",
            Parent    = headerRow,
            Text      = "Bantu kami berkembang dengan melaporkan bug atau memberikan saran.",
            Size      = UDim2.new(1, 0, 0, 13),
            Position  = UDim2.new(0, 0, 0, 19),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 4,
        })
    end

    -- ── CATEGORY TABS ──────────────────────────────────────
    local categories = { "Bug Report", "Suggestion", "General" }
    local catRow = Functions.CreateFrame({
        Name                   = "CategoryRow",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 30),
        BackgroundColor        = Theme.Get("ButtonSecondary"),
        CornerRadius           = 8,
        LayoutOrder            = 1,
    })

    Functions.ApplyPadding(catRow, { Top = 3, Bottom = 3, Left = 3, Right = 3 })

    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection       = Enum.FillDirection.Horizontal
    catLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    catLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    catLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    catLayout.Padding             = UDim.new(0, 3)
    catLayout.Parent              = catRow

    local catBtns = {}

    local function UpdateCategoryHighlight(active)
        for _, obj in ipairs(catBtns) do
            local isActive = (obj.cat == active)
            local ts = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.12), {
                BackgroundColor3    = isActive and Theme.Get("Accent")    or Theme.Get("ButtonSecondary"),
                BackgroundTransparency = isActive and 0 or 1,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.12), {
                TextColor3 = isActive and Color3.fromRGB(255,255,255) or Theme.Get("TextSecondary"),
            }):Play()
        end
    end

    for i, cat in ipairs(categories) do
        local isActive = (cat == FeedbackUI._activeTab)

        local catBtn = Functions.CreateButton({
            Name            = "Cat_" .. cat,
            Parent          = catRow,
            Size            = UDim2.new(1/#categories, 0, 1, 0),
            BackgroundColor = isActive and Theme.Get("Accent") or Theme.Get("ButtonSecondary"),
            BackgroundTransparency = isActive and 0 or 1,
            CornerRadius    = 6,
            ZIndex          = 4,
            LayoutOrder     = i,
            Text            = "",
        })

        local catLbl = Functions.CreateLabel({
            Name      = "CatText",
            Parent    = catBtn,
            Text      = cat,
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 11,
            TextColor = isActive and Color3.fromRGB(255,255,255) or Theme.Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 5,
        })

        catBtn.MouseButton1Click:Connect(function()
            FeedbackUI._activeTab = cat
            UpdateCategoryHighlight(cat)
            -- Tampilkan/sembunyikan severity (hanya untuk Bug Report)
            if _severityGroup then
                _severityGroup.Visible = (cat == "Bug Report")
            end
        end)

        table.insert(catBtns, { btn = catBtn, lbl = catLbl, cat = cat })
    end

    -- ── SEVERITY (khusus Bug Report) ───────────────────────
    local severityLevels = { "Low", "Medium", "High", "Critical" }
    local severityColors = {
        Low      = Theme.Get("Success"),
        Medium   = Theme.Get("Warning"),
        High     = Color3.fromRGB(255, 140, 60),
        Critical = Theme.Get("Error"),
    }

    local severityGroup = Functions.CreateFrame({
        Name                   = "SeverityGroup",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder            = 2,
        Visible                = true,
    })

    Functions.ApplyListLayout(severityGroup, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 6),
    })

    _severityGroup = severityGroup

    Functions.CreateLabel({
        Name      = "SevLabel",
        Parent    = severityGroup,
        Text      = "Tingkat Keparahan",
        Size      = UDim2.new(1, 0, 0, 14),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 0,
    })

    local sevRow = Functions.CreateFrame({
        Name                   = "SevRow",
        Parent                 = severityGroup,
        Size                   = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder            = 1,
    })

    Functions.ApplyListLayout(sevRow, {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding       = UDim.new(0, 6),
    })

    local sevBtns = {}

    local function UpdateSeverityHighlight(active)
        _selectedSeverity = active
        for _, obj in ipairs(sevBtns) do
            local isSel = (obj.sev == active)
            local color = severityColors[obj.sev] or Theme.Get("Accent")
            local ts = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.12), {
                BackgroundColor3       = color,
                BackgroundTransparency = isSel and 0 or 0.8,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.12), {
                TextColor3 = isSel and Color3.fromRGB(255,255,255) or color,
            }):Play()
        end
    end

    for i, sev in ipairs(severityLevels) do
        local color  = severityColors[sev]
        local isSel  = (sev == _selectedSeverity)

        local sevBtn = Functions.CreateButton({
            Name            = "Sev_" .. sev,
            Parent          = sevRow,
            Size            = UDim2.new(0.25, -5, 1, 0),
            BackgroundColor = color,
            BackgroundTransparency = isSel and 0 or 0.8,
            CornerRadius    = 6,
            ZIndex          = 4,
            LayoutOrder     = i,
            Text            = "",
        })

        local sevLbl = Functions.CreateLabel({
            Name      = "SevText",
            Parent    = sevBtn,
            Text      = sev,
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 10,
            TextColor = isSel and Color3.fromRGB(255,255,255) or color,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 5,
        })

        sevBtn.MouseButton1Click:Connect(function()
            UpdateSeverityHighlight(sev)
        end)

        table.insert(sevBtns, { btn = sevBtn, lbl = sevLbl, sev = sev })
    end

    -- ── TITLE INPUT ────────────────────────────────────────
    Functions.CreateLabel({
        Name      = "TitleLabel",
        Parent    = container,
        Text      = "Judul",
        Size      = UDim2.new(1, 0, 0, 14),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 3,
    })

    local titleWrapper = Functions.CreateFrame({
        Name            = "TitleWrapper",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, 32),
        BackgroundColor = Theme.Get("InputBackground"),
        CornerRadius    = 7,
        LayoutOrder     = 4,
    })

    local titleStroke = Functions.ApplyStroke(titleWrapper, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.4,
    })

    local titleBox = Functions.CreateTextBox({
        Name            = "TitleBox",
        Parent          = titleWrapper,
        Size            = UDim2.new(1, -16, 1, 0),
        Position        = UDim2.new(0, 8, 0, 0),
        PlaceholderText = "Ringkasan singkat masalah atau saran...",
        Font            = Config.Font.Body,
        TextSize        = Config.Font.Size.ComponentLabel,
        TextColor       = Theme.Get("TextPrimary"),
        BackgroundColor = Theme.Get("InputBackground"),
        BackgroundTransparency = 1,
        ZIndex          = 4,
    })

    _titleInput = titleBox

    -- Char counter untuk judul
    local titleCounter = Functions.CreateLabel({
        Name      = "TitleCounter",
        Parent    = titleWrapper,
        Text      = "0/120",
        Size      = UDim2.new(0, 50, 0, 12),
        Position  = UDim2.new(1, -54, 1, 2),
        Font      = Config.Font.Small,
        TextSize  = 9,
        TextColor = Theme.Get("TextDisabled"),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex    = 5,
    })

    titleBox:GetPropertyChangedSignal("Text"):Connect(function()
        local len = math.min(#titleBox.Text, 120)
        if #titleBox.Text > 120 then
            titleBox.Text = titleBox.Text:sub(1, 120)
        end
        titleCounter.Text = len .. "/120"
        titleCounter.TextColor3 = len >= 100 and Theme.Get("Warning") or Theme.Get("TextDisabled")
    end)

    local ts = game:GetService("TweenService")
    titleBox.Focused:Connect(function()
        ts:Create(titleStroke, TweenInfo.new(0.15), { Color = Theme.Get("Accent"), Transparency = 0.1 }):Play()
    end)
    titleBox.FocusLost:Connect(function()
        ts:Create(titleStroke, TweenInfo.new(0.15), { Color = Theme.Get("Stroke"), Transparency = 0.4 }):Play()
    end)

    -- ── DESCRIPTION INPUT ──────────────────────────────────
    Functions.CreateLabel({
        Name      = "DescLabel",
        Parent    = container,
        Text      = "Deskripsi",
        Size      = UDim2.new(1, 0, 0, 14),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 5,
    })

    local descWrapper = Functions.CreateFrame({
        Name            = "DescWrapper",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, 90),
        BackgroundColor = Theme.Get("InputBackground"),
        CornerRadius    = 7,
        LayoutOrder     = 6,
    })

    local descStroke = Functions.ApplyStroke(descWrapper, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.4,
    })

    local descBox = Functions.CreateTextBox({
        Name            = "DescBox",
        Parent          = descWrapper,
        Size            = UDim2.new(1, -16, 1, -20),
        Position        = UDim2.new(0, 8, 0, 8),
        PlaceholderText = "Jelaskan secara detail: apa yang terjadi, bagaimana mereproduksinya, dll...",
        Font            = Config.Font.Body,
        TextSize        = Config.Font.Size.ComponentLabel - 1,
        TextColor       = Theme.Get("TextPrimary"),
        BackgroundColor = Theme.Get("InputBackground"),
        BackgroundTransparency = 1,
        ZIndex          = 4,
        MultiLine       = true,
    })

    _descInput = descBox

    local descCounter = Functions.CreateLabel({
        Name      = "DescCounter",
        Parent    = descWrapper,
        Text      = "0/2000",
        Size      = UDim2.new(0, 55, 0, 12),
        Position  = UDim2.new(1, -58, 1, -14),
        Font      = Config.Font.Small,
        TextSize  = 9,
        TextColor = Theme.Get("TextDisabled"),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex    = 5,
    })

    _charCountLabel = descCounter

    descBox:GetPropertyChangedSignal("Text"):Connect(function()
        local len = math.min(#descBox.Text, 2000)
        if #descBox.Text > 2000 then
            descBox.Text = descBox.Text:sub(1, 2000)
        end
        descCounter.Text = len .. "/2000"
        descCounter.TextColor3 = len >= 1800 and Theme.Get("Warning") or Theme.Get("TextDisabled")
    end)

    descBox.Focused:Connect(function()
        ts:Create(descStroke, TweenInfo.new(0.15), { Color = Theme.Get("Accent"), Transparency = 0.1 }):Play()
    end)
    descBox.FocusLost:Connect(function()
        ts:Create(descStroke, TweenInfo.new(0.15), { Color = Theme.Get("Stroke"), Transparency = 0.4 }):Play()
    end)

    -- ── FOOTER ROW (cooldown info + submit) ───────────────
    local footerRow = Functions.CreateFrame({
        Name                   = "FooterRow",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder            = 7,
    })

    local cooldownLabel = Functions.CreateLabel({
        Name      = "CooldownInfo",
        Parent    = footerRow,
        Text      = "",
        Size      = UDim2.new(1, -110, 1, 0),
        Font      = Config.Font.Small,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextDisabled"),
        ZIndex    = 4,
    })

    _cooldownLabel = cooldownLabel

    local submitBtn = Functions.CreateButton({
        Name            = "SubmitBtn",
        Parent          = footerRow,
        Size            = UDim2.new(0, 100, 0, 30),
        Position        = UDim2.new(1, -100, 0, 1),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius    = 7,
        ZIndex          = 4,
        Text            = "",
    })

    Functions.CreateLabel({
        Name      = "SubmitText",
        Parent    = submitBtn,
        Text      = "✉  Kirim",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = 12,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 5,
    })

    _submitBtn = submitBtn

    -- ── SUBMIT LOGIC ───────────────────────────────────────
    submitBtn.MouseButton1Click:Connect(function()
        local canSubmit, remaining = FeedbackManager.CanSubmit()

        if not canSubmit then
            cooldownLabel.Text = "Tunggu " .. remaining .. " detik lagi."
            cooldownLabel.TextColor3 = Theme.Get("Warning")
            return
        end

        local title       = Functions.Trim(titleBox.Text)
        local description = Functions.Trim(descBox.Text)
        local category    = FeedbackUI._activeTab
        local severity    = _selectedSeverity

        if title == "" then
            cooldownLabel.Text = "Judul tidak boleh kosong."
            cooldownLabel.TextColor3 = Theme.Get("Error")
            ts:Create(titleStroke, TweenInfo.new(0.1), { Color = Theme.Get("Error"), Transparency = 0 }):Play()
            return
        end

        if description == "" then
            cooldownLabel.Text = "Deskripsi tidak boleh kosong."
            cooldownLabel.TextColor3 = Theme.Get("Error")
            ts:Create(descStroke, TweenInfo.new(0.1), { Color = Theme.Get("Error"), Transparency = 0 }):Play()
            return
        end

        -- Disable submit sementara
        submitBtn.Active = false
        ts:Create(submitBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.4 }):Play()
        cooldownLabel.Text      = "Mengirim..."
        cooldownLabel.TextColor3 = Theme.Get("TextSecondary")

        -- Submit via FeedbackManager
        local result = FeedbackManager.Submit({
            Category    = category,
            Title       = title,
            Description = description,
            Severity    = severity,
        })

        task.delay(0.5, function()
            submitBtn.Active = true
            ts:Create(submitBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0 }):Play()

            if result.status == FeedbackManager.Status.PENDING
            or result.status == FeedbackManager.Status.SENT then
                -- Reset form
                titleBox.Text   = ""
                descBox.Text    = ""
                cooldownLabel.Text = ""

                Notifications.Send({
                    Title   = "Feedback Terkirim",
                    Content = "Terima kasih! " .. category .. " kamu sudah kami terima.",
                    Type    = "Success",
                })

                FeedbackManager._lastSubmit = os.time()
                pcall(onSent, result)
            else
                cooldownLabel.Text      = "Gagal mengirim. Coba lagi."
                cooldownLabel.TextColor3 = Theme.Get("Error")

                Notifications.Send({
                    Title   = "Gagal Mengirim",
                    Content = result.error or "Terjadi kesalahan saat mengirim feedback.",
                    Type    = "Error",
                })
            end
        end)
    end)

    -- ── HOVER EFFECT ───────────────────────────────────────
    local Animations = require(script.Parent.Parent.UI.Animations)
    Animations.ApplyHoverEffect(submitBtn, Theme.Get("AccentHover"), Theme.Get("Accent"))

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        container.BackgroundColor3  = Theme.Get("CardBackground")
        titleWrapper.BackgroundColor3 = Theme.Get("InputBackground")
        descWrapper.BackgroundColor3  = Theme.Get("InputBackground")
        titleBox.TextColor3          = Theme.Get("TextPrimary")
        descBox.TextColor3           = Theme.Get("TextPrimary")
        catRow.BackgroundColor3      = Theme.Get("ButtonSecondary")
        submitBtn.BackgroundColor3   = Theme.Get("Accent")
    end)

    return container
end

-- ============================================================
-- HISTORY PANEL (mini, bisa dipasang di bawah form)
-- ============================================================

--[[
    FeedbackUI.BuildHistoryPanel(parent, options)
    Tampilkan riwayat feedback yang sudah dikirim.

    @param parent   Frame
    @param options {
        Limit:   number  -- max item (default 5)
        Filter:  string  -- kategori filter
    }
]]
function FeedbackUI.BuildHistoryPanel(parent, options)
    options = options or {}
    local limit  = options.Limit  or 5
    local filter = options.Filter

    local panel = Functions.CreateFrame({
        Name                   = "FBHistoryPanel",
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })

    Functions.ApplyListLayout(panel, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 6),
    })

    local history = FeedbackManager.GetHistory({ Limit = limit, Category = filter })

    if #history == 0 then
        Functions.CreateLabel({
            Name      = "EmptyHint",
            Parent    = panel,
            Text      = "Belum ada feedback yang dikirim.",
            Size      = UDim2.new(1, 0, 0, 28),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextDisabled"),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        return panel
    end

    for i, fb in ipairs(history) do
        local statusColor = {
            sent     = Theme.Get("Success"),
            failed   = Theme.Get("Error"),
            pending  = Theme.Get("Warning"),
            retrying = Theme.Get("Info"),
        }

        local row = Functions.CreateFrame({
            Name            = "HistRow_" .. i,
            Parent          = panel,
            Size            = UDim2.new(1, 0, 0, 36),
            BackgroundColor = Theme.Get("ButtonSecondary"),
            CornerRadius    = 6,
            LayoutOrder     = i,
        })

        Functions.ApplyPadding(row, { Left = 10, Right = 10 })

        -- Status dot
        local dot = Functions.CreateFrame({
            Name            = "StatusDot",
            Parent          = row,
            Size            = UDim2.new(0, 8, 0, 8),
            Position        = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint     = Vector2.new(0, 0.5),
            BackgroundColor = statusColor[fb.status] or Theme.Get("TextDisabled"),
            CornerRadius    = UDim.new(1, 0),
        })

        -- Judul
        Functions.CreateLabel({
            Name      = "HistTitle",
            Parent    = row,
            Text      = Functions.TruncateText(fb.title, 40),
            Size      = UDim2.new(1, -100, 0, 18),
            Position  = UDim2.new(0, 16, 0, 4),
            Font      = Enum.Font.GothamBold,
            TextSize  = 12,
            TextColor = Theme.Get("TextPrimary"),
            ZIndex    = 4,
        })

        -- Kategori + status
        Functions.CreateLabel({
            Name      = "HistMeta",
            Parent    = row,
            Text      = fb.category .. "  ·  " .. fb.status,
            Size      = UDim2.new(1, -100, 0, 12),
            Position  = UDim2.new(0, 16, 0, 22),
            Font      = Config.Font.Small,
            TextSize  = 9,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 4,
        })

        -- ID singkat
        Functions.CreateLabel({
            Name      = "HistId",
            Parent    = row,
            Text      = fb.id:sub(1, 14),
            Size      = UDim2.new(0, 80, 1, 0),
            Position  = UDim2.new(1, -80, 0, 0),
            Font      = Config.Font.Small,
            TextSize  = 9,
            TextColor = Theme.Get("TextDisabled"),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex    = 4,
        })
    end

    return panel
end

return FeedbackUI
