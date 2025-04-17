import os
import pandas as pd
import numpy as np


def extract_metrics_from_txt(file_path):
    """
    从 metrics 文件中提取 J_mean, F_mean, J&F_mean, Dice_mean
    """
    metrics = {}
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            for line in f:
                key, value = line.strip().split(":")
                metrics[key.strip()] = float(value.strip())
    return metrics


def collect_metrics_for_method(root_path):
    """
    从根路径收集各级别 (L1, L2, L3) 和 overall 的指标
    """
    level_metrics = {}
    overall_metrics = {}

    for dirpath, dirnames, filenames in os.walk(root_path):
        # Collect level metrics
        if os.path.basename(dirpath).startswith("Level"):
            level_name = os.path.basename(dirpath)
            metrics_path = os.path.join(dirpath, "level_metrics.txt")
            level_metrics[level_name] = extract_metrics_from_txt(metrics_path)

        # Collect overall metrics
        if "overall_metrics.txt" in filenames:
            overall_metrics = extract_metrics_from_txt(os.path.join(dirpath, "overall_metrics.txt"))

    return level_metrics, overall_metrics


def create_table_data(method_paths, method_names):
    """
    创建表格数据
    """
    data = []

    for method_path, method_name in zip(method_paths, method_names):
        level_metrics, overall_metrics = collect_metrics_for_method(method_path)

        # Add level metrics
        row = [method_name]
        for level in ["Level1", "Level2", "Level3"]:
            if level in level_metrics:
                row.append(level_metrics[level].get("J_mean", np.nan))
                row.append(level_metrics[level].get("F_mean", np.nan))
                row.append(level_metrics[level].get("J&F_mean", np.nan))
                row.append(level_metrics[level].get("Dice_mean", np.nan))
            else:
                row.extend([np.nan] * 4)

        # Add overall metrics
        row.append(overall_metrics.get("J_mean", np.nan))
        row.append(overall_metrics.get("F_mean", np.nan))
        row.append(overall_metrics.get("J&F_mean", np.nan))
        row.append(overall_metrics.get("Dice_mean", np.nan))

        data.append(row)

    return data


def generate_table():
    # 方法的根路径和名称
    method_paths = [
        r"F:\pythonProject\segment-anything-2\my_script\my_method_result",
        r"F:\pythonProject\segment-anything-2\my_script\pure_sam_result",
        r"F:\pythonProject\Unet_try\data\test_leveled"
    ]
    method_names = ["Ours", "SAM2", "UNet"]

    # 创建表格数据
    data = create_table_data(method_paths, method_names)

    # 创建 DataFrame
    columns = ["Dataset"]
    for level in ["L1", "L2", "L3", "overall"]:
        columns.extend([f"{level}-J", f"{level}-F", f"{level}-J&F", f"{level}-Dice"])
    df = pd.DataFrame(data, columns=columns)

    # 保存为 CSV 文件（可选）
    output_csv_path = r"metrics_table.csv"
    df.to_csv(output_csv_path, index=False)
    print(f"Table saved to {output_csv_path}")

    # 打印表格（用于 LaTeX 或其他格式的进一步处理）
    print(df.to_markdown(index=False))  # 或者打印为 LaTeX 格式：print(df.to_latex(index=False))


if __name__ == "__main__":
    generate_table()
