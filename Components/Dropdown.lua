--[[
    BorcaUIHub — Components/Dropdowns.lua
    Komponen dropdown untuk banyak pilihan dalam satu tempat.
    Mendukung animasi buka/tutup, search, dan multi-select opsional.

    FIX (Fix 9b):
    - Saat single-select, setelah user memilih opsi, dropdown menutup
      SEBELUMNYA: task.delay(0.1, function() Dropdowns._Close(dropFrame, chevron, isOpen, cb) end)
                  → isOpen adalah snapshot nilai lama yang bisa sudah berubah sebelum delay selesai
      SEKARANG:   task.delay(0.1, function() Close() end)
                  → Close() adalah fungsi lokal yang membaca isOpen saat ini (live state),
                    bukan snapshot, dan sudah mengelola semua state dengan benar
]]

local Dropdowns = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- Daftar dropdown terbuka (hanya satu yang boleh terbuka sekaligus)
local _openDropdown = nil

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Dropdowns.Create(parent, options) → dropdownObject
    Buat komponen dropdown.

    @param options {
        Label:        string
        Description:  string       -- opsional
        Items:        {string}     -- daftar pilihan
        Default:      string       -- nilai awal (harus ada di Items)
        Placeholder:  string       -- teks saat belum dipilih
        MultiSelect:  boolean      -- izinkan memilih lebih dari satu (default false)
        MaxHeight:    number       -- tinggi max dropdown list
        Disabled:     boolean
        OnChanged:    function(selected: string | {string})
        LayoutOrder:  number
    }
    @return dropdownObject {
        Frame:      Frame
        GetValue:   function → string | {string}
        SetValue:   function(string | {string}, silent?)
        SetItems:   function({string})
        SetDisabled:function(boolean)
        Close:      function
        Open:       function
    }
]]
function Dropdowns.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Dropdown"
    local description = options.Description or ""
    local items       = options.Items       or {}
    local placeholder = options.Placeholder or "Pilih opsi..."
    local multiSelect = options.MultiSelect or false
    local maxHeight   = options.MaxHeight   or Config.Dropdown.MaxHeight
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0

    local selectedValues = {}
    if options.Default then
        if type(options.Default) == "table" then
            selectedValues = options.Default
        else
            selectedValues = { options.Default }
        end
    end

    local headerH = description ~= "" and Config.UI.ComponentHeight + 14 or Config.UI.ComponentHeight
    local isOpen = false

    -- ── WRAPPER (untuk clipping dropdown) ──────────────────
    local wrapper = Functions.CreateFrame({
        Name                   = "Dropdown_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, headerH),
        BackgroundTransparency = 1,
        ClipDescendants        = false,
        LayoutOrder            = layoutOrder,
        ZIndex                 = 3,
    })

    -- ── HEADER CONTAINER ───────────────────────────────────
    local headerContainer = Functions.CreateFrame({
        Name                   = "DropdownHeader",
        Parent                 = wrapper,
        Size                   = UDim2.new(1, 0, 0, headerH),
        BackgroundTransparency = 1,
        ZIndex                 = 3,
    })

    -- Label
    local labelText = Functions.CreateLabel({
        Name      = "DropLabel",
        Parent    = headerContainer,
        Text      = label,
        Size      = UDim2.new(1, 0, 0, 16),
        Position  = description ~= "" and UDim2.new(0, 0, 0, 6) or UDim2.new(0, 0, 0.5, description ~= "" and -16 or -8),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    if description ~= "" then
        Functions.CreateLabel({
            Name      = "DropDesc",
            Parent    = headerContainer,
            Text      = description,
            Size      = UDim2.new(1, 0, 0, 13),
            Position  = UDim2.new(0, 0, 0, 24),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── BUTTON SELECTOR ────────────────────────────────────
    local selectorY = description ~= "" and headerH - 30 or 0
    local selectorH = 30

    local selector = Functions.CreateButton({
        Name            = "DropSelector",
        Parent          = wrapper,
        Size            = UDim2.new(1, 0, 0, selectorH),
        Position        = UDim2.new(0, 0, 0, selectorY),
        BackgroundColor = Theme.Get("InputBackground"),
        CornerRadius    = Config.UI.ButtonRadius,
        ZIndex          = 4,
        Text            = "",
    })

    Functions.ApplyStroke(selector, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.4,
    })

    Functions.ApplyPadding(selector, { Left = 10, Right = 10 })

    -- Layout isi selector
    local selectorLayout = Instance.new("UIListLayout")
    selectorLayout.FillDirection      = Enum.FillDirection.Horizontal
    selectorLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
    selectorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    selectorLayout.SortOrder          = Enum.SortOrder.LayoutOrder
    selectorLayout.Padding            = UDim.new(0, 6)
    selectorLayout.Parent             = selector

    -- Teks nilai yang dipilih
    local function GetDisplayText()
        if #selectedValues == 0 then return placeholder end
        if multiSelect then
            return table.concat(selectedValues, ", ")
        end
        return selectedValues[1] or placeholder
    end

    local selectedText = Functions.CreateLabel({
        Name      = "SelectedText",
        Parent    = selector,
        Text      = GetDisplayText(),
        Size      = UDim2.new(1, -20, 1, 0),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel - 1,
        TextColor = #selectedValues == 0 and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex    = 5,
        LayoutOrder = 0,
    })

    -- Chevron ikon
    local chevron = Functions.CreateLabel({
        Name      = "Chevron",
        Parent    = selector,
        Text      = "▾",
        Size      = UDim2.new(0, 16, 1, 0),
        Position  = UDim2.new(1, -18, 0, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = 11,
        TextColor = Theme.Get("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 5,
    })

    -- ── DROPDOWN LIST ──────────────────────────────────────
    local optionH  = Config.Dropdown.OptionHeight
    local totalH   = math.min(#items * optionH + 8, maxHeight)

    local dropFrame = Functions.CreateFrame({
        Name            = "DropList",
        Parent          = wrapper,
        Size            = UDim2.new(1, 0, 0, 0),
        Position        = UDim2.new(0, 0, 0, selectorY + selectorH + 4),
        BackgroundColor = Theme.Get("CardBackground"),
        CornerRadius    = Config.UI.ButtonRadius,
        ClipDescendants = true,
        ZIndex          = 10,
        Visible         = false,
    })

    Functions.ApplyStroke(dropFrame, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.3,
    })

    -- Scroll di dalam drop list
    local dropScroll = Instance.new("ScrollingFrame")
    dropScroll.Name                 = "DropScroll"
    dropScroll.Parent               = dropFrame
    dropScroll.Size                 = UDim2.new(1, 0, 1, 0)
    dropScroll.BackgroundTransparency = 1
    dropScroll.ScrollBarThickness   = 3
    dropScroll.ScrollBarImageColor3 = Theme.Get("Accent")
    dropScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    dropScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    dropScroll.ScrollingDirection   = Enum.ScrollingDirection.Y

    Functions.ApplyListLayout(dropScroll, {
        Padding = UDim.new(0, Config.Dropdown.OptionGap),
    })
    Functions.ApplyPadding(dropScroll, {
        Top = 4, Bottom = 4, Left = 4, Right = 4,
    })

    -- ── OPTION ITEMS ───────────────────────────────────────
    local optionButtons = {}

    local function IsSelected(item)
        for _, v in ipairs(selectedValues) do
            if v == item then return true end
        end
        return false
    end

    local function RefreshOptionColors()
        for _, obj in ipairs(optionButtons) do
            local sel = IsSelected(obj.item)
            local ts  = game:GetService("TweenService")
            ts:Create(obj.btn, TweenInfo.new(0.1), {
                BackgroundColor3    = sel and Theme.Get("ButtonHover") or Theme.Get("CardBackground"),
                BackgroundTransparency = sel and 0 or 1,
            }):Play()
            ts:Create(obj.lbl, TweenInfo.new(0.1), {
                TextColor3 = sel and Theme.Get("Accent") or Theme.Get("TextPrimary"),
            }):Play()
        end
    end

    -- ── TOGGLE OPEN / CLOSE ────────────────────────────────
    -- Dideklarasikan sebagai local di atas BuildOptions agar bisa
    -- dipanggil dari dalam opsi klik (FIX 9b)
    local Open
    local Close

    local function BuildOptions(itemList)
        -- Bersihkan dulu
        for _, obj in ipairs(optionButtons) do
            obj.btn:Destroy()
        end
        optionButtons = {}

        for i, item in ipairs(itemList) do
            local sel = IsSelected(item)

            local optBtn = Functions.CreateButton({
                Name            = "Option_" .. i,
                Parent          = dropScroll,
                Size            = UDim2.new(1, 0, 0, optionH - 4),
                BackgroundColor = sel and Theme.Get("ButtonHover") or Theme.Get("CardBackground"),
                BackgroundTransparency = sel and 0 or 1,
                CornerRadius    = 6,
                LayoutOrder     = i,
                ZIndex          = 11,
                Text            = "",
            })

            Functions.ApplyPadding(optBtn, { Left = 10, Right = 10 })

            -- Check mark (untuk multi-select)
            local checkLbl = nil
            if multiSelect then
                checkLbl = Functions.CreateLabel({
                    Name      = "Check",
                    Parent    = optBtn,
                    Text      = sel and "✓" or "",
                    Size      = UDim2.new(0, 16, 1, 0),
                    Position  = UDim2.new(0, 0, 0, 0),
                    Font      = Enum.Font.GothamBold,
                    TextSize  = 11,
                    TextColor = Theme.Get("Accent"),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex    = 12,
                })
            end

            local optLbl = Functions.CreateLabel({
                Name      = "OptionText",
                Parent    = optBtn,
                Text      = item,
                Size      = UDim2.new(1, multiSelect and -20 or 0, 1, 0),
                Position  = UDim2.new(0, multiSelect and 20 or 0, 0, 0),
                Font      = Config.Font.Body,
                TextSize  = Config.Font.Size.ComponentLabel - 1,
                TextColor = sel and Theme.Get("Accent") or Theme.Get("TextPrimary"),
                ZIndex    = 12,
            })

            -- Hover
            local ts = game:GetService("TweenService")
            optBtn.MouseEnter:Connect(function()
                if not IsSelected(item) then
                    ts:Create(optBtn, TweenInfo.new(0.1), {
                        BackgroundColor3 = Theme.Get("ButtonSecondary"),
                        BackgroundTransparency = 0,
                    }):Play()
                end
            end)
            optBtn.MouseLeave:Connect(function()
                if not IsSelected(item) then
                    ts:Create(optBtn, TweenInfo.new(0.1), {
                        BackgroundTransparency = 1,
                    }):Play()
                end
            end)

            -- Klik opsi
            optBtn.MouseButton1Click:Connect(function()
                if multiSelect then
                    -- Toggle item dalam selectedValues
                    local found = false
                    for j, v in ipairs(selectedValues) do
                        if v == item then
                            table.remove(selectedValues, j)
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(selectedValues, item)
                    end
                    if checkLbl then
                        checkLbl.Text = IsSelected(item) and "✓" or ""
                    end
                    RefreshOptionColors()
                else
                    selectedValues = { item }
                    RefreshOptionColors()
                    -- FIX (Fix 9b): Panggil Close() lokal, bukan Dropdowns._Close(...)
                    -- SEBELUMNYA: task.delay(0.1, function()
                    --                 Dropdowns._Close(dropFrame, chevron, isOpen, function()
                    --                     isOpen = false
                    --                     wrapper.Size = UDim2.new(1, 0, 0, headerH)
                    --                 end)
                    --             end)
                    --             → isOpen adalah snapshot yang bisa sudah basi setelah delay
                    -- SEKARANG:   Close() membaca isOpen live dan mengelola semua state sendiri
                    task.delay(0.1, function()
                        Close()
                    end)
                end

                -- Update display
                selectedText.Text      = GetDisplayText()
                selectedText.TextColor3 = #selectedValues == 0 and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")

                if callback then
                    if multiSelect then
                        pcall(callback, selectedValues)
                    else
                        pcall(callback, selectedValues[1])
                    end
                end
            end)

            table.insert(optionButtons, { btn = optBtn, lbl = optLbl, item = item })
        end
    end

    BuildOptions(items)

    -- ── DEFINISI OPEN / CLOSE ──────────────────────────────
    -- Didefinisikan setelah BuildOptions agar BuildOptions bisa
    -- dipakai di Open (rebuild jika items berubah)

    Open = function()
        if disabled then return end
        -- Tutup dropdown lain yang terbuka
        if _openDropdown and _openDropdown ~= dropFrame then
            _openDropdown.Visible = false
            _openDropdown.Size = UDim2.new(1, 0, 0, 0)
        end
        _openDropdown = dropFrame
        isOpen = true

        -- Expand wrapper agar dropFrame terlihat
        local expandH = math.min(#items * optionH + 8, maxHeight)
        wrapper.Size = UDim2.new(1, 0, 0, headerH + expandH + 8)

        Animations.DropdownOpen(dropFrame, expandH)
        local ts = game:GetService("TweenService")
        ts:Create(chevron, TweenInfo.new(0.15), { Rotation = 180 }):Play()
        ts:Create(selector, TweenInfo.new(0.12), {
            BackgroundColor3 = Theme.Get("ButtonHover"),
        }):Play()
    end

    Close = function()
        if not isOpen then return end
        isOpen = false
        _openDropdown = nil
        Animations.DropdownClose(dropFrame, function()
            wrapper.Size = UDim2.new(1, 0, 0, headerH)
        end)
        local ts = game:GetService("TweenService")
        ts:Create(chevron, TweenInfo.new(0.15), { Rotation = 0 }):Play()
        ts:Create(selector, TweenInfo.new(0.12), {
            BackgroundColor3 = Theme.Get("InputBackground"),
        }):Play()
    end

    if not disabled then
        selector.MouseButton1Click:Connect(function()
            if isOpen then Close() else Open() end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        labelText.TextColor3      = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        selectedText.TextColor3   = #selectedValues == 0 and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        selector.BackgroundColor3 = Theme.Get("InputBackground")
        dropFrame.BackgroundColor3 = Theme.Get("CardBackground")
        chevron.TextColor3        = Theme.Get("TextSecondary")
        dropScroll.ScrollBarImageColor3 = Theme.Get("Accent")
        RefreshOptionColors()
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = wrapper,

        GetValue = function()
            if multiSelect then return selectedValues end
            return selectedValues[1]
        end,

        SetValue = function(val, silent)
            if type(val) == "table" then
                selectedValues = val
            else
                selectedValues = val and { val } or {}
            end
            selectedText.Text       = GetDisplayText()
            selectedText.TextColor3 = #selectedValues == 0 and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
            RefreshOptionColors()
            if not silent and callback then
                pcall(callback, multiSelect and selectedValues or selectedValues[1])
            end
        end,

        SetItems = function(newItems)
            items = newItems
            BuildOptions(newItems)
        end,

        SetDisabled = function(state)
            disabled = state
            selector.Active = not state
            selector.BackgroundTransparency = state and 0.5 or 0
            labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        Open  = Open,
        Close = Close,
    }
end

-- Helper internal untuk tutup dari luar
-- Dipertahankan untuk kompatibilitas tapi tidak lagi dipakai dari dalam opsi
function Dropdowns._Close(dropFrame, chevron, isOpenRef, cb)
    if not isOpenRef then return end
    Animations.DropdownClose(dropFrame, cb)
    local ts = game:GetService("TweenService")
    ts:Create(chevron, TweenInfo.new(0.15), { Rotation = 0 }):Play()
end

return Dropdowns
