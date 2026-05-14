--[[
    BorcaUIHub — Navigation/TabManager.lua
    Mengatur tab aktif, transisi antar tab, dan state navigasi.
    Mencegah overlap konten dan menjaga navigasi tetap rapi.

    FIX (Fix 8):
    - Tambah _builtTabs table: track tab yang sudah dibangun kontennya
      SEBELUMNYA: lazy build hanya berlaku untuk tab dinamis (punya _builder)
                  tab default TIDAK ditandai _built → bisa dianggap belum ready
      SEKARANG:   semua tab (default maupun dinamis) pakai satu mekanisme:
                  TabManager._builtTabs[tabId] = true saat konten sudah dibangun
    - Init() sekarang punya guard: tidak re-init kalau sudah pernah dipanggil
      (mencegah duplicate frame dan duplicate listener)
    - Switch() "silent=true" pada init tetap set _active dengan benar
]]

local TabManager = {}

local Animations = require(script.Parent.Parent.UI.Animations)
local Tabs       = require(script.Parent.Tabs)
local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

TabManager._active       = nil   -- ID tab yang sedang aktif
TabManager._previous     = nil   -- ID tab sebelumnya
TabManager._sidebarItems = {}    -- { [tabId] = sidebarButtonRef }
TabManager._listeners    = {}    -- callback saat tab berubah

-- FIX (Fix 8): track tab yang sudah dibangun kontennya
-- SEBELUMNYA: tidak ada tracking ini — tab default tidak punya flag built
-- SEKARANG:   semua tab pakai tabel ini; Switch() cek sebelum build
TabManager._builtTabs = {}

-- FIX (Fix 8): guard agar Init() tidak jalan dua kali
TabManager._initialized = false

-- ============================================================
-- INIT
-- ============================================================

--[[
    TabManager.Init(contentParent, defaultTab)
    Inisialisasi TabManager. Buat semua frame konten tab dan
    tampilkan tab default.

    @param contentParent  Frame   -- ScrollContent dari Main.lua
    @param defaultTab     string  -- ID tab yang dibuka pertama kali
]]
function TabManager.Init(contentParent, defaultTab)
    -- FIX (Fix 8): guard double-init
    -- SEBELUMNYA: tidak ada guard → frame duplikat kalau dipanggil 2x
    -- SEKARANG:   langsung return kalau sudah diinit
    if TabManager._initialized then
        warn("[BorcaUIHub][TabManager] Init() sudah dipanggil sebelumnya — skip.")
        return
    end
    TabManager._initialized = true

    -- Buat frame untuk setiap tab yang terdaftar
    for _, tabDef in ipairs(Tabs.GetAll()) do
        Tabs.CreateContentFrame(tabDef.Id, contentParent)
    end

    -- Tampilkan tab default
    local first = defaultTab or Tabs.GetOrder()[1]
    if first then
        TabManager.Switch(first, true)  -- silent = true (tanpa animasi)
    end
end

-- ============================================================
-- SWITCHING
-- ============================================================

--[[
    TabManager.Switch(tabId, silent)
    Pindah ke tab tertentu.

    @param tabId   string   -- ID tab tujuan
    @param silent  boolean  -- jika true, tidak ada animasi (untuk init)
]]
function TabManager.Switch(tabId, silent)
    -- Jangan proses jika sudah aktif
    if TabManager._active == tabId then return end

    local targetDef = Tabs.GetById(tabId)
    if not targetDef then
        warn("[BorcaUIHub][TabManager] Tab tidak ditemukan: " .. tabId)
        return
    end

    local prevId    = TabManager._active
    local prevFrame = prevId and Tabs.GetFrame(prevId)
    local newFrame  = Tabs.GetFrame(tabId)

    if not newFrame then
        warn("[BorcaUIHub][TabManager] Frame tidak ditemukan untuk tab: " .. tabId)
        return
    end

    -- FIX (Fix 8): Build konten tab jika belum dibangun
    -- SEBELUMNYA: Tabs.BuildTabContent() hanya lari untuk tab dengan _builder
    --             tab default (tanpa _builder) tidak punya flag built → ambiguitas
    -- SEKARANG:   cek _builtTabs dulu; kalau belum, panggil BuildTabContent()
    --             lalu set _builtTabs[tabId] = true SETELAH build selesai
    --             Ini konsisten untuk SEMUA tab, default maupun dinamis
    if not TabManager._builtTabs[tabId] then
        -- Panggil builder kalau ada (tab dinamis dengan _builder)
        Tabs.BuildTabContent(tabId)
        -- Tandai sebagai sudah dibangun — berlaku juga untuk tab default
        -- (yang memang tidak punya _builder, tapi frame-nya sudah diisi oleh Script)
        TabManager._builtTabs[tabId] = true
    end

    -- Update state
    TabManager._previous = prevId
    TabManager._active   = tabId

    -- Animasi transisi
    if silent or not Config.Animation.Enabled then
        if prevFrame then
            prevFrame.Visible = false
        end
        newFrame.Visible = true
        newFrame.BackgroundTransparency = 0
    else
        local direction = TabManager._GetDirection(prevId, tabId)
        if prevFrame then
            Animations.SwitchTab(prevFrame, nil)
        end
        Animations.SlideTabIn(newFrame, direction)
    end

    -- Update visual sidebar items
    TabManager._UpdateSidebarHighlight(prevId, tabId)

    -- Notify listeners
    TabManager._Notify(tabId, prevId)
end

--[[
    TabManager.MarkBuilt(tabId)
    Tandai tab sebagai sudah dibangun kontennya dari luar (oleh Script).
    Dipanggil setelah FreeScript/PremiumScript selesai mengisi tab.

    FIX (Fix 8): ini adalah entry point untuk script hub agar bisa
    memberitahu TabManager bahwa konten tab sudah siap, tanpa harus
    melalui _builder di Tabs.Registry.
]]
function TabManager.MarkBuilt(tabId)
    TabManager._builtTabs[tabId] = true
end

--[[
    TabManager.IsBuilt(tabId) → boolean
    Cek apakah konten tab sudah dibangun.
]]
function TabManager.IsBuilt(tabId)
    return TabManager._builtTabs[tabId] == true
end

-- Tentukan arah animasi berdasarkan posisi tab
function TabManager._GetDirection(fromId, toId)
    if not fromId then return "right" end

    local order = Tabs.GetOrder()
    local fromIndex, toIndex = 0, 0

    for i, id in ipairs(order) do
        if id == fromId then fromIndex = i end
        if id == toId   then toIndex   = i end
    end

    return toIndex > fromIndex and "right" or "left"
end

-- ============================================================
-- SIDEBAR HIGHLIGHT
-- ============================================================

--[[
    TabManager.RegisterSidebarItem(tabId, button, indicator)
    Daftarkan tombol sidebar ke TabManager agar bisa di-highlight.
]]
function TabManager.RegisterSidebarItem(tabId, button, indicator)
    TabManager._sidebarItems[tabId] = {
        button    = button,
        indicator = indicator,
    }

    button.MouseButton1Click:Connect(function()
        TabManager.Switch(tabId)
    end)
end

function TabManager._UpdateSidebarHighlight(prevId, newId)
    if prevId and TabManager._sidebarItems[prevId] then
        local item = TabManager._sidebarItems[prevId]
        Animations.SidebarItemDeselect(item.button, item.indicator)
    end

    if newId and TabManager._sidebarItems[newId] then
        local item = TabManager._sidebarItems[newId]
        Animations.SidebarItemSelect(item.button, item.indicator)
    end
end

-- ============================================================
-- LISTENERS
-- ============================================================

function TabManager.OnTabChanged(callback)
    table.insert(TabManager._listeners, callback)
    return function()
        for i, cb in ipairs(TabManager._listeners) do
            if cb == callback then
                table.remove(TabManager._listeners, i)
                break
            end
        end
    end
end

function TabManager._Notify(newId, prevId)
    for _, cb in ipairs(TabManager._listeners) do
        pcall(cb, newId, prevId)
    end
end

-- ============================================================
-- GETTERS
-- ============================================================

function TabManager.GetActive()
    return TabManager._active
end

function TabManager.GetPrevious()
    return TabManager._previous
end

function TabManager.IsActive(tabId)
    return TabManager._active == tabId
end

-- ============================================================
-- NAVIGATION SHORTCUTS
-- ============================================================

function TabManager.Next()
    local order   = Tabs.GetOrder()
    local current = TabManager._active

    for i, id in ipairs(order) do
        if id == current then
            local next = order[i + 1] or order[1]
            TabManager.Switch(next)
            return
        end
    end
end

function TabManager.Previous()
    local order   = Tabs.GetOrder()
    local current = TabManager._active

    for i, id in ipairs(order) do
        if id == current then
            local prev = order[i - 1] or order[#order]
            TabManager.Switch(prev)
            return
        end
    end
end

-- ============================================================
-- RESET (untuk testing / re-init setelah logout)
-- ============================================================

--[[
    TabManager.Reset()
    Kosongkan state agar Init() bisa dipanggil ulang.
    Berguna saat user logout dan re-login tanpa reload.
]]
function TabManager.Reset()
    TabManager._active      = nil
    TabManager._previous    = nil
    TabManager._sidebarItems = {}
    TabManager._listeners   = {}
    TabManager._builtTabs   = {}
    TabManager._initialized = false
end

return TabManager
