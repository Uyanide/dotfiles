#!/usr/bin/env python3
"""Pause MPD when a Bluetooth audio device disconnects."""

import os
import subprocess

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

MPD_SOCKET = os.environ.get(
    "MPD_SOCKET",
    os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"),
        "mpdsocket",
    ),
)


def on_properties_changed(interface, changed, invalidated, path=None):
    if interface != "org.bluez.Device1":
        return
    if "Connected" in changed and not changed["Connected"]:
        subprocess.run(["mpc", "-h", MPD_SOCKET, "pause"], check=False)


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    bus.add_signal_receiver(
        on_properties_changed,
        signal_name="PropertiesChanged",
        dbus_interface="org.freedesktop.DBus.Properties",
        bus_name="org.bluez",
        path_keyword="path",
    )
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
