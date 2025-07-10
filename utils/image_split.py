from PIL import Image
import numpy as np
import os

def auto_split_sprite_sheet(image_path, output_folder, base_name="frame"):
    os.makedirs(output_folder, exist_ok=True)
    img = Image.open(image_path).convert("RGBA")
    img_np = np.array(img)

    alpha = img_np[:, :, 3]
    row_sum = np.sum(alpha > 0, axis=1)
    col_sum = np.sum(alpha > 0, axis=0)

    # 自动寻找非空白行范围（多段分割）
    def find_slices(arr):
        slices = []
        in_slice = False
        for i, val in enumerate(arr):
            if val > 0 and not in_slice:
                start = i
                in_slice = True
            elif val == 0 and in_slice:
                end = i
                slices.append((start, end))
                in_slice = False
        if in_slice:
            slices.append((start, len(arr)))
        return slices

    row_slices = find_slices(row_sum)
    col_slices = find_slices(col_sum)

    index = 1
    for y0, y1 in row_slices:
        for x0, x1 in col_slices:
            if (y1 - y0 > 5) and (x1 - x0 > 5):  # 排除小碎块
                frame = img.crop((x0, y0, x1, y1))
                output_path = os.path.join(output_folder, f"{base_name}_{index}.png")
                frame.save(output_path)
                print(f"Saved {output_path}")
                index += 1

# 用法：
run_image_path = "/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/run2right.png"
save_folder = "/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/images"
auto_split_sprite_sheet(run_image_path, save_folder, base_name="player_run_right")
#split_sprite_sheet_adjustable("/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/run2right.png", "/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/images", cols=2, rows=2, base_name="player_run_right")