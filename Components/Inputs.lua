--[[
    BorcaUIHub — Components/Inputs.lua
    Komponen textbox untuk input teks: nama config, search, filter, dll.
    Mendukung validasi, karakter limit, password mode, dan focus styling.
]]

local Inputs = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Inputs.Create(parent, options) → inputObject
    Buat komponen input text.

    @param options {
        Label:        string
        Description:  string   -- opsional
        Placeholder:  string   -- placeholder text
        Default:      string   -- nilai awal
        MaxLength:    number   -- batas karakter
        Password:     boolean  -- sembunyikan teks (• • •)
        NumberOnly:   boolean  -- hanya angka
        Disabled:     boolean
        OnChanged:    function(text: string)
        OnFocused:    function()
        OnUnfocused:  function(text: string, enterPressed: boolean)
        LayoutOrder:  number
    }
    @return inputObject {
        Frame:        Frame
        GetValue:     function → string
        SetValue:     function(string)
        SetDisabled:  function(boolean)
        SetLabel:     function(string)
        Focus:        function()
        ClearInput:   function()
    }
]]
function Inputs.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Input"
    local description = options.Description or ""
    local placeholder = options.Placeholder or "Ketik di sini..."
    local defaultVal  = options.Default     or ""
    local maxLength   = options.MaxLength   or 0        -- 0 = tidak ada batas
    local isPassword  = options.Password    or false
    local numberOnly  = options.NumberOnly  or false
    local disabled    = options.Disabled    or false
    local onChanged   = options.OnChanged
    local onFocused   = options.OnFocused
    local onUnfocused = options.OnUnfocused
    local layoutOrder = options.LayoutOrder or 0

    local showLabel  = label ~= "" and label ~= false
    local showDesc   = description ~= ""
    local inputH     = 36
    local totalH     = inputH
    if showLabel then totalH = totalH + 20 end
    if showDesc  then totalH = totalH + 16 end

    -- ── CONTAINER ──────────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "Input_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, totalH),
        BackgroundTransparency = 1,
        LayoutOrder            = layoutOrder,
    })

    Functions.ApplyListLayout(container, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 4),
    })

    -- ── LABEL ──────────────────────────────────────────────
    local labelText = nil
    if showLabel then
        labelText = Functions.CreateLabel({
            Name      = "InputLabel",
            Parent    = container,
            Text      = label,
            Size      = UDim2.new(1, 0, 0, 16),
            Font      = Config.Font.Body,
            TextSize  = Config.Font.Size.ComponentLabel,
            TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
            ZIndex    = 3,
            LayoutOrder = 0,
        })
    end

    if showDesc then
        Functions.CreateLabel({
            Name      = "InputDesc",
            Parent    = container,
            Text      = description,
            Size      = UDim2.new(1, 0, 0, 13),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
            LayoutOrder = 1,
        })
    end

    -- ── INPUT BOX WRAPPER ──────────────────────────────────
    local inputWrapper = Functions.CreateFrame({
        Name            = "InputWrapper",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, inputH),
        BackgroundColor = Theme.Get("InputBackground"),
        CornerRadius    = Config.UI.ButtonRadius,
        ZIndex          = 3,
        LayoutOrder     = 2,
    })

    local stroke = Functions.ApplyStroke(inputWrapper, {
        Color        = Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.4,
    })

    -- Ikon kiri opsional (search, lock, dll)
    local iconPaddingL = 10
    if options.Icon then
        local iconLbl = Functions.CreateLabel({
            Name      = "InputIcon",
            Parent    = inputWrapper,
            Text      = options.Icon,
            Size      = UDim2.new(0, 24, 1, 0),
            Position  = UDim2.new(0, 8, 0, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 13,
            TextColor = Theme.Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 4,
        })
        iconPaddingL = 34
    end

    -- ── TEXTBOX ────────────────────────────────────────────
    local textBox = Functions.CreateTextBox({
        Name            = "TextInput",
        Parent          = inputWrapper,
        Size            = UDim2.new(1, -(iconPaddingL + (options.RightIcon and 34 or 10)), 1, 0),
        Position        = UDim2.new(0, iconPaddingL, 0, 0),
        PlaceholderText = placeholder,
        Text            = defaultVal,
        Font            = Config.Font.Body,
        TextSize        = Config.Font.Size.ComponentLabel,
        TextColor       = Theme.Get("TextPrimary"),
        BackgroundColor = Theme.Get("InputBackground"),
        BackgroundTransparency = 1,
        ZIndex          = 4,
        MultiLine       = options.MultiLine or false,
    })

    textBox.PlaceholderColor3 = Theme.Get("TextDisabled")

    -- Password masking
    if isPassword then
        -- Simpan teks asli, tampilkan bullet
        local realText = defaultVal
        textBox.Text = string.rep("•", #defaultVal)

        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            -- Sederhana: track perubahan karakter
            local new = textBox.Text
            local bullets = string.rep("•", #new)
            if new ~= bullets then
                -- user menambah karakter baru
                local diff = #new - #realText
                if diff > 0 then
                    realText = realText .. new:sub(#bullets + 1)
                elseif diff < 0 then
                    realText = realText:sub(1, #new)
                end
                textBox.Text = string.rep("•", #realText)
            end
        end)
    end

    -- Karakter limit
    if maxLength > 0 and not isPassword then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            if #textBox.Text > maxLength then
                textBox.Text = textBox.Text:sub(1, maxLength)
            end
        end)
    end

    -- Hanya angka
    if numberOnly and not isPassword then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local filtered = textBox.Text:gsub("[^%d%-%.%,]", "")
            if filtered ~= textBox.Text then
                textBox.Text = filtered
            end
        end)
    end

    -- ── FOCUS STYLING ──────────────────────────────────────
    if not disabled then
        local ts = game:GetService("TweenService")

        textBox.Focused:Connect(function()
            ts:Create(stroke, TweenInfo.new(0.15), {
                Color = Theme.Get("Accent"),
                Transparency = 0.1,
            }):Play()
            ts:Create(inputWrapper, TweenInfo.new(0.15), {
                BackgroundColor3 = Theme.Get("ButtonHover"),
            }):Play()
            if onFocused then pcall(onFocused) end
        end)

        textBox.FocusLost:Connect(function(enterPressed)
            ts:Create(stroke, TweenInfo.new(0.15), {
                Color = Theme.Get("Stroke"),
                Transparency = 0.4,
            }):Play()
            ts:Create(inputWrapper, TweenInfo.new(0.15), {
                BackgroundColor3 = Theme.Get("InputBackground"),
            }):Play()
            if onUnfocused then pcall(onUnfocused, textBox.Text, enterPressed) end
        end)

        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            if onChanged then
                pcall(onChanged, isPassword and "" or textBox.Text)
            end
        end)
    else
        textBox.Interactable = false
        textBox.TextColor3   = Theme.Get("TextDisabled")
        textBox.PlaceholderColor3 = Theme.Get("TextDisabled")
        inputWrapper.BackgroundTransparency = 0.4
    end

    -- Char counter (opsional)
    if maxLength > 0 and not isPassword then
        local counter = Functions.CreateLabel({
            Name      = "CharCounter",
            Parent    = inputWrapper,
            Text      = "0/" .. maxLength,
            Size      = UDim2.new(0, 50, 0, 14),
            Position  = UDim2.new(1, -54, 1, 2),
            AnchorPoint = Vector2.new(0, 0),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint - 1,
            TextColor = Theme.Get("TextDisabled"),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex    = 5,
        })

        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local len = #textBox.Text
            counter.Text = len .. "/" .. maxLength
            counter.TextColor3 = len >= maxLength and Theme.Get("Error") or Theme.Get("TextDisabled")
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        if labelText then
            labelText.TextColor3 = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end
        inputWrapper.BackgroundColor3 = Theme.Get("InputBackground")
        textBox.TextColor3            = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        textBox.PlaceholderColor3     = Theme.Get("TextDisabled")
        stroke.Color                  = Theme.Get("Stroke")
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = container,

        GetValue = function()
            return textBox.Text
        end,

        SetValue = function(val)
            textBox.Text = val or ""
        end,

        SetDisabled = function(state)
            disabled = state
            textBox.Interactable = not state
            textBox.TextColor3   = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
            inputWrapper.BackgroundTransparency = state and 0.4 or 0
            if labelText then
                labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
            end
        end,

        SetLabel = function(newLabel)
            if labelText then labelText.Text = newLabel end
        end,

        Focus = function()
            textBox:CaptureFocus()
        end,

        ClearInput = function()
            textBox.Text = ""
        end,
    }
end

return Inputs
