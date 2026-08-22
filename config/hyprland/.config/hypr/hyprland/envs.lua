-- Cursor

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")

-- Qt

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "Kvantum")

-- Nvidia

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")

-- Aquamarine reads AQ_DRM_DEVICES; set_display exports the resolved list as
-- HYPR_AQ_DRM_DEVICES. The fallback applies only if it was never sourced.
local drm_devices = os.getenv("HYPR_AQ_DRM_DEVICES")
if drm_devices == nil or drm_devices == "" then
    drm_devices = "/dev/dri/card0:/dev/dri/card1"
end
hl.env("AQ_DRM_DEVICES", drm_devices)

-- Input method

hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
hl.env("INPUT_METHOD", "fcitx")

-- Swing

hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Others

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
