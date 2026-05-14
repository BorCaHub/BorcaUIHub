--[[
    BorcaUIHub — Navigation/TabManager.lua
    Mengatur tab aktif, transisi antar tab, dan state navigasi.
    Mencegah overlap konten dan menjaga navigasi tetap rapi.
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

    -- Cek akses premium
    if targetDef.Premium then
        -- Validasi bisa ditambahkan di sini
        -- Untuk sementara biarkan lewat
    end

    local prevId    = TabManager._active
    local prevFrame = prevId and Tabs.GetFrame(prevId)
    local newFrame  = Tabs.GetFrame(tabId)

    if not newFrame then
        warn("[BorcaUIHub][TabManager] Frame tidak ditemukan untuk tab: " .. tabId)
        return
    end

    -- Build konten tab jika belum dibangun (lazy build)
    Tabs.BuildTabContent(tabId)

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
        -- Tentukan arah slide berdasarkan urutan tab
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
    Dipanggil oleh Sidebar.lua saat membuat tombol navigasi.
    
    @param tabId      string
    @param button     TextButton | Frame
    @param indicator  Frame  -- strip aktif kiri (opsional)
]]
function TabManager.RegisterSidebarItem(tabId, button, indicator)
    TabManager._sidebarItems[tabId] = {
        button    = button,
        indicator = indicator,
    }

    -- Klik sidebar item → switch tab
    button.MouseButton1Click:Connect(function()
        TabManager.Switch(tabId)
    end)
end

-- Update highlight visual sidebar setelah tab berganti
function TabManager._UpdateSidebarHighlight(prevId, newId)
    -- Deselect previous
    if prevId and TabManager._sidebarItems[prevId] then
        local item = TabManager._sidebarItems[prevId]
        Animations.SidebarItemDeselect(item.button, item.indicator)
    end

    -- Select new
    if newId and TabManager._sidebarItems[newId] then
        local item = TabManager._sidebarItems[newId]
        Animations.SidebarItemSelect(item.button, item.indicator)
    end
end

-- ============================================================
-- LISTENERS
-- ============================================================

--[[
    TabManager.OnTabChanged(callback)
    Daftarkan callback yang dipanggil saat tab berganti.
    
    @param callback  function(newTabId, prevTabId)
    @return disconnectFn
]]
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

--[[
    TabManager.GetActive() → string | nil
    Kembalikan ID tab yang sedang aktif.
]]
function TabManager.GetActive()
    return TabManager._active
end

--[[
    TabManager.GetPrevious() → string | nil
    Kembalikan ID tab sebelumnya.
]]
function TabManager.GetPrevious()
    return TabManager._previous
end

--[[
    TabManager.IsActive(tabId) → boolean
    Cek apakah tab tertentu sedang aktif.
]]
function TabManager.IsActive(tabId)
    return TabManager._active == tabId
end

-- ============================================================
-- NAVIGATION SHORTCUTS
-- ============================================================

--[[
    TabManager.Next()
    Pindah ke tab berikutnya dalam urutan.
]]
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

--[[
    TabManager.Previous()
    Pindah ke tab sebelumnya dalam urutan.
]]
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

return TabManager
