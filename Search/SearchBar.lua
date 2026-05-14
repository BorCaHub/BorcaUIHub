-- // SearchBar.lua
-- // BorcaScriptHub - Search Bar UI Component
-- // Kolom pencarian yang dipasang di atas ContentArea window.
-- // Terhubung ke SearchSystem untuk memfilter tab/section/elemen.

local SearchBar = {}
local Functions, Theme, Config
local UIS = game:GetService("UserInputService")

function SearchBar.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // BUILD SEARCH BAR
-- // Dipanggil sekali saat window dibuat.
-- // Parent = frame di atas ContentArea (bukan di dalam tab).
-- ========================
--[[
options = {
    Parent      = Frame,          -- parent GuiObject (wajib)
    Placeholder = "Cari fitur...",
    OnSearch    = function(text) end,   -- dipanggil setiap ketikan
    OnClear     = function() end,       -- dipanggil saat teks dikosongkan
    OnFocus     = function() end,
    OnUnfocus   = function() end,
}
]]
function SearchBar.Build(options)
    options = options or {}
    local parent      = options.Parent
    local placeholder = options.Placeholder or "Cari fitur..."
    local onSearch    = options.OnSearch    or function(_) end
    local onClear     = options.OnClear     or function() end
    local onFocus     = options.OnFocus     or function() end
    local onUnfocus   = options.OnUnfocus   or function() end

    assert(parent, "[BorcaHub] SearchBar.Build: Parent wajib diisi")

    -- ========================
    -- // CONTAINER
    -- ========================
    local container = Functions.Create("Frame", {
        Name             = "SearchBarContainer",
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Get("SecondaryBG"),
        BorderSizePixel  = 0,
    }, parent)

    -- Bottom divider
    Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Get("Border"),
        BorderSizePixel  = 0,
    }, container)

    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
    }, container)

    -- ========================
    -- // INNER FRAME
    -- ========================
    local inner = Functions.Create("Frame", {
        Name             = "Inner",
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Get("ElementBG"),
        BorderSizePixel  = 0,
    }, container)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, Config.UI.ElementCorner)}, inner)

    local stroke = Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inner)

    -- Search icon
    local searchIcon = Functions.Create("TextLabel", {
        Name                   = "Icon",
        Size                   = UDim2.fromOffset(24, 24),
        Position               = UDim2.fromOffset(6, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text                   = "🔍",
        TextSize               = 12,
        Font                   = Enum.Font.GothamMedium,
        TextXAlignment         = Enum.TextXAlignment.Center,
    }, inner)

    -- TextBox
    local textBox = Functions.Create("TextBox", {
        Name                   = "SearchBox",
        Size                   = UDim2.new(1, -58, 1, 0),
        Position               = UDim2.fromOffset(28, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        PlaceholderText        = placeholder,
        PlaceholderColor3      = Theme.Get("TextDisabled"),
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.FontSize - 1,
        Font                   = Config.UI.Font,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = false,
        BorderSizePixel        = 0,
    }, inner)

    -- Clear button (X) — tersembunyi saat kosong
    local clearBtn = Functions.Create("TextButton", {
        Name             = "ClearBtn",
        Size             = UDim2.fromOffset(20, 20),
        Position         = UDim2.new(1, -24, 0.5, -10),
        BackgroundColor3 = Theme.Get("TertiaryBG"),
        Text             = "✕",
        TextColor3       = Theme.Get("TextMuted"),
        TextSize         = 9,
        Font             = Enum.Font.GothamBold,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
        Visible          = false,
    }, inner)
    Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, clearBtn)

    -- ========================
    -- // EVENTS
    -- ========================
    local currentText = ""

    local function updateClear(text)
        clearBtn.Visible = (text ~= "")
    end

    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local t = textBox.Text or ""
        currentText = t
        updateClear(t)
        if t == "" then
            Functions.SafeCall(onClear)
        else
            Functions.SafeCall(onSearch, t)
        end
    end)

    textBox.Focused:Connect(function()
        Functions.Tween(stroke, {Color = Theme.Get("Accent")}, 0.12)
        Functions.Tween(inner,  {BackgroundColor3 = Theme.Get("HoverBG")}, 0.12)
        Functions.SafeCall(onFocus)
    end)

    textBox.FocusLost:Connect(function()
        Functions.Tween(stroke, {Color = Theme.Get("Border")}, 0.12)
        Functions.Tween(inner,  {BackgroundColor3 = Theme.Get("ElementBG")}, 0.12)
        Functions.SafeCall(onUnfocus)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        textBox.Text = ""
        currentText  = ""
        clearBtn.Visible = false
        Functions.SafeCall(onClear)
        textBox:CaptureFocus()
    end)

    clearBtn.MouseEnter:Connect(function()
        Functions.Tween(clearBtn, {BackgroundColor3 = Theme.Get("Error")}, 0.1)
        Functions.Tween(clearBtn, {TextColor3 = Color3.new(1,1,1)}, 0.1)
    end)
    clearBtn.MouseLeave:Connect(function()
        Functions.Tween(clearBtn, {BackgroundColor3 = Theme.Get("TertiaryBG")}, 0.1)
        Functions.Tween(clearBtn, {TextColor3 = Theme.Get("TextMuted")}, 0.1)
    end)

    -- Ctrl+F shortcut buka search
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.F
        and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            textBox:CaptureFocus()
        end
        -- Escape clear focus
        if inp.KeyCode == Enum.KeyCode.Escape then
            textBox:ReleaseFocus()
        end
    end)

    -- ========================
    -- // SEARCHBAR OBJECT
    -- ========================
    local Bar = {
        Frame   = container,
        TextBox = textBox,
    }

    function Bar:GetText()
        return currentText
    end

    function Bar:SetText(t)
        textBox.Text = tostring(t or "")
    end

    function Bar:Clear()
        textBox.Text = ""
        currentText  = ""
        clearBtn.Visible = false
        Functions.SafeCall(onClear)
    end

    function Bar:Focus()
        textBox:CaptureFocus()
    end

    function Bar:SetPlaceholder(t)
        textBox.PlaceholderText = tostring(t or "")
    end

    function Bar:SetVisible(v)
        container.Visible = v
    end

    function Bar:Destroy()
        container:Destroy()
    end

    return Bar
end

return SearchBar
