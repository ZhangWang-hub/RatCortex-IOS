import cv2
import numpy as np

# 模糊检测（彩色图像）
def calculate_sharpness_rgb(image):
    channels = cv2.split(image)
    sharpness_values = [cv2.Laplacian(channel, cv2.CV_64F).var() for channel in channels]
    return np.mean(sharpness_values)

def is_blurry(image, sharpness_threshold=100):
    sharpness = calculate_sharpness_rgb(image)
    return sharpness < sharpness_threshold, sharpness

# 消失检测（彩色图像）
def get_binary_mask(color_image, lower_hsv, upper_hsv):
    hsv_image = cv2.cvtColor(color_image, cv2.COLOR_BGR2HSV)
    return cv2.inRange(hsv_image, lower_hsv, upper_hsv)

def is_disappeared(mask, area_threshold=0.01):
    object_area = np.sum(mask > 0)
    total_area = mask.size
    return (object_area / total_area) < area_threshold, object_area

# 主函数：对彩色图像进行模糊和消失检测
def classify_frame(color_image, sharpness_threshold=100, lower_hsv=None, upper_hsv=None, area_threshold=0.01):
    # 模糊检测
    is_blurry_frame, sharpness = is_blurry(color_image, sharpness_threshold)
    if is_blurry_frame:
        return 'blurry', sharpness

    # 生成分割掩码
    if lower_hsv is None or upper_hsv is None:
        raise ValueError("HSV thresholds must be provided for binary mask generation.")
    mask = get_binary_mask(color_image, lower_hsv, upper_hsv)

    # 消失检测
    is_disappeared_frame, object_area = is_disappeared(mask, area_threshold)
    if is_disappeared_frame:
        return 'disappeared', object_area

    return 'clear', None

# 使用示例
if __name__ == '__main__':
    color_image = cv2.imread(r"F:\pythonProject\Unet_try\data\test\images\20231019_151250.jpg")

    lower_hsv = np.array([30, 40, 40])  # HSV下限
    upper_hsv = np.array([70, 255, 255])  # HSV上限

    result, value = classify_frame(color_image, sharpness_threshold=100, lower_hsv=lower_hsv, upper_hsv=upper_hsv, area_threshold=0.01)
    print(f"Frame classification: {result}, Metric: {value}")
