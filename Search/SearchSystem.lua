-- // SearchSystem.lua
-- // BorcaScriptHub - Search System Logic
-- // Memproses input dari SearchBar, menyaring tab/section/elemen,
-- // dan menampilkan hasil secara real-time di ContentArea.

local SearchSystem = {}
local Functions, Theme, Config

function SearchSystem.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // STATE
-- ========================
local registeredTabs    = {}   -- { tabObj, sections[] }
local resultContainer   = nil  -- Frame tempat hasil ditampilkan
local originalContainer = nil  -- ContentArea asli
local isSearching       = false
local lastQuery         = ""

-- ========================
-- // REGISTER WINDOW
-- // Dipanggil sekali setelah semua tab & section dibuat.
-- // window = object dari UI.CreateWindow
-- ========================
function SearchSystem.RegisterWindow(window)
    if not window then return end
    registeredTabs  = {}
    resultContainer = nil

    -- Buat result frame di ContentArea
    -- Disembunyikan saat tidak search
    resultContainer = Functions.Create("ScrollingFrame", {
        Name                  = "SearchResults",
        Size                  = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = Config.UI.ScrollBarWidth,
        ScrollBarImageColor3   = Theme.Get("ScrollBar"),
        CanvasSize             = UDim2.fromScale(0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Visible                = false,
        ZIndex                 = 2,
    }, window.ContentArea)

    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, Config.UI.SectionPadding),
    }, resultContainer)

    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, resultContainer)

    originalContainer = window.ContentArea
end

-- ========================
-- // REGISTER TAB
-- // Daftarkan tab + semua sectionnya ke sistem pencarian.
-- // Dipanggil setelah tab dan section selesai dibuat.
-- ========================
function SearchSystem.RegisterTab(tabObj)
    if not tabObj then return end
    table.insert(registeredTabs, tabObj)
end

-- ========================
-- // INTERNAL: normalize string untuk pencarian
-- ========================
local function normalize(s)
    return tostring(s or ""):lower():match("^%s*(.-)%s*$")
end

-- ========================
-- // INTERNAL: cek apakah query cocok dengan teks
-- ========================
local function matches(text, query)
    return normalize(text):find(normalize(query), 1, true) ~= nil
end

-- ========================
-- // INTERNAL: Bersihkan result container
-- ========================
local function clearResults()
    if not resultContainer then return end
    for _, child in ipairs(resultContainer:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

-- ========================
-- // INTERNAL: Buat header kategori di hasil
-- ========================
local function makeResultHeader(text, parent, order)
    local frame = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = order,
    }, parent)

    -- Garis kiri accent
    Functions.Create("Frame", {
        Size             = UDim2.fromOffset(3, 14),
        Position         = UDim2.fromOffset(0, 4),
        BackgroundColor3 = Theme.Get("Accent"),
        BorderSizePixel  = 0,
    }, frame)
    Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)},
        frame:GetChildren()[1])

    Functions.Create("TextLabel", {
        Size                   = UDim2.new(1, -10, 1, 0),
        Position               = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text                   = text:upper(),
        TextColor3             = Theme.Get("Accent"),
        TextSize               = 9,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, frame)

    return frame
end

-- ========================
-- // INTERNAL: Buat result item (clone visual elemen)
-- ========================
local function makeResultItem(elementFrame, tabName, sectionName, parent, order)
    -- Wrapper dengan label sumber kecil
    local wrapper = Functions.Create("Frame", {
        Name             = "ResultItem_" .. order,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Get("TertiaryBG"),
        BorderSizePixel  = 0,
        LayoutOrder      = order,
        ClipsDescendants = false,
    }, parent)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, Config.UI.ElementCorner)}, wrapper)
    Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, wrapper)
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
    }, wrapper)
    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 3),
    }, wrapper)

    -- Breadcrumb path kecil
    Functions.Create("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1,
        Text                   = tabName .. "  ›  " .. sectionName,
        TextColor3             = Theme.Get("TextMuted"),
        TextSize               = 9,
        Font                   = Config.UI.SmallFont,
        TextXAlignment         = Enum.TextXAlignment.Left,
        LayoutOrder            = 1,
    }, wrapper)

    -- Clone frame elemen asli ke wrapper
    -- Tidak bisa clone Instance secara langsung tanpa mengacaukan layout asli,
    -- jadi kita buat mirror ringkas dari nama + tipe elemen
    if elementFrame and elementFrame.Parent then
        -- Ambil nama dari child "Name" label atau Name property frame
        local nameLabel = elementFrame:FindFirstChild("Name", true)
        local displayName = (nameLabel and nameLabel:IsA("TextLabel"))
            and nameLabel.Text
            or  elementFrame.Name:gsub("^%w+_", "")

        local typeTag = elementFrame.Name:match("^(%w+)_") or "Element"

        local row = Functions.Create("Frame", {
            Size             = UDim2.new(1, 0, 0, Config.UI.ElementHeight),
            BackgroundColor3 = Theme.Get("ElementBG"),
            BorderSizePixel  = 0,
            LayoutOrder      = 2,
        }, wrapper)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0, Config.UI.ElementCorner)}, row)

        -- Nama elemen
        Functions.Create("TextLabel", {
            Size                   = UDim2.new(1, -70, 1, 0),
            Position               = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text                   = displayName,
            TextColor3             = Theme.Get("TextPrimary"),
            TextSize               = Config.UI.FontSize,
            Font                   = Config.UI.Font,
            TextXAlignment         = Enum.TextXAlignment.Left,
        }, row)

        -- Tipe badge
        local typeBadge = Functions.Create("TextLabel", {
            Size                   = UDim2.fromOffset(0, 16),
            AutomaticSize          = Enum.AutomaticSize.X,
            Position               = UDim2.new(1, -4, 0.5, -8),
            AnchorPoint            = Vector2.new(1, 0),
            BackgroundColor3       = Theme.Get("Accent"),
            BackgroundTransparency = 0.78,
            Text                   = " " .. typeTag .. " ",
            TextColor3             = Theme.Get("Accent"),
            TextSize               = 8,
            Font                   = Enum.Font.GothamBold,
        }, row)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0, 3)}, typeBadge)
    end

    return wrapper
end

-- ========================
-- // INTERNAL: Tampilkan "tidak ada hasil"
-- ========================
local function showEmpty(query, parent)
    local frame = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
    }, parent)

    Functions.Create("TextLabel", {
        Size                   = UDim2.fromScale(1, 0.5),
        BackgroundTransparency = 1,
        Text                   = "🔍",
        TextSize               = 22,
        Font                   = Enum.Font.GothamMedium,
        TextXAlignment         = Enum.TextXAlignment.Center,
    }, frame)

    Functions.Create("TextLabel", {
        Size                   = UDim2.new(1, 0, 0.5, 0),
        Position               = UDim2.fromScale(0, 0.5),
        BackgroundTransparency = 1,
        Text                   = 'Tidak ditemukan: "' .. query .. '"',
        TextColor3             = Theme.Get("TextMuted"),
        TextSize               = Config.UI.FontSize - 1,
        Font                   = Config.UI.SmallFont,
        TextXAlignment         = Enum.TextXAlignment.Center,
    }, frame)
end

-- ========================
-- // SEARCH
-- // Dipanggil oleh SearchBar.OnSearch
-- ========================
function SearchSystem.Search(query, window)
    if not resultContainer or not window then return end
    query = normalize(query)
    if query == lastQuery then return end
    lastQuery = query

    -- Kosong → restore
    if query == "" then
        SearchSystem.Clear(window)
        return
    end

    isSearching = true
    clearResults()

    -- Sembunyikan semua tab content, tampilkan result frame
    for _, tab in ipairs(window.Tabs) do
        if tab.Content then
            tab.Content.Visible = false
        end
    end
    resultContainer.Visible = true

    -- ── Scan semua tab → section → elemen ──
    local totalFound = 0
    local orderIdx   = 0

    for _, tab in ipairs(window.Tabs) do
        local tabMatches = {}   -- { section, element, frame }

        -- Cek apakah nama tab cocok
        local tabNameMatch = matches(tab.Name, query)

        for _, section in ipairs(tab.Sections or {}) do
            local sectionNameMatch = matches(section.Name, query)

            for _, element in ipairs(section.Elements or {}) do
                local elName = tostring(element.Name or "")
                local elMatch = matches(elName, query)

                if tabNameMatch or sectionNameMatch or elMatch then
                    table.insert(tabMatches, {
                        section = section,
                        element = element,
                        frame   = element.Frame,
                    })
                end
            end

            -- Jika section cocok tapi tidak ada elemen, tetap tampilkan section header
            if sectionNameMatch and #section.Elements == 0 then
                table.insert(tabMatches, {
                    section = section,
                    element = nil,
                    frame   = nil,
                })
            end
        end

        if #tabMatches > 0 then
            orderIdx += 1
            makeResultHeader("📂  " .. tab.Name, resultContainer, orderIdx)

            for _, m in ipairs(tabMatches) do
                orderIdx += 1
                totalFound += 1
                makeResultItem(
                    m.frame,
                    tab.Name,
                    m.section and m.section.Name or "—",
                    resultContainer,
                    orderIdx
                )
            end
        end
    end

    -- Tidak ada hasil
    if totalFound == 0 then
        showEmpty(query, resultContainer)
    end

    -- Update judul result
    -- (opsional — bisa dipakai oleh caller untuk update label)
    return totalFound
end

-- ========================
-- // CLEAR — restore tampilan normal
-- ========================
function SearchSystem.Clear(window)
    if not window then return end
    isSearching = false
    lastQuery   = ""

    clearResults()

    if resultContainer then
        resultContainer.Visible = false
    end

    -- Tampilkan kembali tab yang aktif
    if window.ActiveTab and window.ActiveTab.Content then
        window.ActiveTab.Content.Visible = true
    end
end

-- ========================
-- // GETTERS
-- ========================
function SearchSystem.IsSearching()
    return isSearching
end

function SearchSystem.GetLastQuery()
    return lastQuery
end

-- ========================
-- // RESET (unregister semua)
-- ========================
function SearchSystem.Reset()
    registeredTabs  = {}
    resultContainer = nil
    isSearching     = false
    lastQuery       = ""
end

return SearchSystem
