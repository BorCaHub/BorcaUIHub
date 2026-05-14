--[[
    BorcaUIHub — Utilities/Utils.lua
    File bantuan umum yang berisi fungsi-fungsi kecil dan penting.
    Dipakai untuk pembuatan object, validasi data, operasi aman,
    dan helper lain yang sering digunakan lintas modul.
    Keberadaan Utils membuat file lain menjadi lebih bersih dan fokus.
]]

local Utils = {}

-- ============================================================
-- INSTANCE UTILITIES
-- ============================================================

--[[
    Utils.Create(className, properties, parent) → Instance
    Buat instance dengan properties langsung dari tabel.
    Lebih ringkas daripada set satu per satu.
]]
function Utils.Create(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        pcall(function()
            instance[key] = value
        end)
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

--[[
    Utils.Clone(instance, parent) → Instance
    Clone instance ke parent baru secara aman.
]]
function Utils.Clone(instance, parent)
    if not instance then return nil end
    local clone = instance:Clone()
    if parent then clone.Parent = parent end
    return clone
end

--[[
    Utils.IsValid(instance) → boolean
    Cek apakah instance masih valid dan tidak dihapus.
]]
function Utils.IsValid(instance)
    return instance ~= nil
        and typeof(instance) == "Instance"
        and instance.Parent ~= nil
end

--[[
    Utils.SafeDestroy(instance)
    Hapus instance tanpa error jika sudah tidak ada.
]]
function Utils.SafeDestroy(instance)
    if Utils.IsValid(instance) then
        pcall(function() instance:Destroy() end)
    end
end

--[[
    Utils.SafeCall(fn, ...) → ok, result
    Panggil fungsi dengan pcall, kembalikan status dan hasil.
]]
function Utils.SafeCall(fn, ...)
    if type(fn) ~= "function" then return false, nil end
    return pcall(fn, ...)
end

--[[
    Utils.WaitForInstance(parent, name, timeout) → Instance | nil
    Tunggu instance dengan nama tertentu muncul di parent.
]]
function Utils.WaitForInstance(parent, name, timeout)
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local found = parent:FindFirstChild(name, true)
        if found then return found end
        task.wait(0.05)
    end
    return nil
end

-- ============================================================
-- STRING UTILITIES
-- ============================================================

--[[
    Utils.Trim(str) → string
    Hapus whitespace di awal dan akhir string.
]]
function Utils.Trim(str)
    return tostring(str or ""):match("^%s*(.-)%s*$")
end

--[[
    Utils.Split(str, separator) → {string}
    Pisahkan string berdasarkan separator.
]]
function Utils.Split(str, separator)
    separator = separator or ","
    local result = {}
    for part in tostring(str):gmatch("([^" .. separator .. "]+)") do
        table.insert(result, Utils.Trim(part))
    end
    return result
end

--[[
    Utils.StartsWith(str, prefix) → boolean
]]
function Utils.StartsWith(str, prefix)
    return tostring(str):sub(1, #prefix) == prefix
end

--[[
    Utils.EndsWith(str, suffix) → boolean
]]
function Utils.EndsWith(str, suffix)
    local s = tostring(str)
    return suffix == "" or s:sub(-#suffix) == suffix
end

--[[
    Utils.Truncate(str, maxLen, ellipsis) → string
    Potong string jika lebih panjang dari maxLen.
]]
function Utils.Truncate(str, maxLen, ellipsis)
    str      = tostring(str or "")
    ellipsis = ellipsis or "..."
    if #str <= maxLen then return str end
    return str:sub(1, maxLen - #ellipsis) .. ellipsis
end

--[[
    Utils.PadLeft(str, length, char) → string
    Padding kiri dengan karakter tertentu.
]]
function Utils.PadLeft(str, length, char)
    str  = tostring(str)
    char = char or " "
    while #str < length do str = char .. str end
    return str
end

--[[
    Utils.FormatTime(seconds) → string
    Format detik menjadi "MM:SS" atau "HH:MM:SS".
]]
function Utils.FormatTime(seconds)
    seconds = math.floor(seconds or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

--[[
    Utils.FormatNumber(n, decimals, separator) → string
    Format angka dengan pemisah ribuan.
    Contoh: 1234567 → "1,234,567"
]]
function Utils.FormatNumber(n, decimals, separator)
    decimals  = decimals  or 0
    separator = separator or ","
    local formatted = string.format("%." .. decimals .. "f", n)
    local int, dec  = formatted:match("^(-?%d+)(%.?%d*)$")
    if not int then return formatted end
    local result = int:reverse():gsub("(%d%d%d)", "%1" .. separator):reverse()
    if result:sub(1, 1) == separator then result = result:sub(2) end
    return result .. dec
end

-- ============================================================
-- NUMBER UTILITIES
-- ============================================================

--[[
    Utils.Clamp(value, min, max) → number
]]
function Utils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

--[[
    Utils.Lerp(a, b, t) → number
    Linear interpolasi.
]]
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

--[[
    Utils.Round(value, decimals) → number
]]
function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

--[[
    Utils.Map(value, inMin, inMax, outMin, outMax) → number
    Peta nilai dari satu range ke range lain.
]]
function Utils.Map(value, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin))
end

--[[
    Utils.Sign(n) → -1 | 0 | 1
]]
function Utils.Sign(n)
    if n > 0 then return 1
    elseif n < 0 then return -1
    else return 0 end
end

-- ============================================================
-- COLOR UTILITIES
-- ============================================================

--[[
    Utils.ColorToHex(color) → string   -- "#RRGGBB"
]]
function Utils.ColorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

--[[
    Utils.HexToColor(hex) → Color3
    @param hex  "#RRGGBB" atau "RRGGBB"
]]
function Utils.HexToColor(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

--[[
    Utils.LightenColor(color, amount) → Color3
]]
function Utils.LightenColor(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.min(color.R + amount, 1),
        math.min(color.G + amount, 1),
        math.min(color.B + amount, 1)
    )
end

--[[
    Utils.DarkenColor(color, amount) → Color3
]]
function Utils.DarkenColor(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.max(color.R - amount, 0),
        math.max(color.G - amount, 0),
        math.max(color.B - amount, 0)
    )
end

--[[
    Utils.ColorLuminance(color) → number  (0-1)
    Hitung luminance perseptual warna untuk menentukan teks terang/gelap.
]]
function Utils.ColorLuminance(color)
    return color.R * 0.299 + color.G * 0.587 + color.B * 0.114
end

--[[
    Utils.ContrastColor(bgColor) → Color3
    Kembalikan hitam atau putih tergantung kontras background.
]]
function Utils.ContrastColor(bgColor)
    return Utils.ColorLuminance(bgColor) > 0.5
        and Color3.fromRGB(20, 20, 20)
        or  Color3.fromRGB(245, 245, 245)
end

-- ============================================================
-- TABLE UTILITIES
-- ============================================================

--[[
    Utils.TableContains(tbl, value) → boolean
]]
function Utils.TableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

--[[
    Utils.TableFind(tbl, predicate) → value | nil, index | nil
]]
function Utils.TableFind(tbl, predicate)
    for i, v in ipairs(tbl) do
        if predicate(v) then return v, i end
    end
    return nil, nil
end

--[[
    Utils.TableRemove(tbl, value)
    Hapus nilai dari tabel array (bukan index).
]]
function Utils.TableRemove(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

--[[
    Utils.TableKeys(tbl) → {key}
]]
function Utils.TableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do table.insert(keys, k) end
    return keys
end

--[[
    Utils.TableValues(tbl) → {value}
]]
function Utils.TableValues(tbl)
    local values = {}
    for _, v in pairs(tbl) do table.insert(values, v) end
    return values
end

--[[
    Utils.DeepCopy(tbl) → table
    Salin tabel secara rekursif.
]]
function Utils.DeepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
    end
    return setmetatable(copy, getmetatable(tbl))
end

--[[
    Utils.Merge(base, override) → table
    Gabungkan dua tabel, override menang.
]]
function Utils.Merge(base, override)
    local result = Utils.DeepCopy(base)
    for k, v in pairs(override or {}) do
        result[k] = v
    end
    return result
end

--[[
    Utils.Filter(tbl, predicate) → {value}
]]
function Utils.Filter(tbl, predicate)
    local result = {}
    for _, v in ipairs(tbl) do
        if predicate(v) then table.insert(result, v) end
    end
    return result
end

--[[
    Utils.Map(tbl, fn) → {value}
    (Overload untuk tabel — berbeda dari Utils.Map number)
]]
function Utils.MapTable(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v, i)
    end
    return result
end

-- ============================================================
-- DEBOUNCE / THROTTLE
-- ============================================================

--[[
    Utils.Debounce(fn, delay) → function
    Bungkus fungsi dengan debounce agar tidak dipanggil terlalu sering.
]]
function Utils.Debounce(fn, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall < delay then return end
        lastCall = now
        return fn(...)
    end
end

--[[
    Utils.Throttle(fn, interval) → function
    Batasi frekuensi pemanggilan fungsi (max 1x per interval).
]]
function Utils.Throttle(fn, interval)
    local lastTime = -math.huge
    return function(...)
        local now = tick()
        if now - lastTime >= interval then
            lastTime = now
            return fn(...)
        end
    end
end

--[[
    Utils.Once(fn) → function
    Bungkus fungsi agar hanya bisa dipanggil sekali.
]]
function Utils.Once(fn)
    local called = false
    return function(...)
        if called then return end
        called = true
        return fn(...)
    end
end

-- ============================================================
-- MISC
-- ============================================================

--[[
    Utils.UUID() → string
    Generate ID unik sederhana.
]]
function Utils.UUID()
    return string.format("%08x-%04x-%04x-%04x-%012x",
        math.random(0, 0xFFFFFFFF),
        math.random(0, 0xFFFF),
        math.random(0, 0xFFFF),
        math.random(0, 0xFFFF),
        math.random(0, 0xFFFFFFFFFFFF)
    )
end

--[[
    Utils.Timestamp() → string
    Kembalikan timestamp yang bisa dibaca manusia.
    Format: "YYYY-MM-DD HH:MM:SS" (UTC)
]]
function Utils.Timestamp()
    local t = os.date("!*t")
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",
        t.year, t.month, t.day, t.hour, t.min, t.sec)
end

--[[
    Utils.GetPlayerName() → string
    Nama LocalPlayer secara aman.
]]
function Utils.GetPlayerName()
    local ok, name = pcall(function()
        return game:GetService("Players").LocalPlayer.Name
    end)
    return ok and name or "Unknown"
end

--[[
    Utils.GetUserId() → number
]]
function Utils.GetUserId()
    local ok, id = pcall(function()
        return game:GetService("Players").LocalPlayer.UserId
    end)
    return ok and id or 0
end

return Utils
