#!/bin/env python3
import sys
from colorthief import ColorThief


def extract_colors(image_path, palette_size=0):
    """
    Extracts the dominant color and a palette of colors from an image.

    :param image_path: Path to the image file.
    :param palette_size: Number of colors to extract (default is 5).
    :return: A tuple containing the dominant color and a list of palette colors.
    """
    if palette_size != 0 and palette_size < 2:
        raise ValueError("palette_size must not be fewer than 2.")
    color_thief = ColorThief(image_path)
    dominant_color = color_thief.get_color(quality=1)
    palette = color_thief.get_palette(color_count=palette_size) if palette_size > 0 else []
    return dominant_color, palette


def main():
    if len(sys.argv) != 2:
        print("Usage: extract-color.py <image_path>")
        sys.exit(1)
    print("{:02x}{:02x}{:02x}".format(*extract_colors(sys.argv[1])[0]), end=' ')


if __name__ == "__main__":
    main()
