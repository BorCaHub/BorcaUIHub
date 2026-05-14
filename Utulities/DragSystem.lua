--[[
    BorcaUIHub — Utilities/DragSystem.lua
    Memungkinkan window digeser dengan mouse.
    Memberikan kebebasan kepada user menempatkan window di posisi yang nyaman.
    Mendukung batas layar agar window tidak keluar dari viewport.

    FIX (Fix 11):
    - Konversi posisi scale → offset tidak lagi pakai task.defer
      SEBELUMNYA: task.defer(function() ... window.AbsolutePosition ... end)
                  → task.defer hanya menunggu SATU frame; kalau UI baru dibuat
                    di frame yang sama, AbsolutePosition masih 0,0
                  → window meloncat ke pojok kiri atas (0,0) saat pertama di-drag
      SEKARANG:   task.spawn dengan loop tunggu AbsoluteSize > 0
                  (AbsoluteSize valid = frame sudah di-render = AbsolutePosition valid)
                  Konversi juga hanya dilakukan jika posisi masih scale-based,
                  tidak menimpa posisi yang sudah offset
]]

local DragSystem = {}

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    DragSystem.Attach(window, handle, options) → dragObject
    Pasang drag system ke sebuah window menggunakan handle tertentu.

    @param window   Frame       -- frame yang akan digeser
    @param handle   GuiObject   -- area yang bisa di-drag (biasanya header)
    @param options {
        BoundToScreen:  boolean  -- batasi agar tidak keluar layar (default true)
        BoundPadding:   number   -- jarak minimal dari tepi layar (pixel, default 10)
        Enabled:        boolean  -- mulai enabled (default true)
        OnDragStart:    function()
        OnDragEnd:      function(finalPos: UDim2)
        OnDragging:     function(delta: Vector2)
    }
    @return dragObject {
        Enable:      function()
        Disable:     function()
        SetBound:    function(boolean)
        ResetPos:    function()
        GetPosition: function → UDim2
        Destroy:     function()
    }
]]
function DragSystem.Attach(window, handle, options)
    options = options or {}

    local boundToScreen = options.BoundToScreen ~= false
    local boundPadding  = options.BoundPadding  or 10
    local enabled       = options.Enabled       ~= false
    local onDragStart   = options.OnDragStart
    local onDragEnd     = options.OnDragEnd
    local onDragging    = options.OnDragging

    -- State drag
    local isDragging    = false
    local dragStartPos  = Vector2.new(0, 0)   -- posisi mouse saat drag mulai
    local frameStartPos = Vector2.new(0, 0)   -- posisi frame saat drag mulai

    local connections = {}

    -- ── Cursor visual feedback ──────────────────────────────
    local function SetGrabCursor(state)
        if state then
            pcall(function() UserInputService.MouseIcon = "rbxasset://textures/DragCursor.png" end)
        else
            pcall(function() UserInputService.MouseIcon = "" end)
        end
    end

    -- ── Hitung posisi yang dibatasi layar ───────────────────
    local function ClampPosition(pos)
        if not boundToScreen then return pos end

        local vp = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)

        local wSize = window.AbsoluteSize
        local minX  = boundPadding
        local minY  = boundPadding
        local maxX  = vp.X - wSize.X - boundPadding
        local maxY  = vp.Y - wSize.Y - boundPadding

        return Vector2.new(
            math.max(minX, math.min(maxX, pos.X)),
            math.max(minY, math.min(maxY, pos.Y))
        )
    end

    -- ── Apply posisi ke frame ───────────────────────────────
    local function ApplyPosition(px, py)
        local clamped = ClampPosition(Vector2.new(px, py))
        window.Position = UDim2.fromOffset(clamped.X, clamped.Y)
        window.AnchorPoint = Vector2.new(0, 0)
    end

    -- ── InputBegan pada handle ──────────────────────────────
    local conn1 = handle.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        isDragging    = true
        dragStartPos  = Vector2.new(input.Position.X, input.Position.Y)
        frameStartPos = Vector2.new(window.AbsolutePosition.X, window.AbsolutePosition.Y)

        SetGrabCursor(true)
        if onDragStart then pcall(onDragStart) end
    end)
    table.insert(connections, conn1)

    -- ── InputChanged global (mouse move) ───────────────────
    local conn2 = UserInputService.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local curPos  = Vector2.new(input.Position.X, input.Position.Y)
        local delta   = curPos - dragStartPos
        local newX    = frameStartPos.X + delta.X
        local newY    = frameStartPos.Y + delta.Y

        ApplyPosition(newX, newY)

        if onDragging then pcall(onDragging, delta) end
    end)
    table.insert(connections, conn2)

    -- ── InputEnded global (mouse release) ──────────────────
    local conn3 = UserInputService.InputEnded:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        isDragging = false
        SetGrabCursor(false)
        if onDragEnd then pcall(onDragEnd, window.Position) end
    end)
    table.insert(connections, conn3)

    -- ── Handle hover cursor ────────────────────────────────
    local conn4 = handle.MouseEnter:Connect(function()
        if enabled and not isDragging then
            pcall(function()
                UserInputService.MouseIcon = "rbxasset://textures/DragCursor.png"
            end)
        end
    end)
    table.insert(connections, conn4)

    local conn5 = handle.MouseLeave:Connect(function()
        if not isDragging then
            pcall(function() UserInputService.MouseIcon = "" end)
        end
    end)
    table.insert(connections, conn5)

    -- ── Inisialisasi posisi (agar anchor = 0,0) ─────────────
    -- FIX (Fix 11): Tidak lagi pakai task.defer yang hanya menunggu 1 frame
    --
    -- SEBELUMNYA:
    --   task.defer(function()
    --       local absX = window.AbsolutePosition.X   -- bisa 0,0 kalau belum render!
    --       local absY = window.AbsolutePosition.Y
    --       window.AnchorPoint = Vector2.new(0, 0)
    --       window.Position    = UDim2.fromOffset(absX, absY)
    --   end)
    --   → Frame baru dibuat di frame yang sama → AbsolutePosition = 0,0
    --   → window.Position = UDim2.fromOffset(0, 0) → window loncat ke pojok kiri atas
    --
    -- SEKARANG:
    --   task.spawn dengan loop tunggu AbsoluteSize.X > 0
    --   AbsoluteSize valid = frame sudah di-layout oleh engine = AbsolutePosition juga valid
    --   Konversi hanya dilakukan jika posisi masih scale-based (ada Scale != 0)
    task.spawn(function()
        -- Tunggu sampai frame benar-benar selesai di-render oleh engine
        -- AbsoluteSize == 0 berarti frame belum di-layout
        local waited = 0
        while window and window.Parent and window.AbsoluteSize.X == 0 do
            task.wait()
            waited += 1
            -- Batas keamanan: tidak menunggu lebih dari ~3 detik (180 frame @ 60fps)
            if waited > 180 then
                break
            end
        end

        -- Cek ulang apakah frame masih ada setelah menunggu
        if not window or not window.Parent then return end

        -- Hanya konversi jika posisi masih scale-based
        -- (Scale != 0 artinya posisi pakai persentase layar, perlu dikonversi ke pixel)
        -- Kalau sudah offset (Scale == 0), tidak perlu diapa-apakan
        local pos = window.Position
        if pos.X.Scale ~= 0 or pos.Y.Scale ~= 0 then
            local absX = window.AbsolutePosition.X
            local absY = window.AbsolutePosition.Y

            -- Validasi: AbsolutePosition harus masuk akal (> 0 atau setidaknya bukan NaN)
            if absX == absX and absY == absY then  -- NaN check: NaN ~= NaN
                window.AnchorPoint = Vector2.new(0, 0)
                window.Position    = UDim2.fromOffset(absX, absY)
            end
        end
    end)

    -- ── Return drag object ──────────────────────────────────
    local dragObj = {}

    function dragObj.Enable()
        enabled = true
    end

    function dragObj.Disable()
        enabled = false
        if isDragging then
            isDragging = false
            SetGrabCursor(false)
        end
    end

    function dragObj.SetBound(state)
        boundToScreen = state
    end

    function dragObj.SetBoundPadding(px)
        boundPadding = px
    end

    function dragObj.ResetPos(centerPos)
        -- Kembalikan ke tengah layar atau posisi yang diberikan
        local vp = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)
        local wSize = window.AbsoluteSize
        local target = centerPos
            or Vector2.new(vp.X / 2 - wSize.X / 2, vp.Y / 2 - wSize.Y / 2)

        local ts = game:GetService("TweenService")
        ts:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(target.X, target.Y),
        }):Play()
    end

    function dragObj.GetPosition()
        return window.Position
    end

    function dragObj.IsDragging()
        return isDragging
    end

    function dragObj.Destroy()
        -- Hentikan drag dulu jika sedang berjalan
        if isDragging then
            isDragging = false
            SetGrabCursor(false)
        end
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
    end

    return dragObj
end

-- ============================================================
-- SIMPLE DRAG (tanpa handle terpisah)
-- ============================================================

--[[
    DragSystem.Simple(frame, options) → dragObject
    Versi sederhana: drag langsung dari seluruh frame (bukan handle).
]]
function DragSystem.Simple(frame, options)
    return DragSystem.Attach(frame, frame, options)
end

return DragSystem
