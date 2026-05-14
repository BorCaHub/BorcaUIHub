--[[
    BorcaUIHub — Sections/SectionManager.lua
    Mengelola tata letak section: urutan, jarak, ukuran container,
    dan penyesuaian saat konten berubah secara dinamis.
]]

local SectionManager = {}

local Theme     = require(script.Parent.Parent.UI.Theme)
local Config    = require(script.Parent.Parent.UI.Config)
local Functions = require(script.Parent.Parent.UI.Functions)
local Sections  = require(script.Parent.Sections)

-- ============================================================
-- STATE
-- Per-tab registry: { [tabId] = { sections = {}, container = Frame } }
-- ============================================================

SectionManager._tabs = {}

-- ============================================================
-- INIT
-- ============================================================

--[[
    SectionManager.InitTab(tabId, contentFrame)
    Daftarkan sebuah tab ke SectionManager dan siapkan container-nya.
    Harus dipanggil sebelum AddSection bisa digunakan pada tab tersebut.

    @param tabId         string
    @param contentFrame  Frame  -- frame konten tab (dari Tabs.GetFrame)
]]
function SectionManager.InitTab(tabId, contentFrame)
    if SectionManager._tabs[tabId] then return end

    SectionManager._tabs[tabId] = {
        sections  = {},   -- { { id, order } }
        container = contentFrame,
    }
end

-- ============================================================
-- SECTION CREATION
-- ============================================================

--[[
    SectionManager.AddSection(tabId, options) → sectionObject
    Buat section baru di dalam tab tertentu dan daftarkan ke manager.

    @param tabId    string
    @param options  table  -- diteruskan ke Sections.Create
    @return sectionObject
]]
function SectionManager.AddSection(tabId, options)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then
        warn("[BorcaUIHub][SectionManager] Tab belum diinisialisasi: " .. tostring(tabId))
        return nil
    end

    options = options or {}

    -- Auto LayoutOrder jika tidak ditentukan
    if not options.LayoutOrder then
        options.LayoutOrder = #tabData.sections + 1
    end

    local section = Sections.Create(tabData.container, options)
    if not section then return nil end

    table.insert(tabData.sections, {
        id    = section.Id,
        order = options.LayoutOrder,
    })

    -- Urutkan ulang
    SectionManager._SortTab(tabId)

    return section
end

--[[
    SectionManager.RemoveSection(tabId, sectionId)
    Hapus section dari tab dan registry.

    @param tabId      string
    @param sectionId  string
]]
function SectionManager.RemoveSection(tabId, sectionId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    -- Hapus dari list
    for i, entry in ipairs(tabData.sections) do
        if entry.id == sectionId then
            table.remove(tabData.sections, i)
            break
        end
    end

    -- Hapus dari Sections registry dan UI
    Sections.Remove(sectionId)

    -- Recalculate order
    SectionManager._RecalculateOrder(tabId)
end

-- ============================================================
-- ORDERING
-- ============================================================

--[[
    SectionManager.SetOrder(tabId, orderedIds)
    Atur ulang urutan section di sebuah tab.

    @param tabId      string
    @param orderedIds {string}  -- daftar section ID dalam urutan baru
]]
function SectionManager.SetOrder(tabId, orderedIds)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    for newOrder, sectionId in ipairs(orderedIds) do
        -- Update entry
        for _, entry in ipairs(tabData.sections) do
            if entry.id == sectionId then
                entry.order = newOrder
                break
            end
        end

        -- Update LayoutOrder di frame
        local section = Sections.Get(sectionId)
        if section and Functions.IsValid(section.Frame) then
            section.Frame.LayoutOrder = newOrder
        end
    end

    SectionManager._SortTab(tabId)
end

--[[
    SectionManager.MoveSection(tabId, sectionId, direction)
    Geser section ke atas atau bawah relatif terhadap posisinya saat ini.

    @param direction  "up" | "down"
]]
function SectionManager.MoveSection(tabId, sectionId, direction)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    local index = nil
    for i, entry in ipairs(tabData.sections) do
        if entry.id == sectionId then
            index = i
            break
        end
    end

    if not index then return end

    local swapIndex = direction == "up" and (index - 1) or (index + 1)
    if swapIndex < 1 or swapIndex > #tabData.sections then return end

    -- Tukar
    tabData.sections[index], tabData.sections[swapIndex] =
        tabData.sections[swapIndex], tabData.sections[index]

    SectionManager._RecalculateOrder(tabId)
    SectionManager._SortTab(tabId)
end

-- ============================================================
-- VISIBILITY
-- ============================================================

--[[
    SectionManager.ShowSection(tabId, sectionId)
    Tampilkan section yang tersembunyi.
]]
function SectionManager.ShowSection(tabId, sectionId)
    local section = Sections.Get(sectionId)
    if section then
        section.Frame.Visible = true
        SectionManager._RecalculateOrder(tabId)
    end
end

--[[
    SectionManager.HideSection(tabId, sectionId)
    Sembunyikan section tanpa menghapusnya.
]]
function SectionManager.HideSection(tabId, sectionId)
    local section = Sections.Get(sectionId)
    if section then
        section.Frame.Visible = false
    end
end

--[[
    SectionManager.CollapseAll(tabId)
    Collapse semua section yang collapsible di sebuah tab.
]]
function SectionManager.CollapseAll(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    for _, entry in ipairs(tabData.sections) do
        local section = Sections.Get(entry.id)
        if section and not section.IsCollapsed() then
            section.Toggle()
        end
    end
end

--[[
    SectionManager.ExpandAll(tabId)
    Expand semua section yang collapsed di sebuah tab.
]]
function SectionManager.ExpandAll(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    for _, entry in ipairs(tabData.sections) do
        local section = Sections.Get(entry.id)
        if section and section.IsCollapsed() then
            section.Toggle()
        end
    end
end

-- ============================================================
-- QUERY
-- ============================================================

--[[
    SectionManager.GetSections(tabId) → {sectionObject}
    Kembalikan semua section di tab dalam urutan saat ini.
]]
function SectionManager.GetSections(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return {} end

    local result = {}
    for _, entry in ipairs(tabData.sections) do
        local section = Sections.Get(entry.id)
        if section then
            table.insert(result, section)
        end
    end
    return result
end

--[[
    SectionManager.GetSection(tabId, sectionId) → sectionObject | nil
    Ambil satu section berdasarkan ID.
]]
function SectionManager.GetSection(tabId, sectionId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return nil end

    for _, entry in ipairs(tabData.sections) do
        if entry.id == sectionId then
            return Sections.Get(sectionId)
        end
    end
    return nil
end

--[[
    SectionManager.GetCount(tabId) → number
    Hitung jumlah section di tab.
]]
function SectionManager.GetCount(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return 0 end
    return #tabData.sections
end

-- ============================================================
-- LAYOUT UTILITIES
-- ============================================================

--[[
    SectionManager.SetGap(tabId, gap)
    Ubah jarak antar section di tab tertentu.

    @param gap  number  -- pixel
]]
function SectionManager.SetGap(tabId, gap)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    local layout = tabData.container:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout.Padding = UDim.new(0, gap)
    end
end

--[[
    SectionManager.SetPadding(tabId, padding)
    Ubah padding dalam container tab.

    @param padding  number | table { Top, Bottom, Left, Right }
]]
function SectionManager.SetPadding(tabId, padding)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    local pad = tabData.container:FindFirstChildOfClass("UIPadding")
    if pad then
        if type(padding) == "number" then
            pad.PaddingTop    = UDim.new(0, padding)
            pad.PaddingBottom = UDim.new(0, padding)
            pad.PaddingLeft   = UDim.new(0, padding)
            pad.PaddingRight  = UDim.new(0, padding)
        else
            if padding.Top    then pad.PaddingTop    = UDim.new(0, padding.Top)    end
            if padding.Bottom then pad.PaddingBottom = UDim.new(0, padding.Bottom) end
            if padding.Left   then pad.PaddingLeft   = UDim.new(0, padding.Left)   end
            if padding.Right  then pad.PaddingRight  = UDim.new(0, padding.Right)  end
        end
    end
end

--[[
    SectionManager.ClearTab(tabId)
    Hapus semua section di sebuah tab.
]]
function SectionManager.ClearTab(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    for _, entry in ipairs(tabData.sections) do
        Sections.Remove(entry.id)
    end

    tabData.sections = {}
end

-- ============================================================
-- SEARCH SUPPORT
-- ============================================================

--[[
    SectionManager.FilterByKeyword(tabId, keyword)
    Tampilkan hanya section yang judulnya mengandung keyword.
    Jika keyword kosong, tampilkan semua.

    @param keyword  string
]]
function SectionManager.FilterByKeyword(tabId, keyword)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    keyword = (keyword or ""):lower():gsub("%s+", "")

    for _, entry in ipairs(tabData.sections) do
        local section = Sections.Get(entry.id)
        if section and Functions.IsValid(section.Frame) then
            if keyword == "" then
                section.Frame.Visible = true
            else
                local titleLbl = section.Header:FindFirstChild("SectionTitle")
                local titleText = titleLbl and titleLbl.Text:lower():gsub("%s+", "") or ""
                section.Frame.Visible = titleText:find(keyword, 1, true) ~= nil
            end
        end
    end
end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- Urutkan sections berdasarkan order field
function SectionManager._SortTab(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    table.sort(tabData.sections, function(a, b)
        return a.order < b.order
    end)

    -- Terapkan LayoutOrder ke frames
    for i, entry in ipairs(tabData.sections) do
        local section = Sections.Get(entry.id)
        if section and Functions.IsValid(section.Frame) then
            section.Frame.LayoutOrder = i
        end
    end
end

-- Recalculate order setelah penghapusan atau pemindahan
function SectionManager._RecalculateOrder(tabId)
    local tabData = SectionManager._tabs[tabId]
    if not tabData then return end

    for i, entry in ipairs(tabData.sections) do
        entry.order = i
    end

    SectionManager._SortTab(tabId)
end

-- ============================================================
-- PRESET LAYOUTS
-- Bantu pembuatan layout section yang umum dipakai
-- ============================================================

--[[
    SectionManager.BuildSettingsLayout(tabId)
    Contoh preset: layout section untuk tab Settings.
    Membuat 4 section standar: Appearance, Behavior, Keybinds, About.
]]
function SectionManager.BuildSettingsLayout(tabId)
    SectionManager.AddSection(tabId, {
        Id           = tabId .. "_appearance",
        Title        = "Appearance",
        Icon         = "◈",
        Description  = "Warna, tema, dan tampilan UI",
        Collapsible  = true,
        LayoutOrder  = 1,
    })

    SectionManager.AddSection(tabId, {
        Id           = tabId .. "_behavior",
        Title        = "Behavior",
        Icon         = "⚙",
        Description  = "Animasi, blur, dan performa",
        Collapsible  = true,
        LayoutOrder  = 2,
    })

    SectionManager.AddSection(tabId, {
        Id           = tabId .. "_keybinds",
        Title        = "Keybinds",
        Icon         = "⌨",
        Description  = "Shortcut keyboard",
        Collapsible  = true,
        LayoutOrder  = 3,
    })

    SectionManager.AddSection(tabId, {
        Id           = tabId .. "_about",
        Title        = "About",
        Icon         = "◉",
        Description  = "Versi dan informasi hub",
        Collapsible  = true,
        Collapsed    = true,
        LayoutOrder  = 4,
    })
end

return SectionManager
