--[[
    BorcaUIHub — Feedback/SuggestionReport.lua
    Dipakai untuk menampung ide atau saran dari pengguna.
    Memisahkan saran dari bug agar data lebih mudah diproses.
    Mendukung: kategori saran, prioritas, voting sederhana, dan upvote tracking.
    Dengan memisahkan, proses evaluasi jadi lebih jelas dan tertata.
]]

local SuggestionReport = {}

local Theme          = require(script.Parent.Parent.UI.Theme)
local Config         = require(script.Parent.Parent.UI.Config)
local Functions      = require(script.Parent.Parent.UI.Functions)
local FeedbackManager = require(script.Parent.FeedbackManager)
local Notifications  = require(script.Parent.Parent.Overlays.Notifications)

-- ============================================================
-- KATEGORI SARAN
-- ============================================================

SuggestionReport.Categories = {
    "Fitur Baru",
    "Peningkatan UI",
    "Performa",
    "Kenyamanan",
    "Integrasi Game",
    "Lain-lain",
}

-- Ikon per kategori
local CATEGORY_ICONS = {
    ["Fitur Baru"]     = "✨",
    ["Peningkatan UI"] = "🎨",
    ["Performa"]       = "⚡",
    ["Kenyamanan"]     = "🛋",
    ["Integrasi Game"] = "🎮",
    ["Lain-lain"]      = "💬",
}

-- ============================================================
-- SUBMIT SHORTCUT
-- ============================================================

--[[
    SuggestionReport.Submit(options) → { id, status }
    Submit saran dengan format terstruktur.

    @param options {
        Title:       string   -- judul saran
        Description: string   -- penjelasan detail
        Category:    string   -- sub-kategori saran
        Priority:    string   -- "Low" | "Medium" | "High"
        UseCase:     string   -- situasi penggunaan / context
        Tags:        {string}
    }
]]
function SuggestionReport.Submit(options)
    options = options or {}

    local title    = options.Title       or "Saran"
    local priority = options.Priority    or "Medium"
    local category = options.Category    or "Lain-lain"
    local tags     = options.Tags        or {}

    -- Bangun deskripsi terstruktur
    local parts = {}

    if options.Description and options.Description ~= "" then
        table.insert(parts, "## Deskripsi Saran\n" .. options.Description)
    end

    if options.UseCase and options.UseCase ~= "" then
        table.insert(parts, "## Situasi Penggunaan\n" .. options.UseCase)
    end

    if options.Benefit and options.Benefit ~= "" then
        table.insert(parts, "## Manfaat yang Diharapkan\n" .. options.Benefit)
    end

    local description = table.concat(parts, "\n\n")
    if description == "" then description = "(Tidak ada deskripsi)" end

    -- Tag otomatis
    table.insert(tags, "suggestion")
    table.insert(tags, category:lower():gsub(" ", "-"))

    return FeedbackManager.Submit({
        Category    = "Suggestion",
        Title       = title,
        Description = description,
        Severity    = priority,     -- pakai field severity untuk priority
        Tags        = tags,
        Attachments = options.Attachments or {},
    })
end

-- ============================================================
-- BUILD UI PANEL
-- ============================================================

--[[
    SuggestionReport.BuildPanel(parent, options)
    Buat panel UI saran yang lebih detail dan ramah.

    @param parent   Frame
    @param options {
        OnSent: function(result)
    }
    @return frame
]]
function SuggestionReport.BuildPanel(parent, options)
    options = options or {}
    local onSent = options.OnSent or function() end

    local container = Functions.CreateFrame({
        Name          = "SuggestionPanel",
        Parent        = parent,
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor = Theme.Get("CardBackground"),
        CornerRadius  = Config.UI.CardRadius,
    })

    Functions.ApplyStroke(container, {
        Color        = Theme.Get("Accent"),
        Thickness    = 1,
        Transparency = 0.55,
    })

    Functions.ApplyPadding(container, { Top = 14, Bottom = 16, Left = 14, Right = 14 })
    Functions.ApplyListLayout(container, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 8),
    })

    -- Header
    Functions.CreateFrame({
        Name                   = "SGHeader",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder            = 0,
    })

    local headerFrame = container:FindFirstChild("SGHeader")
    Functions.CreateLabel({
        Name      = "SGTitle",
        Parent    = headerFrame,
        Text      = "💡  Kirim Saran",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentLabel + 1,
        TextColor = Theme.Get("Accent"),
        ZIndex    = 4,
    })

    -- Kategori saran (grid 2x3)
    Functions.CreateLabel({
        Name      = "CatLabel",
        Parent    = container,
        Text      = "Kategori Saran",
        Size      = UDim2.new(1, 0, 0, 13),
        Font      = Config.Font.Small,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 1,
    })

    local catGrid = Functions.CreateFrame({
        Name                   = "CatGrid",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
        LayoutOrder            = 2,
    })

    local grid = Instance.new("UIGridLayout")
    grid.CellSize    = UDim2.new(0.5, -4, 0, 28)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.SortOrder   = Enum.SortOrder.LayoutOrder
    grid.Parent      = catGrid

    local selectedCat = "Fitur Baru"
    local catBtns     = {}

    local function UpdateCatHighlight(active)
        selectedCat = active
        for _, obj in ipairs(catBtns) do
            local isSel = (obj.cat == active)
            local ts = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.12), {
                BackgroundColor3       = Theme.Get("Accent"),
                BackgroundTransparency = isSel and 0 or 0.85,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.12), {
                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Theme.Get("TextSecondary"),
            }):Play()
        end
    end

    for i, cat in ipairs(SuggestionReport.Categories) do
        local icon   = CATEGORY_ICONS[cat] or "•"
        local isSel  = (cat == selectedCat)

        local btn = Functions.CreateButton({
            Name            = "Cat_" .. i,
            Parent          = catGrid,
            Size            = UDim2.new(0.5, -4, 0, 28),
            BackgroundColor = Theme.Get("Accent"),
            BackgroundTransparency = isSel and 0 or 0.85,
            CornerRadius    = 6,
            ZIndex          = 4,
            LayoutOrder     = i,
            Text            = "",
        })

        local lbl = Functions.CreateLabel({
            Name      = "CL", Parent = btn,
            Text      = icon .. "  " .. cat,
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Config.Font.Body, TextSize = 11,
            TextColor = isSel and Color3.fromRGB(255,255,255) or Theme.Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
        })

        btn.MouseButton1Click:Connect(function() UpdateCatHighlight(cat) end)
        table.insert(catBtns, { btn = btn, lbl = lbl, cat = cat })
    end

    -- Helper field builder
    local function MakeField(labelText, placeholder, height, multiline, layoutOrder)
        Functions.CreateLabel({
            Name      = "SFL_" .. layoutOrder,
            Parent    = container,
            Text      = labelText,
            Size      = UDim2.new(1, 0, 0, 13),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            LayoutOrder = layoutOrder,
        })

        local wrapper = Functions.CreateFrame({
            Name            = "SFW_" .. layoutOrder,
            Parent          = container,
            Size            = UDim2.new(1, 0, 0, height),
            BackgroundColor = Theme.Get("InputBackground"),
            CornerRadius    = 7,
            LayoutOrder     = layoutOrder + 0.5,
        })

        local stroke = Functions.ApplyStroke(wrapper, {
            Color        = Theme.Get("Stroke"),
            Thickness    = 1,
            Transparency = 0.4,
        })

        local box = Functions.CreateTextBox({
            Name            = "SFB_" .. layoutOrder,
            Parent          = wrapper,
            Size            = UDim2.new(1, -16, 1, -8),
            Position        = UDim2.new(0, 8, 0, 4),
            PlaceholderText = placeholder,
            Font            = Config.Font.Body,
            TextSize        = 12,
            TextColor       = Theme.Get("TextPrimary"),
            BackgroundColor = Theme.Get("InputBackground"),
            BackgroundTransparency = 1,
            ZIndex          = 4,
            MultiLine       = multiline or false,
        })

        local ts = game:GetService("TweenService")
        box.Focused:Connect(function()
            ts:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Get("Accent"), Transparency = 0.1 }):Play()
        end)
        box.FocusLost:Connect(function()
            ts:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Get("Stroke"), Transparency = 0.4 }):Play()
        end)

        return box
    end

    local titleBox   = MakeField("Judul Saran",               "Contoh: Tambahkan fitur auto-farm dengan delay kustom", 32, false, 3)
    local descBox    = MakeField("Deskripsi Detail",           "Jelaskan saran kamu secara detail...",                  80, true,  5)
    local usecaseBox = MakeField("Situasi Penggunaan",         "Kapan / di mana fitur ini akan berguna?",               50, true,  7)
    local benefitBox = MakeField("Manfaat yang Diharapkan",    "Apa yang akan lebih baik jika saran ini diterapkan?",   50, true,  9)

    -- Prioritas
    Functions.CreateLabel({
        Name      = "PrioLabel",
        Parent    = container,
        Text      = "Prioritas (menurut kamu)",
        Size      = UDim2.new(1, 0, 0, 13),
        Font      = Config.Font.Small,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 11,
    })

    local priorities = { { "Low", "Bisa nanti" }, { "Medium", "Cukup penting" }, { "High", "Sangat dibutuhkan" } }
    local selectedPriority = "Medium"
    local prioBtns = {}

    local prioRow = Functions.CreateFrame({
        Name                   = "PrioRow",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder            = 12,
    })
    Functions.ApplyListLayout(prioRow, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })

    local function UpdatePrioHighlight(active)
        selectedPriority = active
        for _, obj in ipairs(prioBtns) do
            local isSel = (obj.prio == active)
            local ts = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.12), {
                BackgroundTransparency = isSel and 0 or 0.8,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.12), {
                TextColor3 = isSel and Color3.fromRGB(255,255,255) or Theme.Get("TextSecondary"),
            }):Play()
        end
    end

    for i, pair in ipairs(priorities) do
        local prio, hint = pair[1], pair[2]
        local isSel = (prio == selectedPriority)
        local btn = Functions.CreateButton({
            Name            = "Prio_" .. prio,
            Parent          = prioRow,
            Size            = UDim2.new(0.333, -6, 1, 0),
            BackgroundColor = Theme.Get("Accent"),
            BackgroundTransparency = isSel and 0 or 0.8,
            CornerRadius    = 7,
            ZIndex          = 4,
            LayoutOrder     = i,
            Text            = "",
        })
        local lbl = Functions.CreateLabel({
            Name      = "PL", Parent = btn,
            Text      = prio .. "\n" .. hint,
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold, TextSize = 10,
            TextColor = isSel and Color3.fromRGB(255,255,255) or Theme.Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
        })
        btn.MouseButton1Click:Connect(function() UpdatePrioHighlight(prio) end)
        table.insert(prioBtns, { btn = btn, lbl = lbl, prio = prio })
    end

    -- Submit
    local submitBtn = Functions.CreateButton({
        Name            = "SGSubmit",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, 32),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius    = 7,
        ZIndex          = 4,
        LayoutOrder     = 13,
        Text            = "",
    })
    Functions.CreateLabel({
        Name = "SGSubmitText", Parent = submitBtn,
        Text = "💡  Kirim Saran",
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
    })

    submitBtn.MouseButton1Click:Connect(function()
        local canSubmit, remaining = FeedbackManager.CanSubmit()
        if not canSubmit then
            Notifications.Send({
                Title   = "Cooldown Aktif",
                Content = "Tunggu " .. remaining .. " detik lagi.",
                Type    = "Warning",
            })
            return
        end

        local titleText = Functions.Trim(titleBox.Text)
        local descText  = Functions.Trim(descBox.Text)

        if titleText == "" or descText == "" then
            Notifications.Send({
                Title   = "Form Belum Lengkap",
                Content = "Judul dan deskripsi wajib diisi.",
                Type    = "Error",
            })
            return
        end

        local result = SuggestionReport.Submit({
            Title       = titleText,
            Description = descText,
            UseCase     = Functions.Trim(usecaseBox.Text),
            Benefit     = Functions.Trim(benefitBox.Text),
            Category    = selectedCat,
            Priority    = selectedPriority,
        })

        if result.status == FeedbackManager.Status.PENDING
        or result.status == FeedbackManager.Status.SENT then
            titleBox.Text   = ""
            descBox.Text    = ""
            usecaseBox.Text = ""
            benefitBox.Text = ""

            Notifications.Send({
                Title   = "Saran Terkirim",
                Content = "Terima kasih! Saran kamu akan kami pertimbangkan.",
                Type    = "Success",
            })

            FeedbackManager._lastSubmit = os.time()
            pcall(onSent, result)
        else
            Notifications.Send({
                Title   = "Gagal Mengirim",
                Content = result.error or "Terjadi kesalahan. Coba lagi.",
                Type    = "Error",
            })
        end
    end)

    Theme.OnChanged(function()
        container.BackgroundColor3 = Theme.Get("CardBackground")
    end)

    return container
end

return SuggestionReport
