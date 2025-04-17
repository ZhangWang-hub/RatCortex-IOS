
clc
clear all
%%功能： 根据 每一帧信号的mask图生成信号经过的区域mask 并切计算其面积存入txt中。 
%作者：zhangwang
%日期：2024/5/20

JsonFilePath = "F:\matlab_code\seg\T20230705 鼠十九 MCAO组_1s_chouyang5_diff_la";
LabelMaskPath ="F:\matlab_code\seg\T20230705 鼠十九 MCAO组_1s_chouyang5_diff_la";
result_path = 'F:\matlab_code\seg\T20230705 鼠十九 MCAO组_1s_result\';%存储结果视频 

%标注数据需要给：
%               出一个文件夹的信号片段数量，比如一个文件夹有3次触发信号片段
%               每次出发信号片段的首尾帧名字
%                   
signalfragent_nums = 2;%此处应该根据实际情况修改
%singal首尾帧名字
startfname = ["20230705_214942","20230705_215957"];
endfname = ["20230705_215112","20230705_220142"];

labelinfo = dir(fullfile(JsonFilePath,"*.json"));
masknums = length(labelinfo);


%根据首尾帧name计算该片段中所有
namelist = cell(signalfragent_nums,1); % 使用 cell 数组来存储每个片段的索引
% 迭代所有帧
for i = 1:length(labelinfo)
    namecell = split(labelinfo(i).name, '.');
    frameName = string(namecell(1)); 
    % 遍历每个片段，检查帧名是否在片段范围内
    for j = 1:signalfragent_nums
        if (frameName >= startfname(j)) && (frameName <= endfname(j))% 检查帧名是否在当前片段的范围内
            namelist{j} = [namelist{j}; frameName]; % 将索引添加到对应片段中
        end
    end
end


fid = fopen(fullfile(LabelMaskPath,'CoverArea.txt'),'w');%初始化清空txt文件
fclose(fid);

for index = 1:signalfragent_nums
    eachsignalcell = namelist(index);
    eachsignal = eachsignalcell{1,1};
    singalfisrtname = eachsignal(1);
    singalendname = eachsignal(end);
    singal_fragment_name = strcat('fragment[',num2str(eachsignal(1)),'_',num2str(eachsignal(end)),']');
    fid = fopen(fullfile(LabelMaskPath,'CoverArea.txt'),'a+');%写入文件路径
    coverarea = zeros();
    area_x = [];
    area_y = [];
    for i = 1:length(eachsignal)
        jsonStr_i = fileread(fullfile(JsonFilePath,strcat(eachsignal(i),'.json')));
        jsondate_i = jsondecode(jsonStr_i);
        
        num_rois = length(jsondate_i.shapes);
        mask = zeros();
        for j = 1:num_rois %num_rois表示感兴趣区域数量
            roi_x = jsondate_i.shapes(j).points(:,1);
            roi_y = jsondate_i.shapes(j).points(:,2);
            mask = mask + poly2mask(roi_x,roi_y,512,512);%同一张图的几个不同mask 相加
        end
        mask(find(mask~=0))=1;   %若mask有重叠区域，重叠区域mask相加后大于1，则令其仍为1
            % 对mask做均值处理，去除锯齿
            % 均值滤波
            mask1 = filter2(fspecial('average',11),mask);
            mask2 = mask1;
            mask2(find(mask2<0.5))=0;
            mask2(find(mask2>=0.5))=1;
            
            jsoninfo = split(labelinfo(i).name,'.');
            jsonname = string(jsoninfo(1));

            imwrite(mask2,fullfile(LabelMaskPath,strcat(jsonname,'.jpg')));
            area_x = [area_x;roi_x];
            area_y = [area_y;roi_y];
    end

    cm_bdp = boundary(area_x,area_y); %covermask_boundarypoints
    cm_bdp_x = area_x(cm_bdp);
    cm_bdp_y = area_y(cm_bdp);
    coverareamask =  poly2mask(cm_bdp_x,cm_bdp_y,512,512);
   
    %coverareamask = imbinarize(coverarea);
    coverareamask1 = filter2(fspecial('average',31),coverareamask);
    
    coverareamask2 = coverareamask1;
    coverareamask2(find(coverareamask2<0.5))=0;
    coverareamask2(find(coverareamask2>=0.5))=1;
    pix_real_area = (10.5/512)^2;    %%平方毫米
    signal_cover_area = bwarea(coverareamask2)*pix_real_area;
    disp(strcat(jsonname,"cover_area:",num2str(signal_cover_area,'%.2f')," mm^2"));
    fprintf(fid,strcat(singal_fragment_name," cover_area: ",num2str(signal_cover_area,'%.2f')," mm^2\r\n"));

    imwrite(coverareamask2,fullfile(LabelMaskPath,strcat(jsonname,'cover.jpg')));
    %imshow(coverareamask2);

end
fclose(fid);