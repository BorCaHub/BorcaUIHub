--[[
    BorcaUIHub — Navigation/Breadcrumb.lua
    Penunjuk lokasi halaman saat ini.
    Contoh: Home > Player > Speed
    Membantu user memahami posisi mereka di dalam UI.
]]

local Breadcrumb = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)
local TabManager = require(script.Parent.TabManager)
local Tabs       = require(script.Parent.Tabs)

-- ============================================================
-- STATE
-- ============================================================

Breadcrumb._frame  = nil   -- frame container breadcrumb
Breadcrumb._crumbs = {}    -- { {label, callback}, ... }

-- ============================================================
-- BUILD
-- ============================================================

--[[
    Breadcrumb.Build(parent, options)
    Bangun bar breadcrumb dan pasang ke parent frame.
    
    @param parent   Frame  -- biasanya header atau area atas content
    @param options {
        Height:  number  -- tinggi bar (default 32)
        AutoSync: boolean -- otomatis sync dengan TabManager (default true)
    }
    @return frame  -- frame breadcrumb
]]
function Breadcrumb.Build(parent, options)
    options = options or {}

    local height = options.Height or 32

    -- Container breadcrumb
    local frame = Functions.CreateFrame({
        Name            = "BreadcrumbBar",
        Parent          = parent,
        Size            = UDim2.new(1, 0, 0, height),
        BackgroundColor = Theme.Get("HeaderBackground"),
        BackgroundTransparency = 0.3,
    })

    Functions.ApplyStroke(frame, {
        Color       = Theme.Get("Stroke"),
        Thickness   = 1,
        Transparency = 0.7,
    })

    Functions.ApplyPadding(frame, { Left = 14, Right = 14, Top = 0, Bottom = 0 })

    -- Scroll horizontal untuk banyak level
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name                 = "BreadcrumbScroll"
    scrollFrame.Parent               = frame
    scrollFrame.Size                 = UDim2.new(1, 0, 1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness   = 0
    scrollFrame.ScrollingDirection   = Enum.ScrollingDirection.X
    scrollFrame.CanvasSize           = UDim2.new(0, 0, 1, 0)
    scrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.X

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection         = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment     = Enum.VerticalAlignment.Center
    listLayout.SortOrder             = Enum.SortOrder.LayoutOrder
    listLayout.Padding               = UDim.new(0, 4)
    listLayout.Parent                = scrollFrame

    Breadcrumb._frame      = frame
    Breadcrumb._scrollFrame = scrollFrame

    -- Auto-sync dengan tab aktif
    if options.AutoSync ~= false then
        -- Set breadcrumb awal dari tab aktif
        local active = TabManager.GetActive()
        if active then
            local tabDef = Tabs.GetById(active)
            if tabDef then
                Breadcrumb.Set({ { label = tabDef.Label } })
            end
        end

        -- Update saat tab berubah
        TabManager.OnTabChanged(function(newId)
            local tabDef = Tabs.GetById(newId)
            if tabDef then
                Breadcrumb.Set({ { label = tabDef.Label } })
            end
        end)
    end

    return frame
end

-- ============================================================
-- API
-- ============================================================

--[[
    Breadcrumb.Set(crumbs)
    Set breadcrumb secara penuh dengan animasi.
    
    @param crumbs  { { label: string, callback: function? }, ... }
    
    Contoh:
    Breadcrumb.Set({
        { label = "Player" },
        { label = "Speed", callback = function() ... end },
    })
]]
function Breadcrumb.Set(crumbs)
    if not Breadcrumb._scrollFrame then return end
    Breadcrumb._crumbs = crumbs or {}
    Breadcrumb._Render()
end

--[[
    Breadcrumb.Push(label, callback)
    Tambah satu level ke breadcrumb yang ada.
    
    @param label     string
    @param callback  function  (opsional, dipanggil saat diklik)
]]
function Breadcrumb.Push(label, callback)
    table.insert(Breadcrumb._crumbs, { label = label, callback = callback })
    Breadcrumb._Render()
end

--[[
    Breadcrumb.Pop()
    Hapus level terakhir dari breadcrumb.
]]
function Breadcrumb.Pop()
    if #Breadcrumb._crumbs > 0 then
        table.remove(Breadcrumb._crumbs)
        Breadcrumb._Render()
    end
end

--[[
    Breadcrumb.Clear()
    Bersihkan semua level breadcrumb.
]]
function Breadcrumb.Clear()
    Breadcrumb._crumbs = {}
    Breadcrumb._Render()
end

--[[
    Breadcrumb.SetVisible(visible)
    Tampilkan atau sembunyikan bar breadcrumb.
]]
function Breadcrumb.SetVisible(visible)
    if Breadcrumb._frame then
        Breadcrumb._frame.Visible = visible
    end
end

-- ============================================================
-- RENDER
-- ============================================================

function Breadcrumb._Render()
    local scroll = Breadcrumb._scrollFrame
    if not scroll then return end

    -- Bersihkan isi lama
    for _, child in ipairs(scroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    -- Tambah "Home" sebagai root selalu ada
    local allCrumbs = {}
    table.insert(allCrumbs, { label = "Home", isHome = true })
    for _, c in ipairs(Breadcrumb._crumbs) do
        table.insert(allCrumbs, c)
    end

    for i, crumb in ipairs(allCrumbs) do
        local isLast = (i == #allCrumbs)

        -- Label crumb
        local crumbBtn = Functions.CreateButton({
            Name            = "Crumb_" .. i,
            Parent          = scroll,
            Size            = UDim2.new(0, 0, 1, 0),
            AutomaticSize   = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text            = crumb.label,
            Font            = isLast and Config.Font.Title or Config.Font.Body,
            TextSize        = Config.Font.Size.ComponentHint + 1,
            TextColor       = isLast and Theme.Get("TextPrimary") or Theme.Get("TextSecondary"),
            ZIndex          = 3,
            LayoutOrder     = i * 2 - 1,
        })

        Functions.ApplyPadding(crumbBtn, { Left = 2, Right = 2, Top = 0, Bottom = 0 })

        -- Hover effect untuk crumb yang bisa diklik
        if not isLast then
            local ts = game:GetService("TweenService")
            local hInfo = TweenInfo.new(0.1)

            crumbBtn.MouseEnter:Connect(function()
                ts:Create(crumbBtn, hInfo, { TextColor3 = Theme.Get("Accent") }):Play()
            end)

            crumbBtn.MouseLeave:Connect(function()
                ts:Create(crumbBtn, hInfo, { TextColor3 = Theme.Get("TextSecondary") }):Play()
            end)

            -- Klik navigasi
            crumbBtn.MouseButton1Click:Connect(function()
                if crumb.isHome then
                    -- Kembali ke root: hapus semua crumb
                    Breadcrumb.Clear()
                    TabManager.Switch(Tabs.GetOrder()[1])
                elseif crumb.callback then
                    crumb.callback()
                end
                -- Potong crumb hingga posisi ini
                local newCrumbs = {}
                for j = 2, i do  -- mulai dari 2 (skip Home)
                    table.insert(newCrumbs, Breadcrumb._crumbs[j - 1])
                end
                Breadcrumb._crumbs = newCrumbs
                Breadcrumb._Render()
            end)
        end

        -- Separator chevron ">" antara crumb (kecuali yang terakhir)
        if not isLast then
            Functions.CreateLabel({
                Name      = "Sep_" .. i,
                Parent    = scroll,
                Text      = "›",
                Size      = UDim2.new(0, 12, 1, 0),
                Font      = Enum.Font.GothamBold,
                TextSize  = Config.Font.Size.ComponentHint,
                TextColor = Theme.Get("TextDisabled"),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex    = 3,
                LayoutOrder = i * 2,
            })
        end
    end
end

-- ============================================================
-- THEME UPDATE
-- ============================================================

Theme.OnChanged(function()
    -- Re-render saat tema berubah agar warna breadcrumb ikut update
    if Breadcrumb._frame then
        Breadcrumb._Render()
    end
end)

return Breadcrumb
