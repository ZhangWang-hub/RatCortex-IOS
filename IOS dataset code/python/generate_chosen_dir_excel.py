import os
import pandas as pd

# 定义源目录和输出文件路径
selected_samples_mannal_label_path = r"F:\pythonProject\segment-anything-2\my_script\selected_samples_mannal_label"
output_excel_path = r"F:\pythonProject\segment-anything-2\my_script\manul_GT_time.xlsx"

# 存储数据的列表
data = []

# 遍历 selected_samples_mannal_label 下的每个一级子文件夹
for level_folder in os.listdir(selected_samples_mannal_label_path):
    level_folder_path = os.path.join(selected_samples_mannal_label_path, level_folder)

    if os.path.isdir(level_folder_path) and level_folder.startswith("Level"):
        # 遍历该一级子文件夹下的二级文件夹
        for second_level_folder in os.listdir(level_folder_path):
            second_level_folder_path = os.path.join(level_folder_path, second_level_folder)

            if os.path.isdir(second_level_folder_path):
                # 添加一级和二级文件夹名到数据列表
                data.append([level_folder, second_level_folder])

# 将数据保存到 Excel 文件
df = pd.DataFrame(data, columns=["一级文件夹", "二级文件夹"])
df.to_excel(output_excel_path, index=False)

print(f"Excel 文件已保存到: {output_excel_path}")
