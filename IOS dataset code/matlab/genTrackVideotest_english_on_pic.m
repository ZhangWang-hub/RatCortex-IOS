


clc
clear all


% 循环调用单个文件夹数据处理函数 处理所有文件夹

%---------------------文件路径在这里修改--------------------------
% path1 = "G:\T";                     %硬盘1
% path2 = "H:\T\T Only_KCL";          %硬盘2
% path3 = "J:\其余数据\优先数据\T";    %硬盘3
% path4 = "K:\T";                     %硬盘4
path5 = "H:\T1";                %硬盘5
%path5 = "G:\T\T Only_KCL";
%Ptest = "H:\103Ttest";
% %path1-path4在远程端
%pathlist = [path1,path2,path3,path4]';
pathlist = [path5];

folderPathList = string([]);
for i = 1:length(pathlist) %硬盘数 
    subdirpathi = dir(pathlist(i));
    for j = 1 : length( subdirpathi )
        namej = strsplit(subdirpathi( j ).name,'_');
        if(  ( subdirpathi( j ).name~="." ) && ( subdirpathi( j ).name~= "..") ...
           &&( namej(end) ~= "1s" ) && ( namej(end) ~= "diff" )  ...
           && ( namej(end) ~= "la" )  && ( namej(end) ~= "mask" ) && ( namej(end) ~= "result" )   )               % 如果是目录则跳过
            folderPathList =[folderPathList; fullfile(subdirpathi(j).folder,subdirpathi(j).name)];
        end
    end
end



for i = 1:length(folderPathList)

    OriginalPath = strcat(folderPathList(i),"_1s");    DimagePath = strcat(OriginalPath,"_chouyang5_diff");
    JsonLabelPath = strcat(DimagePath,"_la");
    MaskLabelPath = strcat(JsonLabelPath,"_mask");
    ResultPath = strcat(DimagePath,"_result");
    
    %路径预处理，生成不存在的文件夹
    if exist(ResultPath,'dir')  %若存在result 文件夹，说明之前运行过代码
        delete(strcat(ResultPath,'\*'));      %先删除result 文件夹下的结果，以便删除之前运行的结果，确保本次运行结果都是新的
    else
        mkdir(ResultPath);% 建立result 文件夹
    end

    t = readtable(fullfile(JsonLabelPath,"1.xlsx"));
    
    % SFN EFN ：一段信号的 startfname, endfname 列表，需要标label时记录
    SFN = t.SFN;
    EFN = t.EFN;
    
    %信号片段数量
    signalclipsnums = length(SFN);
    disp(strcat(OriginalPath,"文件夹正在处理..."));
    for ii = 1:signalclipsnums
        disp(strcat("   信号",num2str(ii),"正在处理..."));
        startfname = SFN(ii);
        endfname = EFN(ii);
        singalclips_index = ii;
        labels_struct = genTrackVideo1(OriginalPath,DimagePath,JsonLabelPath,MaskLabelPath,ResultPath, startfname,endfname);
        

        %数据写入表
        signalfragengname = strcat('[',startfname,'--',endfname,']');
        fieldNames = fieldnames(labels_struct);
        for k = 1:numel(fieldNames)
            valid_label_name = string(fieldNames(k));
        
            % newdata = {'SignalClipsName', 'Labelindex', 'OrigalPoint_x', 'OrigalPoint_y', ...
                %         'EndPoint_x', 'EndPoint_y', 'SignalAmp', 'AverageSpeed', 'Distance', 'LastTime', 'CoverArea'};
            SignalClipsName = signalfragengname;
            Labelindex = labels_struct.(valid_label_name).name;
            Brain_region = labels_struct.(valid_label_name).region;
            OrigalPoint_x = labels_struct.(valid_label_name).initialCentroid(1);
            OrigalPoint_y = labels_struct.(valid_label_name).initialCentroid(2);
            EndPoint_x = labels_struct.(valid_label_name).endCentroid(1);
            EndPoint_y = labels_struct.(valid_label_name).endCentroid(2);
            SignalAmp = 1;
            AverageSpeed = labels_struct.(valid_label_name).averagespeed;
            Distance = labels_struct.(valid_label_name).journery;
            LastTime = labels_struct.(valid_label_name).timestart2current ; 
            CoverArea = labels_struct.(valid_label_name).cover_area; 
            
            newData = {SignalClipsName, Labelindex,Brain_region, OrigalPoint_x, OrigalPoint_y, EndPoint_x, EndPoint_y, SignalAmp, AverageSpeed, Distance, LastTime, CoverArea};
            if (ii ==1 && k == 1)
                overwriteflag = 1;
            else
                overwriteflag = 0;
            end
            recordData2Excel(ResultPath, newData,overwriteflag);
    
            
            Amp = labels_struct.(valid_label_name).amp;
            recordAmp2Excel(ResultPath,SignalClipsName,Labelindex,Amp);
            
        end







    end
    disp(strcat(OriginalPath,"文件夹处理完成."));

end















%***************************************************************************************************************
%***************************************************************************************************************
% 函数名：genTrackVideo1
% 功能：  由手动标记的label图像和差值图像生成的伪彩 ，生成信号追踪视频
% 参数说明：
%          -DimagePath：     差值图像路径
%          -JsonLabelPath:   Json label路径
%          -MaskLabelPath:   Json label 生成的mask存储路径
%          -ResultPath：     需要的处理指标存储路径
%          -startfname：     有信号视频片段的首帧，从标记的label图像获得
%          -endfname：       有信号视频片段的末帧，从标记的label图像获得

% 作者： zengguang zhangwang 
% 时间： 2024/5/19
%***************************************************************************************************************
%***************************************************************************************************************

function labels_struct = genTrackVideo1(OriginalPath,DimagePath,JsonLabelPath,MaskLabelPath,ResultPath, startfname,endfname)

%------------------------路径信息-----------------------------------------------
%
% 读取label名包含时间信息
labelinfo = dir(fullfile(JsonLabelPath,"*.json"));

%----------------------------------------------------------------------------


%---------------------初始化变量设置----------------------------
% 普通变量初始化

namelist =[];

signalfragengname = strcat('[',startfname,'--',endfname,']');

% 创建 VideoWriter 对象
%outputVideo = VideoWriter(fullfile(ResultPath,strcat(signalfragengname,'video.avi'))); % 您可以选择不同的文件名和格式
outputVideo = VideoWriter(fullfile(ResultPath,strcat(signalfragengname,'video.mp4')),'MPEG-4'); % 您可以选择不同的文件名和格式
outputVideo.FrameRate = 10; % 设置帧率，例如 10 帧/秒
open(outputVideo);

%
%********************************************************************************
%------------------------------------main----------------------------------------
%********************************************************************************


%-----------------------------------预处理---------------------------------
%根据首尾帧name计算该片段中所有帧名字
for i = 1:length(labelinfo)
    namecell = split(labelinfo(i).name,'.');
    if (string(namecell(1))>=startfname) && (string(namecell(1))<=endfname)
        namelist = [namelist,string(namecell(1))];
    end
end
namelist = namelist';


%--------------------------------------------------------------------------






%-------由mask的json 文件生成每一帧mask.jpg图---------------------------
%-------同时计算一次完整信号的覆盖区域的数值并生成覆盖区域mask------------
%
eachsignalclips = namelist;
% 初始化 labels_struct
labels_struct = struct();
%step1
for i = 1:length(eachsignalclips)
    % 读取 JSON 文件
    jsonStr_i = fileread(fullfile(JsonLabelPath, strcat(eachsignalclips(i), '.json')));
    jsondata_i = jsondecode(jsonStr_i);

    % 初始化全局 Mask
    mask_all = zeros(512, 512);

    % 聚合所有点生成大 Mask
    for j = 1:length(jsondata_i.shapes)
        points = jsondata_i.shapes(j).points;
        roi_x = points(:, 1);
        roi_y = points(:, 2);
        mask_all = mask_all + poly2mask(roi_x, roi_y, 512, 512);
    end
    mask_all(mask_all ~= 0) = 1;
    %mask 平滑滤波去锯齿
    mask_label_filtered = filter2(fspecial('average',11),mask_all);
    mask_label_filtered(find(mask_label_filtered<0.5)) = 0;
    mask_label_filtered(find(mask_label_filtered>=0.5)) = 1;
    mask_all = mask_label_filtered;

    % 保存大 Mask
    imwrite(mask_all, fullfile(MaskLabelPath, strcat(eachsignalclips(i), '.jpg')));


    % 按标签聚合点并记录中心、面积
    for j = 1:length(jsondata_i.shapes)
        label_name = jsondata_i.shapes(j).label;
        valid_label_name = matlab.lang.makeValidName(label_name);
        points = jsondata_i.shapes(j).points;
        roi_x = points(:, 1);
        roi_y = points(:, 2);

        if ~isfield(labels_struct, valid_label_name)
            labels_struct.(valid_label_name).name = label_name;
            labels_struct.(valid_label_name).region = [];
            labels_struct.(valid_label_name).points = [];
            labels_struct.(valid_label_name).centers = {};
            labels_struct.(valid_label_name).centerpoints={};%用于累计中心点，在循环中供轨迹显示用
            labels_struct.(valid_label_name).ampsamplepoint={};
            labels_struct.(valid_label_name).ampsampleblocks={};
            labels_struct.(valid_label_name).amp = [];
            labels_struct.(valid_label_name).areas = [];
            labels_struct.(valid_label_name).initialCentroid = [];
            labels_struct.(valid_label_name).distancelist = [];
            labels_struct.(valid_label_name).journery = [];
            labels_struct.(valid_label_name).averagespeed = [];
            labels_struct.(valid_label_name).endCentroid = [];
            labels_struct.(valid_label_name).starttime = [];
            labels_struct.(valid_label_name).prevCentroid = [];
            labels_struct.(valid_label_name).prevtime = [];
            labels_struct.(valid_label_name).timestart2current = [];
            labels_struct.(valid_label_name).masks = zeros(512, 512); % 存储合并后的掩模
        end
    
        labels_struct.(valid_label_name).points = [labels_struct.(valid_label_name).points; points];
    
        % 生成每帧的标签 Mask 并合并
        current_mask = poly2mask(roi_x, roi_y, 512, 512);

        %mask 平滑滤波去锯齿
        mask_label_filtered = filter2(fspecial('average',11),current_mask);
        mask_label_filtered(find(mask_label_filtered<0.5)) = 0;
        mask_label_filtered(find(mask_label_filtered>=0.5)) = 1;

        current_mask = mask_label_filtered;
        labels_struct.(valid_label_name).masks = labels_struct.(valid_label_name).masks + double(current_mask);
    end

    % 计算中心和面积
    for k = fieldnames(labels_struct)'
        valid_label_name = k{1};
        mask_label = labels_struct.(valid_label_name).masks;
        mask_label(mask_label ~= 0) = 1; % 二值化
        mask_label = imbinarize(mask_label);%转为逻辑值
        %mask_label = uint16(mask_label);



        % 计算中心和面积
        [rows, cols] = size(mask_label);
        [x, y] = meshgrid(1:cols, 1:rows);
        mask_area = sum(mask_label(:));
        if mask_area > 0
            centroid = [sum(x(mask_label) / mask_area), sum(y(mask_label) / mask_area)];%mask_label为逻辑值才能用于矩阵索引
        else
            centroid = [NaN, NaN]; % 避免除零错误
        end

        % 记录中心和面积
        labels_struct.(valid_label_name).centers = [labels_struct.(valid_label_name).centers; {eachsignalclips(i),centroid}];
        labels_struct.(valid_label_name).areas = [labels_struct.(valid_label_name).areas; mask_area];
        
        % 清空合并掩模以便处理下一帧
        labels_struct.(valid_label_name).masks = zeros(512, 512);
    end

end

%Step 2: 生成标签区域 Mask
label_names = fieldnames(labels_struct);

for k = 1:length(label_names)
    valid_label_name = label_names{k};
    points = labels_struct.(valid_label_name).points;

    % 生成标签覆盖区域 Mask
    area_x = points(:, 1);
    area_y = points(:, 2);
    cm_bdp = boundary(area_x,area_y); %covermask_boundarypoints
    cm_bdp_x = area_x(cm_bdp);
    cm_bdp_y = area_y(cm_bdp);
    cover_mask =  poly2mask(cm_bdp_x,cm_bdp_y,512,512);

    % 保存标签覆盖区域 Mask
    imwrite(cover_mask, fullfile(MaskLabelPath, strcat(valid_label_name, '_cover.jpg')));

    % 计算区域面积
    cover_area = sum(cover_mask(:)) * (10.5/512)^2;
    labels_struct.(valid_label_name).cover_area = cover_area;
end




% for i = 1:length(eachsignalclips)
%     jsonStr_i = fileread(fullfile(JsonLabelPath,strcat(eachsignalclips(i),'.json')));
%     jsondata_i = jsondecode(jsonStr_i);
% 
%     num_rois = length(jsondata_i.shapes);%rois 可能属于多个信号label
% 
%     %num_rois表示label数量，jsondata_i是label结构体，
%     % 初始化一个结构体数组，用于按标签分类存储 ROIs
%     labels_struct = struct();
% 
%     % 遍历所有 ROIs
%     for j = 1:num_rois 
%         label_name = jsondata_i.shapes(j).label;% 获取当前 ROI 的标签名
%         valid_label_name = matlab.lang.makeValidName(label_name);
%         points = jsondata_i.shapes(j).points;% 获取当前 ROI 的点
%         % 如果该标签还未在结构体中创建，初始化该标签的字段
%         if ~isfield(labels_struct, valid_label_name)
%             labels_struct.(valid_label_name).name = label_name;
%             labels_struct.(valid_label_name).points = [];
%         end
%         % 将当前 ROI 的点添加到该标签的 points 列表中
%         labels_struct.(valid_label_name).points = [labels_struct.(valid_label_name).points; points];
%     end
%     % 处理每个标签，生成掩码并计算覆盖区域
%     label_names = fieldnames(labels_struct);
%     mask2toatal = zeros([512,512]);
%     for k = 1:length(label_names)
%         % 获取当前标签的点
%         valid_label_name = label_names{k};
%         points = labels_struct.(valid_label_name).points;
% 
%         % 初始化掩码
%         mask = zeros(512, 512);
%         % 获取 ROI 的 x 和 y 坐标
%         roi_x = points(:,1);
%         roi_y = points(:,2);
% 
%         % 创建 ROI 的掩码
%          mask = poly2mask(roi_x, roi_y, 512, 512);
%         % 将掩码值限定为 1
%         mask(mask ~= 0) = 1;
% 
%         % 对掩码进行均值滤波处理
%         mask1 = filter2(fspecial('average', 11), mask);
%         mask2 = mask1;
%         mask2(mask2 < 0.5) = 0;
%         mask2(mask2 >= 0.5) = 1;
%         % 保存处理后的掩码
%         imwrite(mask2, fullfile(MaskLabelPath, strcat(eachsignalclips(i), '_', valid_label_name, '.jpg')));
%         mask2copy = mask2;
% 
% 
%         % 计算所有点的边界并生成覆盖区域掩码
%         cm_bdp = boundary(roi_x, roi_y);
%         cm_bdp_x = roi_x(cm_bdp);
%         cm_bdp_y = roi_y(cm_bdp);
%         coverareamask = poly2mask(cm_bdp_x, cm_bdp_y, 512, 512);
% 
%         % 对覆盖区域掩码进行均值滤波处理
%         coverareamask1 = filter2(fspecial('average', 31), coverareamask);
%         coverareamask2 = coverareamask1;
%         coverareamask2(coverareamask2 < 0.5) = 0;
%         coverareamask2(coverareamask2 >= 0.5) = 1;
% 
%         % 计算覆盖区域的真实面积
%         pix_real_area = (10.5 / 512)^2;  % 平方毫米
%         signal_cover_area = bwarea(coverareamask2) * pix_real_area;
%         % 输出信号覆盖区域
%         disp(['Signal Cover Area for_f', num2str(i),' ',valid_label_name, ': ', num2str(signal_cover_area), ' mm^2']);
%     end
% 
%     % 将掩码值限定为 1
%     mask2toatal = mask2toatal + mask2copy;
%     mask2toatal(mask2toatal ~= 0) = 1;
%     %imwrite(mask2toatal, fullfile(MaskLabelPath, strcat(eachsignalclips(i), '.jpg')));
% 
% 
% 
% end


%---------------------------------------------------------------------------------





%------------循环一次信号序列包含的所有帧,生成信号移动的伪彩视频-----------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  step3  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 初始化一些变量
Frame1name = split(eachsignalclips(1), '_'); % 分离时间和日期
time1 = Frame1name(2);
[hh1, mm1, ss1] = str2time(time1);
t1 = hh1 * 3600 + mm1 * 60 + ss1; % start time : s
tstart = t1;

% 初始化轨迹、距离和速度相关变量
dislist = []; % 相邻两帧信号中心距离
dis2list = []; % 当前帧到初始帧信号中心距离
t2clist = [];
speedminlist = [];
plmin = 10.5 / 512; % signal pixel length min
plmax = 11 / 512; % signal pixel length max
alpha1 = 0.9; % 透明度设置
alpha2 = 0.5; % 透明度设置


label_names = fieldnames(labels_struct);



%算出一次信号片段中 每个label对应的信号的 长度（帧数） ,
% 取路径中间三个点，每个点为中心的3x3block 算信号强度
for ii = 1:length(label_names)
    valid_label_nameii = label_names{ii};
    signal_center_track_points_nums = length(labels_struct.(valid_label_nameii).centers);
    gap = round(signal_center_track_points_nums/4);
    sampleindex = [gap,2*gap,3*gap];
    %fprintf("[gap,2*gap,3*gap]:[%d, %d, %d]\n",sampleindex);%
    ampsamplepoint = labels_struct.(valid_label_nameii).centers(sampleindex,:);
    labels_struct.(valid_label_nameii).ampsamplepoint = ampsamplepoint(:,2);
    %fprintf("labelNo.:%d\n",ii);

    for jj =1:length(labels_struct.(valid_label_nameii).ampsamplepoint)%
        point_jj = labels_struct.(valid_label_nameii).ampsamplepoint(jj);
        %disp(point_jj);
        point_jj = cell2mat(point_jj);
        
        x_jj = round(point_jj(1));
        y_jj = round(point_jj(2));
        ampsampleblock_x = [x_jj-1,x_jj,x_jj+1]; %采样block x

        ampsampleblock_y = [y_jj-1,y_jj, y_jj+1]; %采样block y
        %fprintf("labelNo.%d ---> samplePointsNo.%d\n",ii,jj);
        %fprintf("sample_xy:[%d,%d,%d],[%d,%d,%d]\n",ampsampleblock_x,ampsampleblock_y);
        %[X_jj,Y_jj] = meshgrid(ampsampleblock_x,ampsampleblock_y);
        labels_struct.(valid_label_nameii).ampsampleblocks = [labels_struct.(valid_label_nameii).ampsampleblocks;[ampsampleblock_x;ampsampleblock_y]];%采样block
        
    end
end








for index = 1:length(eachsignalclips)
    mask_img_path = fullfile(MaskLabelPath, eachsignalclips(index));
    signal_img_path = fullfile(DimagePath, strcat(eachsignalclips(index), ".tiff"));
    orignal_img_path = fullfile(OriginalPath, strcat(eachsignalclips(index), ".tiff"));

    signal_img = imread(signal_img_path);
    original_img = im2uint8(imread(orignal_img_path));
    mask_img = imread(strcat(mask_img_path, '.jpg'));
    
    % 转伪彩
    if size(signal_img, 3) == 1
        signal_img8bit = im2uint8(signal_img);
        signal_img = ind2rgb(gray2ind(signal_img8bit, 256), jet(256));
    end
    
    signal_img = cat(3, original_img, original_img, original_img) * alpha1 ...
                 + (im2uint8(signal_img) .* im2uint8(mask_img)) * alpha2;
    originalImage = signal_img;




    Frameiname = split(eachsignalclips(index), '_'); % 分离时间和日期
    timei = Frameiname(2);
    [hhi, mmi, ssi] = str2time(timei);
    ti = hhi * 3600 + mmi * 60 + ssi; % start time : s  
    t2 = ti;


    labelnums = length(label_names);

    % 一帧内 循环label
    for k = 1:labelnums
        current_label_name = labels_struct.(valid_label_name).name;
        %disp(current_label_name);
        if strcmp(current_label_name, '1') || strcmp(current_label_name, '1-2') || strcmp(current_label_name, '2') || strcmp(current_label_name, '2-2')
            %disp(strcat('label1:', current_label_name))
            labels_struct.(valid_label_name).region = 'left';
        end
        if strcmp(current_label_name,'3') ||strcmp(current_label_name,'3-2') ||strcmp(current_label_name,'4')||strcmp(current_label_name,'4-2')
            %disp(strcat('lable3:',current_label_name))
            labels_struct.(valid_label_name).region = 'right';
        end

        valid_label_name = label_names{k};
        % 从 labels_struct 获取中心和面积
        centercell = labels_struct.(valid_label_name).centers(index,:);
        if isnan(cell2mat(centercell(2)))
            continue;
        end
        center_frame_name = string(centercell(1));

        % 每个label不一定在每帧图中都有，没有的center补一个空的cell
        if(center_frame_name == eachsignalclips(index))
            centroid = cell2mat(centercell(2));
            labels_struct.(valid_label_name).centerpoints = [labels_struct.(valid_label_name).centerpoints,{centroid}];%中心点累计，用于轨迹显示
            %进入这个if 说明此次label为k， 在index 帧中存在 这帧需要计算该信号的幅度（根据采样block）
            samplepoints = labels_struct.(valid_label_nameii).ampsampleblocks;
            amp_3pp = [];
            for pp = 1:length(samplepoints)
                pp_block_xy = cell2mat(samplepoints(pp));
                orig_img = imread(orignal_img_path);
                [orig__x,orig_y] = size(orig_img);
                %disp(pp_block_xy(1,:))
                %disp(pp_block_xy(2,:))
                if pp_block_xy(1,1)<=0 
                   pp_block_xy(1,:) = pp_block_xy(1,:)+1;
                end
                
                if pp_block_xy(2,1)<=0 
                   pp_block_xy(2,:) = pp_block_xy(2,:)+1;
                end    
                if pp_block_xy(1,3)>=orig__x 
                   pp_block_xy(1,:) = pp_block_xy(1,:)-1;
                end   
                if pp_block_xy(2,3)>=orig_y  
                   pp_block_xy(2,:) = pp_block_xy(2,:)-1;
                end  
                
                %fprintf("signal[%d] --> label[%d] -->point[%d]  sample points:x[%d %d %d],y[%d %d %d]----[%s]\n",index,k,pp,pp_block_xy(1,:),pp_block_xy(2,:),eachsignalclips(index));

              
                block = orig_img(pp_block_xy(1,:),pp_block_xy(2,:)) ;
                %disp(block);
                amp_pp = mean2(block);
                amp_3pp = [amp_3pp,amp_pp];

            end
            labels_struct.(valid_label_name).amp = [labels_struct.(valid_label_name).amp;amp_3pp];
       

        else
            centroid = [];%清空centroid变量
            if(index==1)
                labels_struct.(valid_label_name).centers = [[{NaN},{NaN}];labels_struct.(valid_label_name).centers];
                labels_struct.(valid_label_name).areas = [0;labels_struct.(valid_label_name).areas];
            end
            if(index==length(eachsignalclips))
                labels_struct.(valid_label_name).centers = [labels_struct.(valid_label_name).centers;[{NaN},{NaN}]];
                labels_struct.(valid_label_name).areas = [labels_struct.(valid_label_name).areas;0];
            end
            if(index>1 && index<length(eachsignalclips))
                labels_struct.(valid_label_name).centers = [labels_struct.(valid_label_name).centers(1:index-1,:);[{NaN},{NaN}];labels_struct.(valid_label_name).centers(index:end,:)];
                labels_struct.(valid_label_name).areas = [labels_struct.(valid_label_name).areas(1:index-1);0;labels_struct.(valid_label_name).areas(index:end)];
            end
            continue;%进入else 说明当前帧没有此label，后续不用算了，算也有错误
        end
        
        maskArea = labels_struct.(valid_label_name).areas(index);
        

        % 如果这是第一帧，记录初始中心
        if isempty(labels_struct.(valid_label_name).initialCentroid)
            labels_struct.(valid_label_name).initialCentroid = centroid;
            labels_struct.(valid_label_name).starttime = t2;
            labels_struct.(valid_label_name).prevtime = t2;
        end
        




        timeDiff = t2 - labels_struct.(valid_label_name).prevtime;% 两个中心点之间的时间差（秒）
        labels_struct.(valid_label_name).timestart2current = t2 - labels_struct.(valid_label_name).starttime;% 信号开始到当前时刻的时间差
        t2clist = [t2clist, labels_struct.(valid_label_name).timestart2current];
            
        % 找到掩模的边缘
        maskEdges = edge(mask_img, 'Sobel');

        % 高亮显示边缘
        highlightedColor = [255, 0, 0]; % 红色高亮
        for channel = 1:3
            channelData = originalImage(:, :, channel);
            channelData(maskEdges) = highlightedColor(channel);
            originalImage(:, :, channel) = channelData;
        end

        % 添加箭头（如果有前一个中心点）
        %disp(index);disp(k);
        if ~isempty(labels_struct.(valid_label_name).prevCentroid) && any(labels_struct.(valid_label_name).prevCentroid ~= centroid)
            originalImage = insertShape(originalImage, 'Line', [labels_struct.(valid_label_name).prevCentroid, centroid], 'Color', 'yellow', 'LineWidth', 2);

            % 箭头参数
            arrowSize = 10; % 箭头大小
            angle = atan2(centroid(2) - labels_struct.(valid_label_name).prevCentroid(2), centroid(1) - labels_struct.(valid_label_name).prevCentroid(1)); % 计算角度

            % 计算箭头头部的两个点
            arrowPoint1 = centroid - arrowSize * [cos(angle - pi/4), sin(angle - pi/4)];
            arrowPoint2 = centroid - arrowSize * [cos(angle + pi/4), sin(angle + pi/4)];

            % 绘制箭头头部
            originalImage = insertShape(originalImage, 'FilledPolygon', [centroid, arrowPoint1, arrowPoint2], 'Color', 'yellow', 'Opacity', 1);

            % 计算传播速度
            distance = sqrt((centroid(1) - labels_struct.(valid_label_name).prevCentroid(1))^2 + (centroid(2) - labels_struct.(valid_label_name).prevCentroid(2))^2);
            distance2 = sqrt((centroid(1) - labels_struct.(valid_label_name).initialCentroid(1))^2 + (centroid(2) - labels_struct.(valid_label_name).initialCentroid(2))^2);

            distancemin = plmin * distance; % unit mm
            distancemax = plmax * distance; % unit mm

            distancemin2 = plmin * distance2;

            labels_struct.(valid_label_name).distancelist = [labels_struct.(valid_label_name).distancelist,distancemin]; %记录相邻两点距离的 列表
            dis2list = [dis2list, distancemin2];

            speedmin = distancemin / timeDiff * 60;
            speedmax = distancemax / timeDiff * 60;

            distancemin2 = plmin * distance2;
            distancemax2 = plmax * distance2;
            speedmin2 = distancemin2 / labels_struct.(valid_label_name).timestart2current  * 60;
            speedmax2 = distancemax2 / labels_struct.(valid_label_name).timestart2current  * 60;

            % 显示传播速度
            speedTextmin = sprintf('Inst V: %.2f mm/min', speedmin);
            speedminlist = [speedminlist, speedmin];
            originalImage = insertText(originalImage, [20, 60*(k-1)+10], speedTextmin, 'TextColor', 'white', 'FontSize', 12, 'BoxOpacity', 0,'Font', fontName);


            labels_struct.(valid_label_name).journery  = sum(labels_struct.(valid_label_name).distancelist); 
            labels_struct.(valid_label_name).averagespeed = labels_struct.(valid_label_name).journery / labels_struct.(valid_label_name).timestart2current * 60;
            speedTextmin2 = sprintf('Aver V: %.2f mm/min', labels_struct.(valid_label_name).averagespeed);
            originalImage = insertText(originalImage, [200, 60*(k-1)+10], speedTextmin2, 'TextColor', 'white', 'FontSize', 12, 'BoxOpacity', 0,'Font', fontName);




        end

        % 更新 prevCentroid 为当前帧的中心
        labels_struct.(valid_label_name).prevCentroid = centroid;
        % 更新 endCentroid 为当前帧的中心
        labels_struct.(valid_label_name).endCentroid = centroid;
         % 更新 prevtime 为当前帧的时间
        labels_struct.(valid_label_name).prevtime = t2;



        % 最大最小面积
        pixmin = (10.5 / 512)^2; % 平方毫米
        pixmax = (11 / 512)^2; % 平方毫米

        % 添加文本标注，指定字体
        fontName = 'Microsoft YaHei'; % 或者其他支持中文的字体
        maskAreamax = maskArea * pixmax;
        maskAreamin = maskArea * pixmin;

        originalImage = insertText(originalImage, [350, 60*(k-1)+10], ['Aera: ', num2str(maskAreamax), 'mm²'], 'TextColor', 'white', 'BoxOpacity', 0, 'FontSize', 12, 'Font', fontName);
        originalImage = insertText(originalImage, centroid, ['Central point: (', num2str(centroid(1)), ', ', num2str(centroid(2)), ')'], 'TextColor', 'white', 'BoxOpacity', 0, 'FontSize', 12, 'Font', fontName);

        if length(labels_struct.(valid_label_name).centerpoints) >= 2
            % 起源点
            originalImage = insertText(originalImage, labels_struct.(valid_label_name).initialCentroid, ...
                ['Original point: (', num2str(labels_struct.(valid_label_name).initialCentroid(1)), ', ', num2str(labels_struct.(valid_label_name).initialCentroid(2)), ')'], ...
                'TextColor', 'white', 'BoxOpacity', 0, 'FontSize', 12, 'Font', fontName);

            % 传播方向
            originalImage = insertShape(originalImage, 'line', [labels_struct.(valid_label_name).initialCentroid, centroid], 'Color', 'green', 'LineWidth', 3); %

            % 传播距离
            dis = (10.5 / 512 * sqrt(sum((centroid - labels_struct.(valid_label_name).initialCentroid).^2)));
            transferdistText = sprintf('Distance: %.2f mm', dis);

            originalImage = insertText(originalImage, (labels_struct.(valid_label_name).initialCentroid + (centroid - labels_struct.(valid_label_name).initialCentroid) / 2), ...
                transferdistText, 'TextColor', 'green', 'BoxOpacity', 0, 'FontSize', 12, 'Font', fontName);

            % 传播轨迹
         
            originalImage = insertShape(originalImage, 'line', cell2mat(labels_struct.(valid_label_name).centerpoints), 'Color', 'red', 'LineWidth', 2);

            % 持续时间
            timestart2currentText = sprintf('Last time: %d s', labels_struct.(valid_label_name).timestart2current);
            originalImage = insertText(originalImage, [20, 60*(k-1)+40], timestart2currentText, 'TextColor', 'white', 'FontSize', 12, 'BoxOpacity', 0, 'Font', fontName);

        end
    end
    % 添加当前帧到视频  
    writeVideo(outputVideo, originalImage);
end
close(outputVideo);







%--------------------------调用的子函数-----------------------------------------
%解析时间字符串
function [hh,mm,ss] = str2time(timestr)
    t = str2num(timestr);
    hh = floor(t/10000);
    mm = floor((t-hh*10000)/100);
    ss = t - hh*10000 -mm *100;
end

% 灰度图转rgb图
function rgb=gray2rgb(Image)
%Gives a grayscale image an extra dimension
%in order to use color within it
rgb(:,:,1)=Image;
rgb(:,:,2)=Image;
rgb(:,:,3)=Image;
end
%----------------------------------------------------------------------------

end



