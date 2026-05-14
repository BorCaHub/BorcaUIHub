--[[
    BorcaUIHub — Navigation/Tabs.lua
    Definisi semua halaman/tab dalam UI.
    Setiap tab mewakili satu kategori isi yang bisa dipilih user.
]]

local Tabs = {}

local Theme     = require(script.Parent.Parent.UI.Theme)
local Config    = require(script.Parent.Parent.UI.Config)
local Functions = require(script.Parent.Parent.UI.Functions)

-- ============================================================
-- TAB REGISTRY
-- Daftar semua tab yang tersedia dalam UI.
-- Urutan di sini = urutan tampil di sidebar.
-- ============================================================

Tabs.Registry = {}   -- akan diisi oleh RegisterTab
Tabs._frames  = {}   -- menyimpan frame konten setiap tab { [tabId] = frame }
Tabs._order   = {}   -- urutan tab { tabId, ... }

-- ============================================================
-- TAB DEFINITION
-- ============================================================

--[[
    Tabs.Define(tabId, options)
    Daftarkan sebuah tab baru ke registry.
    
    @param tabId    string  -- ID unik tab (contoh: "home", "player")
    @param options {
        Label:        string   -- Teks yang ditampilkan di sidebar
        Icon:         string   -- Karakter ikon (unicode atau rbxasset)
        LayoutOrder:  number   -- Urutan tampil
        Premium:      boolean  -- Apakah tab khusus premium
        Visible:      boolean  -- Apakah tab ditampilkan (default true)
        Description:  string   -- Deskripsi singkat tab (untuk tooltip)
    }
]]
function Tabs.Define(tabId, options)
    if Tabs.Registry[tabId] then
        warn("[BorcaUIHub][Tabs] Tab sudah terdaftar: " .. tabId)
        return
    end

    options = options or {}
    Tabs.Registry[tabId] = {
        Id          = tabId,
        Label       = options.Label       or tabId,
        Icon        = options.Icon        or "◈",
        LayoutOrder = options.LayoutOrder or #Tabs._order + 1,
        Premium     = options.Premium     or false,
        Visible     = options.Visible     ~= false,  -- default true
        Description = options.Description or "",
    }

    table.insert(Tabs._order, tabId)

    -- Urutkan berdasarkan LayoutOrder
    table.sort(Tabs._order, function(a, b)
        return (Tabs.Registry[a].LayoutOrder or 0) < (Tabs.Registry[b].LayoutOrder or 0)
    end)
end

-- ============================================================
-- DEFAULT TABS
-- Tab-tab standar BorcaHub. Script hub bisa menambah tab baru.
-- ============================================================

Tabs.Define("home", {
    Label       = "Home",
    Icon        = "⌂",
    LayoutOrder = 1,
    Description = "Halaman utama dan ringkasan fitur",
})

Tabs.Define("player", {
    Label       = "Player",
    Icon        = "◉",
    LayoutOrder = 2,
    Description = "Modifikasi karakter dan pergerakan",
})

Tabs.Define("combat", {
    Label       = "Combat",
    Icon        = "⚔",
    LayoutOrder = 3,
    Description = "Fitur pertarungan dan damage",
})

Tabs.Define("visual", {
    Label       = "Visual",
    Icon        = "◈",
    LayoutOrder = 4,
    Description = "ESP, highlight, dan efek visual",
})

Tabs.Define("misc", {
    Label       = "Misc",
    Icon        = "⚙",
    LayoutOrder = 5,
    Description = "Fitur lain-lain dan utilitas",
})

Tabs.Define("settings", {
    Label       = "Settings",
    Icon        = "✦",
    LayoutOrder = 6,
    Description = "Pengaturan UI dan preferensi",
})

-- ============================================================
-- FRAME MANAGEMENT
-- ============================================================

--[[
    Tabs.CreateContentFrame(tabId, parent) → Frame
    Buat frame konten untuk tab tertentu di dalam content panel.
    Frame ini yang akan diisi oleh section dan komponen.
    
    @param tabId   string
    @param parent  Frame  -- biasanya ScrollContent dari Main.lua
    @return Frame
]]
function Tabs.CreateContentFrame(tabId, parent)
    if Tabs._frames[tabId] then
        warn("[BorcaUIHub][Tabs] Frame sudah dibuat untuk tab: " .. tabId)
        return Tabs._frames[tabId]
    end

    local frame = Functions.CreateFrame({
        Name                   = "Tab_" .. tabId,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 1, 0),
        Position               = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Visible                = false,  -- disembunyikan by default, TabManager yang mengatur
        ClipDescendants        = false,
    })

    -- Layout vertikal untuk section di dalam tab
    Functions.ApplyListLayout(frame, {
        FillDirection      = Enum.FillDirection.Vertical,
        Padding            = UDim.new(0, Config.UI.SectionGap),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    Functions.ApplyPadding(frame, {
        Top    = 14,
        Bottom = 20,
        Left   = 0,
        Right  = 0,
    })

    Tabs._frames[tabId] = frame
    return frame
end

--[[
    Tabs.GetFrame(tabId) → Frame | nil
    Ambil frame konten tab berdasarkan ID.
]]
function Tabs.GetFrame(tabId)
    return Tabs._frames[tabId]
end

--[[
    Tabs.GetAll() → {tabDefinition}
    Ambil semua definisi tab dalam urutan yang benar.
]]
function Tabs.GetAll()
    local result = {}
    for _, id in ipairs(Tabs._order) do
        if Tabs.Registry[id] and Tabs.Registry[id].Visible then
            table.insert(result, Tabs.Registry[id])
        end
    end
    return result
end

--[[
    Tabs.GetById(tabId) → tabDefinition | nil
    Ambil definisi tab berdasarkan ID.
]]
function Tabs.GetById(tabId)
    return Tabs.Registry[tabId]
end

--[[
    Tabs.GetOrder() → {string}
    Kembalikan daftar ID tab dalam urutan tampil.
]]
function Tabs.GetOrder()
    local result = {}
    for _, id in ipairs(Tabs._order) do
        if Tabs.Registry[id] and Tabs.Registry[id].Visible then
            table.insert(result, id)
        end
    end
    return result
end

-- ============================================================
-- EXTERNAL TAB ADDITION
-- Script hub bisa menambah tab baru ke UI secara dinamis.
-- ============================================================

--[[
    Tabs.AddTab(tabId, options, contentBuilder)
    Tambah tab baru secara dinamis dari luar (misal dari script game).
    
    @param tabId          string
    @param options        table   -- sama seperti Tabs.Define
    @param contentBuilder function(frame)  -- fungsi untuk mengisi konten tab
]]
function Tabs.AddTab(tabId, options, contentBuilder)
    Tabs.Define(tabId, options)

    -- Simpan builder untuk dipanggil saat tab pertama kali dibuka
    if contentBuilder then
        Tabs.Registry[tabId]._builder = contentBuilder
        Tabs.Registry[tabId]._built   = false
    end
end

--[[
    Tabs.BuildTabContent(tabId)
    Panggil content builder tab jika belum dibangun.
    Dipanggil oleh TabManager saat tab pertama kali diaktifkan.
]]
function Tabs.BuildTabContent(tabId)
    local tab = Tabs.Registry[tabId]
    if not tab then return end
    if tab._built then return end
    if not tab._builder then return end

    local frame = Tabs._frames[tabId]
    if not frame then return end

    pcall(tab._builder, frame)
    tab._built = true
end

--[[
    Tabs.SetVisible(tabId, visible)
    Tampilkan atau sembunyikan tab dari sidebar.
]]
function Tabs.SetVisible(tabId, visible)
    if Tabs.Registry[tabId] then
        Tabs.Registry[tabId].Visible = visible
    end
end

return Tabs
