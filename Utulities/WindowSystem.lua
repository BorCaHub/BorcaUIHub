--[[
    BorcaUIHub — Utilities/WindowSystem.lua
    Mengatur perilaku window secara umum.
    Mencakup: minimize, maximize, close, restore, snap, dan state persistence.
    Membuat UI terasa seperti software yang matang, bukan sekadar panel statis.
]]

local WindowSystem = {}

local TweenService = game:GetService("TweenService")
local Animations   = require(script.Parent.Parent.UI.Animations)
local Config       = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

WindowSystem._windows = {}   -- { [windowId] = windowState }
WindowSystem._activeWindow = nil

-- ============================================================
-- REGISTER WINDOW
-- ============================================================

--[[
    WindowSystem.Register(id, windowObject, options) → windowController
    Daftarkan window ke sistem dan kembalikan controller.

    @param id            string
    @param windowObject  table  -- dari Main.CreateWindow
    @param options {
        MinSize:  Vector2
        MaxSize:  Vector2
        Resizable: boolean
    }
    @return windowController {
        Minimize, Restore, Maximize, Close,
        SetVisible, GetState, Focus,
        IsMinimized, IsMaximized, IsClosed,
        OnStateChanged
    }
]]
function WindowSystem.Register(id, windowObject, options)
    options = options or {}

    local frame       = windowObject.Window
    local body        = windowObject.Body
    local screenGui   = windowObject.ScreenGui

    -- Simpan ukuran asli
    local originalSize = frame.AbsoluteSize
    local originalPos  = frame.AbsolutePosition

    local state = {
        id          = id,
        window      = windowObject,
        frame       = frame,
        minimized   = false,
        maximized   = false,
        closed      = false,
        visible     = true,
        originalSize = UDim2.fromOffset(originalSize.X, originalSize.Y),
        originalPos  = UDim2.fromOffset(originalPos.X, originalPos.Y),
        minSize     = options.MinSize or Vector2.new(Config.Window.MinSize.X, Config.Window.MinSize.Y),
        maxSize     = options.MaxSize or Vector2.new(Config.Window.MaxSize.X, Config.Window.MaxSize.Y),
        resizable   = options.Resizable or Config.Window.Resizable or false,
        listeners   = {},
    }

    WindowSystem._windows[id] = state

    -- ── Controller ─────────────────────────────────────────
    local ctrl = {}

    -- MINIMIZE
    function ctrl.Minimize()
        if state.minimized or state.closed then return end
        state.minimized = true

        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(frame, info, {
            Size = UDim2.new(0, frame.AbsoluteSize.X, 0, Config.UI.HeaderHeight),
        }):Play()
        task.delay(0.2, function()
            if body then body.Visible = false end
        end)

        WindowSystem._Notify(state, "minimized")
    end

    -- RESTORE
    function ctrl.Restore()
        if state.closed then return end
        state.minimized = false
        state.maximized = false

        if body then body.Visible = true end

        local info = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(frame, info, { Size = state.originalSize }):Play()

        WindowSystem._Notify(state, "restored")
    end

    -- MAXIMIZE
    function ctrl.Maximize()
        if state.closed then return end

        if state.maximized then
            ctrl.Restore()
            return
        end

        -- Simpan posisi/ukuran sebelum maximize
        state.preMaxSize = frame.AbsoluteSize
        state.preMaxPos  = frame.AbsolutePosition

        state.maximized = true

        local vp = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)

        local info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(frame, info, {
            Size     = UDim2.fromOffset(vp.X - 20, vp.Y - 20),
            Position = UDim2.fromOffset(10, 10),
        }):Play()

        frame.AnchorPoint = Vector2.new(0, 0)

        WindowSystem._Notify(state, "maximized")
    end

    -- CLOSE
    function ctrl.Close(callback)
        if state.closed then return end
        state.closed = true

        Animations.FadeOut(frame, function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            WindowSystem._windows[id] = nil
            WindowSystem._Notify(state, "closed")
            if callback then pcall(callback) end
        end)
    end

    -- SET VISIBLE
    function ctrl.SetVisible(visible)
        if state.closed then return end
        state.visible = visible
        if visible then
            Animations.FadeIn(frame)
        else
            Animations.FadeOut(frame)
        end
        WindowSystem._Notify(state, visible and "shown" or "hidden")
    end

    -- TOGGLE VISIBILITY
    function ctrl.Toggle()
        ctrl.SetVisible(not state.visible)
    end

    -- FOCUS (bring to front via ZIndex)
    function ctrl.Focus()
        if screenGui then
            screenGui.DisplayOrder = Config.Window.DisplayOrder + 10
        end
        WindowSystem._activeWindow = id
        WindowSystem._Notify(state, "focused")
    end

    -- GETTERS
    function ctrl.GetState()    return state end
    function ctrl.IsMinimized() return state.minimized end
    function ctrl.IsMaximized() return state.maximized end
    function ctrl.IsClosed()    return state.closed end
    function ctrl.IsVisible()   return state.visible end

    -- ON STATE CHANGED
    function ctrl.OnStateChanged(callback)
        table.insert(state.listeners, callback)
        return function()
            for i, cb in ipairs(state.listeners) do
                if cb == callback then
                    table.remove(state.listeners, i)
                    break
                end
            end
        end
    end

    -- RESIZE (jika resizable)
    function ctrl.SetSize(newSize, animate)
        if state.closed then return end
        -- Clamp ke min/max
        local w = math.clamp(newSize.X, state.minSize.X, state.maxSize.X)
        local h = math.clamp(newSize.Y, state.minSize.Y, state.maxSize.Y)
        local target = UDim2.fromOffset(w, h)

        if animate then
            local info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            TweenService:Create(frame, info, { Size = target }):Play()
        else
            frame.Size = target
        end

        state.originalSize = target
    end

    -- SNAP TO CORNER
    function ctrl.Snap(corner)
        if state.closed then return end
        local vp = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)
        local wSize = frame.AbsoluteSize
        local pad   = 20

        local positions = {
            TopLeft     = Vector2.new(pad, pad),
            TopRight    = Vector2.new(vp.X - wSize.X - pad, pad),
            BottomLeft  = Vector2.new(pad, vp.Y - wSize.Y - pad),
            BottomRight = Vector2.new(vp.X - wSize.X - pad, vp.Y - wSize.Y - pad),
            Center      = Vector2.new(vp.X / 2 - wSize.X / 2, vp.Y / 2 - wSize.Y / 2),
        }

        local target = positions[corner] or positions.Center
        local info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        frame.AnchorPoint = Vector2.new(0, 0)
        TweenService:Create(frame, info, {
            Position = UDim2.fromOffset(target.X, target.Y),
        }):Play()
    end

    return ctrl
end

-- ============================================================
-- INTERNAL
-- ============================================================

function WindowSystem._Notify(state, eventName)
    for _, cb in ipairs(state.listeners) do
        pcall(cb, eventName, state)
    end
end

-- ============================================================
-- GLOBAL API
-- ============================================================

--[[
    WindowSystem.Get(id) → windowState | nil
]]
function WindowSystem.Get(id)
    return WindowSystem._windows[id]
end

--[[
    WindowSystem.GetAll() → {windowState}
]]
function WindowSystem.GetAll()
    local result = {}
    for _, state in pairs(WindowSystem._windows) do
        table.insert(result, state)
    end
    return result
end

--[[
    WindowSystem.CloseAll()
    Tutup semua window yang terdaftar.
]]
function WindowSystem.CloseAll()
    for id, state in pairs(WindowSystem._windows) do
        if not state.closed and state.window then
            local frame = state.frame
            if frame and frame.Parent then
                Animations.FadeOut(frame, function()
                    local sg = state.window.ScreenGui
                    if sg and sg.Parent then sg:Destroy() end
                end)
            end
            WindowSystem._windows[id] = nil
        end
    end
end

--[[
    WindowSystem.GetActive() → string | nil
    ID window yang sedang aktif.
]]
function WindowSystem.GetActive()
    return WindowSystem._activeWindow
end

return WindowSystem
