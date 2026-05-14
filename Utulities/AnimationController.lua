--[[
    BorcaUIHub — Utilities/AnimationController.lua
    Mengatur seluruh animasi agar tidak saling bentrok.
    Jika terlalu banyak tween jalan bersamaan tanpa kontrol,
    UI bisa terasa patah atau berat. Controller ini menjaga stabilitas.
    Semua animasi bisa dikelola lebih rapi dan tidak spam tween.
]]

local AnimationController = {}

local TweenService = game:GetService("TweenService")
local Config       = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

AnimationController._activeTweens  = {}   -- { [instance] = { [property] = tween } }
AnimationController._groups        = {}   -- { [groupId] = {tweens} }
AnimationController._sequences     = {}   -- animasi berurutan
AnimationController._paused        = false
AnimationController._globalSpeed   = 1.0

-- ============================================================
-- CORE TWEEN MANAGEMENT
-- ============================================================

--[[
    AnimationController.Tween(instance, goals, info, options) → tween
    Buat dan jalankan tween dengan manajemen otomatis.
    Menghentikan tween sebelumnya pada property yang sama jika ada.

    @param instance  GuiObject
    @param goals     table       -- { Property = value, ... }
    @param info      TweenInfo | nil  -- auto-generate dari Config jika nil
    @param options {
        Group:     string   -- ID grup (untuk stop/pause bersama)
        Force:     boolean  -- paksa stop tween lama meski mid-animation
        OnComplete: function
    }
    @return tween
]]
function AnimationController.Tween(instance, goals, info, options)
    if not instance or not instance.Parent then return nil end
    if AnimationController._paused then return nil end

    options = options or {}

    -- Adjust speed
    if not info then
        local dur = (Config.Animation.DefaultDuration or 0.25) / AnimationController._globalSpeed
        info = TweenInfo.new(
            dur,
            Config.Animation.EasingStyle or Enum.EasingStyle.Quart,
            Config.Animation.EasingDirection or Enum.EasingDirection.Out
        )
    end

    -- Stop tweens lama pada property yang sama
    if not AnimationController._activeTweens[instance] then
        AnimationController._activeTweens[instance] = {}
    end

    for prop, _ in pairs(goals) do
        local old = AnimationController._activeTweens[instance][prop]
        if old then
            old:Cancel()
            AnimationController._activeTweens[instance][prop] = nil
        end
    end

    -- Buat tween baru
    local tween = TweenService:Create(instance, info, goals)

    -- Simpan referensi per property
    for prop, _ in pairs(goals) do
        AnimationController._activeTweens[instance][prop] = tween
    end

    -- Callback selesai
    tween.Completed:Connect(function()
        -- Bersihkan referensi
        for prop, _ in pairs(goals) do
            if AnimationController._activeTweens[instance]
            and AnimationController._activeTweens[instance][prop] == tween then
                AnimationController._activeTweens[instance][prop] = nil
            end
        end
        if options.OnComplete then
            pcall(options.OnComplete)
        end
    end)

    -- Daftarkan ke grup
    if options.Group then
        if not AnimationController._groups[options.Group] then
            AnimationController._groups[options.Group] = {}
        end
        table.insert(AnimationController._groups[options.Group], tween)
    end

    tween:Play()
    return tween
end

--[[
    AnimationController.TweenMultiple(targets, info, options) → {tween}
    Jalankan tween pada beberapa instance sekaligus.

    @param targets  { { instance, goals }, ... }
]]
function AnimationController.TweenMultiple(targets, info, options)
    local tweens = {}
    for _, target in ipairs(targets) do
        local t = AnimationController.Tween(target[1], target[2], info, options)
        if t then table.insert(tweens, t) end
    end
    return tweens
end

-- ============================================================
-- STOP / CANCEL
-- ============================================================

--[[
    AnimationController.Stop(instance, property)
    Hentikan tween pada instance (opsional: hanya property tertentu).
]]
function AnimationController.Stop(instance, property)
    if not AnimationController._activeTweens[instance] then return end

    if property then
        local tween = AnimationController._activeTweens[instance][property]
        if tween then
            tween:Cancel()
            AnimationController._activeTweens[instance][property] = nil
        end
    else
        -- Stop semua property pada instance ini
        for prop, tween in pairs(AnimationController._activeTweens[instance]) do
            tween:Cancel()
            AnimationController._activeTweens[instance][prop] = nil
        end
        AnimationController._activeTweens[instance] = nil
    end
end

--[[
    AnimationController.StopGroup(groupId)
    Hentikan semua tween dalam sebuah grup.
]]
function AnimationController.StopGroup(groupId)
    local group = AnimationController._groups[groupId]
    if not group then return end

    for _, tween in ipairs(group) do
        pcall(function() tween:Cancel() end)
    end
    AnimationController._groups[groupId] = {}
end

--[[
    AnimationController.StopAll()
    Hentikan semua tween yang sedang berjalan.
]]
function AnimationController.StopAll()
    for _, props in pairs(AnimationController._activeTweens) do
        for _, tween in pairs(props) do
            pcall(function() tween:Cancel() end)
        end
    end
    AnimationController._activeTweens = {}

    for id, _ in pairs(AnimationController._groups) do
        AnimationController._groups[id] = {}
    end
end

-- ============================================================
-- PAUSE / RESUME
-- ============================================================

--[[
    AnimationController.Pause()
    Pause semua tween aktif dan block tween baru.
]]
function AnimationController.Pause()
    AnimationController._paused = true
    for _, props in pairs(AnimationController._activeTweens) do
        for _, tween in pairs(props) do
            pcall(function() tween:Pause() end)
        end
    end
end

--[[
    AnimationController.Resume()
    Lanjutkan semua tween yang di-pause.
]]
function AnimationController.Resume()
    AnimationController._paused = false
    for _, props in pairs(AnimationController._activeTweens) do
        for _, tween in pairs(props) do
            pcall(function() tween:Play() end)
        end
    end
end

--[[
    AnimationController.IsPaused() → boolean
]]
function AnimationController.IsPaused()
    return AnimationController._paused
end

-- ============================================================
-- SPEED CONTROL
-- ============================================================

--[[
    AnimationController.SetSpeed(multiplier)
    Ubah kecepatan global animasi.
    @param multiplier  number  -- 1.0 = normal, 0.5 = lambat, 2.0 = cepat
]]
function AnimationController.SetSpeed(multiplier)
    AnimationController._globalSpeed = math.max(0.1, multiplier)
    Config.Animation.Speed = AnimationController._globalSpeed
end

--[[
    AnimationController.GetSpeed() → number
]]
function AnimationController.GetSpeed()
    return AnimationController._globalSpeed
end

-- ============================================================
-- SEQUENCES
-- ============================================================

--[[
    AnimationController.Sequence(steps) → { Play, Stop, IsPlaying }
    Buat animasi berurutan (step 1 selesai → step 2 mulai, dst).

    @param steps  { { instance, goals, duration?, delay? }, ... }
]]
function AnimationController.Sequence(steps)
    local seqId  = "seq_" .. tostring(tick()):gsub("%.", "")
    local running = false

    local function Play(onDone)
        if running then return end
        running = true

        task.spawn(function()
            for i, step in ipairs(steps) do
                if not running then break end

                local instance = step[1]
                local goals    = step[2]
                local duration = step[3] or Config.Animation.DefaultDuration
                local delay    = step[4] or 0

                if delay > 0 then
                    task.wait(delay)
                end

                local info = TweenInfo.new(
                    duration / AnimationController._globalSpeed,
                    Config.Animation.EasingStyle,
                    Config.Animation.EasingDirection
                )

                local done = false
                local t = AnimationController.Tween(instance, goals, info, {
                    Group = seqId,
                    OnComplete = function() done = true end,
                })

                -- Tunggu selesai
                local timeout = duration + delay + 1
                local elapsed = 0
                while not done and elapsed < timeout do
                    task.wait(0.05)
                    elapsed += 0.05
                end
            end

            running = false
            if onDone then pcall(onDone) end
        end)
    end

    local function Stop()
        running = false
        AnimationController.StopGroup(seqId)
    end

    local function IsPlaying()
        return running
    end

    local seq = { Play = Play, Stop = Stop, IsPlaying = IsPlaying }
    AnimationController._sequences[seqId] = seq
    return seq
end

-- ============================================================
-- CLEANUP
-- ============================================================

--[[
    AnimationController.CleanupInstance(instance)
    Hapus semua referensi tween untuk instance yang sudah dihapus.
    Dipanggil otomatis saat instance dihancurkan, atau manual.
]]
function AnimationController.CleanupInstance(instance)
    AnimationController.Stop(instance)
    AnimationController._activeTweens[instance] = nil
end

--[[
    AnimationController.CleanupAll()
    Bersihkan semua state (untuk reset total).
]]
function AnimationController.CleanupAll()
    AnimationController.StopAll()
    AnimationController._sequences = {}
end

-- ============================================================
-- STATS
-- ============================================================

--[[
    AnimationController.GetStats() → { activeTweens, groups, sequences }
]]
function AnimationController.GetStats()
    local tweenCount = 0
    for _, props in pairs(AnimationController._activeTweens) do
        for _ in pairs(props) do
            tweenCount += 1
        end
    end

    local groupCount = 0
    for _ in pairs(AnimationController._groups) do groupCount += 1 end

    local seqCount = 0
    for _ in pairs(AnimationController._sequences) do seqCount += 1 end

    return {
        activeTweens = tweenCount,
        groups       = groupCount,
        sequences    = seqCount,
        paused       = AnimationController._paused,
        speed        = AnimationController._globalSpeed,
    }
end

return AnimationController
