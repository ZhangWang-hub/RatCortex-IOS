clear 
clc

% 指定文件夹路径
%folder1 = 'folder1';  % 原始文件夹路径
folder1 = 'H:\T\20230717 鼠三十 迷走神经刺激组_1s_chouyang5_diff';

selected_clips1(folder1);



function selected_clips1(folder1)
    folder1_selected_clips = [folder1 '_selected_clips'];  % 目标文件夹路径
    % 检查目标文件夹是否存在，如果不存在则创建
    if ~exist(folder1_selected_clips, 'dir')
        mkdir(folder1_selected_clips);
        fprintf('创建文件夹: %s\n', folder1_selected_clips);
    else
        fprintf('文件夹已存在: %s\n', folder1_selected_clips);
    end
    
    % Excel文件路径
    excel_file = fullfile(folder1_selected_clips, 'selected_sfn_efn_record.xlsx');
    
    % 检查Excel文件是否存在，如果不存在则创建
    if ~exist(excel_file, 'file')
        % 创建Excel表格并写入第一行标题
        headers = {'SFN', 'EFN'};  % 开始帧名和结束帧名
        T = cell2table(headers);
        
        % 写入Excel文件
        writetable(T, excel_file, 'WriteVariableNames', false);
        fprintf('创建Excel文件: %s\n', excel_file);
    else
        fprintf('Excel文件已存在: %s\n', excel_file);
    end
end