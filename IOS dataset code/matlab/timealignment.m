%%功能：对原始帧，基于修改时间，按秒排好序，路径存入FrameSecSeq中
%其中，FrameSecSeq中帧路径排列方式为：
%FrameSecSeq=
%{f11, f12, f13, ..., f1m_1};   %第1s内的帧-> average_1s
%{f21, f22, f23, ..., f2m_2};   %第2s内的帧-> average_2s
%           ...
%{fn1, fn2, fn3, ..., fnm_n};   %第ns内的帧-> average_ns
                                %注意，m1,m2,...,m_n表示每秒内的帧数不一定相同



function FrameSecSeq = timealignment(folderPath)
    disp('  开始时间对齐...');
    % 读取文件夹中的所有图像文件
    imageFiles = dir(fullfile(folderPath, '*.tiff')); % 根据实际图像格式修改
    
    % 初始化一个结构数组来存储每个图像的创建时间和路径
    imageInfo = struct('CreateTime', {}, 'Path', {});

    % 读取每个图像的创建时间并存储
    bar = waitbar(0,'处理中...');    % waitbar显示进度条
    for i = 1:numel(imageFiles)
        fullPath = fullfile(folderPath, imageFiles(i).name);
        info = imfinfo(fullPath);
        createDateTime = datetime(info.FileModDate);
        imageInfo(i).CreateTime = createDateTime;
        imageInfo(i).Path = fullPath;
        str=['读取每个图像的创建时间并存储...',num2str(100*i/numel(imageFiles),'%.2f'),'%'];    % 百分比形式显示处理进程,不需要删掉这行代码就行
        waitbar(i/numel(imageFiles),bar,str)    
    end
    close(bar);

    % 按照创建时间排序图像信息结构数组
    [~, sortedIdx] = sort([imageInfo.CreateTime]);
    sortedImageInfo = imageInfo(sortedIdx);

    % 初始化一个单元数组来存储每秒的帧
    FrameSec = cell(1);
    secIndex = 1;
    currentSec = sortedImageInfo(1).CreateTime.Second;

    % 将每秒的帧放入数组中
    bar = waitbar(0,'处理中...');    % waitbar显示进度条
    for i = 1:numel(sortedImageInfo)
        currentImage = sortedImageInfo(i);
        if currentImage.CreateTime.Second ~= currentSec
            secIndex = secIndex + 1;
            currentSec = currentImage.CreateTime.Second;
            FrameSec{secIndex} = {currentImage};
        else
            FrameSec{secIndex} = [FrameSec{secIndex}, {currentImage}];
        end
        str=['将每秒的帧放入数组中...',num2str(100*i/numel(sortedImageInfo),'%.2f'),'%'];    % 百分比形式显示处理进程,不需要删掉这行代码就行
        waitbar(i/numel(sortedImageInfo),bar,str);  
    end
    close(bar);

    % 将每秒的帧按时间序列排列成一个二维单元数组
    FrameSecSeq = cell(numel(FrameSec), 1);
    bar = waitbar(0,'处理中...');
    for i = 1:numel(FrameSec)
        FrameSecSeq{i} = FrameSec{i};
        str=['将每秒的帧按时间序列排列成一个二维单元数组...',num2str(100*i/numel(FrameSec),'%.2f'),'%'];    % 百分比形式显示处理进程,不需要删掉这行代码就行
        waitbar(i/numel(FrameSec),bar,str); 
    end
    close(bar);
    disp('  时间对齐完成.')
end















%%没有封装成函数的脚本
%{
% 设置图像文件夹路径
folderPath = 'F:\matlab_code\seg\doudong_frames';

% 读取文件夹中的所有图像文件
imageFiles = dir(fullfile(folderPath, '*.tiff')); % 根据实际图像格式修改

% 初始化一个结构数组来存储每个图像的创建时间和路径
imageInfo = struct('CreateTime', {}, 'Path', {});

% 读取每个图像的创建时间并存储
for i = 1:numel(imageFiles)
    fullPath = fullfile(folderPath, imageFiles(i).name);
    info = imfinfo(fullPath);
    createDateTime = datetime(info.FileModDate);
    imageInfo(i).CreateTime = createDateTime;
    imageInfo(i).Path = fullPath;
end

% 按照创建时间排序图像信息结构数组
[~, sortedIdx] = sort([imageInfo.CreateTime]);
sortedImageInfo = imageInfo(sortedIdx);

% 初始化一个单元数组来存储每秒的帧
FrameSec = cell(1);
secIndex = 1;
currentSec = sortedImageInfo(1).CreateTime.Second;

% 将每秒的帧放入数组中
for i = 1:numel(sortedImageInfo)
    currentImage = sortedImageInfo(i);
    if currentImage.CreateTime.Second ~= currentSec
        secIndex = secIndex + 1;
        currentSec = currentImage.CreateTime.Second;
        FrameSec{secIndex} = {currentImage};
    else
        FrameSec{secIndex} = [FrameSec{secIndex}, {currentImage}];
    end
end

% 将每秒的帧按时间序列排列成一个二维单元数组
FrameSecSeq = cell(numel(FrameSec), 1);
for i = 1:numel(FrameSec)
    FrameSecSeq{i} = FrameSec{i};
end

% FrameSecSeq 现在包含了所有图像信息，按照创建时间排序

%}
