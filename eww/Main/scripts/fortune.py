#!/bin/env python3

import sys
import subprocess


def wrap(text, width, height):
    lines = []

    paragraphs = text.split('\n')

    for paragraph in paragraphs:
        if len(lines) >= height:
            return []

        # Skip empty paragraphs
        if not paragraph.strip():
            lines.append('')
            continue

        current_line = ''
        words = paragraph.split()

        for word in words:
            if current_line:
                test_line = current_line + ' ' + word
            else:
                test_line = word

            if len(test_line) <= width:
                current_line = test_line
            else:
                if current_line:
                    lines.append(current_line)
                    current_line = word
                else:
                    while len(word) > width:
                        lines.append(word[:width])
                        word = word[width:]
                    current_line = word

        if current_line:
            lines.append(current_line)

    return lines


RETRY_LIMIT = 10


def main():
    if len(sys.argv) != 3:
        print("Usage: fortune.py <width> <height>")
        sys.exit(1)

    try:
        width = int(sys.argv[1])
        if width <= 0:
            raise ValueError()
        height = int(sys.argv[2])
        if height <= 0:
            raise ValueError()
    except ValueError:
        print("Invalid argument.")
        sys.exit(1)

    i = 0
    while True:
        if i >= RETRY_LIMIT:
            print("Failed to get fortune after multiple attempts.")
            sys.exit(1)
        i += 1

        try:
            buffer = subprocess.check_output(['fortune', '-s'], text=True)
        except subprocess.CalledProcessError as e:
            print(f"Error running fortune: {e}")
            sys.exit(1)

        lines = wrap(buffer, width, height)

        if lines:
            break
        else:
            print("retrying...")

    for line in lines:
        print(line)


if __name__ == "__main__":
    main()
