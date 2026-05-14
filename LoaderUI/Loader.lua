--[[
    BorcaUIHub — LoaderUI/Loader.lua
    Loader utama BorcaUIHub.
    Bertugas menginisialisasi seluruh sistem UI secara terpusat:
    tema, save, input, komponen, overlay, navigasi, dan utilities.
    Dipanggil oleh BorcaScriptHub (FreeLoader/PremiumLoader) sebelum
    konten tab diisi oleh FreeScript/PremiumScript.

    Urutan inisialisasi:
    1. SaveManager  → muat config tersimpan
    2. ThemeManager → terapkan tema dari config
    3. SettingsManager → terapkan setting dari config
    4. Notifications → siapkan overlay notifikasi
    5. Main         → buat window utama
    6. BlurSystem   → aktifkan efek blur
    7. DragSystem   → pasang sistem drag ke header
    8. WindowSystem → daftarkan window ke controller
    9. InputManager → daftarkan keybind default
    10. Sidebar     → bangun navigasi kiri
    11. TabManager  → inisialisasi semua tab frame
    → return UIContext untuk dipakai oleh Script Hub
]]

-- ============================================================
-- REQUIRE SEMUA MODUL
-- ============================================================

local UI          = require(script.Parent.Parent.UI.Main)
local Theme       = require(script.Parent.Parent.UI.Theme)
local Config      = require(script.Parent.Parent.UI.Config)
local Functions   = require(script.Parent.Parent.UI.Functions)
local Animations  = require(script.Parent.Parent.UI.Animations)
local Responsive  = require(script.Parent.Parent.UI.Responsive)

local Tabs        = require(script.Parent.Parent.Navigation.Tabs)
local TabManager  = require(script.Parent.Parent.Navigation.TabManager)
local Sidebar     = require(script.Parent.Parent.Navigation.Sidebar)
local Breadcrumb  = require(script.Parent.Parent.Navigation.BreadCrumb)

local Sections    = require(script.Parent.Parent.Sections.Sections)
local SectionManager = require(script.Parent.Parent.Sections.SectionManager)

local Toggles     = require(script.Parent.Parent.Components.Toggles)
local Switches    = require(script.Parent.Parent.Components.Switches)
local Sliders     = require(script.Parent.Parent.Components.Sliders)
local Buttons     = require(script.Parent.Parent.Components.Buttons)
local Dropdowns   = require(script.Parent.Parent.Components.Dropdown)
local Inputs      = require(script.Parent.Parent.Components.Inputs)
local Labels      = require(script.Parent.Parent.Components.Labels)
local Paragraphs  = require(script.Parent.Parent.Components.Paragraphs)
local ColorPickers = require(script.Parent.Parent.Components.ColorPicker)
local KeyBinds    = require(script.Parent.Parent.Components.KeyBinds)
local Cards       = require(script.Parent.Parent.Components.Cards)
local Separators  = require(script.Parent.Parent.Components.Separators)

local SaveManager     = require(script.Parent.Parent.Managers.SaveManager)
local ThemeManager    = require(script.Parent.Parent.Managers.ThemeManager)
local InputManager    = require(script.Parent.Parent.Managers.InputManager)
local SettingsManager = require(script.Parent.Parent.Managers.SettingsManager)
local FeedbackManager = require(script.Parent.Parent.Managers.FeedbackManager)

local Notifications   = require(script.Parent.Parent.Overlays.Notifications)
local Modals          = require(script.Parent.Parent.Overlays.Modals)
local Tooltips        = require(script.Parent.Parent.Overlays.Tooltips)
local Loading         = require(script.Parent.Parent.Overlays.Loading)

local DragSystem      = require(script.Parent.Parent.Utulities.DragSystem)
local WindowSystem    = require(script.Parent.Parent.Utulities.WindowSystem)
local BlurSystem      = require(script.Parent.Parent.Utulities.BlurSystem)
local AnimationController = require(script.Parent.Parent.Utulities.AnimationController)

local SearchBar    = require(script.Parent.Parent.Search.SearchBar)
local SearchSystem = require(script.Parent.Parent.Search.SearchSystem)

local FeedbackSender = require(script.Parent.Parent.Feedback.FeedbackSender)

-- ============================================================
-- LOADER MODULE
-- ============================================================

local Loader = {}

-- ============================================================
-- INIT DEPS (overlay & sistem yang butuh deps inject)
-- ============================================================

local function _InitDeps()
    local deps = {
        Functions = Functions,
        Theme     = Theme,
        Config    = Config,
    }

    Notifications.Init(deps)
    Modals.Init(deps)
    Tooltips.Init(deps)
    Loading.Init(deps)
    SearchBar.Init(deps)
    SearchSystem.Init(deps)

    -- Cards dan Separators memakai pola Init berbeda (deps table)
    Cards.Init(deps)
    Separators.Init(deps)

    -- FeedbackManager terhubung ke FeedbackSender
    FeedbackManager.Init(FeedbackSender)
end

-- ============================================================
-- PUBLIC: Init
-- ============================================================

--[[
    Loader.Init(options) → UIContext
    Inisialisasi penuh BorcaUIHub.

    @param options {
        -- Identitas hub
        HubName:    string    -- contoh "BorcaScriptHub"
        HubVersion: string    -- contoh "v1.0.0"
        HubIcon:    string    -- karakter ikon header
        SubTitle:   string    -- teks kecil di header

        -- User
        Premium:    boolean   -- apakah session premium
        Username:   string    -- nama player (opsional, auto-detect)

        -- Config
        ConfigName: string    -- nama file config (opsional)
        FolderName: string    -- nama folder save (opsional)

        -- Tab default pertama dibuka
        DefaultTab: string    -- ID tab (default "home")

        -- Callback
        OnReady:    function(UIContext)  -- dipanggil setelah selesai
        OnClose:    function()
        OnToggle:   function(visible: boolean)
    }

    @return UIContext {
        -- Referensi window
        Window, Header, Sidebar, ContentPanel, ScrollContent, ScreenGui,

        -- Controller
        WindowCtrl, DragCtrl,

        -- Sistem
        TabManager, SectionManager, Sections, SaveManager,
        ThemeManager, SettingsManager, InputManager, Notifications,
        Modals, Tooltips, BlurSystem, SearchSystem,

        -- Komponen
        Toggles, Switches, Sliders, Buttons, Dropdowns,
        Inputs, Labels, Paragraphs, ColorPickers, KeyBinds,
        Cards, Separators,

        -- Fungsi bantu
        AddTab: function(tabId, options, builder)
        GetTabFrame: function(tabId) → Frame
        SwitchTab: function(tabId)
        Notify: function(options)
        Cleanup: function()
    }
]]
function Loader.Init(options)
    options = options or {}

    local hubName    = options.HubName    or "BorcaUIHub"
    local hubVersion = options.HubVersion or ("v" .. Config.Flags.Version)
    local hubIcon    = options.HubIcon    or "◈"
    local subTitle   = options.SubTitle   or hubName
    local isPremium  = options.Premium    or false
    local username   = options.Username
        or (pcall(function() return game:GetService("Players").LocalPlayer.Name end)
            and game:GetService("Players").LocalPlayer.Name
            or "Player")
    local configName = options.ConfigName or (isPremium and "premium_config.json" or "free_config.json")
    local folderName = options.FolderName or "BorcaUIHub"
    local defaultTab = options.DefaultTab or "home"
    local onReady    = options.OnReady
    local onClose    = options.OnClose
    local onToggle   = options.OnToggle

    -- ── 1. SaveManager ──────────────────────────────────────
    SaveManager.Init({
        Folder     = folderName,
        ConfigName = configName,
        AutoSave   = true,
    })

    -- ── 2. ThemeManager ─────────────────────────────────────
    -- Hanya loader yang memanggil ThemeManager.Init (Fix 7)
    ThemeManager.Init(
        SaveManager.GetValue("themeName", isPremium and "Midnight" or "Dark"),
        SaveManager.GetValue("accentHex", nil)
    )

    -- ── 3. SettingsManager ──────────────────────────────────
    SettingsManager.Init(SaveManager.GetValue("settings", {}))

    -- ── 4. Deps (Notifications, Modals, dll) ─────────────────
    _InitDeps()

    -- ── 5. Animasi controller global ─────────────────────────
    AnimationController.SetSpeed(SettingsManager.Get("AnimationSpeed") or 1.0)
    if not SettingsManager.Get("AnimationsEnabled") then
        AnimationController.Pause()
    end

    -- ── 6. Buat window ───────────────────────────────────────
    local window = UI.CreateWindow({
        Title    = hubName,
        SubTitle = subTitle,
        Icon     = hubIcon,
        Size     = Responsive.GetWindowSize(),
    })

    -- Responsive bind
    Responsive.Init(window.ScreenGui)
    Responsive.BindWindowResize(
        window.Window,
        window.Body,
        window.Sidebar,
        window.ContentPanel
    )
    Responsive.BindSidebarCollapse(
        window.Sidebar,
        function() Sidebar.Collapse() end,
        function() Sidebar.Expand() end
    )

    -- ── 7. BlurSystem ────────────────────────────────────────
    BlurSystem.Init({
        Enabled   = SettingsManager.Get("BlurEnabled"),
        Intensity = SettingsManager.Get("BlurIntensity"),
    })
    BlurSystem.Enable()

    -- ── 8. DragSystem ────────────────────────────────────────
    local drag = DragSystem.Attach(window.Window, window.Header, {
        BoundToScreen = true,
        BoundPadding  = 10,
    })

    -- ── 9. WindowSystem ──────────────────────────────────────
    local winCtrl = WindowSystem.Register("main", window, {
        MinSize   = Config.Window.MinSize,
        MaxSize   = Config.Window.MaxSize,
        Resizable = Config.Window.Resizable,
    })

    -- ── 10. InputManager ─────────────────────────────────────
    InputManager.Init()

    InputManager.SetToggleCallback(function()
        winCtrl.Toggle()
        if onToggle then
            pcall(onToggle, not winCtrl.IsVisible())
        end
    end)

    InputManager.SetMinimizeCallback(function()
        winCtrl.Minimize()
    end)

    -- ── 11. Sidebar ──────────────────────────────────────────
    Sidebar.Build(window.Sidebar, {
        HubName    = hubName,
        HubVersion = hubVersion,
        Premium    = isPremium,
        Username   = username,
    })

    -- ── 12. TabManager ───────────────────────────────────────
    TabManager.Init(window.ScrollContent, defaultTab)

    -- ── 13. Auto-save hooks ──────────────────────────────────
    SettingsManager.OnAnyChanged(function(key, val)
        SaveManager.SetValue("settings." .. key, val)
    end)

    ThemeManager.OnChanged(function(changeType, value)
        if changeType == "theme" then
            SaveManager.SetValue("themeName", value)
        elseif changeType == "accent" and typeof(value) == "Color3" then
            SaveManager.SetValue("accentHex", string.format(
                "#%02X%02X%02X",
                math.floor(value.R * 255),
                math.floor(value.G * 255),
                math.floor(value.B * 255)
            ))
        end
    end)

    -- ── 14. Cleanup saat window ditutup ──────────────────────
    winCtrl.OnStateChanged(function(event)
        if event == "closed" then
            BlurSystem.Destroy()
            SaveManager.Save()
            drag.Destroy()
            Responsive.Stop()
            InputManager.Disable()
            AnimationController.CleanupAll()
            if onClose then pcall(onClose) end
        end
    end)

    -- ============================================================
    -- BUAT UIContext — return ke Script Hub
    -- ============================================================

    local UIContext = {

        -- ── Window references ────────────────────────────────
        Window        = window.Window,
        Header        = window.Header,
        Sidebar       = window.Sidebar,
        ContentPanel  = window.ContentPanel,
        ScrollContent = window.ScrollContent,
        ScreenGui     = window.ScreenGui,
        Body          = window.Body,

        -- ── Controllers ──────────────────────────────────────
        WindowCtrl    = winCtrl,
        DragCtrl      = drag,

        -- ── Sistem ───────────────────────────────────────────
        TabManager      = TabManager,
        SectionManager  = SectionManager,
        Sections        = Sections,
        SaveManager     = SaveManager,
        ThemeManager    = ThemeManager,
        SettingsManager = SettingsManager,
        InputManager    = InputManager,
        FeedbackManager = FeedbackManager,
        Notifications   = Notifications,
        Modals          = Modals,
        Tooltips        = Tooltips,
        BlurSystem      = BlurSystem,
        SearchSystem    = SearchSystem,
        AnimationController = AnimationController,

        -- ── Komponen ─────────────────────────────────────────
        Toggles       = Toggles,
        Switches      = Switches,
        Sliders       = Sliders,
        Buttons       = Buttons,
        Dropdowns     = Dropdowns,
        Inputs        = Inputs,
        Labels        = Labels,
        Paragraphs    = Paragraphs,
        ColorPickers  = ColorPickers,
        KeyBinds      = KeyBinds,
        Cards         = Cards,
        Separators    = Separators,

        -- ── Helpers ──────────────────────────────────────────

        --[[
            UIContext.AddTab(tabId, options, builder)
            Tambah tab dinamis dan opsional isi kontennya.
            builder: function(frame) dipanggil saat tab pertama dibuka (lazy).
        ]]
        AddTab = function(tabId, tabOptions, builder)
            Tabs.AddTab(tabId, tabOptions, builder)
        end,

        --[[
            UIContext.GetTabFrame(tabId) → Frame
            Ambil frame konten tab untuk diisi manual.
        ]]
        GetTabFrame = function(tabId)
            return Tabs.GetFrame(tabId)
        end,

        --[[
            UIContext.InitTab(tabId)
            Daftarkan tab ke SectionManager.
        ]]
        InitTab = function(tabId)
            local frame = Tabs.GetFrame(tabId)
            if frame then
                SectionManager.InitTab(tabId, frame)
                TabManager.MarkBuilt(tabId)
            end
        end,

        --[[
            UIContext.SwitchTab(tabId)
            Pindah ke tab tertentu.
        ]]
        SwitchTab = function(tabId)
            TabManager.Switch(tabId)
        end,

        --[[
            UIContext.Notify(options)
            Shortcut kirim notifikasi.
        ]]
        Notify = function(notifOptions)
            Notifications.Send(notifOptions)
        end,

        --[[
            UIContext.Cleanup()
            Bersihkan semua resource dan tutup window.
        ]]
        Cleanup = function()
            winCtrl.Close()
        end,
    }

    -- ── Callback OnReady ─────────────────────────────────────
    if onReady then
        task.spawn(function()
            pcall(onReady, UIContext)
        end)
    end

    return UIContext
end

-- ============================================================
-- PUBLIC: ShowLoading
-- Shortcut untuk menampilkan loading screen sebelum Loader.Init
-- ============================================================

--[[
    Loader.ShowLoading(options) → loadingScreen
    Tampilkan loading screen. Sama seperti Loading.Show tapi
    tersedia dari satu titik masuk.
]]
function Loader.ShowLoading(options)
    return Loading.Show(options)
end

return Loader
