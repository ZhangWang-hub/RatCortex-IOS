import os
import re
import pandas as pd

# 定义根路径
root_path = r"F:\pythonProject\segment-anything-2\my_script\selected_videos"
# 转换成相对路径
root_path = os.path.relpath(root_path)

# 创建一个空的列表，用于存储数据
data = []


# 自定义排序函数，用于按数字大小排序
def extract_segment_number(folder_name):
    match = re.match(r"segment_(\d+)_.*", folder_name)  # 匹配数字部分
    return int(match.group(1)) if match else float('inf')  # 返回数字部分，匹配不到时返回无穷大


# 遍历根路径下的一级子文件夹
for folder in sorted(os.listdir(root_path)):  # 一级子文件夹排序
    folder_path = os.path.join(root_path, folder)

    # 检查是否是文件夹
    if os.path.isdir(folder_path):
        first_level_path = folder  # 一级子文件夹名（相对路径）

        # 找到该一级子文件夹下的所有二级子文件夹，并按自定义规则排序
        second_level_folders = sorted([
            subfolder
            for subfolder in os.listdir(folder_path)
            if os.path.isdir(os.path.join(folder_path, subfolder)) and "_la" not in subfolder
        ], key=extract_segment_number)  # 使用自定义的排序函数

        # 将一级子文件夹路径存储一次，后续行留空
        for idx, second_folder in enumerate(second_level_folders):
            if idx == 0:  # 只有第一次出现时存储一级子文件夹名
                data.append([first_level_path, second_folder])
            else:
                data.append([first_level_path, second_folder])

# 创建一个DataFrame对象来存储数据
df = pd.DataFrame(data, columns=["一级子文件夹", "二级子文件夹"])

# 保存到Excel文件
output_path = r"manual_leveled.xlsx"  # 你可以修改为你希望保存的路径和文件名
df.to_excel(output_path, index=False)

print(f"数据已保存到 {output_path}")
