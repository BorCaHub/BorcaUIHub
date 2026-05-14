-- // Notifications.lua
-- // BorcaScriptHub - Notification System
-- // No fullscreen overlay; uses a narrow side-panel ScreenGui
-- // Parented safely with Functions.ParentGui

local Notifications = {}
local Functions, Theme, Config

function Notifications.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // STATE
-- ========================
local notifGui    = nil
local notifHolder = nil
local activeNotifs = {}

local TYPE_ACCENT = {
    Success = "Success",
    Warning = "Warning",
    Error   = "Error",
    Info    = "Info",
    Default = "Accent",
}

-- ========================
-- // ENSURE GUI (created once)
-- ========================
local function ensureGui()
    if notifGui and notifGui.Parent then return end

    notifGui = Instance.new("ScreenGui")
    notifGui.Name           = "BorcaNotifications"
    notifGui.ResetOnSpawn   = false
    notifGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder   = 9999
    notifGui.IgnoreGuiInset = true

    if type(Functions.ParentGui) == "function" then
        Functions.ParentGui(notifGui)
    else
        local ok = pcall(function()
            notifGui.Parent = game:GetService("CoreGui")
        end)
        if not ok then
            notifGui.Parent = game:GetService("Players").LocalPlayer
                :WaitForChild("PlayerGui")
        end
    end

    local W = Config.Notification.Width

    notifHolder = Functions.Create("Frame", {
        Name             = "NotifHolder",
        Size             = UDim2.fromOffset(W, 0),
        Position         = UDim2.new(
            1, -(W + Config.Notification.RightOffset),
            1, -Config.Notification.BottomOffset
        ),
        AnchorPoint      = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.Y,
    }, notifGui)

    Functions.Create("UIListLayout", {
        FillDirection     = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, Config.Notification.Padding),
    }, notifHolder)
end

-- ========================
-- // SEND NOTIFICATION
-- ========================
function Notifications.Send(options)
    options = options or {}
    local title    = tostring(options.Title   or "Notification")
    local content  = tostring(options.Content or "")
    local nType    = tostring(options.Type    or "Default")
    local duration = tonumber(options.Duration) or Config.Notification.Duration

    ensureGui()

    local W          = Config.Notification.Width
    local accentKey  = TYPE_ACCENT[nType] or "Accent"
    local accentColor = Theme.Get(accentKey)

    local notifFrame = Functions.Create("Frame", {
        Name             = "Notif_" .. title:sub(1, 16),
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Get("NotifyBackground"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
    }, notifHolder)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 8)}, notifFrame)
    Functions.Create("UIStroke", {
        Color           = Theme.Get("Border"),
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, notifFrame)

    -- Left accent bar
    local accentBar = Functions.Create("Frame", {
        Size             = UDim2.fromOffset(3, 0),
        Position         = UDim2.fromScale(0, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
    }, notifFrame)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 4)}, accentBar)

    local contentFrame = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, notifFrame)
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 9),
        PaddingBottom = UDim.new(0, 9),
        PaddingLeft   = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 10),
    }, contentFrame)
    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 3),
    }, contentFrame)

    -- Type badge
    local badge = Functions.Create("TextLabel", {
        Size                  = UDim2.new(0, 0, 0, 14),
        AutomaticSize         = Enum.AutomaticSize.X,
        BackgroundColor3      = accentColor,
        BackgroundTransparency = 0.72,
        Text                  = " " .. nType .. " ",
        TextColor3            = accentColor,
        TextSize              = 9,
        Font                  = Enum.Font.GothamBold,
        LayoutOrder           = 1,
    }, contentFrame)
    Functions.Create("UICorner", {CornerRadius = UDim.new(0, 3)}, badge)

    -- Title
    Functions.Create("TextLabel", {
        Size                  = UDim2.new(1, 0, 0, 0),
        AutomaticSize         = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text                  = title,
        TextColor3            = Theme.Get("TextPrimary"),
        TextSize              = Config.UI.FontSize,
        Font                  = Config.UI.TitleFont,
        TextXAlignment        = Enum.TextXAlignment.Left,
        TextWrapped           = true,
        LayoutOrder           = 2,
    }, contentFrame)

    -- Body
    if content ~= "" then
        Functions.Create("TextLabel", {
            Size                  = UDim2.new(1, 0, 0, 0),
            AutomaticSize         = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text                  = content,
            TextColor3            = Theme.Get("TextSecondary"),
            TextSize              = Config.UI.FontSize - 2,
            Font                  = Config.UI.SmallFont,
            TextXAlignment        = Enum.TextXAlignment.Left,
            TextWrapped           = true,
            LayoutOrder           = 3,
        }, contentFrame)
    end

    -- Progress bar
    local progressBar = Functions.Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, notifFrame)

    -- Animate in
    notifFrame.Position = UDim2.fromOffset(W + 10, 0)
    Functions.Tween(notifFrame, {BackgroundTransparency = 0},        Config.Notification.AnimDuration)
    Functions.Tween(notifFrame, {Position = UDim2.fromOffset(0, 0)}, Config.Notification.AnimDuration)

    table.insert(activeNotifs, notifFrame)

    -- Auto dismiss
    task.spawn(function()
        Functions.Tween(progressBar,
            {Size = UDim2.new(0, 0, 0, 2)},
            duration,
            Enum.EasingStyle.Linear
        )
        task.wait(duration)

        Functions.Tween(notifFrame, {
            BackgroundTransparency = 1,
            Position               = UDim2.fromOffset(W + 10, 0),
        }, Config.Notification.AnimDuration)
        task.wait(Config.Notification.AnimDuration + 0.05)

        if notifFrame and notifFrame.Parent then
            notifFrame:Destroy()
        end
        Functions.TableRemove(activeNotifs, notifFrame)
    end)

    -- Click to dismiss
    notifFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Functions.Tween(notifFrame, {
                BackgroundTransparency = 1,
                Position               = UDim2.fromOffset(W + 10, 0),
            }, 0.15)
            task.delay(0.18, function()
                if notifFrame and notifFrame.Parent then
                    notifFrame:Destroy()
                end
                Functions.TableRemove(activeNotifs, notifFrame)
            end)
        end
    end)
end

-- ========================
-- // SHORTHAND SENDERS
-- ========================
function Notifications.Success(title, content, duration)
    Notifications.Send({Title=title, Content=content, Type="Success", Duration=duration})
end
function Notifications.Warning(title, content, duration)
    Notifications.Send({Title=title, Content=content, Type="Warning", Duration=duration})
end
function Notifications.Error(title, content, duration)
    Notifications.Send({Title=title, Content=content, Type="Error", Duration=duration})
end
function Notifications.Info(title, content, duration)
    Notifications.Send({Title=title, Content=content, Type="Info", Duration=duration})
end

function Notifications.ClearAll()
    for _, n in ipairs(activeNotifs) do
        pcall(function() n:Destroy() end)
    end
    activeNotifs = {}
end

return Notifications
