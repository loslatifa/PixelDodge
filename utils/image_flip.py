from PIL import Image
import os

def flip_images_horizontally(folder_path, output_folder):
    """
    将指定文件夹内的所有 PNG 水平翻转并输出到目标文件夹

    :param folder_path: 输入文件夹路径
    :param output_folder: 输出文件夹路径
    """
    os.makedirs(output_folder, exist_ok=True)
    for filename in sorted(os.listdir(folder_path)):
        if filename.lower().endswith(".png"):
            img = Image.open(os.path.join(folder_path, filename))
            flipped = img.transpose(Image.FLIP_LEFT_RIGHT)
            output_path = os.path.join(output_folder, filename)
            flipped.save(output_path)
            print(f"已保存翻转帧：{output_path}")

# ======== 使用示例 ========
# 输入文件夹路径，例如：
# "C:/Users/YourName/Documents/PixelFrames"
# 输出文件夹路径，例如：
# "C:/Users/YourName/Documents/PixelFramesFlipped"

output_folder = "/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/images/player_run_left"
input_folder = "/Users/kirschgarrix/Desktop/PixelDodge Game/PixelDodge/images/player_run_right"
flip_images_horizontally(input_folder, output_folder)