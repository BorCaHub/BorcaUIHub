--[[
    BorcaUIHub — Managers/FeedbackManager.lua
    Mengatur semua alur feedback dari pengguna.
    Menerima data dari UI feedback, memvalidasi isinya,
    lalu meneruskannya ke sistem pengiriman (FeedbackSender).
    Memisahkan bug report dan suggestion agar data lebih terstruktur.
]]

local FeedbackManager = {}

-- ============================================================
-- STATE
-- ============================================================

FeedbackManager._sender    = nil    -- referensi ke FeedbackSender
FeedbackManager._queue     = {}     -- antrian feedback yang belum terkirim
FeedbackManager._history   = {}     -- riwayat feedback yang sudah terkirim
FeedbackManager._maxHistory = 50
FeedbackManager._listeners = {}

-- Kategori yang didukung
FeedbackManager.Categories = {
    "Bug Report",
    "Suggestion",
    "General",
    "Performance",
    "UI Issue",
}

-- Status feedback
FeedbackManager.Status = {
    PENDING  = "pending",
    SENT     = "sent",
    FAILED   = "failed",
    RETRYING = "retrying",
}

-- ============================================================
-- INIT
-- ============================================================

--[[
    FeedbackManager.Init(sender)
    Inisialisasi dengan referensi ke FeedbackSender.

    @param sender  FeedbackSender  -- modul pengirim
]]
function FeedbackManager.Init(sender)
    FeedbackManager._sender = sender

    -- Coba kirim ulang antrian yang gagal
    FeedbackManager._RetryQueue()
end

-- ============================================================
-- SUBMIT FEEDBACK
-- ============================================================

--[[
    FeedbackManager.Submit(options) → { id, status }
    Terima dan proses feedback dari user.

    @param options {
        Category:    string   -- "Bug Report" | "Suggestion" | dll
        Title:       string   -- judul singkat
        Description: string   -- penjelasan lengkap
        Severity:    string   -- "Low" | "Medium" | "High" | "Critical" (untuk bug)
        Tags:        {string} -- tag tambahan opsional
        Attachments: table    -- data tambahan (state, settings, dll)
        Username:    string   -- nama user (opsional, bisa anonim)
    }
    @return { id, status, error? }
]]
function FeedbackManager.Submit(options)
    options = options or {}

    -- Validasi input
    local ok, validErr = FeedbackManager._Validate(options)
    if not ok then
        return { id = nil, status = FeedbackManager.Status.FAILED, error = validErr }
    end

    -- Buat objek feedback
    local feedback = FeedbackManager._Build(options)

    -- Tambah ke queue
    table.insert(FeedbackManager._queue, feedback)

    -- Coba kirim
    FeedbackManager._TrySend(feedback)

    return { id = feedback.id, status = feedback.status }
end

--[[
    FeedbackManager.SubmitBug(title, description, severity, extras) → { id, status }
    Shortcut untuk submit bug report.
]]
function FeedbackManager.SubmitBug(title, description, severity, extras)
    return FeedbackManager.Submit({
        Category    = "Bug Report",
        Title       = title,
        Description = description,
        Severity    = severity or "Medium",
        Attachments = extras or {},
    })
end

--[[
    FeedbackManager.SubmitSuggestion(title, description, extras) → { id, status }
    Shortcut untuk submit suggestion.
]]
function FeedbackManager.SubmitSuggestion(title, description, extras)
    return FeedbackManager.Submit({
        Category    = "Suggestion",
        Title       = title,
        Description = description,
        Attachments = extras or {},
    })
end

-- ============================================================
-- INTERNAL BUILDERS
-- ============================================================

function FeedbackManager._Validate(options)
    if not options.Title or options.Title:gsub("%s+", "") == "" then
        return false, "Judul tidak boleh kosong"
    end
    if #options.Title > 120 then
        return false, "Judul terlalu panjang (maks 120 karakter)"
    end
    if not options.Description or options.Description:gsub("%s+", "") == "" then
        return false, "Deskripsi tidak boleh kosong"
    end
    if #options.Description > 2000 then
        return false, "Deskripsi terlalu panjang (maks 2000 karakter)"
    end
    if options.Category and not FeedbackManager._CategoryValid(options.Category) then
        return false, "Kategori tidak valid: " .. tostring(options.Category)
    end
    return true, nil
end

function FeedbackManager._CategoryValid(category)
    for _, c in ipairs(FeedbackManager.Categories) do
        if c == category then return true end
    end
    return false
end

function FeedbackManager._Build(options)
    local player = game:GetService("Players").LocalPlayer
    local feedback = {
        id          = FeedbackManager._GenerateId(),
        timestamp   = os.time(),
        category    = options.Category    or "General",
        title       = options.Title,
        description = options.Description,
        severity    = options.Severity    or "Medium",
        tags        = options.Tags        or {},
        status      = FeedbackManager.Status.PENDING,
        retries     = 0,
        maxRetries  = 3,
        meta = {
            username  = options.Username or (player and player.Name or "Unknown"),
            userId    = player and player.UserId or 0,
            placeId   = game.PlaceId,
            gameId    = game.GameId,
            version   = require(script.Parent.Parent.UI.Config).Flags.Version,
        },
        attachments = options.Attachments or {},
    }
    return feedback
end

function FeedbackManager._GenerateId()
    return "fb_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

-- ============================================================
-- SEND LOGIC
-- ============================================================

function FeedbackManager._TrySend(feedback)
    if not FeedbackManager._sender then
        feedback.status = FeedbackManager.Status.PENDING
        return
    end

    feedback.status = FeedbackManager.Status.PENDING

    task.spawn(function()
        local ok, err = pcall(function()
            FeedbackManager._sender.Send(feedback)
        end)

        if ok then
            feedback.status = FeedbackManager.Status.SENT
            FeedbackManager._MoveToHistory(feedback)
            FeedbackManager._Notify("sent", feedback)
        else
            feedback.retries += 1
            if feedback.retries < feedback.maxRetries then
                feedback.status = FeedbackManager.Status.RETRYING
                task.delay(5 * feedback.retries, function()
                    FeedbackManager._TrySend(feedback)
                end)
            else
                feedback.status = FeedbackManager.Status.FAILED
                FeedbackManager._Notify("failed", feedback)
            end
        end
    end)
end

function FeedbackManager._RetryQueue()
    for _, feedback in ipairs(FeedbackManager._queue) do
        if feedback.status == FeedbackManager.Status.PENDING
        or feedback.status == FeedbackManager.Status.RETRYING then
            FeedbackManager._TrySend(feedback)
        end
    end
end

function FeedbackManager._MoveToHistory(feedback)
    -- Hapus dari queue
    for i, fb in ipairs(FeedbackManager._queue) do
        if fb.id == feedback.id then
            table.remove(FeedbackManager._queue, i)
            break
        end
    end

    -- Tambah ke history
    table.insert(FeedbackManager._history, 1, feedback)

    -- Batasi ukuran history
    while #FeedbackManager._history > FeedbackManager._maxHistory do
        table.remove(FeedbackManager._history)
    end
end

-- ============================================================
-- HISTORY & QUERY
-- ============================================================

--[[
    FeedbackManager.GetHistory(filter) → {feedback}
    Kembalikan riwayat feedback.

    @param filter {
        Category: string
        Status:   string
        Limit:    number
    }
]]
function FeedbackManager.GetHistory(filter)
    filter = filter or {}
    local result = {}

    for _, fb in ipairs(FeedbackManager._history) do
        local match = true
        if filter.Category and fb.category ~= filter.Category then match = false end
        if filter.Status   and fb.status   ~= filter.Status   then match = false end
        if match then
            table.insert(result, fb)
            if filter.Limit and #result >= filter.Limit then break end
        end
    end

    return result
end

--[[
    FeedbackManager.GetPending() → {feedback}
    Kembalikan feedback yang belum terkirim.
]]
function FeedbackManager.GetPending()
    local result = {}
    for _, fb in ipairs(FeedbackManager._queue) do
        if fb.status ~= FeedbackManager.Status.SENT then
            table.insert(result, fb)
        end
    end
    return result
end

--[[
    FeedbackManager.GetStats() → { total, sent, failed, pending }
]]
function FeedbackManager.GetStats()
    local stats = { total = 0, sent = 0, failed = 0, pending = 0 }
    for _, fb in ipairs(FeedbackManager._history) do
        stats.total += 1
        if fb.status == FeedbackManager.Status.SENT   then stats.sent   += 1 end
        if fb.status == FeedbackManager.Status.FAILED then stats.failed += 1 end
    end
    for _, fb in ipairs(FeedbackManager._queue) do
        stats.total   += 1
        stats.pending += 1
    end
    return stats
end

-- ============================================================
-- LISTENERS
-- ============================================================

--[[
    FeedbackManager.OnEvent(event, callback) → disconnectFn
    @param event  "sent" | "failed" | "queued"
]]
function FeedbackManager.OnEvent(event, callback)
    if not FeedbackManager._listeners[event] then
        FeedbackManager._listeners[event] = {}
    end
    table.insert(FeedbackManager._listeners[event], callback)

    return function()
        local list = FeedbackManager._listeners[event]
        if not list then return end
        for i, cb in ipairs(list) do
            if cb == callback then
                table.remove(list, i)
                break
            end
        end
    end
end

function FeedbackManager._Notify(event, data)
    local list = FeedbackManager._listeners[event]
    if not list then return end
    for _, cb in ipairs(list) do
        pcall(cb, data)
    end
end

-- ============================================================
-- RATE LIMITING
-- ============================================================

FeedbackManager._lastSubmit = 0
FeedbackManager._cooldown   = 30  -- detik antar submission

--[[
    FeedbackManager.CanSubmit() → boolean, number
    Cek apakah user boleh submit feedback sekarang.
    @return canSubmit, secondsRemaining
]]
function FeedbackManager.CanSubmit()
    local now = os.time()
    local elapsed = now - FeedbackManager._lastSubmit
    if elapsed >= FeedbackManager._cooldown then
        return true, 0
    end
    return false, FeedbackManager._cooldown - elapsed
end

function FeedbackManager.SetCooldown(seconds)
    FeedbackManager._cooldown = seconds
end

return FeedbackManager
