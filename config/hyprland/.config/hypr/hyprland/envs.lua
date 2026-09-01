-- Aquamarine reads AQ_DRM_DEVICES; set_display exports the resolved list as
-- HYPR_AQ_DRM_DEVICES. The fallback applies only if it was never sourced.
local drm_devices = os.getenv("HYPR_AQ_DRM_DEVICES")
if drm_devices == nil or drm_devices == "" then
    drm_devices = "/dev/dri/card0:/dev/dri/card1"
end
hl.env("AQ_DRM_DEVICES", drm_devices)
