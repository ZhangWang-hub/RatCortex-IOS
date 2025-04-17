import os
import random
import shutil
import json
import cv2
import numpy as np
from scipy.signal import convolve2d
def generate_mask_from_json(json_file_path, output_mask_path):
    """
    从 JSON 文件解析数据并生成黑白 mask 图像。
    """
    with open(json_file_path, 'r', encoding='utf-8') as f:
        json_data = json.load(f)

    # 获取图像尺寸
    img_width = json_data['info']['width']
    img_height = json_data['info']['height']

    # 创建空白 mask
    mask = np.zeros((img_height, img_width), dtype=np.uint8)

    # 遍历 JSON 中的对象，填充为 255
    for obj in json_data['objects']:
        points = np.array(obj['segmentation'], dtype=np.int32)
        points = points.reshape((-1, 1, 2))  # 转为 OpenCV 所需格式
        cv2.fillPoly(mask, [points], 255)

    # 二值化处理
    _, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)

    # 转为浮点类型以便均值滤波
    mask = mask.astype(np.float32) / 255.0

    # 7x7 的均值滤波
    kernel = np.ones((7, 7), dtype=np.float32) / 49.0
    mask_smoothed = convolve2d(mask, kernel, mode='same', boundary='symm')

    # 再次二值化
    mask_binary = np.where(mask_smoothed >= 0.5, 1, 0).astype(np.uint8)

    # 转回到 0/255 的格式
    mask_result = (mask_binary * 255).astype(np.uint8)

    # 保存 mask 图像
    cv2.imwrite(output_mask_path, mask_result)

if __name__ == '__main__':

    json_file_path = r"F:\pythonProject\segment-anything-2\my_script\my_method_data\Level3\20231012 -shu-113_segment_6_20231012_164653_20231012_164853"
    output_mask_path = os.path.join(json_file_path, "preds")
    if not os.path.exists(output_mask_path):
        os.makedirs(output_mask_path)



    for items in os.listdir(json_file_path):#json转换 ,再删除该json
        if items.endswith(".json"):
            mask_name = os.path.splitext(items)[0] + '.jpg'
            generate_mask_from_json(os.path.join(json_file_path, items), os.path.join(output_mask_path, mask_name))
            os.remove(os.path.join(json_file_path, items))
        else:
            os.remove(os.path.join(json_file_path, items))
