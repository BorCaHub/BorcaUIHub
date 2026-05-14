--[[
    BorcaUIHub — Components/Keybinds.lua
    Komponen untuk binding tombol keyboard ke fungsi tertentu.
    User bisa klik lalu tekan tombol untuk mengatur keybind.
]]

local Keybinds = {}

local Theme            = require(script.Parent.Parent.UI.Theme)
local Config           = require(script.Parent.Parent.UI.Config)
local Functions        = require(script.Parent.Parent.UI.Functions)
local Animations       = require(script.Parent.Parent.UI.Animations)
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- HELPER
-- ============================================================

-- Konversi KeyCode ke string yang mudah dibaca
local function KeyCodeToString(keyCode)
    if not keyCode then return "None" end
    local name = keyCode.Name
    -- Sederhanakan nama panjang
    local map = {
        LeftShift = "L.Shift", RightShift = "R.Shift",
        LeftControl = "L.Ctrl", RightControl = "R.Ctrl",
        LeftAlt = "L.Alt", RightAlt = "R.Alt",
        Return = "Enter", BackSpace = "Backspace",
        Delete = "Del", Insert = "Ins",
        Home = "Home", End = "End",
        PageUp = "PgUp", PageDown = "PgDn",
    }
    return map[name] or name
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Keybinds.Create(parent, options) → keybindObject
    Buat komponen keybind.

    @param options {
        Label:        string
        Description:  string   -- opsional
        Default:      Enum.KeyCode | nil
        Blacklist:    {Enum.KeyCode}  -- tombol yang tidak diizinkan
        Disabled:     boolean
        OnChanged:    function(keyCode: Enum.KeyCode | nil)
        LayoutOrder:  number
    }
    @return keybindObject {
        Frame:        Frame
        GetValue:     function → Enum.KeyCode | nil
        SetValue:     function(Enum.KeyCode | nil, silent?)
        SetDisabled:  function(boolean)
        SetLabel:     function(string)
    }
]]
function Keybinds.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Keybind"
    local description = options.Description or ""
    local defaultKey  = options.Default
    local blacklist   = options.Blacklist   or {}
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0
    local height      = description ~= "" and Config.UI.ComponentHeight + 14 or Config.UI.ComponentHeight

    local currentKey  = defaultKey
    local isListening = false

    -- ── CONTAINER ──────────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "Keybind_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        LayoutOrder            = layoutOrder,
    })

    -- ── LABEL ──────────────────────────────────────────────
    local labelText = Functions.CreateLabel({
        Name      = "KeybindLabel",
        Parent    = container,
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
            Name      = "KeybindDesc",
            Parent    = container,
            Text      = description,
            Size      = UDim2.new(1, -100, 0, 13),
            Position  = UDim2.new(0, 0, 0, 24),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── KEY BADGE ──────────────────────────────────────────
    local badgeW = 80
    local badge = Functions.CreateButton({
        Name            = "KeyBadge",
        Parent          = container,
        Size            = UDim2.new(0, badgeW, 0, 26),
        Position        = UDim2.new(1, -badgeW, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("ButtonSecondary"),
        CornerRadius    = 6,
        ZIndex          = 4,
        Text            = "",
    })

    Functions.ApplyStroke(badge, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.4,
    })

    local keyLabel = Functions.CreateLabel({
        Name      = "KeyText",
        Parent    = badge,
        Text      = currentKey and KeyCodeToString(currentKey) or "None",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentHint + 1,
        TextColor = currentKey and Theme.Get("Accent") or Theme.Get("TextDisabled"),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 5,
    })

    -- ── STATE FUNCTIONS ────────────────────────────────────
    local inputConnection = nil

    local function StopListening()
        isListening = false
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
        -- Reset visual
        local ts = game:GetService("TweenService")
        ts:Create(badge, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Get("ButtonSecondary"),
        }):Play()
        ts:Create(keyLabel, TweenInfo.new(0.1), {
            TextColor3 = currentKey and Theme.Get("Accent") or Theme.Get("TextDisabled"),
        }):Play()
        keyLabel.Text = currentKey and KeyCodeToString(currentKey) or "None"
    end

    local function StartListening()
        if disabled then return end
        isListening = true
        keyLabel.Text = "..."

        local ts = game:GetService("TweenService")
        ts:Create(badge, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Get("ButtonHover"),
        }):Play()
        ts:Create(keyLabel, TweenInfo.new(0.1), {
            TextColor3 = Theme.Get("Warning"),
        }):Play()

        -- Tangkap input berikutnya
        inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            local inputType = input.UserInputType

            -- Hanya keyboard
            if inputType ~= Enum.UserInputType.Keyboard then
                StopListening()
                return
            end

            local keyCode = input.KeyCode

            -- Escape = batalkan (set ke None)
            if keyCode == Enum.KeyCode.Escape then
                currentKey = nil
                StopListening()
                if callback then pcall(callback, nil) end
                return
            end

            -- Cek blacklist
            for _, bk in ipairs(blacklist) do
                if bk == keyCode then
                    StopListening()
                    return
                end
            end

            currentKey = keyCode
            StopListening()
            if callback then pcall(callback, currentKey) end
        end)
    end

    local function SetValue(keyCode, silent)
        currentKey = keyCode
        keyLabel.Text      = keyCode and KeyCodeToString(keyCode) or "None"
        keyLabel.TextColor3 = keyCode and Theme.Get("Accent") or Theme.Get("TextDisabled")
        if not silent and callback then
            pcall(callback, keyCode)
        end
    end

    -- ── INTERAKSI ──────────────────────────────────────────
    if not disabled then
        badge.MouseButton1Click:Connect(function()
            if isListening then
                StopListening()
            else
                StartListening()
            end
        end)

        -- Klik kanan = reset ke None
        badge.MouseButton2Click:Connect(function()
            if isListening then StopListening() end
            SetValue(nil)
        end)

        -- Hover
        local ts = game:GetService("TweenService")
        badge.MouseEnter:Connect(function()
            if not isListening then
                ts:Create(badge, TweenInfo.new(0.1), {
                    BackgroundColor3 = Theme.Get("ButtonHover"),
                }):Play()
            end
        end)
        badge.MouseLeave:Connect(function()
            if not isListening then
                ts:Create(badge, TweenInfo.new(0.1), {
                    BackgroundColor3 = Theme.Get("ButtonSecondary"),
                }):Play()
            end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        labelText.TextColor3  = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        badge.BackgroundColor3 = isListening and Theme.Get("ButtonHover") or Theme.Get("ButtonSecondary")
        keyLabel.TextColor3   = isListening and Theme.Get("Warning")
            or (currentKey and Theme.Get("Accent") or Theme.Get("TextDisabled"))
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = container,

        GetValue = function() return currentKey end,

        SetValue = SetValue,

        SetDisabled = function(state)
            disabled = state
            if state and isListening then StopListening() end
            badge.Active = not state
            badge.BackgroundTransparency = state and 0.5 or 0
            labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        SetLabel = function(newLabel)
            labelText.Text = newLabel
        end,
    }
end

return Keybinds
