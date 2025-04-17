


% 指定文件夹路径
%folder1 = '';  % 原始帧文件夹路径

folder1 = 'H:\T\20230717 鼠三十 迷走神经刺激组_1s_chouyang5_diff';

extract_clips1(folder1);

function extract_clips1(folder1)


    folder1_selected_clips = [folder1 '_selected_clips'];  % 已存在的目标文件夹路径
    
    % Excel文件路径
    excel_file = fullfile(folder1_selected_clips, 'selected_sfn_efn_record.xlsx');
    
    % 读取Excel表格中的数据，假设首行是标题
    [~,~,data] = xlsread(excel_file);  % 读取Excel文件
    data = data(2:end,:);  % 去掉第一行标题
    
    % 检查原始文件夹是否存在
    if ~exist(folder1, 'dir')
        error('原始文件夹不存在: %s', folder1);
    end
    
    % 遍历每个片段
    for i = 1:size(data,1)
        sfn = data{i,1};  % 读取开始帧名
        efn = data{i,2};  % 读取结束帧名
        
        % 创建每个片段的文件夹
        clip_folder_name = sprintf('clip%d_%s_%s', i, sfn, efn);
        clip_folder_path = fullfile(folder1_selected_clips, clip_folder_name);
        
        % 检查片段文件夹是否已经存在，如果不存在则创建
        if ~exist(clip_folder_path, 'dir')
            mkdir(clip_folder_path);
            fprintf('创建片段文件夹: %s\n', clip_folder_path);
        else
            fprintf('片段文件夹已存在: %s\n', clip_folder_path);
        end
        
        % 获取所有的帧文件列表
        suffix = '.tiff';
        a = fullfile(folder1,strcat('*',suffix));
        frame_files = dir(fullfile(folder1,strcat('*',suffix)));  % 假设图片格式为png，可以改为你的格式
        frame_files = {frame_files.name};  % 提取文件名
        
        % 筛选出开始帧和结束帧之间的所有帧
        start_idx = find(strcmp(frame_files, [sfn suffix]));
        end_idx = find(strcmp(frame_files, [efn suffix]));

        
        if isempty(start_idx) || isempty(end_idx)
            fprintf('找不到帧: %s 或 %s\n', sfn, efn);
            continue;
        end
        
        % 将开始帧到结束帧之间的帧拷贝到目标文件夹
        for j = start_idx:end_idx
            src_file = fullfile(folder1, frame_files{j});  % 原始文件路径
            dest_file = fullfile(clip_folder_path, frame_files{j});  % 目标文件路径
            copyfile(src_file, dest_file);  % 复制文件
        end
        
        %fprintf('片段 %d: 从 %s 到 %s 的帧已复制到 %s\n', i, sfn, efn, clip_folder_path);
        
    end
end