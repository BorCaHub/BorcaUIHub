--[[
    BorcaUIHub — Components/ColorPickers.lua
    Komponen pemilih warna dengan palette preset dan input hex.
    Terhubung ke ThemeManager untuk perubahan accent real-time.

    FIX (Fix 9a):
    - SetColor dideklarasikan sebagai local di atas semua UI builder
      SEBELUMNYA: function SetColor(...) → global scope, bisa konflik
                  + forward reference crash karena swatch callback
                  memanggil SetColor sebelum didefinisikan
      SEKARANG:   local SetColor dideklarasikan dulu (forward),
                  lalu diisi body-nya setelah semua UI selesai dibuat
]]

local ColorPickers = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- PRESET PALETTES
-- ============================================================

ColorPickers.Presets = {
    -- Biru
    Color3.fromRGB(100, 160, 255),
    Color3.fromRGB(65, 130, 230),
    Color3.fromRGB(80, 190, 240),
    -- Ungu
    Color3.fromRGB(180, 100, 255),
    Color3.fromRGB(140, 80, 220),
    Color3.fromRGB(200, 130, 255),
    -- Merah / Pink
    Color3.fromRGB(255, 80, 120),
    Color3.fromRGB(220, 60, 100),
    Color3.fromRGB(255, 120, 160),
    -- Hijau
    Color3.fromRGB(80, 200, 120),
    Color3.fromRGB(50, 170, 90),
    Color3.fromRGB(120, 220, 150),
    -- Oranye / Kuning
    Color3.fromRGB(255, 160, 60),
    Color3.fromRGB(240, 190, 50),
    Color3.fromRGB(255, 120, 30),
    -- Putih / Abu
    Color3.fromRGB(220, 220, 235),
    Color3.fromRGB(160, 160, 185),
    Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    ColorPickers.Create(parent, options) → colorPickerObject
    Buat komponen color picker dengan palette dan hex input.

    @param options {
        Label:        string
        Description:  string   -- opsional
        Default:      Color3
        ShowHex:      boolean  -- tampilkan input hex (default true)
        ShowPalette:  boolean  -- tampilkan palette preset (default true)
        Disabled:     boolean
        OnChanged:    function(color: Color3)
        LayoutOrder:  number
    }
    @return colorPickerObject {
        Frame:       Frame
        GetValue:    function → Color3
        SetValue:    function(Color3, silent?)
        SetDisabled: function(boolean)
    }
]]
function ColorPickers.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Color"
    local description = options.Description or ""
    local defaultCol  = options.Default     or Theme.Get("Accent")
    local showHex     = options.ShowHex     ~= false
    local showPalette = options.ShowPalette ~= false
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0

    local currentColor = defaultCol
    local isOpen = false

    -- Hitung tinggi header
    local headerH = description ~= "" and Config.UI.ComponentHeight + 14 or Config.UI.ComponentHeight

    -- ── WRAPPER ────────────────────────────────────────────
    local wrapper = Functions.CreateFrame({
        Name                   = "ColorPicker_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, headerH),
        BackgroundTransparency = 1,
        ClipDescendants        = false,
        LayoutOrder            = layoutOrder,
        ZIndex                 = 3,
    })

    -- ── LABEL ──────────────────────────────────────────────
    local labelText = Functions.CreateLabel({
        Name      = "CPLabel",
        Parent    = wrapper,
        Text      = label,
        Size      = UDim2.new(1, -100, 0, 16),
        Position  = description ~= "" and UDim2.new(0, 0, 0, 6) or UDim2.new(0, 0, 0.5, -8),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    if description ~= "" then
        Functions.CreateLabel({
            Name      = "CPDesc",
            Parent    = wrapper,
            Text      = description,
            Size      = UDim2.new(1, -100, 0, 13),
            Position  = UDim2.new(0, 0, 0, 24),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── COLOR PREVIEW BUTTON ───────────────────────────────
    local previewBtn = Functions.CreateButton({
        Name            = "ColorPreview",
        Parent          = wrapper,
        Size            = UDim2.new(0, 80, 0, 28),
        Position        = UDim2.new(1, -82, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = currentColor,
        CornerRadius    = 6,
        ZIndex          = 4,
        Text            = "",
    })

    Functions.ApplyStroke(previewBtn, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.3,
    })

    -- Teks hex kecil di atas preview
    local hexPreviewLbl = Functions.CreateLabel({
        Name      = "HexPreview",
        Parent    = previewBtn,
        Text      = Functions.ColorToHex(currentColor),
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = 9,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 5,
    })
    hexPreviewLbl.TextStrokeTransparency = 0.4
    hexPreviewLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    -- ── PICKER PANEL ───────────────────────────────────────
    local panelH = 0
    if showPalette then panelH = panelH + 86 end
    if showHex     then panelH = panelH + 44 end

    local pickerPanel = Functions.CreateFrame({
        Name            = "ColorPanel",
        Parent          = wrapper,
        Size            = UDim2.new(1, 0, 0, 0),
        Position        = UDim2.new(0, 0, 0, headerH + 4),
        BackgroundColor = Theme.Get("CardBackground"),
        CornerRadius    = Config.UI.ButtonRadius,
        ClipDescendants = true,
        ZIndex          = 10,
        Visible         = false,
    })

    Functions.ApplyStroke(pickerPanel, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.3,
    })

    Functions.ApplyPadding(pickerPanel, { Top = 8, Bottom = 8, Left = 8, Right = 8 })
    Functions.ApplyListLayout(pickerPanel, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 8),
    })

    -- ============================================================
    -- FIX (Fix 9a): SetColor dideklarasikan sebagai local di sini
    -- SEBELUMNYA: function SetColor(...) → global, bisa bocor + forward ref crash
    -- SEKARANG:   local SetColor dideklarasikan lebih dulu sebagai nil,
    --             lalu diisi setelah semua UI selesai dibuat.
    --             Dengan begitu swatch callback bisa mereferensikannya
    --             tanpa forward reference crash.
    -- ============================================================
    local SetColor

    -- ── PALETTE GRID ───────────────────────────────────────
    local paletteSwatchRefs = {}

    if showPalette then
        local paletteContainer = Functions.CreateFrame({
            Name                   = "Palette",
            Parent                 = pickerPanel,
            Size                   = UDim2.new(1, 0, 0, 72),
            BackgroundTransparency = 1,
            LayoutOrder            = 0,
        })

        local grid = Instance.new("UIGridLayout")
        grid.CellSize        = UDim2.new(0, 24, 0, 24)
        grid.CellPadding     = UDim2.new(0, 4, 0, 4)
        grid.SortOrder       = Enum.SortOrder.LayoutOrder
        grid.Parent          = paletteContainer

        for i, color in ipairs(ColorPickers.Presets) do
            local swatch = Functions.CreateButton({
                Name            = "Swatch_" .. i,
                Parent          = paletteContainer,
                Size            = UDim2.new(0, 24, 0, 24),
                BackgroundColor = color,
                CornerRadius    = 5,
                ZIndex          = 11,
                Text            = "",
                LayoutOrder     = i,
            })

            -- Cek apakah ini warna aktif
            local isActive = color == currentColor
            if isActive then
                Functions.ApplyStroke(swatch, {
                    Color        = Color3.fromRGB(255, 255, 255),
                    Thickness    = 2,
                    Transparency = 0,
                })
            end

            local ts = game:GetService("TweenService")
            swatch.MouseEnter:Connect(function()
                ts:Create(swatch, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 26, 0, 26),
                }):Play()
            end)
            swatch.MouseLeave:Connect(function()
                ts:Create(swatch, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 24, 0, 24),
                }):Play()
            end)

            -- FIX: SetColor dipanggil di sini, tapi karena local SetColor
            -- sudah dideklarasikan di atas (walau belum diisi), Lua
            -- akan mencari nilai saat callback ini dieksekusi (bukan saat
            -- fungsi ini didefinisikan), sehingga tidak crash.
            swatch.MouseButton1Click:Connect(function()
                if disabled then return end
                SetColor(color)
                -- Update stroke semua swatch
                for _, sw in ipairs(paletteSwatchRefs) do
                    local stroke = sw.btn:FindFirstChildOfClass("UIStroke")
                    if sw.color == color then
                        if not stroke then
                            Functions.ApplyStroke(sw.btn, {
                                Color = Color3.fromRGB(255, 255, 255),
                                Thickness = 2, Transparency = 0,
                            })
                        end
                    else
                        if stroke then stroke:Destroy() end
                    end
                end
            end)

            table.insert(paletteSwatchRefs, { btn = swatch, color = color })
        end
    end

    -- ── HEX INPUT ──────────────────────────────────────────
    local hexBox = nil

    if showHex then
        local hexRow = Functions.CreateFrame({
            Name                   = "HexRow",
            Parent                 = pickerPanel,
            Size                   = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder            = 1,
        })

        local hexLayout = Instance.new("UIListLayout")
        hexLayout.FillDirection      = Enum.FillDirection.Horizontal
        hexLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
        hexLayout.SortOrder          = Enum.SortOrder.LayoutOrder
        hexLayout.Padding            = UDim.new(0, 8)
        hexLayout.Parent             = hexRow

        Functions.CreateLabel({
            Name      = "HexHash",
            Parent    = hexRow,
            Text      = "#",
            Size      = UDim2.new(0, 12, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = Config.Font.Size.ComponentLabel,
            TextColor = Theme.Get("Accent"),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 11,
            LayoutOrder = 0,
        })

        hexBox = Functions.CreateTextBox({
            Name            = "HexInput",
            Parent          = hexRow,
            Size            = UDim2.new(1, -70, 1, 0),
            PlaceholderText = "RRGGBB",
            Text            = Functions.ColorToHex(currentColor):sub(2),  -- tanpa #
            Font            = Enum.Font.GothamBold,
            TextSize        = Config.Font.Size.ComponentLabel,
            TextColor       = Theme.Get("TextPrimary"),
            BackgroundColor = Theme.Get("InputBackground"),
            CornerRadius    = 6,
            ZIndex          = 11,
            LayoutOrder     = 1,
        })

        hexBox.FocusLost:Connect(function(enter)
            local hex = hexBox.Text:gsub("[^%x]", ""):upper():sub(1, 6)
            if #hex == 6 then
                local ok, col = pcall(Functions.HexToColor, "#" .. hex)
                if ok then
                    SetColor(col)
                    hexBox.Text = hex
                end
            end
        end)

        -- Tombol apply
        local applyBtn = Functions.CreateButton({
            Name            = "ApplyBtn",
            Parent          = hexRow,
            Size            = UDim2.new(0, 44, 1, 0),
            BackgroundColor = Theme.Get("Accent"),
            CornerRadius    = 6,
            ZIndex          = 11,
            Text            = "Apply",
            Font            = Enum.Font.GothamBold,
            TextSize        = 10,
            TextColor       = Color3.fromRGB(255, 255, 255),
            LayoutOrder     = 2,
        })

        applyBtn.MouseButton1Click:Connect(function()
            local hex = hexBox.Text:gsub("[^%x]", ""):upper():sub(1, 6)
            if #hex == 6 then
                local ok, col = pcall(Functions.HexToColor, "#" .. hex)
                if ok then SetColor(col) end
            end
        end)
    end

    -- ============================================================
    -- FIX (Fix 9a): SetColor diisi SETELAH semua UI dibuat
    -- SEBELUMNYA: function SetColor(...) global di tengah-tengah kode
    -- SEKARANG:   SetColor = function(...) local, diisi di sini
    --             Semua callback di atas yang memanggil SetColor akan
    --             mendapat referensi yang sudah terisi saat dieksekusi
    -- ============================================================
    SetColor = function(color, silent)
        currentColor = color
        previewBtn.BackgroundColor3 = color
        hexPreviewLbl.Text = Functions.ColorToHex(color)
        -- Warna teks kontras
        local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
        hexPreviewLbl.TextColor3 = brightness > 0.6
            and Color3.fromRGB(30, 30, 30)
            or  Color3.fromRGB(255, 255, 255)

        -- Update hex input jika ada
        if hexBox and hexBox.Parent then
            pcall(function()
                hexBox.Text = Functions.ColorToHex(color):sub(2)
            end)
        end

        if not silent and callback then
            pcall(callback, color)
        end
    end

    -- ── TOGGLE PANEL ───────────────────────────────────────
    local function OpenPanel()
        isOpen = true
        wrapper.Size = UDim2.new(1, 0, 0, headerH + panelH + 12)
        Animations.DropdownOpen(pickerPanel, panelH)
        local ts = game:GetService("TweenService")
        ts:Create(previewBtn, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 80, 0, 28),
        }):Play()
    end

    local function ClosePanel()
        isOpen = false
        Animations.DropdownClose(pickerPanel, function()
            wrapper.Size = UDim2.new(1, 0, 0, headerH)
        end)
    end

    if not disabled then
        previewBtn.MouseButton1Click:Connect(function()
            if isOpen then ClosePanel() else OpenPanel() end
        end)

        -- Hover
        local ts = game:GetService("TweenService")
        previewBtn.MouseEnter:Connect(function()
            ts:Create(previewBtn, TweenInfo.new(0.1), {
                Size = UDim2.new(0, 84, 0, 30),
            }):Play()
        end)
        previewBtn.MouseLeave:Connect(function()
            if not isOpen then
                ts:Create(previewBtn, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 80, 0, 28),
                }):Play()
            end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        labelText.TextColor3       = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        pickerPanel.BackgroundColor3 = Theme.Get("CardBackground")
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = wrapper,

        GetValue = function() return currentColor end,

        SetValue = function(color, silent)
            SetColor(color, silent)
            -- Update palette highlights
            for _, sw in ipairs(paletteSwatchRefs) do
                local stroke = sw.btn:FindFirstChildOfClass("UIStroke")
                if sw.color == color then
                    if not stroke then
                        Functions.ApplyStroke(sw.btn, {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2, Transparency = 0,
                        })
                    end
                else
                    if stroke then stroke:Destroy() end
                end
            end
        end,

        SetDisabled = function(state)
            disabled = state
            previewBtn.Active = not state
            previewBtn.BackgroundTransparency = state and 0.5 or 0
            labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        Close = ClosePanel,
    }
end

return ColorPickers
