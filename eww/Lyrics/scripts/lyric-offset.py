#!/bin/env python3

APP_NAME = "spotify-lyrics"
STATE_DIR_NAME = "~/.local/state/eww/lyrics"
STATE_FILE_NAME = "offset"


def notify_send(title, message):
    import subprocess
    subprocess.run(["notify-send", "-t", "1000", "-a", APP_NAME, title, message], check=True)


def main():
    import sys
    import os

    state_dir = os.path.expanduser(STATE_DIR_NAME)
    if not os.path.exists(state_dir):
        os.makedirs(state_dir)

    offset_file = os.path.join(state_dir, STATE_FILE_NAME)
    if not os.path.exists(offset_file):
        with open(offset_file, "w") as f:
            f.write("0")

    if len(sys.argv) < 2:
        new_offset = 0
    else:
        try:
            increment = int(sys.argv[1])
            with open(offset_file, "r") as f:
                current_offset = int(f.read().strip())
            new_offset = current_offset + increment
        except ValueError:
            print("Invalid input. Please provide an integer value.")
            return

    with open(offset_file, "w") as f:
        f.write(str(new_offset))

    notify_send("Lyrics Speed Changed", f"The offset has been changed to {new_offset} ms.")


if __name__ == "__main__":
    main()
