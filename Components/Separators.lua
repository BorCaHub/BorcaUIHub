-- // Separators.lua
-- // BorcaScriptHub - Separator Component
-- // Garis pemisah antar bagian untuk keterbacaan dan kerapian layout.
-- // Mendukung: line biasa, label di tengah, dengan icon, dan spacing saja.

local Separators = {}
local Functions, Theme, Config

function Separators.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // CREATE SEPARATOR
-- ========================
--[[
options = {
    -- Style
    Type      = "Line",        -- "Line" | "LabelLine" | "IconLine" | "Spacer"
    Label     = "",            -- teks di tengah (untuk LabelLine)
    Icon      = "",            -- emoji/char (untuk IconLine)
    Thickness = 1,             -- ketebalan garis (1-3, default 1)
    Color     = nil,           -- Color3 override (default Theme.Border)
    Spacing   = 6,             -- jarak atas & bawah container

    Order     = nil,
}

Tipe:
  "Line"       = garis horizontal tipis penuh
  "LabelLine"  = garis dengan teks di tengah (garis — LABEL — garis)
  "IconLine"   = seperti LabelLine tapi dengan icon + teks
  "Spacer"     = hanya ruang kosong tanpa garis (pure spacing)
]]
function Separators.CreateSeparator(section, options)
    options = options or {}

    local sepType   = options.Type      or "Line"
    local label     = options.Label     or ""
    local icon      = options.Icon      or ""
    local thickness = math.clamp(tonumber(options.Thickness) or 1, 1, 3)
    local color     = options.Color     or Theme.Get("Divider")
    local spacing   = math.max(tonumber(options.Spacing) or 6, 0)
    local order     = options.Order     or #section.Elements + 1

    -- ========================
    -- // SPACER ONLY
    -- ========================
    if sepType == "Spacer" then
        local spacer = Functions.Create("Frame", {
            Name             = "Spacer_" .. order,
            Size             = UDim2.new(1, 0, 0, spacing * 2),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
        }, section.ContentHolder)

        local Sep = { Name = "Spacer", Frame = spacer }
        function Sep:SetVisible(v) spacer.Visible = v end
        function Sep:Destroy()
            spacer:Destroy()
            Functions.TableRemove(section.Elements, self)
        end
        table.insert(section.Elements, Sep)
        return Sep
    end

    -- ========================
    -- // CONTAINER
    -- ========================
    local containerH = thickness + spacing * 2
    if sepType == "LabelLine" or sepType == "IconLine" then
        containerH = 18 + spacing * 2
    end

    local container = Functions.Create("Frame", {
        Name             = "Sep_" .. order,
        Size             = UDim2.new(1, 0, 0, containerH),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = order,
    }, section.ContentHolder)

    -- ========================
    -- // PLAIN LINE
    -- ========================
    if sepType == "Line" then
        Functions.Create("Frame", {
            Name             = "Line",
            Size             = UDim2.new(1, 0, 0, thickness),
            Position         = UDim2.new(0, 0, 0.5, -math.floor(thickness / 2)),
            AnchorPoint      = Vector2.new(0, 0),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
        }, container)
        Functions.Create("UICorner", {
            CornerRadius = UDim.new(1, 0)
        }, container:FindFirstChild("Line"))
    end

    -- ========================
    -- // LABEL LINE  (garis — teks — garis)
    -- ========================
    if sepType == "LabelLine" or sepType == "IconLine" then
        local midY    = containerH / 2
        local lineY   = midY - math.floor(thickness / 2)

        -- Kiri
        local lineLeft = Functions.Create("Frame", {
            Name             = "LineLeft",
            Size             = UDim2.new(0.5, -60, 0, thickness),
            Position         = UDim2.new(0, 0, 0.5, -math.floor(thickness / 2)),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
        }, container)
        Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, lineLeft)

        -- Kanan
        local lineRight = Functions.Create("Frame", {
            Name             = "LineRight",
            Size             = UDim2.new(0.5, -60, 0, thickness),
            Position         = UDim2.new(0.5, 60, 0.5, -math.floor(thickness / 2)),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
        }, container)
        Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, lineRight)

        -- Tengah: icon + label
        local hasIcon = sepType == "IconLine" and icon ~= ""
        local textStr = hasIcon and (icon .. "  " .. label) or label

        Functions.Create("TextLabel", {
            Name                   = "CenterLabel",
            Size                   = UDim2.fromOffset(114, 18),
            Position               = UDim2.new(0.5, -57, 0.5, -9),
            BackgroundTransparency = 1,
            Text                   = textStr,
            TextColor3             = Theme.Get("TextMuted"),
            TextSize               = 9,
            Font                   = Enum.Font.GothamBold,
            TextXAlignment         = Enum.TextXAlignment.Center,
        }, container)
    end

    -- ========================
    -- // SEPARATOR OBJECT
    -- ========================
    local Sep = {
        Name  = "Separator",
        Frame = container,
        Type  = sepType,
    }

    function Sep:SetColor(c)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") then
                child.BackgroundColor3 = c
            end
        end
    end

    function Sep:SetVisible(v)
        container.Visible = v
    end

    function Sep:Destroy()
        container:Destroy()
        Functions.TableRemove(section.Elements, self)
    end

    table.insert(section.Elements, Sep)
    return Sep
end

return Separators
