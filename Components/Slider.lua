--[[
    BorcaUIHub — Components/Sliders.lua
    Komponen slider untuk nilai bertingkat: transparansi, skala, FOV, dll.
    Mendukung range kustom, snap ke integer, dan callback realtime.
]]

local Sliders = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Sliders.Create(parent, options) → sliderObject
    Buat komponen slider.

    @param options {
        Label:       string
        Description: string      -- opsional
        Min:         number      -- nilai minimum (default 0)
        Max:         number      -- nilai maksimum (default 100)
        Default:     number      -- nilai awal
        Step:        number      -- langkah snap (nil = bebas)
        Suffix:      string      -- teks di belakang nilai (contoh: "%", "px")
        Decimals:    number      -- jumlah desimal tampilan (default 0)
        Disabled:    boolean
        OnChanged:   function(value: number)
        LayoutOrder: number
    }
    @return sliderObject {
        Frame:       Frame
        GetValue:    function → number
        SetValue:    function(number, silent?)
        SetDisabled: function(boolean)
        SetLabel:    function(string)
    }
]]
function Sliders.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Slider"
    local description = options.Description or ""
    local minVal      = options.Min         or 0
    local maxVal      = options.Max         or 100
    local step        = options.Step
    local suffix      = options.Suffix      or ""
    local decimals    = options.Decimals    or 0
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0

    -- Clamp default
    local defaultVal = Functions.Clamp(options.Default or minVal, minVal, maxVal)

    local height = description ~= "" and Config.UI.ComponentHeight + 20 or Config.UI.ComponentHeight + 8

    -- ── CONTAINER ──────────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "Slider_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        LayoutOrder            = layoutOrder,
    })

    -- ── HEADER ROW (label + nilai) ──────────────────────────
    local labelText = Functions.CreateLabel({
        Name      = "SliderLabel",
        Parent    = container,
        Text      = label,
        Size      = UDim2.new(0.65, 0, 0, 16),
        Position  = UDim2.new(0, 0, 0, 0),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    local valueText = Functions.CreateLabel({
        Name      = "SliderValue",
        Parent    = container,
        Text      = tostring(defaultVal) .. suffix,
        Size      = UDim2.new(0.35, 0, 0, 16),
        Position  = UDim2.new(0.65, 0, 0, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentHint + 1,
        TextColor = Theme.Get("Accent"),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex    = 3,
    })

    if description ~= "" then
        Functions.CreateLabel({
            Name      = "SliderDesc",
            Parent    = container,
            Text      = description,
            Size      = UDim2.new(1, 0, 0, 13),
            Position  = UDim2.new(0, 0, 0, 18),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── TRACK ──────────────────────────────────────────────
    local trackY = description ~= "" and 36 or 22
    local trackH = Config.Slider.TrackHeight

    local trackBg = Functions.CreateFrame({
        Name            = "SliderTrack",
        Parent          = container,
        Size            = UDim2.new(1, 0, 0, trackH),
        Position        = UDim2.new(0, 0, 0, trackY),
        BackgroundColor = Theme.Get("SliderTrack"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 3,
    })

    -- Fill bar
    local initialScale = (defaultVal - minVal) / (maxVal - minVal)
    local fillBar = Functions.CreateFrame({
        Name            = "SliderFill",
        Parent          = trackBg,
        Size            = UDim2.new(initialScale, 0, 1, 0),
        BackgroundColor = disabled and Theme.Get("TextDisabled") or Theme.Get("SliderFill"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 4,
    })

    -- Gradient pada fill
    Functions.ApplyGradient(fillBar, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Get("AccentDim")),
            ColorSequenceKeypoint.new(1, Theme.Get("Accent")),
        }),
        Rotation = 0,
    })

    -- ── THUMB ──────────────────────────────────────────────
    local thumbSize = Config.Slider.ThumbSize
    local thumb = Functions.CreateFrame({
        Name            = "SliderThumb",
        Parent          = trackBg,
        Size            = UDim2.new(0, thumbSize, 0, thumbSize),
        Position        = UDim2.new(initialScale, -thumbSize / 2, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("SliderThumb"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 5,
    })

    Functions.ApplyStroke(thumb, {
        Color        = Theme.Get("Accent"),
        Thickness    = 2,
        Transparency = 0.3,
    })

    if disabled then
        thumb.BackgroundTransparency = 0.5
    end

    -- ── DRAG LOGIC ─────────────────────────────────────────
    local currentValue = defaultVal
    local isDragging   = false

    local function FormatValue(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(math.floor(v + 0.5)) .. suffix
    end

    local function SetValue(newVal, silent)
        newVal = Functions.Clamp(newVal, minVal, maxVal)
        if step then
            newVal = math.floor((newVal - minVal) / step + 0.5) * step + minVal
            newVal = Functions.Clamp(newVal, minVal, maxVal)
        end

        currentValue = newVal
        local scale = (newVal - minVal) / (maxVal - minVal)

        -- Update fill & thumb
        Animations.SliderFill(fillBar, scale)
        local ts = game:GetService("TweenService")
        ts:Create(thumb, TweenInfo.new(0.07), {
            Position = UDim2.new(scale, -thumbSize / 2, 0.5, 0),
        }):Play()

        -- Update label nilai
        valueText.Text = FormatValue(newVal)

        if not silent and callback then
            pcall(callback, currentValue)
        end
    end

    if not disabled then
        local function HandleInput(input)
            if not isDragging then return end
            local trackAbsPos  = trackBg.AbsolutePosition
            local trackAbsSize = trackBg.AbsoluteSize
            local relX = (input.Position.X - trackAbsPos.X) / trackAbsSize.X
            local mapped = minVal + Functions.Clamp(relX, 0, 1) * (maxVal - minVal)
            SetValue(mapped)
        end

        trackBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                HandleInput(input)
            end
        end)

        thumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isDragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                HandleInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end)

        -- Thumb hover scale
        local ts = game:GetService("TweenService")
        thumb.MouseEnter:Connect(function()
            ts:Create(thumb, TweenInfo.new(0.12), {
                Size = UDim2.new(0, thumbSize + 4, 0, thumbSize + 4),
            }):Play()
        end)
        thumb.MouseLeave:Connect(function()
            if not isDragging then
                ts:Create(thumb, TweenInfo.new(0.12), {
                    Size = UDim2.new(0, thumbSize, 0, thumbSize),
                }):Play()
            end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        labelText.TextColor3  = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        valueText.TextColor3  = Theme.Get("Accent")
        trackBg.BackgroundColor3 = Theme.Get("SliderTrack")
        thumb.BackgroundColor3   = Theme.Get("SliderThumb")
        fillBar.BackgroundColor3 = disabled and Theme.Get("TextDisabled") or Theme.Get("SliderFill")

        local gradient = fillBar:FindFirstChildOfClass("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Get("AccentDim")),
                ColorSequenceKeypoint.new(1, Theme.Get("Accent")),
            })
        end
        local stroke = thumb:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = Theme.Get("Accent") end
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = container,

        GetValue = function() return currentValue end,

        SetValue = SetValue,

        SetDisabled = function(state)
            disabled = state
            thumb.BackgroundTransparency = state and 0.5 or 0
            fillBar.BackgroundColor3     = state and Theme.Get("TextDisabled") or Theme.Get("SliderFill")
            labelText.TextColor3         = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        SetLabel = function(newLabel)
            labelText.Text = newLabel
        end,

        SetRange = function(newMin, newMax)
            minVal = newMin
            maxVal = newMax
            SetValue(Functions.Clamp(currentValue, newMin, newMax), true)
        end,
    }
end

return Sliders
