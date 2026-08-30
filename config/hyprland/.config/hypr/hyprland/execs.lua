hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("waybar")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/soteria-polkit/soteria")
    hl.exec_cmd("solaar -w hide")
end)

-- See ~/.config/niri/config/execs.kdl for programs started by
-- systemd-unit and xdg-autostart
