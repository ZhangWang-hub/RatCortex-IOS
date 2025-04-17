% 获取文件夹中所有图像文件
inputFolder = 'G:\T\T Only_KCL\20221001 1M KCL 2h未迷走刺激_1s_regist'; % 设置你的图像文件夹路径
outputFolder = 'G:\T\T Only_KCL\20221001 1M KCL 2h未迷走刺激_1s_regist_resized_images'; % 设置保存调整后图像的文件夹路径

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

imageFiles = dir(fullfile(inputFolder, '*.tiff')); % 假设图像格式为PNG，可根据需要更改

% 设置目标尺寸
targetSize = [512, 512];

for i = 1:length(imageFiles)
    % 读取图像
    img = imread(fullfile(inputFolder, imageFiles(i).name));
    
    % 获取图像尺寸
    [rows, cols, ~] = size(img);
    
    % 如果图像尺寸大于目标尺寸，进行裁剪
    if rows > targetSize(1)
        startRow = round((rows - targetSize(1)) / 2) + 1;
        img = img(startRow:startRow + targetSize(1) - 1, :, :);
    end
    if cols > targetSize(2)
        startCol = round((cols - targetSize(2)) / 2) + 1;
        img = img(:, startCol:startCol + targetSize(2) - 1, :);
    end
    
    % 如果图像尺寸小于目标尺寸，进行镜像填充
    if rows < targetSize(1)
        padSize = targetSize(1) - rows;
        padTop = floor(padSize / 2);
        padBottom = padSize - padTop;
        img = padarray(img, [padTop, 0], 'symmetric', 'pre');
        img = padarray(img, [padBottom, 0], 'symmetric', 'post');
    end
    if cols < targetSize(2)
        padSize = targetSize(2) - cols;
        padLeft = floor(padSize / 2);
        padRight = padSize - padLeft;
        img = padarray(img, [0, padLeft], 'symmetric', 'pre');
        img = padarray(img, [0, padRight], 'symmetric', 'post');
    end
    
    % 确保最终尺寸为目标尺寸
    img = imresize(img, targetSize);
    
    % 保存调整后的图像
    imwrite(img, fullfile(outputFolder, imageFiles(i).name));
end

disp('All images have been resized to 512x512.');
