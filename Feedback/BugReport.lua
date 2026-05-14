--[[
    BorcaUIHub — Feedback/BugReport.lua
    Format khusus untuk laporan error / bug.
    Tujuannya agar data bug yang masuk lebih terstruktur dan mudah dibaca.
    Berisi: judul bug, deskripsi, langkah reproduksi, severity, dan detail sistem.
    Jika bug report rapi, proses perbaikan jadi jauh lebih cepat.
]]

local BugReport = {}

local Theme          = require(script.Parent.Parent.UI.Theme)
local Config         = require(script.Parent.Parent.UI.Config)
local Functions      = require(script.Parent.Parent.UI.Functions)
local FeedbackManager = require(script.Parent.FeedbackManager)
local Notifications  = require(script.Parent.Parent.Overlays.Notifications)

-- ============================================================
-- SEVERITY CONSTANTS
-- ============================================================

BugReport.Severity = {
    LOW      = "Low",
    MEDIUM   = "Medium",
    HIGH     = "High",
    CRITICAL = "Critical",
}

-- ============================================================
-- AUTO-CAPTURE SYSTEM INFO
-- ============================================================

--[[
    BugReport.CaptureSystemInfo() → table
    Kumpulkan informasi sistem secara otomatis.
    Berguna sebagai attachment pada bug report.
]]
function BugReport.CaptureSystemInfo()
    local info = {}

    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        info.username   = player.Name
        info.userId     = player.UserId
        info.accountAge = player.AccountAge
    end)

    pcall(function()
        info.placeId  = game.PlaceId
        info.gameId   = game.GameId
        info.jobId    = game.JobId
        info.version  = Config.Flags.Version
    end)

    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            info.viewportSize = tostring(camera.ViewportSize)
            info.fov          = camera.FieldOfView
        end
    end)

    pcall(function()
        local stats = game:GetService("Stats")
        info.fps         = math.floor(1 / game:GetService("RunService").Heartbeat:Wait())
        info.ping        = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        info.memUsageMB  = math.floor(stats:GetTotalMemoryUsageMb())
    end)

    info.timestamp = os.time()
    info.osTime    = os.date("!%Y-%m-%d %H:%M:%S UTC")

    return info
end

-- ============================================================
-- SUBMIT SHORTCUT
-- ============================================================

--[[
    BugReport.Submit(options) → { id, status }
    Submit bug report dengan format terstruktur.

    @param options {
        Title:        string   -- judul singkat bug
        Description:  string   -- penjelasan bug
        Steps:        {string} -- langkah-langkah untuk mereproduksi
        Expected:     string   -- perilaku yang diharapkan
        Actual:       string   -- perilaku yang terjadi
        Severity:     string   -- "Low" | "Medium" | "High" | "Critical"
        Tags:         {string} -- tag tambahan
        AutoCapture:  boolean  -- otomatis tangkap info sistem (default true)
    }
]]
function BugReport.Submit(options)
    options = options or {}

    local title    = options.Title       or "Bug Report"
    local severity = options.Severity    or BugReport.Severity.MEDIUM
    local tags     = options.Tags        or {}

    -- Bangun deskripsi terstruktur
    local parts = {}

    if options.Description and options.Description ~= "" then
        table.insert(parts, "## Deskripsi\n" .. options.Description)
    end

    if options.Steps and #options.Steps > 0 then
        local stepsStr = "## Langkah Reproduksi\n"
        for i, step in ipairs(options.Steps) do
            stepsStr = stepsStr .. i .. ". " .. step .. "\n"
        end
        table.insert(parts, stepsStr)
    end

    if options.Expected and options.Expected ~= "" then
        table.insert(parts, "## Perilaku yang Diharapkan\n" .. options.Expected)
    end

    if options.Actual and options.Actual ~= "" then
        table.insert(parts, "## Perilaku yang Terjadi\n" .. options.Actual)
    end

    local description = table.concat(parts, "\n\n")
    if description == "" then
        description = "(Tidak ada deskripsi)"
    end

    -- Kumpulkan attachment
    local attachments = options.Attachments or {}
    if options.AutoCapture ~= false then
        attachments.systemInfo = BugReport.CaptureSystemInfo()
    end

    -- Tambah tag otomatis
    table.insert(tags, "bug")
    if severity == BugReport.Severity.CRITICAL then
        table.insert(tags, "critical")
    end

    return FeedbackManager.Submit({
        Category    = "Bug Report",
        Title       = title,
        Description = description,
        Severity    = severity,
        Tags        = tags,
        Attachments = attachments,
    })
end

-- ============================================================
-- BUILD UI PANEL (form bug report lengkap)
-- ============================================================

--[[
    BugReport.BuildPanel(parent, options)
    Buat panel UI bug report yang lebih detail dari FeedbackUI biasa.
    Memiliki field tambahan: langkah reproduksi, expected vs actual.

    @param parent   Frame
    @param options {
        OnSent:  function(result)
    }
    @return frame
]]
function BugReport.BuildPanel(parent, options)
    options = options or {}
    local onSent = options.OnSent or function() end

    local container = Functions.CreateFrame({
        Name          = "BugReportPanel",
        Parent        = parent,
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor = Theme.Get("CardBackground"),
        CornerRadius  = Config.UI.CardRadius,
    })

    Functions.ApplyStroke(container, {
        Color        = Theme.Get("Error"),
        Thickness    = 1,
        Transparency = 0.6,
    })

    Functions.ApplyPadding(container, { Top = 14, Bottom = 16, Left = 14, Right = 14 })
    Functions.ApplyListLayout(container, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 8),
    })

    -- Header
    local headerRow = Functions.CreateFrame({
        Name                   = "BRHeader",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder            = 0,
    })

    Functions.CreateLabel({
        Name      = "BRTitle",
        Parent    = headerRow,
        Text      = "🐛  Laporan Bug",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentLabel + 1,
        TextColor = Theme.Get("Error"),
        ZIndex    = 4,
    })

    -- Helper untuk buat label + textbox pair
    local function MakeField(labelText, placeholder, height, multiline, layoutOrder)
        Functions.CreateLabel({
            Name      = "FieldLabel_" .. layoutOrder,
            Parent    = container,
            Text      = labelText,
            Size      = UDim2.new(1, 0, 0, 13),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            LayoutOrder = layoutOrder,
        })

        local wrapper = Functions.CreateFrame({
            Name            = "FieldWrap_" .. layoutOrder,
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
            Name            = "FieldBox_" .. layoutOrder,
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
            ts:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Get("Error"), Transparency = 0.2 }):Play()
        end)
        box.FocusLost:Connect(function()
            ts:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Get("Stroke"), Transparency = 0.4 }):Play()
        end)

        return box
    end

    local titleBox    = MakeField("Judul Bug",            "Contoh: Toggle ESP crash saat karakter respawn",  32, false, 1)
    local descBox     = MakeField("Deskripsi",            "Apa yang terjadi secara keseluruhan?",            70, true,  3)
    local stepsBox    = MakeField("Langkah Reproduksi",   "1. Buka tab Visual\n2. Aktifkan ESP\n3. Mati...", 70, true,  5)
    local expectedBox = MakeField("Perilaku yang Diharapkan", "Seharusnya ESP tetap aktif setelah respawn.", 32, false, 7)
    local actualBox   = MakeField("Perilaku yang Terjadi",    "UI crash dan tidak bisa dibuka kembali.",     32, false, 9)

    -- Severity selector
    Functions.CreateLabel({
        Name      = "SevLabel",
        Parent    = container,
        Text      = "Tingkat Keparahan",
        Size      = UDim2.new(1, 0, 0, 13),
        Font      = Config.Font.Small,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
        LayoutOrder = 11,
    })

    local severities   = { "Low", "Medium", "High", "Critical" }
    local sevColors    = {
        Low = Theme.Get("Success"), Medium = Theme.Get("Warning"),
        High = Color3.fromRGB(255, 140, 60), Critical = Theme.Get("Error"),
    }
    local selectedSev  = "Medium"
    local sevBtns      = {}

    local sevRow = Functions.CreateFrame({
        Name                   = "SevRow",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder            = 12,
    })
    Functions.ApplyListLayout(sevRow, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) })

    local function HighlightSev(active)
        selectedSev = active
        for _, obj in ipairs(sevBtns) do
            local isSel = (obj.sev == active)
            local c = sevColors[obj.sev]
            local ts = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.12), {
                BackgroundColor3       = c,
                BackgroundTransparency = isSel and 0 or 0.82,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.12), {
                TextColor3 = isSel and Color3.fromRGB(255,255,255) or c,
            }):Play()
        end
    end

    for i, sev in ipairs(severities) do
        local c = sevColors[sev]
        local isSel = (sev == selectedSev)
        local btn = Functions.CreateButton({
            Name            = "Sev_" .. sev,
            Parent          = sevRow,
            Size            = UDim2.new(0.25, -5, 1, 0),
            BackgroundColor = c,
            BackgroundTransparency = isSel and 0 or 0.82,
            CornerRadius    = 6,
            ZIndex          = 4,
            LayoutOrder     = i,
            Text            = "",
        })
        local lbl = Functions.CreateLabel({
            Name      = "SL", Parent = btn, Text = sev,
            Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor = isSel and Color3.fromRGB(255,255,255) or c,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
        })
        btn.MouseButton1Click:Connect(function() HighlightSev(sev) end)
        table.insert(sevBtns, { btn = btn, lbl = lbl, sev = sev })
    end

    -- Auto-capture toggle
    local autoCaptureEnabled = true
    local acRow = Functions.CreateFrame({
        Name                   = "AutoCaptureRow",
        Parent                 = container,
        Size                   = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder            = 13,
    })

    -- Track kiri
    local acTrack = Functions.CreateFrame({
        Name            = "ACTrack",
        Parent          = acRow,
        Size            = UDim2.new(0, 36, 0, 18),
        Position        = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("Success"),
        CornerRadius    = UDim.new(1, 0),
    })
    local acThumb = Functions.CreateFrame({
        Name            = "ACThumb",
        Parent          = acTrack,
        Size            = UDim2.new(0, 12, 0, 12),
        Position        = UDim2.new(1, -15, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Color3.fromRGB(255, 255, 255),
        CornerRadius    = UDim.new(1, 0),
    })
    Functions.CreateLabel({
        Name      = "ACLabel", Parent = acRow,
        Text      = "Sertakan info sistem otomatis",
        Size      = UDim2.new(1, -50, 1, 0),
        Position  = UDim2.new(0, 44, 0, 0),
        Font      = Config.Font.Body, TextSize = 12,
        TextColor = Theme.Get("TextSecondary"),
    })

    acTrack.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            autoCaptureEnabled = not autoCaptureEnabled
            local ts = game:GetService("TweenService")
            ts:Create(acTrack, TweenInfo.new(0.18), {
                BackgroundColor3 = autoCaptureEnabled and Theme.Get("Success") or Theme.Get("ButtonSecondary"),
            }):Play()
            ts:Create(acThumb, TweenInfo.new(0.18), {
                Position = autoCaptureEnabled
                    and UDim2.new(1, -15, 0.5, 0)
                    or  UDim2.new(0, 3, 0.5, 0),
            }):Play()
        end
    end)

    -- Submit button
    local submitBtn = Functions.CreateButton({
        Name            = "BRSubmit",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, 32),
        BackgroundColor = Theme.Get("Error"),
        CornerRadius    = 7,
        ZIndex          = 4,
        LayoutOrder     = 14,
        Text            = "",
    })
    Functions.CreateLabel({
        Name      = "BRSubmitText", Parent = submitBtn,
        Text      = "🐛  Kirim Bug Report",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold, TextSize = 12,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
    })

    submitBtn.MouseButton1Click:Connect(function()
        local canSubmit, remaining = FeedbackManager.CanSubmit()
        if not canSubmit then
            Notifications.Send({
                Title   = "Cooldown Aktif",
                Content = "Tunggu " .. remaining .. " detik sebelum mengirim laporan lagi.",
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

        -- Susun steps dari textarea
        local stepsRaw = Functions.Trim(stepsBox.Text)
        local steps    = {}
        for line in stepsRaw:gmatch("[^\n]+") do
            local clean = line:gsub("^%d+%.%s*", ""):gsub("^%-%s*", "")
            if clean ~= "" then
                table.insert(steps, clean)
            end
        end

        local result = BugReport.Submit({
            Title       = titleText,
            Description = descText,
            Steps       = steps,
            Expected    = Functions.Trim(expectedBox.Text),
            Actual      = Functions.Trim(actualBox.Text),
            Severity    = selectedSev,
            AutoCapture = autoCaptureEnabled,
        })

        if result.status == FeedbackManager.Status.PENDING
        or result.status == FeedbackManager.Status.SENT then
            -- Reset form
            titleBox.Text    = ""
            descBox.Text     = ""
            stepsBox.Text    = ""
            expectedBox.Text = ""
            actualBox.Text   = ""

            Notifications.Send({
                Title   = "Bug Report Terkirim",
                Content = "ID: " .. (result.id or "—") .. ". Terima kasih telah melaporkan!",
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

return BugReport
