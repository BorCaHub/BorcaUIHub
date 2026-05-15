--[[
    BorcaUIHub — Feedback/FeedbackManager.lua
    ─────────────────────────────────────────
    FIX (Bug 4): Path inconsistency antara dua require yang berbeda:

    SEBELUMNYA (menyebabkan modul Feedback tidak menemukan FeedbackManager):
      - LoaderUI/Loader.lua          → require(script.Parent.Parent.Managers.FeedbackManager)
      - Feedback/BugReport.lua       → require(script.Parent.FeedbackManager)
      - Feedback/FeedbackUI.lua      → require(script.Parent.FeedbackManager)
      - Feedback/SuggestionReport.lua → require(script.Parent.FeedbackManager)
    Modul Feedback mencari "Feedback/FeedbackManager" yang tidak ada
    → error "module not found" saat form feedback dipakai.

    SEKARANG (konsisten):
      - File ini (Feedback/FeedbackManager.lua) bertindak sebagai jembatan.
      - Ia hanya meneruskan require ke lokasi asli (Managers/FeedbackManager.lua).
      - Semua modul Feedback yang pakai script.Parent.FeedbackManager sekarang
        mendapat objek yang SAMA persis dengan yang dipakai Loader.lua.
      - Tidak ada duplikasi state, tidak ada double-init, tidak ada perbedaan
        referensi antara FeedbackManager yang dipakai UI dan yang dipakai Loader.

    Kenapa pendekatan proxy bukan memindahkan file atau mengubah semua require?
      - Memindahkan Managers/FeedbackManager ke Feedback/ akan memutus Loader.lua
        dan SettingsManager yang sudah benar.
      - Mengubah semua require di Feedback/ berisiko salah path karena struktur
        folder bertingkat berbeda-beda per modul.
      - Proxy satu baris ini adalah perubahan paling minimal dan paling aman:
        hanya satu file baru, tidak ada perubahan di file lain sama sekali.
]]

-- Teruskan langsung ke FeedbackManager yang sebenarnya di Managers/
-- script.Parent       = Feedback/
-- script.Parent.Parent = root BorcaUIHub/
-- script.Parent.Parent.Managers.FeedbackManager = Managers/FeedbackManager.lua
return require(script.Parent.Parent.Managers.FeedbackManager)
