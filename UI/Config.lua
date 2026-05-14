--[[
    BorcaUIHub — UI/Config.lua
    Semua parameter dan pengaturan dasar UI.
    Ubah nilai di sini untuk mengatur perilaku dan tampilan seluruh sistem.
]]

local Config = {}

-- ============================================================
-- WINDOW
-- ============================================================
Config.Window = {
    -- Ukuran default window saat pertama dibuka
    DefaultSize     = UDim2.new(0, 780, 0, 520),

    -- Posisi default (tengah layar)
    DefaultPosition = UDim2.new(0.5, 0, 0.5, 0),

    -- ZIndex display order (agar tampil di atas UI Roblox lain)
    DisplayOrder    = 100,

    -- Ukuran minimum yang diizinkan saat resize
    MinSize         = Vector2.new(560, 380),

    -- Ukuran maksimum
    MaxSize         = Vector2.new(1200, 800),

    -- Apakah window bisa di-resize oleh user
    Resizable       = false,
}

-- ============================================================
-- UI GENERAL
-- ============================================================
Config.UI = {
    -- Radius sudut komponen (dalam pixel)
    CornerRadius    = 12,

    -- Radius sudut tombol
    ButtonRadius    = 8,

    -- Radius sudut card / panel
    CardRadius      = 10,

    -- Tinggi header bar (pixel)
    HeaderHeight    = 52,

    -- Lebar sidebar kiri (pixel)
    SidebarWidth    = 180,

    -- Jarak vertikal antar section dalam content panel
    SectionGap      = 10,

    -- Padding dalam section
    SectionPadding  = 14,

    -- Tinggi standar satu baris komponen (toggle, slider, dll)
    ComponentHeight = 42,

    -- Gap antar komponen dalam section
    ComponentGap    = 6,
}

-- ============================================================
-- TRANSPARANSI
-- ============================================================
Config.Transparency = {
    -- Background utama window (0 = solid, 1 = invisible)
    MainBackground  = 0,

    -- Background sidebar
    Sidebar         = 0,

    -- Background card
    Card            = 0,

    -- Overlay gelap saat modal aktif (0–1)
    ModalDimming    = 0.55,

    -- Transparansi tombol saat tidak di-hover
    ButtonDefault   = 0,

    -- Transparansi stroke / border
    Stroke          = 0.6,
}

-- ============================================================
-- BLUR
-- ============================================================
Config.Blur = {
    -- Aktifkan efek blur belakang window
    Enabled         = true,

    -- Intensitas blur (1–56)
    Intensity       = 24,

    -- Kecepatan transisi blur masuk (detik)
    FadeInDuration  = 0.4,

    -- Kecepatan transisi blur keluar
    FadeOutDuration = 0.3,
}

-- ============================================================
-- ANIMASI
-- ============================================================
Config.Animation = {
    -- Aktifkan semua animasi
    Enabled         = true,

    -- Kecepatan animasi global (1.0 = normal, 0.5 = setengah kecepatan)
    Speed           = 1.0,

    -- Durasi default tween (detik)
    DefaultDuration = 0.25,

    -- EasingStyle default
    EasingStyle     = Enum.EasingStyle.Quart,

    -- EasingDirection default
    EasingDirection = Enum.EasingDirection.Out,

    -- Durasi animasi buka window
    WindowOpenDuration  = 0.35,

    -- Durasi animasi tutup window
    WindowCloseDuration = 0.25,

    -- Durasi fade notifikasi
    NotifDuration   = 0.2,

    -- Durasi hover effect
    HoverDuration   = 0.12,

    -- Durasi tab switch
    TabSwitchDuration = 0.2,
}

-- ============================================================
-- NOTIFIKASI
-- ============================================================
Config.Notification = {
    -- Durasi notifikasi tampil sebelum menghilang (detik)
    DisplayTime     = 3.5,

    -- Posisi notifikasi: "TopRight" | "BottomRight" | "TopLeft" | "BottomLeft"
    Position        = "BottomRight",

    -- Lebar notifikasi (pixel)
    Width           = 280,

    -- Gap antar notifikasi
    Gap             = 8,

    -- Maksimal notifikasi yang ditampilkan bersamaan
    MaxVisible      = 4,

    -- Offset dari tepi layar
    EdgeOffset      = Vector2.new(16, 16),
}

-- ============================================================
-- FONT
-- ============================================================
Config.Font = {
    -- Font untuk judul besar dan heading
    Title       = Enum.Font.GothamBold,

    -- Font untuk teks body dan label umum
    Body        = Enum.Font.Gotham,

    -- Font untuk teks kecil / hint / secondary
    Small       = Enum.Font.Gotham,

    -- Font untuk badge / tag
    Badge       = Enum.Font.GothamBold,

    -- Ukuran teks untuk berbagai konteks (pixel)
    Size = {
        Title       = 16,
        Subtitle    = 12,
        SidebarItem = 13,
        ComponentLabel  = 13,
        ComponentHint   = 11,
        BadgeText       = 10,
        Notification    = 12,
        Tooltip         = 11,
    },
}

-- ============================================================
-- SIDEBAR
-- ============================================================
Config.Sidebar = {
    -- Tinggi area logo / branding di atas sidebar
    BrandingHeight  = 72,

    -- Tinggi per item menu sidebar
    ItemHeight      = 38,

    -- Gap antar item
    ItemGap         = 4,

    -- Padding horizontal item
    ItemPaddingX    = 10,

    -- Lebar indikator aktif (strip kiri)
    ActiveIndicatorWidth = 3,

    -- Radius sudut item
    ItemRadius      = 8,
}

-- ============================================================
-- DROPDOWN
-- ============================================================
Config.Dropdown = {
    -- Tinggi per opsi dalam dropdown
    OptionHeight    = 34,

    -- Maksimal tinggi dropdown sebelum scroll
    MaxHeight       = 200,

    -- Padding dalam dropdown
    PaddingX        = 10,
    PaddingY        = 6,

    -- Gap antar opsi
    OptionGap       = 2,
}

-- ============================================================
-- SLIDER
-- ============================================================
Config.Slider = {
    -- Tinggi track slider (pixel)
    TrackHeight     = 4,

    -- Ukuran thumb slider
    ThumbSize       = 14,

    -- Aktifkan snap ke nilai bulat
    SnapToInteger   = false,
}

-- ============================================================
-- SEARCH
-- ============================================================
Config.Search = {
    -- Delay setelah ketik sebelum pencarian dijalankan (detik)
    DebounceTime    = 0.15,

    -- Tinggi search bar
    BarHeight       = 36,

    -- Placeholder text
    Placeholder     = "Cari fitur...",
}

-- ============================================================
-- SAVE SYSTEM
-- ============================================================
Config.Save = {
    -- Nama folder di mana config disimpan (via writefile)
    FolderName      = "BorcaUIHub",

    -- Nama file config default
    DefaultConfig   = "default.json",

    -- Auto-save saat ada perubahan
    AutoSave        = true,

    -- Interval auto-save dalam detik
    AutoSaveInterval = 30,
}

-- ============================================================
-- KEYBIND DEFAULT
-- ============================================================
Config.Keybind = {
    -- Tombol untuk toggle UI
    ToggleUI        = Enum.KeyCode.RightControl,

    -- Tombol untuk toggle minimize
    MinimizeUI      = Enum.KeyCode.RightAlt,
}

-- ============================================================
-- INTERNAL / FLAGS
-- ============================================================
Config.Flags = {
    -- Mode debug (tampilkan warn dan print ekstra)
    Debug           = false,

    -- Tampilkan FPS counter di corner
    ShowFPS         = false,

    -- Versi internal BorcaUIHub
    Version         = "1.0.0",
}

return Config
