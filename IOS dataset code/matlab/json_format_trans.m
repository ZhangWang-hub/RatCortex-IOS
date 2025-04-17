%聚合后的label仍然是isat_json格式，需要修改到labelme的json 格式
% 
%功能： 修改isat_json 到lableme 的json 格式
%顺便  从readpath复制1.xlsx excel表格到savepath

clear 
clc


% 定义文件路径
readpath = ["F:\pythonProject\segment-anything-2\my_script\selected_videos\20230922 -shu-101\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20230923 -shu-102\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20230924 -shu-103\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20230924 -shu-104\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231012 -shu-113\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231016 -shu-119\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231018 -shu-120\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231019 -shu-121\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231023 -shu-123\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20231024 -shu-124\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\T20230705 -shu-shi-ba\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\T20230711 -shu-er-shi-si\_la";
            "F:\pythonProject\segment-anything-2\my_script\selected_videos\20230723 -shu-si-shi-yi\_la"
            ];


savepath = ["20230922 鼠101 双侧钻孔后迷走刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20230923 鼠102 双侧钻孔后迷走刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20230924 鼠103 双侧钻孔后迷走刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20230924 鼠104 双侧钻孔后迷走刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231012 鼠113 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231016 鼠119 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231018 鼠120 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231019 鼠121 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231023 鼠123 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "20231024 鼠124 双侧钻孔后左侧迷走神经刺激1h后0.125M KCL 2h_1s_chouyang5_diff_la";
            "T20230705 鼠十八 0.25M KCL预适应_1s_chouyang5_diff_la";
            "T20230711 鼠二十四 0.25M KCL 新方法_1s_chouyang5_diff_la";
            "20230723 鼠四十一 迷走神经刺激1h 0.25M KCL_1s_chouyang5_diff_la";
            ];
for index = 13 %1:length(readpath)
    savePath = fullfile("F:\pythonProject\segment-anything-2\my_script\re_analyze_orig_img",savepath(index));
    if exist(savePath)==0
        mkdir(savePath);
    end

    % 获取文件夹中所有的 JSON 文件
    jsonFiles = dir(fullfile(readpath(index), '*.json'));
    % 遍历每个 JSON 文件
    for i = 1:length(jsonFiles)
        % 获取当前文件的完整路径
        jsonFilePath = fullfile(jsonFiles(i).folder, jsonFiles(i).name);
        savejsonFilePath = fullfile("F:\pythonProject\segment-anything-2\my_script\re_analyze_orig_img",savepath(index), jsonFiles(i).name);
        trans_Isatjson_2_Lablemejson(jsonFilePath,savejsonFilePath);
    end
    disp(strcat(readpath(index),'  --->  ',savePath));

    excelsourcepath = fullfile(readpath(index),"1.xlsx");

    exceldestinationpath = fullfile(savePath,'1.xlsx');
    if exist(excelsourcepath,'file')==0
        error("Warning! '1.xlsx' file dose not exist, please check up!");
    end
    if exist(excelsourcepath,'file')==2
        copyfile(excelsourcepath,exceldestinationpath);
    end
end   


    
    function trans_Isatjson_2_Lablemejson(jsonFilePath,savejsonFilePath)
    
    
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
        imageFolder = savepath;
        newData.imagePath = fullfile(imageFolder, jsonData.info.name);
        newData.imageData = '';
        newData.imageHeight = jsonData.info.height;
        newData.imageWidth = jsonData.info.width;
        
        % 将新格式的结构体保存为 JSON 文件，确保字段换行
        outputFile = savejsonFilePath;  % 输出文件路径
        jsonStr = jsonencode(newData, 'PrettyPrint', true);  % 格式化输出 JSON
        fid = fopen(outputFile, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
        [pathStr, name, ext] = fileparts(outputFile);
        %disp(strcat(name,'.JSON 格式转换完成并已保存为输出文件'));
    end



