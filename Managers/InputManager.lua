--[[
    BorcaUIHub — Managers/InputManager.lua
    Menangani semua input dari pengguna secara terpusat.
    Mencakup keyboard shortcut, mouse, dan keybind kustom.
    Memastikan input ditangani dengan konsisten di seluruh UI.

    FIX (Fix 10):
    - _holdTimer di-cancel dulu sebelum membuat yang baru
      SEBELUMNYA: kalau _HandleKeyDown dipanggil dua kali cepat untuk key yang sama
                  (misalnya saat auto-repeat), timer lama tidak di-cancel → dua loop berjalan
      SEKARANG:   selalu cancel + nil dulu sebelum task.delay baru
    - Setelah loop while selesai secara alami (key dilepas sebelum timeout),
      _holdTimer di-set nil agar tidak ada referensi stale yang bisa di-cancel salah
      SEBELUMNYA: _holdTimer masih menyimpan thread yang sudah selesai
                  task.cancel() pada thread selesai di Roblox tidak error, tapi
                  menyimpan referensi stale bisa membingungkan debugging
      SEKARANG:   kb._holdTimer = nil di akhir loop
]]

local InputManager = {}

local UserInputService = game:GetService("UserInputService")
local Config           = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

InputManager._keybinds    = {}    -- { id = { keyCode, callback, enabled, description } }
InputManager._mouseConns  = {}    -- koneksi mouse
InputManager._active      = true  -- apakah input manager aktif

-- Flag agar tidak konflik saat textbox aktif
InputManager._ignoreWhenTyping = true

-- ============================================================
-- INIT
-- ============================================================

--[[
    InputManager.Init()
    Inisialisasi sistem input. Pasang listener global.
    Harus dipanggil sekali setelah UI selesai dibuat.
]]
function InputManager.Init()
    -- Listener keyboard utama
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if InputManager._ignoreWhenTyping and UserInputService:GetFocusedTextBox() then return end
        if not InputManager._active then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            InputManager._HandleKeyDown(input.KeyCode)
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if not InputManager._active then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            InputManager._HandleKeyUp(input.KeyCode)
        end
    end)

    -- Keybind default dari Config
    InputManager._RegisterDefaults()
end

-- ============================================================
-- KEYBIND REGISTRATION
-- ============================================================

--[[
    InputManager.Register(id, options) → disconnectFn
    Daftarkan keybind baru.

    @param id       string  -- ID unik keybind
    @param options {
        KeyCode:      Enum.KeyCode
        Callback:     function()
        Description:  string   -- deskripsi untuk UI keybind
        Enabled:      boolean  -- default true
        Modifiers:    { "Ctrl", "Shift", "Alt" }  -- modifier keys opsional
        OnHeld:       function()  -- dipanggil saat tahan tombol
        HoldDelay:    number      -- detik sebelum OnHeld aktif
    }
    @return disconnectFn
]]
function InputManager.Register(id, options)
    options = options or {}

    InputManager._keybinds[id] = {
        keyCode     = options.KeyCode,
        callback    = options.Callback    or function() end,
        description = options.Description or id,
        enabled     = options.Enabled     ~= false,
        modifiers   = options.Modifiers   or {},
        onHeld      = options.OnHeld,
        holdDelay   = options.HoldDelay   or 0.5,
        _holdTimer  = nil,
    }

    return function()
        InputManager.Unregister(id)
    end
end

--[[
    InputManager.Unregister(id)
    Hapus keybind berdasarkan ID.
]]
function InputManager.Unregister(id)
    local kb = InputManager._keybinds[id]
    if kb and kb._holdTimer then
        -- FIX: cek apakah timer masih ada sebelum cancel
        pcall(function() task.cancel(kb._holdTimer) end)
        kb._holdTimer = nil
    end
    InputManager._keybinds[id] = nil
end

--[[
    InputManager.SetEnabled(id, enabled)
    Aktifkan atau nonaktifkan keybind tertentu.
]]
function InputManager.SetEnabled(id, enabled)
    if InputManager._keybinds[id] then
        InputManager._keybinds[id].enabled = enabled
    end
end

--[[
    InputManager.SetKeyCode(id, keyCode)
    Ubah KeyCode sebuah keybind (berguna untuk sistem rebinding).
]]
function InputManager.SetKeyCode(id, keyCode)
    if InputManager._keybinds[id] then
        InputManager._keybinds[id].keyCode = keyCode
    end
end

--[[
    InputManager.GetKeyCode(id) → Enum.KeyCode | nil
    Ambil KeyCode keybind.
]]
function InputManager.GetKeyCode(id)
    local kb = InputManager._keybinds[id]
    return kb and kb.keyCode or nil
end

--[[
    InputManager.GetAll() → table
    Kembalikan semua keybind yang terdaftar.
]]
function InputManager.GetAll()
    local result = {}
    for id, kb in pairs(InputManager._keybinds) do
        table.insert(result, {
            id          = id,
            keyCode     = kb.keyCode,
            description = kb.description,
            enabled     = kb.enabled,
        })
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end

-- ============================================================
-- MODIFIER KEY HELPERS
-- ============================================================

local function CheckModifiers(modifiers)
    for _, mod in ipairs(modifiers) do
        if mod == "Ctrl" or mod == "Control" then
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                 or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                return false
            end
        elseif mod == "Shift" then
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                 or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
                return false
            end
        elseif mod == "Alt" then
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
                 or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)) then
                return false
            end
        end
    end
    return true
end

-- ============================================================
-- INTERNAL HANDLERS
-- ============================================================

function InputManager._HandleKeyDown(keyCode)
    for _, kb in pairs(InputManager._keybinds) do
        if kb.enabled and kb.keyCode == keyCode then
            if CheckModifiers(kb.modifiers) then
                pcall(kb.callback)

                -- Hold timer
                if kb.onHeld then
                    -- FIX (Fix 10): Cancel timer lama DULU sebelum buat yang baru
                    -- SEBELUMNYA: tidak ada cancel → kalau key down dipanggil dua kali
                    --             (misalnya auto-repeat), dua loop bisa berjalan bersamaan
                    -- SEKARANG:   selalu bersihkan timer sebelumnya lebih dulu
                    if kb._holdTimer then
                        pcall(function() task.cancel(kb._holdTimer) end)
                        kb._holdTimer = nil
                    end

                    kb._holdTimer = task.delay(kb.holdDelay, function()
                        -- Loop selama key masih ditekan
                        while UserInputService:IsKeyDown(keyCode) do
                            pcall(kb.onHeld)
                            task.wait(0.1)
                        end
                        -- FIX (Fix 10): Clear _holdTimer setelah loop selesai secara alami
                        -- SEBELUMNYA: _holdTimer masih menyimpan referensi thread yang sudah selesai
                        --             → menyebabkan task.cancel() di _HandleKeyUp dipanggil pada
                        --               thread yang sudah mati (tidak error di Roblox, tapi stale)
                        -- SEKARANG:   nil-kan sendiri setelah loop selesai
                        kb._holdTimer = nil
                    end)
                end
            end
        end
    end
end

function InputManager._HandleKeyUp(keyCode)
    for _, kb in pairs(InputManager._keybinds) do
        if kb.keyCode == keyCode and kb._holdTimer then
            -- FIX (Fix 10): Gunakan pcall untuk cancel agar tidak error
            -- jika timer sudah selesai sendiri di antara cek dan cancel
            pcall(function() task.cancel(kb._holdTimer) end)
            kb._holdTimer = nil
        end
    end
end

-- ============================================================
-- DEFAULT KEYBINDS
-- ============================================================

function InputManager._RegisterDefaults()
    -- Toggle UI
    InputManager.Register("ui_toggle", {
        KeyCode     = Config.Keybind.ToggleUI or Enum.KeyCode.RightControl,
        Description = "Toggle UI",
        Callback    = function()
            if InputManager._onToggleUI then
                InputManager._onToggleUI()
            end
        end,
    })

    -- Minimize
    InputManager.Register("ui_minimize", {
        KeyCode     = Config.Keybind.MinimizeUI or Enum.KeyCode.RightAlt,
        Description = "Minimize UI",
        Callback    = function()
            if InputManager._onMinimize then
                InputManager._onMinimize()
            end
        end,
    })
end

-- ============================================================
-- CALLBACK SETTERS (dipanggil oleh Main.lua)
-- ============================================================

function InputManager.SetToggleCallback(fn)
    InputManager._onToggleUI = fn
end

function InputManager.SetMinimizeCallback(fn)
    InputManager._onMinimize = fn
end

-- ============================================================
-- MOUSE HELPERS
-- ============================================================

--[[
    InputManager.OnMouseButton1(instance, callback) → disconnectFn
    Pasang listener klik kiri pada instance.
]]
function InputManager.OnMouseButton1(instance, callback)
    if not instance then return function() end end
    local conn = instance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pcall(callback, input)
        end
    end)
    return function() conn:Disconnect() end
end

--[[
    InputManager.OnMouseButton2(instance, callback) → disconnectFn
    Pasang listener klik kanan pada instance.
]]
function InputManager.OnMouseButton2(instance, callback)
    if not instance then return function() end end
    local conn = instance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            pcall(callback, input)
        end
    end)
    return function() conn:Disconnect() end
end

--[[
    InputManager.GetMousePosition() → Vector2
    Posisi mouse saat ini.
]]
function InputManager.GetMousePosition()
    return UserInputService:GetMouseLocation()
end

--[[
    InputManager.IsKeyDown(keyCode) → boolean
    Cek apakah tombol sedang ditekan.
]]
function InputManager.IsKeyDown(keyCode)
    return UserInputService:IsKeyDown(keyCode)
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================

--[[
    InputManager.Enable()
    Aktifkan semua input handling.
]]
function InputManager.Enable()
    InputManager._active = true
end

--[[
    InputManager.Disable()
    Nonaktifkan semua input handling (berguna saat modal terbuka).
]]
function InputManager.Disable()
    InputManager._active = false
end

--[[
    InputManager.SetIgnoreWhenTyping(state)
    Jika true, keybind tidak aktif saat textbox fokus.
]]
function InputManager.SetIgnoreWhenTyping(state)
    InputManager._ignoreWhenTyping = state
end

return InputManager
