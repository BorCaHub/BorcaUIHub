--[[
    BorcaUIHub — Components/Toggles.lua
    Komponen toggle ON/OFF untuk mengaktifkan/menonaktifkan fitur.
    Punya indikator visual jelas dan animasi thumb yang halus.
]]

local Toggles = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Toggles.Create(parent, options) → toggleObject
    Buat komponen toggle ON/OFF.

    @param options {
        Id:           string    -- ID unik untuk SaveManager (opsional)
        Label:        string    -- teks label di kiri
        Description:  string    -- teks kecil di bawah label (opsional)
        Default:      boolean   -- nilai awal (default false)
        Disabled:     boolean   -- nonaktifkan interaksi
        OnChanged:    function(value: boolean)
        LayoutOrder:  number
    }
    @return toggleObject {
        Frame:       Frame
        GetValue:    function → boolean
        SetValue:    function(boolean, silent?)
        SetDisabled: function(boolean)
        SetLabel:    function(string)
    }
]]
function Toggles.Create(parent, options)
    options = options or {}

    local label       = options.Label       or "Toggle"
    local description = options.Description or ""
    local value       = options.Default     or false
    local disabled    = options.Disabled    or false
    local callback    = options.OnChanged
    local layoutOrder = options.LayoutOrder or 0
    local height      = description ~= "" and Config.UI.ComponentHeight + 14 or Config.UI.ComponentHeight

    -- ── CONTAINER ──────────────────────────────────────────
    local container = Functions.CreateFrame({
        Name                   = "Toggle_" .. label,
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        LayoutOrder            = layoutOrder,
    })

    -- ── LABEL ──────────────────────────────────────────────
    local labelText = Functions.CreateLabel({
        Name      = "ToggleLabel",
        Parent    = container,
        Text      = label,
        Size      = UDim2.new(1, -70, 0, 18),
        Position  = description ~= "" and UDim2.new(0, 0, 0, 8) or UDim2.new(0, 0, 0.5, -9),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary"),
        ZIndex    = 3,
    })

    local descText = nil
    if description ~= "" then
        descText = Functions.CreateLabel({
            Name      = "ToggleDesc",
            Parent    = container,
            Text      = description,
            Size      = UDim2.new(1, -70, 0, 14),
            Position  = UDim2.new(0, 0, 0, 28),
            Font      = Config.Font.Small,
            TextSize  = Config.Font.Size.ComponentHint,
            TextColor = Theme.Get("TextSecondary"),
            ZIndex    = 3,
        })
    end

    -- ── TRACK ──────────────────────────────────────────────
    local trackW, trackH = 40, 22
    local track = Functions.CreateFrame({
        Name            = "ToggleTrack",
        Parent          = container,
        Size            = UDim2.new(0, trackW, 0, trackH),
        Position        = UDim2.new(1, -trackW, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = value and Theme.Get("ToggleOn") or Theme.Get("ToggleOff"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 3,
    })

    Functions.ApplyStroke(track, {
        Color        = value and Theme.Get("Accent") or Theme.Get("Stroke"),
        Thickness    = 1,
        Transparency = 0.5,
    })

    -- ── THUMB ──────────────────────────────────────────────
    local thumbSize = trackH - 6
    local thumb = Functions.CreateFrame({
        Name            = "ToggleThumb",
        Parent          = track,
        Size            = UDim2.new(0, thumbSize, 0, thumbSize),
        Position        = value
            and UDim2.new(1, -(thumbSize + 3), 0.5, 0)
            or  UDim2.new(0, 3, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("ToggleThumb"),
        CornerRadius    = UDim.new(1, 0),
        ZIndex          = 4,
    })

    -- Efek disabled
    if disabled then
        track.BackgroundTransparency   = 0.5
        thumb.BackgroundTransparency   = 0.4
    end

    -- ── STATE ──────────────────────────────────────────────
    local currentValue = value

    local function SetValue(newValue, silent)
        currentValue = newValue
        if newValue then
            Animations.ToggleOn(track, thumb, Theme.Get("Accent"))
        else
            Animations.ToggleOff(track, thumb)
        end
        -- Update stroke warna
        local stroke = track:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = newValue and Theme.Get("Accent") or Theme.Get("Stroke")
        end
        if not silent and callback then
            pcall(callback, currentValue)
        end
    end

    -- ── INTERAKSI ──────────────────────────────────────────
    if not disabled then
        -- Klik track atau seluruh container
        local function OnToggle()
            SetValue(not currentValue)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                OnToggle()
            end
        end)

        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                OnToggle()
            end
        end)

        -- Hover effect pada track
        local ts = game:GetService("TweenService")
        container.MouseEnter:Connect(function()
            ts:Create(labelText, TweenInfo.new(0.1), {
                TextColor3 = Theme.Get("TextPrimary"),
            }):Play()
        end)
        container.MouseLeave:Connect(function()
            if not disabled then
                ts:Create(labelText, TweenInfo.new(0.1), {
                    TextColor3 = Theme.Get("TextPrimary"),
                }):Play()
            end
        end)
    end

    -- ── THEME UPDATE ───────────────────────────────────────
    Theme.OnChanged(function()
        labelText.TextColor3 = disabled and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        if descText then
            descText.TextColor3 = Theme.Get("TextSecondary")
        end
        if currentValue then
            track.BackgroundColor3 = Theme.Get("ToggleOn")
        else
            track.BackgroundColor3 = Theme.Get("ToggleOff")
        end
        thumb.BackgroundColor3 = Theme.Get("ToggleThumb")
    end)

    -- ── RETURN OBJECT ──────────────────────────────────────
    return {
        Frame = container,

        GetValue = function()
            return currentValue
        end,

        SetValue = SetValue,

        SetDisabled = function(state)
            disabled = state
            container.Active  = not state
            track.BackgroundTransparency = state and 0.5 or 0
            thumb.BackgroundTransparency = state and 0.4 or 0
            labelText.TextColor3 = state and Theme.Get("TextDisabled") or Theme.Get("TextPrimary")
        end,

        SetLabel = function(newLabel)
            labelText.Text = newLabel
        end,
    }
end

--[[
    Toggles.CreateCompact(parent, options) → toggleObject
    Versi ringkas toggle tanpa description, lebih kecil.
    Cocok untuk daftar fitur yang padat.
]]
function Toggles.CreateCompact(parent, options)
    options = options or {}
    options.Description = ""
    return Toggles.Create(parent, options)
end

return Toggles
