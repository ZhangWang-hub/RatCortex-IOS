import numpy as np
from sklearn.metrics import precision_score, recall_score


def calculate_iou(pred_mask, gt_mask):
    """
    计算二值掩膜的IoU（区域相似性 J）
    :param pred_mask: 预测掩膜（二值numpy数组）
    :param gt_mask: 真值掩膜（二值numpy数组）
    :return: IoU值（浮点数）
    """
    intersection = np.logical_and(pred_mask, gt_mask).sum()
    union = np.logical_or(pred_mask, gt_mask).sum()
    return intersection / union if union > 0 else 0.0


def calculate_dice(pred_mask, gt_mask):
    """
    计算二值掩膜的Dice系数
    :param pred_mask: 预测掩膜（二值numpy数组）
    :param gt_mask: 真值掩膜（二值numpy数组）
    :return: Dice系数（浮点数）
    """
    intersection = np.logical_and(pred_mask, gt_mask).sum()
    total = pred_mask.sum() + gt_mask.sum()
    return (2 * intersection) / total if total > 0 else 0.0


def calculate_f_score(pred_contour, gt_contour):
    """
    计算基于轮廓的F分数（轮廓精度 F）
    :param pred_contour: 预测轮廓（二值numpy数组）
    :param gt_contour: 真值轮廓（二值numpy数组）
    :return: F分数（浮点数）
    """
    pred_flat = pred_contour.flatten()
    gt_flat = gt_contour.flatten()
    precision = precision_score(gt_flat, pred_flat, zero_division=0)
    recall = recall_score(gt_flat, pred_flat, zero_division=0)

    #print(f"Precision: {precision}, Recall: {recall}")

    f_score = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
    return f_score


def evaluate_metrics(pred_masks, gt_masks):
    js = []
    fs = []
    dices = []

    for pred_mask, gt_mask in zip(pred_masks, gt_masks):
        # 计算区域相似性（J）
        j = calculate_iou(pred_mask, gt_mask)
        js.append(j)

        # 计算Dice系数
        dice = calculate_dice(pred_mask, gt_mask)
        dices.append(dice)

        # 检查掩膜形状是否足够大
        if pred_mask.shape[0] > 1 and pred_mask.shape[1] > 1:
            pred_contour = np.gradient(pred_mask.astype(float))[0] > 0
            gt_contour = np.gradient(gt_mask.astype(float))[0] > 0
        else:
            print("Skipping gradient calculation due to small shape:", pred_mask.shape)
            pred_contour = np.zeros_like(pred_mask)
            gt_contour = np.zeros_like(gt_mask)

        # 计算轮廓精度（F）
        f = calculate_f_score(pred_contour, gt_contour)
        fs.append(f)

    # 计算均值
    j_mean = np.mean(js)
    f_mean = np.mean(fs)
    dice_mean = np.mean(dices)

    # 综合性能
    jf_mean = (j_mean + f_mean) / 2
    return j_mean, f_mean, dice_mean, jf_mean


# 示例用法
if __name__ == "__main__":
    # 示例掩膜（用随机生成的二值数组替代实际数据）
    pred_masks = [np.random.randint(0, 2, (128, 128)) for _ in range(5)]
    gt_masks = [np.random.randint(0, 2, (128, 128)) for _ in range(5)]

    j_mean, f_mean, dice_mean, jf_mean = evaluate_metrics(pred_masks, gt_masks)
    print(f"区域相似性（J_mean）: {j_mean:.4f}")
    print(f"轮廓精度（F_mean）: {f_mean:.4f}")
    print(f"Dice系数（Dice_mean）: {dice_mean:.4f}")
    print(f"整体性能（J&F_mean）: {jf_mean:.4f}")
