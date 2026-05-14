--[[
    BorcaUIHub — Feedback/FeedbackSender.lua
    Pengirim data feedback ke tujuan eksternal.
    Bisa mengirim ke Discord webhook, API endpoint, atau server internal.
    Ini adalah jembatan antara input user dan sistem penerima data.
    Memiliki handling error yang baik agar tidak silent fail.
]]

local FeedbackSender = {}

local Config = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- KONFIGURASI ENDPOINT
-- Ubah URL di bawah sesuai target pengiriman.
-- ============================================================

FeedbackSender.Config = {
    -- URL Discord webhook (kosongkan jika tidak dipakai)
    WebhookURL  = "",

    -- URL API kustom (kosongkan jika tidak dipakai)
    ApiURL      = "",

    -- Header tambahan untuk API kustom
    ApiHeaders  = {
        ["Content-Type"] = "application/json",
    },

    -- Timeout request dalam detik
    Timeout     = 10,

    -- Aktifkan mode dry run (data diprint ke console, tidak dikirim)
    DryRun      = false,

    -- Format pengiriman: "discord" | "json" | "form"
    Format      = "discord",
}

-- ============================================================
-- FORMATTER
-- ============================================================

-- Format payload untuk Discord webhook
local function FormatDiscord(feedback)
    -- Warna embed berdasarkan severity / category
    local colorMap = {
        Low      = 0x57F287,   -- hijau
        Medium   = 0xFEE75C,   -- kuning
        High     = 0xE67E22,   -- oranye
        Critical = 0xED4245,   -- merah
    }
    local catColorMap = {
        ["Bug Report"]  = colorMap[feedback.severity] or 0xED4245,
        ["Suggestion"]  = 0x5865F2,
        ["General"]     = 0x99AAB5,
        ["Performance"] = 0xFEE75C,
        ["UI Issue"]    = 0xEB459E,
    }

    local embedColor = catColorMap[feedback.category] or 0x99AAB5

    -- Tags string
    local tagsStr = #feedback.tags > 0
        and table.concat(feedback.tags, ", ")
        or "—"

    -- Attachments string (singkat)
    local attStr = ""
    for k, v in pairs(feedback.attachments or {}) do
        attStr = attStr .. "`" .. tostring(k) .. "`: " .. tostring(v):sub(1, 60) .. "\n"
    end
    if attStr == "" then attStr = "—" end

    local fields = {
        { name = "📋 Kategori",    value = feedback.category,                    inline = true  },
        { name = "⚠️ Severity",    value = feedback.severity or "—",             inline = true  },
        { name = "🏷️ Tags",        value = tagsStr,                              inline = true  },
        { name = "👤 User",         value = feedback.meta.username ..
                                           " (" .. tostring(feedback.meta.userId) .. ")",
                                                                                 inline = true  },
        { name = "🎮 Game",         value = tostring(feedback.meta.placeId),      inline = true  },
        { name = "📦 Versi",        value = tostring(feedback.meta.version),      inline = true  },
        { name = "📝 Deskripsi",    value = feedback.description:sub(1, 1024),   inline = false },
        { name = "📎 Attachments",  value = attStr:sub(1, 512),                  inline = false },
    }

    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", feedback.timestamp)

    return {
        username   = "BorcaFeedback",
        avatar_url = "https://cdn.discordapp.com/embed/avatars/0.png",
        embeds = {
            {
                title       = "[" .. feedback.category .. "] " .. feedback.title:sub(1, 200),
                color       = embedColor,
                fields      = fields,
                footer      = {
                    text = "ID: " .. feedback.id .. " • " .. timestamp,
                },
                timestamp   = timestamp,
            }
        }
    }
end

-- Format payload sebagai JSON generik
local function FormatJSON(feedback)
    return {
        id          = feedback.id,
        timestamp   = feedback.timestamp,
        category    = feedback.category,
        title       = feedback.title,
        description = feedback.description,
        severity    = feedback.severity,
        tags        = feedback.tags,
        status      = feedback.status,
        meta        = feedback.meta,
        attachments = feedback.attachments,
    }
end

-- ============================================================
-- JSON ENCODER SEDERHANA
-- ============================================================

local function EncodeValue(val, depth)
    depth = depth or 0
    local t = type(val)
    if t == "nil"     then return "null"
    elseif t == "boolean" then return val and "true" or "false"
    elseif t == "number"  then return tostring(val)
    elseif t == "string"  then
        val = val:gsub('\\', '\\\\')
                 :gsub('"', '\\"')
                 :gsub('\n', '\\n')
                 :gsub('\r', '\\r')
                 :gsub('\t', '\\t')
        return '"' .. val .. '"'
    elseif t == "table" then
        -- Deteksi array vs object
        local isArray = true
        local maxN    = 0
        for k, _ in pairs(val) do
            if type(k) ~= "number" then isArray = false; break end
            if k > maxN then maxN = k end
        end
        isArray = isArray and maxN == #val

        local parts = {}
        if isArray then
            for _, v in ipairs(val) do
                table.insert(parts, EncodeValue(v, depth + 1))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(parts, '"' .. tostring(k) .. '":' .. EncodeValue(v, depth + 1))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

local function EncodeJSON(tbl)
    return EncodeValue(tbl)
end

-- ============================================================
-- SENDER UTAMA
-- ============================================================

--[[
    FeedbackSender.Send(feedback) → boolean, string
    Kirim feedback ke endpoint yang dikonfigurasi.

    @param feedback  table  -- objek feedback dari FeedbackManager
    @return ok, error
]]
function FeedbackSender.Send(feedback)
    if not feedback then
        return false, "Feedback kosong"
    end

    -- DRY RUN: hanya print, tidak kirim
    if FeedbackSender.Config.DryRun then
        print("[BorcaFeedback][DryRun] Feedback yang akan dikirim:")
        print("  ID       :", feedback.id)
        print("  Kategori :", feedback.category)
        print("  Judul    :", feedback.title)
        print("  Deskripsi:", feedback.description:sub(1, 100))
        print("  Severity :", feedback.severity)
        print("  User     :", feedback.meta and feedback.meta.username or "Unknown")
        return true, nil
    end

    -- Tentukan URL dan payload berdasarkan format
    local url     = nil
    local payload = nil
    local headers = { ["Content-Type"] = "application/json" }

    local format = FeedbackSender.Config.Format

    if format == "discord" then
        url     = FeedbackSender.Config.WebhookURL
        payload = EncodeJSON(FormatDiscord(feedback))
    elseif format == "json" then
        url     = FeedbackSender.Config.ApiURL
        payload = EncodeJSON(FormatJSON(feedback))
        for k, v in pairs(FeedbackSender.Config.ApiHeaders or {}) do
            headers[k] = v
        end
    else
        -- Fallback ke JSON
        url     = FeedbackSender.Config.ApiURL
        payload = EncodeJSON(FormatJSON(feedback))
    end

    -- Validasi URL
    if not url or url == "" then
        -- Tidak ada endpoint dikonfigurasi — simpan lokal saja
        FeedbackSender._SaveLocal(feedback)
        return true, nil
    end

    -- Kirim via HttpService (executor environment)
    local ok, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        local response = HttpService:RequestAsync({
            Url     = url,
            Method  = "POST",
            Headers = headers,
            Body    = payload,
        })

        if not response.Success then
            error("HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.Body):sub(1, 200))
        end
    end)

    if not ok then
        warn("[BorcaFeedback] Gagal mengirim: " .. tostring(err))
        -- Fallback: simpan lokal
        FeedbackSender._SaveLocal(feedback)
        return false, tostring(err)
    end

    return true, nil
end

-- ============================================================
-- LOCAL SAVE FALLBACK
-- Simpan ke file lokal jika tidak ada endpoint atau request gagal.
-- ============================================================

FeedbackSender._localQueue = {}

function FeedbackSender._SaveLocal(feedback)
    table.insert(FeedbackSender._localQueue, feedback)

    -- Coba tulis ke file
    pcall(function()
        local folder = Config.Save.FolderName or "BorcaUIHub"
        local path   = folder .. "/feedback_queue.json"

        -- Buat folder jika belum ada
        if not isfolder(folder) then
            makefolder(folder)
        end

        -- Encode dan simpan
        local encoded = EncodeJSON(FeedbackSender._localQueue)
        writefile(path, encoded)
    end)
end

--[[
    FeedbackSender.LoadLocalQueue() → {feedback}
    Muat feedback yang tersimpan di file lokal.
]]
function FeedbackSender.LoadLocalQueue()
    local result = {}
    pcall(function()
        local folder = Config.Save.FolderName or "BorcaUIHub"
        local path   = folder .. "/feedback_queue.json"
        if isfile(path) then
            local content = readfile(path)
            -- Decode sederhana via loadstring
            local fn, err = loadstring("return " .. content)
            if fn then
                local ok, data = pcall(fn)
                if ok and type(data) == "table" then
                    result = data
                end
            end
        end
    end)
    FeedbackSender._localQueue = result
    return result
end

--[[
    FeedbackSender.ClearLocalQueue()
    Hapus antrian lokal setelah berhasil dikirim.
]]
function FeedbackSender.ClearLocalQueue()
    FeedbackSender._localQueue = {}
    pcall(function()
        local folder = Config.Save.FolderName or "BorcaUIHub"
        local path   = folder .. "/feedback_queue.json"
        if isfile(path) then
            writefile(path, "[]")
        end
    end)
end

-- ============================================================
-- CONFIGURATION API
-- ============================================================

--[[
    FeedbackSender.SetWebhook(url)
    Set URL Discord webhook.
]]
function FeedbackSender.SetWebhook(url)
    FeedbackSender.Config.WebhookURL = url
    FeedbackSender.Config.Format     = "discord"
end

--[[
    FeedbackSender.SetAPI(url, headers)
    Set URL API endpoint beserta header kustom.
]]
function FeedbackSender.SetAPI(url, headers)
    FeedbackSender.Config.ApiURL    = url
    FeedbackSender.Config.Format    = "json"
    if headers then
        for k, v in pairs(headers) do
            FeedbackSender.Config.ApiHeaders[k] = v
        end
    end
end

--[[
    FeedbackSender.SetDryRun(enabled)
    Aktifkan/nonaktifkan dry run mode.
]]
function FeedbackSender.SetDryRun(enabled)
    FeedbackSender.Config.DryRun = enabled
end

--[[
    FeedbackSender.GetStatus() → table
]]
function FeedbackSender.GetStatus()
    return {
        webhookSet  = FeedbackSender.Config.WebhookURL ~= "",
        apiSet      = FeedbackSender.Config.ApiURL     ~= "",
        format      = FeedbackSender.Config.Format,
        dryRun      = FeedbackSender.Config.DryRun,
        localQueue  = #FeedbackSender._localQueue,
    }
end

return FeedbackSender
