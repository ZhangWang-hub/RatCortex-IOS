clear;
clc;

% 定义文件夹路径
%folder1 = 'folder1';  % 原始帧文件夹路径
folder1 = 'H:\T\20230717 鼠三十 迷走神经刺激组_1s_chouyang5_diff';

final_label1(folder1);

function final_label1(folder1)

    folder1_selected_clips = [folder1 '_selected_clips'];  % 已存在的clips文件夹路径
    folder1_la = [folder1 '_la'];  % 聚合所有json的目标文件夹
    
    % 检查目标文件夹是否存在，如果存在则删除并重新创建
    if exist(folder1_la, 'dir')
        rmdir(folder1_la, 's');
        fprintf('重新生成文件夹: %s\n', folder1_la);
    end
    mkdir(folder1_la);
    % 定义源Excel文件路径和目标路径
    source_excel_file = fullfile(folder1_selected_clips, 'selected_sfn_efn_record.xlsx');
    destination_excel_file = fullfile(folder1_la, '1.xlsx');
    
    % 复制Excel文件并重命名
    if exist(source_excel_file, 'file')
        copyfile(source_excel_file, destination_excel_file);
        fprintf('已复制并重命名Excel文件到: %s\n', destination_excel_file);
    else
        warning('未找到Excel文件: %s', source_excel_file);
    end

    
    % 遍历所有clip文件夹
    clip_folders = dir(fullfile(folder1_selected_clips, 'clip*'));
    
    for k = 1:length(clip_folders)
        clip_folder_path = fullfile(clip_folders(k).folder, clip_folders(k).name);
        
        % 获取当前clip文件夹中所有的JSON文件
        jsonFiles = dir(fullfile(clip_folder_path, '*.json'));
        
        % 遍历每个JSON文件
        for i = 1:length(jsonFiles)
            % 获取当前文件的完整路径
            jsonFilePath = fullfile(jsonFiles(i).folder, jsonFiles(i).name);
            
            % 定义保存路径到目标folder1_la文件夹
            savejsonFilePath = fullfile(folder1_la, jsonFiles(i).name);
            
            % 调用转码函数，将原始json转为目标格式json
            trans_Isatjson_2_Lablemejson(jsonFilePath, savejsonFilePath);
        end
        
        fprintf('已处理文件夹: %s\n', clip_folders(k).name);
    end
    
    % 转码函数：修改 ISAT JSON 到 LableMe JSON 格式
    function trans_Isatjson_2_Lablemejson(jsonFilePath, savejsonFilePath)
        % 读取 JSON 文件内容
        jsonStr_i = fileread(jsonFilePath);
        
        % 解析 JSON 数据
        jsonData = jsondecode(jsonStr_i);
        
        % 创建目标格式的结构体
        newData.version = '5.5.0';
        newData.flags = struct();
        
        % 提取所有的点信息
        numObjects = numel(jsonData.objects);  % 获取对象的数量
        shapes = struct([]);
        
        for i = 1:numObjects
            shapes(i).label = jsonData.objects(i).category;
            shapes(i).points = jsonData.objects(i).segmentation;
            shapes(i).group_id = [];
            shapes(i).description = '';
            shapes(i).shape_type = '';
            shapes(i).flags = struct();
            shapes(i).mask = [];
        end
        
        newData.shapes = {shapes};  % 将 shapes 数组添加到 newData 中
        
        % 设置图片路径和其他信息
        newData.imagePath = jsonData.info.name;
        newData.imageData = '';
        newData.imageHeight = jsonData.info.height;
        newData.imageWidth = jsonData.info.width;
        
        % 将新格式的结构体保存为 JSON 文件
        jsonStr = jsonencode(newData, 'PrettyPrint', true);  % 格式化输出 JSON
        fid = fopen(savejsonFilePath, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
end