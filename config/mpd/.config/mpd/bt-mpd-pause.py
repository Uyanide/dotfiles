#!/usr/bin/env python3
"""Pause MPD when a Bluetooth audio transport that was playing goes away."""

import os
import shutil
import subprocess
import sys
import time

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BLUEZ = "org.bluez"
TRANSPORT_IFACE = "org.bluez.MediaTransport1"
OBJECT_MANAGER_IFACE = "org.freedesktop.DBus.ObjectManager"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"

# BlueZ may flip a transport to "idle" just before removing it, so a transport
# that was active this recently still counts as "was playing".
ACTIVE_GRACE = 3.0
MPC_TIMEOUT = 5

# mpc reads $MPD_HOST itself; only supply the fallback when it is unset.
os.environ.setdefault(
    "MPD_HOST",
    os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"),
        "mpdsocket",
    ),
)

# transport object path -> monotonic time it was last seen active
# (None = never seen active, inf = active right now)
transports = {}


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def pause(reason):
    log(f"{reason}, pausing MPD")
    try:
        result = subprocess.run(
            ["mpc", "--quiet", "pause"],
            capture_output=True,
            text=True,
            timeout=MPC_TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"mpc failed: {e}")
        return
    if result.returncode != 0:
        log(f"mpc exited {result.returncode}: {result.stderr.strip()}")


def set_state(path, state):
    if state == "active":
        transports[path] = float("inf")
    elif transports.get(path) == float("inf"):
        transports[path] = time.monotonic()
    else:
        transports.setdefault(path, None)


def was_playing(path):
    last_active = transports.get(path)
    return (
        last_active is not None
        and time.monotonic() - last_active <= ACTIVE_GRACE
    )


def on_properties_changed(interface, changed, invalidated, path=None):
    if "State" in changed:
        set_state(path, str(changed["State"]))


def on_interfaces_added(path, interfaces):
    if TRANSPORT_IFACE in interfaces:
        set_state(path, str(interfaces[TRANSPORT_IFACE].get("State", "idle")))


def on_interfaces_removed(path, interfaces):
    if TRANSPORT_IFACE not in interfaces:
        return
    playing = was_playing(path)
    transports.pop(path, None)
    if playing:
        pause(f"transport {path} removed")


def on_name_owner_changed(bus, owner):
    if not owner:
        # bluetoothd went away without telling us about each object.
        playing = any(was_playing(p) for p in transports)
        transports.clear()
        if playing:
            pause("bluetoothd vanished")
        return

    transports.clear()
    try:
        manager = dbus.Interface(
            bus.get_object(BLUEZ, "/"), OBJECT_MANAGER_IFACE
        )
        objects = manager.GetManagedObjects()
    except dbus.DBusException as e:
        log(f"GetManagedObjects failed: {e}")
        return
    for path, interfaces in objects.items():
        on_interfaces_added(path, interfaces)


def main():
    if shutil.which("mpc") is None:
        sys.exit("mpc not found in PATH")

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    bus.add_signal_receiver(
        on_properties_changed,
        signal_name="PropertiesChanged",
        dbus_interface=PROPERTIES_IFACE,
        bus_name=BLUEZ,
        arg0=TRANSPORT_IFACE,
        path_keyword="path",
    )
    bus.add_signal_receiver(
        on_interfaces_added,
        signal_name="InterfacesAdded",
        dbus_interface=OBJECT_MANAGER_IFACE,
        bus_name=BLUEZ,
    )
    bus.add_signal_receiver(
        on_interfaces_removed,
        signal_name="InterfacesRemoved",
        dbus_interface=OBJECT_MANAGER_IFACE,
        bus_name=BLUEZ,
    )
    # Fires once immediately with the current owner, which seeds `transports`.
    bus.watch_name_owner(BLUEZ, lambda owner: on_name_owner_changed(bus, owner))
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
