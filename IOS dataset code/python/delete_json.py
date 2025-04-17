import os


# 定义源目录
selected_samples_mannal_label_path = r"F:\pythonProject\segment-anything-2\my_script\selected_samples_mannal_label"

# 目标一级子文件夹名
level_folders = ["Level1", "Level2", "Level3"]

# 遍历 selected_samples_mannal_label 下的每个 Level 文件夹
for level_folder in level_folders:
    level_folder_path = os.path.join(selected_samples_mannal_label_path, level_folder)

    if os.path.isdir(level_folder_path):
        # 遍历每个 Level 文件夹下的二级子文件夹
        for second_level_folder in os.listdir(level_folder_path):
            second_level_folder_path = os.path.join(level_folder_path, second_level_folder)

            if os.path.isdir(second_level_folder_path):
                # 遍历二级子文件夹中的所有文件，删除所有 .json 文件
                for item in os.listdir(second_level_folder_path):
                    item_path = os.path.join(second_level_folder_path, item)

                    if item.endswith(".json"):
                        print(f"删除文件: {item_path}")
                        os.remove(item_path)

print("所有 JSON 文件删除完成！")
