--[[
    BorcaUIHub — Utilities/BlurSystem.lua
    Menambahkan efek blur di belakang window utama.
    Membuat tampilan terasa modern dan premium.
    Dikelola secara terpusat agar performa tetap stabil.
]]

local BlurSystem = {}

local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local Config       = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

BlurSystem._blurEffect = nil    -- BlurEffect instance
BlurSystem._enabled    = false
BlurSystem._intensity  = 0
BlurSystem._target     = 0      -- target intensity untuk tween
BlurSystem._originalIntensity = 0  -- simpan blur asli sebelum UI dibuka

-- ============================================================
-- INIT
-- ============================================================

--[[
    BlurSystem.Init(options)
    Inisialisasi sistem blur. Buat atau temukan BlurEffect di Lighting.

    @param options {
        Enabled:   boolean  -- default dari Config.Blur.Enabled
        Intensity: number   -- default dari Config.Blur.Intensity
    }
]]
function BlurSystem.Init(options)
    options = options or {}

    local enabled   = options.Enabled   ~= nil and options.Enabled   or Config.Blur.Enabled
    local intensity = options.Intensity or Config.Blur.Intensity

    -- Simpan blur asli yang mungkin sudah ada di Lighting
    local existing = Lighting:FindFirstChildOfClass("BlurEffect")
    if existing then
        BlurSystem._originalIntensity = existing.Size
        BlurSystem._blurEffect        = existing
    else
        -- Buat blur baru
        local blur = Instance.new("BlurEffect")
        blur.Size   = 0
        blur.Name   = "BorcaBlur"
        blur.Parent = Lighting
        BlurSystem._blurEffect = blur
    end

    BlurSystem._intensity = intensity
    BlurSystem._enabled   = false   -- mulai dari off, Enable() yang mengaktifkan

    if enabled then
        BlurSystem.Enable(true)  -- silent = no tween saat init
    end
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================

--[[
    BlurSystem.Enable(instant)
    Aktifkan blur dengan animasi fade in (atau langsung jika instant=true).
]]
function BlurSystem.Enable(instant)
    if BlurSystem._enabled then return end
    if not BlurSystem._blurEffect then return end

    BlurSystem._enabled = true
    BlurSystem._target  = BlurSystem._intensity

    if instant then
        BlurSystem._blurEffect.Size = BlurSystem._intensity
    else
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(Config.Blur.FadeInDuration or 0.4, Enum.EasingStyle.Quart),
            { Size = BlurSystem._intensity }
        ):Play()
    end
end

--[[
    BlurSystem.Disable(instant)
    Nonaktifkan blur dengan animasi fade out.
]]
function BlurSystem.Disable(instant)
    if not BlurSystem._enabled then return end
    if not BlurSystem._blurEffect then return end

    BlurSystem._enabled = false
    BlurSystem._target  = 0

    if instant then
        BlurSystem._blurEffect.Size = 0
    else
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(Config.Blur.FadeOutDuration or 0.3, Enum.EasingStyle.Quart),
            { Size = 0 }
        ):Play()
    end
end

--[[
    BlurSystem.Toggle()
    Toggle blur on/off.
]]
function BlurSystem.Toggle()
    if BlurSystem._enabled then
        BlurSystem.Disable()
    else
        BlurSystem.Enable()
    end
end

--[[
    BlurSystem.IsEnabled() → boolean
]]
function BlurSystem.IsEnabled()
    return BlurSystem._enabled
end

-- ============================================================
-- INTENSITY
-- ============================================================

--[[
    BlurSystem.SetIntensity(intensity, animate)
    Ubah kekuatan blur.

    @param intensity  number   -- 1-56
    @param animate    boolean  -- pakai tween (default true)
]]
function BlurSystem.SetIntensity(intensity, animate)
    intensity = math.clamp(intensity, 0, 56)
    BlurSystem._intensity = intensity

    if not BlurSystem._blurEffect then return end
    if not BlurSystem._enabled then return end

    if animate ~= false then
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart),
            { Size = intensity }
        ):Play()
    else
        BlurSystem._blurEffect.Size = intensity
    end
end

--[[
    BlurSystem.GetIntensity() → number
]]
function BlurSystem.GetIntensity()
    return BlurSystem._intensity
end

-- ============================================================
-- PULSE EFFECT
-- ============================================================

--[[
    BlurSystem.Pulse(peakIntensity, duration)
    Buat efek blur pulse: intensitas naik lalu kembali normal.
    Berguna untuk feedback visual saat event penting terjadi.

    @param peakIntensity  number  -- intensitas puncak (default 40)
    @param duration       number  -- total durasi pulse (default 0.6s)
]]
function BlurSystem.Pulse(peakIntensity, duration)
    if not BlurSystem._blurEffect then return end

    peakIntensity = peakIntensity or 40
    duration      = duration or 0.6

    local half = duration / 2
    local base = BlurSystem._enabled and BlurSystem._intensity or 0

    -- Naik ke peak
    TweenService:Create(
        BlurSystem._blurEffect,
        TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { Size = peakIntensity }
    ):Play()

    -- Kembali ke base
    task.delay(half, function()
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            { Size = base }
        ):Play()
    end)
end

-- ============================================================
-- FOCUS MODE
-- ============================================================

--[[
    BlurSystem.FocusMode(enable)
    Mode fokus: blur sangat kuat untuk highlight area tertentu.
    Berguna saat modal terbuka.
]]
function BlurSystem.FocusMode(enable)
    if not BlurSystem._blurEffect then return end

    if enable then
        BlurSystem._preFocusSize = BlurSystem._blurEffect.Size
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart),
            { Size = math.min(BlurSystem._intensity + 16, 56) }
        ):Play()
    else
        TweenService:Create(
            BlurSystem._blurEffect,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart),
            { Size = BlurSystem._preFocusSize or BlurSystem._intensity }
        ):Play()
        BlurSystem._preFocusSize = nil
    end
end

-- ============================================================
-- CLEANUP
-- ============================================================

--[[
    BlurSystem.Destroy()
    Matikan blur dan hapus effect (kembalikan ke state sebelum UI).
    Dipanggil saat UI ditutup.
]]
function BlurSystem.Destroy()
    if not BlurSystem._blurEffect then return end

    -- Kembalikan blur ke intensitas asli (bukan 0 jika sudah ada sebelumnya)
    local targetSize = BlurSystem._originalIntensity

    TweenService:Create(
        BlurSystem._blurEffect,
        TweenInfo.new(Config.Blur.FadeOutDuration or 0.3),
        { Size = targetSize }
    ):Play()

    task.delay(Config.Blur.FadeOutDuration + 0.1, function()
        -- Hapus hanya jika kita yang membuat (Name = "BorcaBlur")
        if BlurSystem._blurEffect
        and BlurSystem._blurEffect.Name == "BorcaBlur"
        and BlurSystem._blurEffect.Parent then
            BlurSystem._blurEffect:Destroy()
        end
        BlurSystem._blurEffect = nil
        BlurSystem._enabled    = false
    end)
end

--[[
    BlurSystem.Reset()
    Reset state tanpa menghapus BlurEffect.
]]
function BlurSystem.Reset()
    BlurSystem._enabled   = false
    BlurSystem._intensity = Config.Blur.Intensity
    if BlurSystem._blurEffect then
        BlurSystem._blurEffect.Size = 0
    end
end

-- ============================================================
-- STATUS
-- ============================================================

--[[
    BlurSystem.GetStatus() → table
]]
function BlurSystem.GetStatus()
    return {
        enabled      = BlurSystem._enabled,
        intensity    = BlurSystem._intensity,
        currentSize  = BlurSystem._blurEffect and BlurSystem._blurEffect.Size or 0,
        effectExists = BlurSystem._blurEffect ~= nil,
    }
end

return BlurSystem
