--[[
    BorcaUIHub — UI/Animations.lua
    Semua animasi, transisi, dan efek visual dikelola di sini.
    Tujuan: konsistensi gerakan di seluruh UI, tidak patah-patah.
]]

local Animations = {}

local TweenService = game:GetService("TweenService")
local Config       = require(script.Parent.Config)
local Theme        = require(script.Parent.Theme)

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- Buat TweenInfo dari Config dengan override opsional
local function MakeTweenInfo(duration, style, direction, repeatCount, reverses, delay)
    local speed = Config.Animation.Speed or 1.0
    return TweenInfo.new(
        (duration or Config.Animation.DefaultDuration) / speed,
        style     or Config.Animation.EasingStyle,
        direction or Config.Animation.EasingDirection,
        repeatCount or 0,
        reverses    or false,
        delay       or 0
    )
end

-- Tween dan panggil callback saat selesai
local function TweenAndCallback(instance, info, goals, callback)
    local tween = TweenService:Create(instance, info, goals)
    if callback then
        tween.Completed:Once(function()
            callback()
        end)
    end
    tween:Play()
    return tween
end

-- ============================================================
-- WINDOW ANIMATIONS
-- ============================================================

--[[
    Animations.WindowOpen(frame, targetSize)
    Animasi buka window dari titik kecil ke ukuran penuh.
]]
function Animations.WindowOpen(frame, targetSize)
    if not Config.Animation.Enabled then
        frame.Size = targetSize
        frame.BackgroundTransparency = 0
        return
    end

    frame.Size = UDim2.new(0, targetSize.X.Offset * 0.85, 0, targetSize.Y.Offset * 0.85)
    frame.BackgroundTransparency = 1

    local info = MakeTweenInfo(Config.Animation.WindowOpenDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(frame, info, {
        Size = targetSize,
        BackgroundTransparency = 0,
    }):Play()
end

--[[
    Animations.FadeOut(frame, callback)
    Fade out + shrink window, panggil callback setelah selesai.
]]
function Animations.FadeOut(frame, callback)
    if not Config.Animation.Enabled then
        frame.Visible = false
        if callback then callback() end
        return
    end

    local info = MakeTweenInfo(Config.Animation.WindowCloseDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenAndCallback(frame, info, {
        BackgroundTransparency = 1,
        Size = UDim2.new(
            0, frame.AbsoluteSize.X * 0.9,
            0, frame.AbsoluteSize.Y * 0.9
        ),
    }, callback)

    -- Fade semua children
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            pcall(function()
                TweenService:Create(child, info, { BackgroundTransparency = 1 }):Play()
            end)
        end
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            pcall(function()
                TweenService:Create(child, info, { TextTransparency = 1 }):Play()
            end)
        end
    end
end

--[[
    Animations.FadeIn(frame)
    Fade in window yang sebelumnya disembunyikan.
]]
function Animations.FadeIn(frame)
    frame.Visible = true
    if not Config.Animation.Enabled then
        frame.BackgroundTransparency = 0
        return
    end

    frame.BackgroundTransparency = 1
    local info = MakeTweenInfo(Config.Animation.DefaultDuration)
    TweenService:Create(frame, info, { BackgroundTransparency = 0 }):Play()
end

--[[
    Animations.Minimize(frame, body)
    Animasi minimize: sembunyikan body, kecilkan frame ke header saja.
]]
function Animations.Minimize(frame, body)
    if not Config.Animation.Enabled then
        body.Visible = false
        return
    end

    local info = MakeTweenInfo(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local headerH = Config.UI.HeaderHeight
    TweenAndCallback(frame, info, {
        Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, headerH),
    }, function()
        body.Visible = false
    end)
end

--[[
    Animations.Restore(frame, body, originalSize)
    Animasi restore dari minimize ke ukuran penuh.
]]
function Animations.Restore(frame, body, originalSize)
    body.Visible = true
    if not Config.Animation.Enabled then
        frame.Size = originalSize
        return
    end

    local info = MakeTweenInfo(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(frame, info, { Size = originalSize }):Play()
end

-- ============================================================
-- HOVER EFFECTS
-- ============================================================

--[[
    Animations.ApplyHoverEffect(button, hoverColor, defaultColor)
    Tambahkan hover dan unhover animation ke sebuah tombol/frame.
    
    @param button        GuiObject
    @param hoverColor    Color3  -- warna saat hover
    @param defaultColor  Color3  -- warna default (opsional, ambil dari button)
]]
function Animations.ApplyHoverEffect(button, hoverColor, defaultColor)
    local original = defaultColor or button.BackgroundColor3
    local hInfo    = MakeTweenInfo(Config.Animation.HoverDuration)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, hInfo, { BackgroundColor3 = hoverColor }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, hInfo, { BackgroundColor3 = original }):Play()
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, MakeTweenInfo(0.08), {
            BackgroundColor3 = Theme.Get("ButtonActive"),
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, hInfo, { BackgroundColor3 = hoverColor }):Play()
    end)
end

--[[
    Animations.ApplyScaleHover(frame, scaleAmount)
    Efek scale-up saat hover pada suatu frame (untuk card, ikon, dll).
    
    @param scaleAmount  number  -- berapa pixel tambahan di semua sisi (default 2)
]]
function Animations.ApplyScaleHover(frame, scaleAmount)
    scaleAmount = scaleAmount or 2
    local origSize = frame.Size
    local hoverSize = UDim2.new(
        origSize.X.Scale,
        origSize.X.Offset + scaleAmount * 2,
        origSize.Y.Scale,
        origSize.Y.Offset + scaleAmount * 2
    )
    local origPos = frame.Position
    local hoverPos = UDim2.new(
        origPos.X.Scale,
        origPos.X.Offset - scaleAmount,
        origPos.Y.Scale,
        origPos.Y.Offset - scaleAmount
    )

    local hInfo = MakeTweenInfo(Config.Animation.HoverDuration)

    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, hInfo, { Size = hoverSize, Position = hoverPos }):Play()
    end)

    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, hInfo, { Size = origSize, Position = origPos }):Play()
    end)
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================

--[[
    Animations.SwitchTab(oldContent, newContent)
    Transisi antara dua tab: fade out old, fade in new.
]]
function Animations.SwitchTab(oldContent, newContent)
    if not Config.Animation.Enabled then
        if oldContent then oldContent.Visible = false end
        if newContent then newContent.Visible = true end
        return
    end

    local dur  = Config.Animation.TabSwitchDuration
    local info = MakeTweenInfo(dur * 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    if oldContent and oldContent.Visible then
        TweenAndCallback(oldContent, info, { BackgroundTransparency = 1 }, function()
            oldContent.Visible = false
            oldContent.BackgroundTransparency = 0
        end)
    end

    if newContent then
        newContent.BackgroundTransparency = 1
        newContent.Visible = true
        local inInfo = MakeTweenInfo(dur * 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.delay(dur * 0.3, function()
            TweenService:Create(newContent, inInfo, { BackgroundTransparency = 0 }):Play()
        end)
    end
end

--[[
    Animations.SlideTabIn(content, direction)
    Slide masuk dari kiri atau kanan saat tab berganti.
    
    @param direction  "left" | "right"
]]
function Animations.SlideTabIn(content, direction)
    if not Config.Animation.Enabled then
        content.Visible = true
        content.Position = UDim2.new(0, 0, 0, 0)
        return
    end

    local offsetX = direction == "right" and 30 or -30
    content.Position = UDim2.new(0, offsetX, 0, 0)
    content.BackgroundTransparency = 1
    content.Visible = true

    local info = MakeTweenInfo(Config.Animation.TabSwitchDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(content, info, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0,
    }):Play()
end

-- ============================================================
-- SIDEBAR ITEM ANIMATIONS
-- ============================================================

--[[
    Animations.SidebarItemSelect(item, indicator)
    Animasi saat item sidebar dipilih: highlight + geser indikator.
]]
function Animations.SidebarItemSelect(item, indicator)
    local info = MakeTweenInfo(0.15)
    TweenService:Create(item, info, {
        BackgroundColor3 = Theme.Get("ButtonHover"),
        BackgroundTransparency = 0,
    }):Play()

    if indicator then
        indicator.BackgroundTransparency = 0
        TweenService:Create(indicator, info, {
            Size = UDim2.new(0, Config.Sidebar.ActiveIndicatorWidth, 1, -8),
        }):Play()
    end
end

--[[
    Animations.SidebarItemDeselect(item, indicator)
    Animasi saat item sidebar di-deselect.
]]
function Animations.SidebarItemDeselect(item, indicator)
    local info = MakeTweenInfo(0.15)
    TweenService:Create(item, info, {
        BackgroundTransparency = 1,
    }):Play()

    if indicator then
        TweenService:Create(indicator, info, {
            Size = UDim2.new(0, 0, 1, -8),
        }):Play()
    end
end

-- ============================================================
-- NOTIFICATION ANIMATIONS
-- ============================================================

--[[
    Animations.NotifSlideIn(notif, fromRight)
    Animasi notifikasi masuk dari sisi kanan/kiri.
]]
function Animations.NotifSlideIn(notif, fromRight)
    if not Config.Animation.Enabled then
        notif.Position = UDim2.new(notif.Position.X.Scale, notif.Position.X.Offset, notif.Position.Y.Scale, notif.Position.Y.Offset)
        return
    end

    local offsetX = fromRight ~= false and 320 or -320
    local targetPos = notif.Position
    notif.Position = UDim2.new(
        targetPos.X.Scale,
        targetPos.X.Offset + offsetX,
        targetPos.Y.Scale,
        targetPos.Y.Offset
    )
    notif.BackgroundTransparency = 1

    local info = MakeTweenInfo(Config.Animation.NotifDuration + 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(notif, info, {
        Position = targetPos,
        BackgroundTransparency = 0,
    }):Play()
end

--[[
    Animations.NotifFadeOut(notif, callback)
    Animasi notifikasi menghilang.
]]
function Animations.NotifFadeOut(notif, callback)
    if not Config.Animation.Enabled then
        notif.Visible = false
        if callback then callback() end
        return
    end

    local info = MakeTweenInfo(Config.Animation.NotifDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenAndCallback(notif, info, {
        BackgroundTransparency = 1,
        Position = UDim2.new(
            notif.Position.X.Scale,
            notif.Position.X.Offset + 40,
            notif.Position.Y.Scale,
            notif.Position.Y.Offset
        ),
    }, function()
        notif.Visible = false
        if callback then callback() end
    end)
end

-- ============================================================
-- MODAL ANIMATIONS
-- ============================================================

--[[
    Animations.ModalOpen(overlay, modal)
    Animasi buka modal: dim background + popup modal dari bawah/tengah.
]]
function Animations.ModalOpen(overlay, modal)
    overlay.BackgroundTransparency = 1
    overlay.Visible = true
    modal.Size = UDim2.new(modal.Size.X.Scale, modal.Size.X.Offset, 0, modal.Size.Y.Offset * 0.8)
    modal.BackgroundTransparency = 1

    local dimInfo   = MakeTweenInfo(0.2)
    local modalInfo = MakeTweenInfo(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    TweenService:Create(overlay, dimInfo, {
        BackgroundTransparency = Config.Transparency.ModalDimming,
    }):Play()

    local targetSize = UDim2.new(modal.Size.X.Scale, modal.Size.X.Offset, 0, modal.Size.Y.Offset / 0.8)
    TweenService:Create(modal, modalInfo, {
        Size = targetSize,
        BackgroundTransparency = 0,
    }):Play()
end

--[[
    Animations.ModalClose(overlay, modal, callback)
    Animasi tutup modal.
]]
function Animations.ModalClose(overlay, modal, callback)
    local info = MakeTweenInfo(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    TweenService:Create(overlay, info, { BackgroundTransparency = 1 }):Play()
    TweenAndCallback(modal, info, {
        BackgroundTransparency = 1,
        Size = UDim2.new(modal.Size.X.Scale, modal.Size.X.Offset, 0, modal.Size.Y.Offset * 0.85),
    }, function()
        overlay.Visible = false
        if callback then callback() end
    end)
end

-- ============================================================
-- DROPDOWN ANIMATIONS
-- ============================================================

--[[
    Animations.DropdownOpen(dropFrame, targetHeight)
    Animasi dropdown membuka (expand ke bawah).
]]
function Animations.DropdownOpen(dropFrame, targetHeight)
    dropFrame.ClipDescendants = true
    dropFrame.Size = UDim2.new(dropFrame.Size.X.Scale, dropFrame.Size.X.Offset, 0, 0)
    dropFrame.Visible = true

    local info = MakeTweenInfo(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(dropFrame, info, {
        Size = UDim2.new(dropFrame.Size.X.Scale, dropFrame.Size.X.Offset, 0, targetHeight),
    }):Play()
end

--[[
    Animations.DropdownClose(dropFrame, callback)
    Animasi dropdown menutup (collapse ke atas).
]]
function Animations.DropdownClose(dropFrame, callback)
    local info = MakeTweenInfo(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenAndCallback(dropFrame, info, {
        Size = UDim2.new(dropFrame.Size.X.Scale, dropFrame.Size.X.Offset, 0, 0),
    }, function()
        dropFrame.Visible = false
        if callback then callback() end
    end)
end

-- ============================================================
-- TOGGLE ANIMATIONS
-- ============================================================

--[[
    Animations.ToggleOn(track, thumb, accentColor)
    Animasi toggle menyala.
]]
function Animations.ToggleOn(track, thumb, accentColor)
    local info = MakeTweenInfo(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(track, info, {
        BackgroundColor3 = accentColor or Theme.Get("ToggleOn"),
    }):Play()
    TweenService:Create(thumb, info, {
        Position = UDim2.new(1, -thumb.AbsoluteSize.X - 3, 0.5, 0),
    }):Play()
end

--[[
    Animations.ToggleOff(track, thumb)
    Animasi toggle mati.
]]
function Animations.ToggleOff(track, thumb)
    local info = MakeTweenInfo(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(track, info, {
        BackgroundColor3 = Theme.Get("ToggleOff"),
    }):Play()
    TweenService:Create(thumb, info, {
        Position = UDim2.new(0, 3, 0.5, 0),
    }):Play()
end

-- ============================================================
-- SLIDER ANIMATIONS
-- ============================================================

--[[
    Animations.SliderFill(fillBar, targetScale)
    Animasi fill slider bergerak halus ke posisi baru.
    
    @param targetScale  number  -- 0 sampai 1
]]
function Animations.SliderFill(fillBar, targetScale)
    local info = MakeTweenInfo(0.1, Enum.EasingStyle.Linear)
    TweenService:Create(fillBar, info, {
        Size = UDim2.new(targetScale, 0, 1, 0),
    }):Play()
end

-- ============================================================
-- LOADING / SPINNER
-- ============================================================

--[[
    Animations.StartSpinner(spinFrame)
    Mulai rotasi terus-menerus pada sebuah frame (loading spinner).
    Returns a stop function.
]]
function Animations.StartSpinner(spinFrame)
    local running = true
    local angle = 0

    task.spawn(function()
        while running and spinFrame and spinFrame.Parent do
            angle = (angle + 6) % 360
            spinFrame.Rotation = angle
            task.wait(1 / 60)
        end
    end)

    return function()
        running = false
    end
end

--[[
    Animations.LoadingPulse(frame)
    Efek pulse (scale in-out) untuk elemen loading.
    Returns a stop function.
]]
function Animations.LoadingPulse(frame)
    local running = true
    local info1 = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local info2 = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    task.spawn(function()
        while running and frame and frame.Parent do
            TweenService:Create(frame, info1, { BackgroundTransparency = 0.3 }):Play()
            task.wait(0.6)
            if not running then break end
            TweenService:Create(frame, info2, { BackgroundTransparency = 0 }):Play()
            task.wait(0.6)
        end
    end)

    return function()
        running = false
    end
end

-- ============================================================
-- TOOLTIP ANIMATION
-- ============================================================

--[[
    Animations.TooltipShow(tooltip)
    Animasi tooltip muncul.
]]
function Animations.TooltipShow(tooltip)
    tooltip.BackgroundTransparency = 1
    tooltip.Visible = true
    local info = MakeTweenInfo(0.12)
    TweenService:Create(tooltip, info, { BackgroundTransparency = 0 }):Play()
end

--[[
    Animations.TooltipHide(tooltip)
    Animasi tooltip menghilang.
]]
function Animations.TooltipHide(tooltip)
    local info = MakeTweenInfo(0.1)
    TweenAndCallback(tooltip, info, { BackgroundTransparency = 1 }, function()
        tooltip.Visible = false
    end)
end

-- ============================================================
-- GENERAL TWEEN SHORTCUT
-- ============================================================

--[[
    Animations.Tween(instance, goals, duration, style, direction) → Tween
    Shortcut umum untuk membuat dan memainkan tween.
]]
function Animations.Tween(instance, goals, duration, style, direction)
    local info = MakeTweenInfo(duration, style, direction)
    local tween = TweenService:Create(instance, info, goals)
    tween:Play()
    return tween
end

--[[
    Animations.TweenCallback(instance, goals, duration, callback) → Tween
    Tween dengan callback setelah selesai.
]]
function Animations.TweenCallback(instance, goals, duration, callback)
    local info = MakeTweenInfo(duration)
    return TweenAndCallback(instance, info, goals, callback)
end

return Animations
