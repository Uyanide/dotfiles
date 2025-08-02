#!/usr/bin/env python3
import sys
import os
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
    from fontTools.ttLib.ttCollection import TTCollection
except ImportError:
    print("fontTools not installed. Please install with: pip install fonttools")
    sys.exit(1)


def modify_ttc_psname_fonttools(input_path, new_psname, output_path):
    """使用 fonttools 修改 TTC 文件的 PostScript 名称"""

    try:
        # 检查是否为 TTC 文件
        if input_path.lower().endswith('.ttc'):
            # 打开 TTC 文件
            ttc = TTCollection(input_path)
            print(f"Found {len(ttc.fonts)} fonts in TTC file")

            for i, font in enumerate(ttc.fonts):
                print(f"Processing font {i+1}/{len(ttc.fonts)}")

                # 修改 name 表中的各种名称
                name_table = font['name']

                # 为多字体 TTC 添加索引后缀
                psname = f"{new_psname}-{i}" if len(ttc.fonts) > 1 else new_psname
                family_name = new_psname.split('-')[0] if '-' in new_psname else new_psname
                full_name = f"{new_psname} {i}" if len(ttc.fonts) > 1 else new_psname

                for record in name_table.names:
                    if record.nameID == 1:  # Font family name
                        record.string = family_name
                    elif record.nameID == 4:  # Full font name
                        record.string = full_name
                    elif record.nameID == 6:  # PostScript name
                        record.string = psname

                print(f"  PostScript name: {psname}")
                print(f"  Family name: {family_name}")
                print(f"  Full name: {full_name}")

            # 保存修改后的 TTC
            ttc.save(output_path)
            print(f"Successfully saved modified TTC: {output_path}")

        else:
            # 处理单个 TTF 文件
            font = TTFont(input_path)
            name_table = font['name']

            family_name = new_psname.split('-')[0] if '-' in new_psname else new_psname

            for record in name_table.names:
                if record.nameID == 1:  # Font family name
                    record.string = family_name
                elif record.nameID == 4:  # Full font name
                    record.string = new_psname
                elif record.nameID == 6:  # PostScript name
                    record.string = new_psname

            font.save(output_path)
            print(f"Successfully saved modified TTF: {output_path}")

    except Exception as e:
        print(f"Error modifying font file: {e}")
        sys.exit(1)


def main():
    if len(sys.argv) != 4:
        print("Usage: python modify-psname-fonttools.py <input_font> <new_psname> <output_font>")
        print("Example: python modify-psname-fonttools.py input.ttc 'Microsoft YaHei' output.ttc")
        sys.exit(1)

    input_path = sys.argv[1]
    new_psname = sys.argv[2]
    output_path = sys.argv[3]

    if not os.path.exists(input_path):
        print(f"Input file does not exist: {input_path}")
        sys.exit(1)

    modify_ttc_psname_fonttools(input_path, new_psname, output_path)


if __name__ == "__main__":
    # 直接调用示例
    modify_ttc_psname_fonttools("/home/kolkas/Downloads/wqy/wqy-zenhei.ttc",
                                "Microsoft YaHei",
                                "/home/kolkas/Downloads/wqy/wqy-zenhei-modified.ttc")
