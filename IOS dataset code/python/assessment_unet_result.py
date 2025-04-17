import os
import numpy as np
from PIL import Image
from asseement import evaluate_metrics  # 调用评价指标代码


def calculate_metrics(data_path):
    overall_js, overall_fs, overall_dices = [], [], []  # 总体指标

    for dirpath, dirnames, filenames in os.walk(data_path):
        if os.path.basename(dirpath) == 'preds':  # 找到 preds 文件夹
            labels_dir = os.path.join(os.path.dirname(dirpath), 'labels')  # 对应的 labels 文件夹
            preds_parent_dir = os.path.dirname(dirpath)  # preds 并列的目录

            # 汇总当前 preds 文件夹的指标
            js, fs, dices = [], [], []

            for filename in filenames:
                if filename.lower().endswith('.jpg'):  # 处理 jpg 文件
                    pred_path = os.path.join(dirpath, filename)
                    label_path = os.path.join(labels_dir, filename)

                    if not os.path.exists(label_path):
                        print(f"Label not found for: {pred_path}")
                        continue

                    # 加载预测图像和标签
                    pred_mask = np.array(Image.open(pred_path).convert('L')) > 127  # 二值化
                    gt_mask = np.array(Image.open(label_path).convert('L')) > 127  # 二值化

                    # 计算指标
                    j_mean, f_mean, dice_mean, _ = evaluate_metrics([pred_mask], [gt_mask])

                    js.append(j_mean)
                    fs.append(f_mean)
                    dices.append(dice_mean)

            # 计算当前 preds 的平均指标
            if js and fs and dices:
                preds_avg_j = np.mean(js)
                preds_avg_f = np.mean(fs)
                preds_avg_dice = np.mean(dices)
                preds_avg_jf = (preds_avg_j + preds_avg_f) / 2

                # 保存 preds 的平均指标到 preds 并列目录
                preds_metrics_file = os.path.join(preds_parent_dir, 'preds_metrics.txt')
                with open(preds_metrics_file, 'w') as f:
                    f.write(f"J_mean: {preds_avg_j:.4f}\n")
                    f.write(f"F_mean: {preds_avg_f:.4f}\n")
                    f.write(f"Dice_mean: {preds_avg_dice:.4f}\n")
                    f.write(f"J&F_mean: {preds_avg_jf:.4f}\n")
                print(f"Saved metrics for preds folder: {dirpath}")

                # 汇总到 Level 指标和总体指标
                overall_js.extend(js)
                overall_fs.extend(fs)
                overall_dices.extend(dices)

    # 汇总每个 Level 文件夹的指标
    for level_dir in next(os.walk(data_path))[1]:  # 遍历 Level 文件夹
        level_path = os.path.join(data_path, level_dir)
        level_metrics_file = os.path.join(level_path, 'level_metrics.txt')

        # 汇总 Level 内所有 preds 的指标
        level_js, level_fs, level_dices = [], [], []
        for subdir in next(os.walk(level_path))[1]:
            preds_metrics_file = os.path.join(level_path, subdir, 'preds_metrics.txt')
            if os.path.exists(preds_metrics_file):
                with open(preds_metrics_file, 'r') as f:
                    lines = f.readlines()
                    level_js.append(float(lines[0].split(":")[1].strip()))
                    level_fs.append(float(lines[1].split(":")[1].strip()))
                    level_dices.append(float(lines[2].split(":")[1].strip()))  # 读取 Dice_mean

        if level_js and level_fs and level_dices:
            level_avg_j = np.mean(level_js)
            level_avg_f = np.mean(level_fs)
            level_avg_dice = np.mean(level_dices)
            level_avg_jf = (level_avg_j + level_avg_f) / 2

            # 保存 Level 的平均指标
            with open(level_metrics_file, 'w') as f:
                f.write(f"J_mean: {level_avg_j:.4f}\n")
                f.write(f"F_mean: {level_avg_f:.4f}\n")
                f.write(f"Dice_mean: {level_avg_dice:.4f}\n")
                f.write(f"J&F_mean: {level_avg_jf:.4f}\n")
            print(f"Saved metrics for Level folder: {level_path}")

    # 汇总总体指标
    if overall_js and overall_fs and overall_dices:
        overall_avg_j = np.mean(overall_js)
        overall_avg_f = np.mean(overall_fs)
        overall_avg_dice = np.mean(overall_dices)
        overall_avg_jf = (overall_avg_j + overall_avg_f) / 2

        # 保存总体平均指标
        overall_metrics_file = os.path.join(data_path, 'overall_metrics.txt')
        with open(overall_metrics_file, 'w') as f:
            f.write(f"J_mean: {overall_avg_j:.4f}\n")
            f.write(f"F_mean: {overall_avg_f:.4f}\n")
            f.write(f"Dice_mean: {overall_avg_dice:.4f}\n")
            f.write(f"J&F_mean: {overall_avg_jf:.4f}\n")
        print(f"Saved overall metrics to: {overall_metrics_file}")


if __name__ == '__main__':
    # 设置根路径
    data_path = r"F:\pythonProject\segment-anything-2\my_script\my_method_result"
    calculate_metrics(data_path)
