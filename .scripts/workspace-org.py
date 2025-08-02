#!/bin/env python3
'''
Author: Uyanide pywang0608@foxmail.com
Date: 2025-08-02 20:56:46
LastEditTime: 2025-08-02 21:27:07
Discription: Organize Hyprland workspaces from 1 to N, where N is the number of workspaces with windows,
             e.g. 3 5 6 -> 1 2 3.
             One must have xtra-dispatchers plugin installed and enabled to use this script.
'''

import subprocess
import re


def get_active_workspace_ids() -> list[int]:
    """Get workspace IDs that have windows > 0"""
    try:
        result = subprocess.run(['hyprctl', 'workspaces'], capture_output=True, text=True, check=True)
        output = result.stdout
    except subprocess.CalledProcessError:
        return []

    workspace_ids = []
    current_id : int | None = None

    for line in output.split('\n'):
        # Match workspace ID line
        workspace_match = re.match(r'^workspace ID (\d+)', line)
        if workspace_match:
            current_id = int(workspace_match.group(1))
            continue

        # Match windows count line
        # Only consider workspaces with at least one window
        windows_match = re.match(r'\s+windows: (\d+)', line)
        if windows_match and current_id is not None:
            windows_count = int(windows_match.group(1))
            if windows_count > 0:
                workspace_ids.append(current_id)
            current_id = None

    return sorted(workspace_ids)


def organize_workspaces(ids: list[int]) -> None:
    """Reorganize workspaces to consecutive numbers starting from 1"""
    if not ids:
        return
    moveto = 1
    for workspace_id in ids:
        if moveto != workspace_id:
            subprocess.run(['hyprctl', 'dispatch', 'workspace', str(moveto)], check=False)
            subprocess.run(['hyprctl', 'dispatch', 'plugin:xtd:bringallfrom', str(workspace_id)], check=False)
        moveto += 1


if __name__ == '__main__':
    organize_workspaces(get_active_workspace_ids())
