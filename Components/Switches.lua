--[[
    BorcaUIHub — Components/Switches.lua
    Versi toggle yang lebih modern dan minimalis secara visual.
    Lebih tipis, lebih halus, lebih premium dari toggle biasa.
    Cocok untuk interface yang mengutamakan estetika.
]]

local Switches = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Switches.Create(parent, options) → switchObject
    Buat komponen switch premium.

    @param options {
        Label:        string
        Description:  string   -- opsional, muncul di bawah label
        Default:      boolean
        Variant:      "default" | "slim" | "pill"
        AccentColor:  Color3   -- override warna ON (opsional)
        ShowLabel:    boolean  -- tampilkan ON/OFF teks dalam switch
        Disabled:     boolean
        OnChanged:    function(value: boolean)
        LayoutOrder:  number
    }
    @return switchObject {
        Frame:        Frame
        GetValue:     function → boolean
        SetValue:     function(boolean, silent?)
        SetDisabled:  function(boolean)
        SetLabel:     function(string)
    }
]]
function Switches.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Switch"
    local description = options.Description or ""
    local value       = options.Default     or false
    local variant     = options.Variant     or "default"
    local accentColor = options.AccentColor or Theme.Get("Accent")
    local showLabel   = options.ShowLabel   or false
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0
    local height      = description ~= "" and Config.UI.ComponentHeight + 14 or Config.UI.ComponentHeight

    -- Dimensi berdasarkan variant
    local trackW, trackH, thumbSize
    if variant == "slim" then
        trackW, trackH, thumbSize = 38, 18, 12
    elseif variant == "pill" then
        trackW, trackH, thumbSize = 52, 26, 20
    else
        trackW, trackH, thumbSize = 44, 22, 16
    end

    -- ── CONTAINER ──────────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "Switch_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        LayoutOrder            = layoutOrder,
    })

    -- ── LABEL ──────────────────────────────────────────────
    local labelText = Functions.CreateLabel({
        Name      = "SwitchLabel",
        Parent    = container,
        Text      = label,
        Size      = UDim2.new(1, -(trackW + 16), 0, 16),
        Position  = description ~= "" and UDim2.new(0, 0, 0, 6) or UDim2.new(0, 0, 0.5, -8),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    local descText = nil
    if description ~= "" then
        descText = Functions.CreateLabel({
            Name      = "SwitchDesc",
            Parent    = container,
            Text      = description,
            Size      = UDim2.new(1, -(trackW + 16), 0, 13),
            Position  = UDim2.new(0, 0, 0, 24),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── TRACK ──────────────────────────────────────────────
    local track = Functions.CreateFrame({
        Name            = "SwitchTrack",
        Parent          = container,
        Size            = UDim2.new(0, trackW, 0, trackH),
        Position        = UDim2.new(1, -(trackW + 2), 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = value and accentColor or Theme.Get("ButtonSecondary"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 3,
    })

    -- Gradient halus pada track saat ON
    local gradient = Functions.ApplyGradient(track, {
        Color = value and ColorSequence.new({
            ColorSequenceKeypoint.new(0, Functions.LightenColor(accentColor, 0.08)),
            ColorSequenceKeypoint.new(1, Functions.DarkenColor(accentColor, 0.08)),
        }) or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Get("ButtonSecondary")),
            ColorSequenceKeypoint.new(1, Theme.Get("ButtonActive")),
        }),
        Rotation = 90,
    })

    -- Stroke tipis
    local stroke = Functions.ApplyStroke(track, {
        Color        = value and Functions.DarkenColor(accentColor, 0.1) or Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.5,
    })

    -- ── THUMB ──────────────────────────────────────────────
    local thumbPad = (trackH - thumbSize) / 2
    local thumb = Functions.CreateFrame({
        Name            = "SwitchThumb",
        Parent          = track,
        Size            = UDim2.new(0, thumbSize, 0, thumbSize),
        Position        = value
            and UDim2.new(1, -(thumbSize + thumbPad), 0.5, 0)
            or  UDim2.new(0, thumbPad, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Color3.fromRGB(255, 255, 255),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 4,
    })

    -- Shadow pada thumb
    Functions.ApplyShadow(thumb, {
        Size    = 4,
        Opacity = 0.25,
        Offset  = Vector2.new(0, 2),
    })

    -- ON/OFF label di dalam track (jika showLabel)
    local trackLabelText = nil
    if showLabel then
        trackLabelText = Functions.CreateLabel({
            Name      = "TrackLabel",
            Parent    = track,
            Text      = value and "ON" or "OFF",
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 8,
            TextColor = value and Color3.fromRGB(255, 255, 255) or Theme.Get("TextDisabled"),
            TextXAlignment = value and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            ZIndex    = 4,
        })
        Functions.ApplyPadding(trackLabelText.Parent ~= nil and track or track, {
            Left = 5, Right = 5,
        })
    end

    -- Disabled state
    if disabled then
        track.BackgroundTransparency = 0.5
        thumb.BackgroundTransparency = 0.3
    end

    -- ── STATE ──────────────────────────────────────────────
    local currentValue = value
    local ts = game:GetService("TweenService")

    local function SetValue(newValue, silent)
        currentValue = newValue
        local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        -- Track color
        ts:Create(track, tweenInfo, {
            BackgroundColor3 = newValue and accentColor or Theme.Get("ButtonSecondary"),
        }):Play()

        -- Gradient update
        gradient.Color = newValue and ColorSequence.new({
            ColorSequenceKeypoint.new(0, Functions.LightenColor(accentColor, 0.08)),
            ColorSequenceKeypoint.new(1, Functions.DarkenColor(accentColor, 0.08)),
        }) or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Get("ButtonSecondary")),
            ColorSequenceKeypoint.new(1, Theme.Get("ButtonActive")),
        })

        -- Stroke
        stroke.Color = newValue and Functions.DarkenColor(accentColor, 0.1) or Theme.Get("Stroke")

        -- Thumb position
        ts:Create(thumb, tweenInfo, {
            Position = newValue
                and UDim2.new(1, -(thumbSize + thumbPad), 0.5, 0)
                or  UDim2.new(0, thumbPad, 0.5, 0),
        }):Play()

        -- Label in track
        if trackLabelText then
            trackLabelText.Text = newValue and "ON" or "OFF"
            trackLabelText.TextXAlignment = newValue
                and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
            trackLabelText.TextColor3 = newValue
                and Color3.fromRGB(255, 255, 255) or Theme.Get("TextDisabled")
        end

        if not silent and callback then
            pcall(callback, currentValue)
        end
    end

    -- ── INTERAKSI ──────────────────────────────────────────
    if not disabled then
        -- Klik track atau container
        local function OnSwitch()
            -- Efek "squish" saat diklik
            ts:Create(thumb, TweenInfo.new(0.1), {
                Size = UDim2.new(0, thumbSize + 4, 0, thumbSize - 2),
            }):Play()
            task.delay(0.15, function()
                ts:Create(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, thumbSize, 0, thumbSize),
                }):Play()
            end)

            SetValue(not currentValue)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then OnSwitch() end
        end)
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then OnSwitch() end
        end)

        -- Hover: track slightly brighten
        container.MouseEnter:Connect(function()
            if not currentValue then
                ts:Create(track, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.Get("ButtonHover"),
                }):Play()
            end
        end)
        container.MouseLeave:Connect(function()
            if not currentValue then
                ts:Create(track, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.Get("ButtonSecondary"),
                }):Play()
            end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        if not options.AccentColor then
            accentColor = Theme.Get("Accent")
        end
        labelText.TextColor3 = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        if descText then descText.TextColor3 = Theme.Get("TextSecondary") end
        if not currentValue then
            track.BackgroundColor3 = Theme.Get("ButtonSecondary")
        else
            track.BackgroundColor3 = accentColor
        end
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = container,

        GetValue  = function() return currentValue end,
        SetValue  = SetValue,

        SetDisabled = function(state)
            disabled = state
            track.BackgroundTransparency = state and 0.5 or 0
            thumb.BackgroundTransparency = state and 0.3 or 0
            labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        SetLabel = function(newLabel)
            labelText.Text = newLabel
        end,

        SetAccent = function(color)
            accentColor = color
            if currentValue then track.BackgroundColor3 = color end
        end,
    }
end

return Switches
