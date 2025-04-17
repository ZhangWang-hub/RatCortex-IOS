%%% 生成mask，存在图片所在文件夹里

function getmask = genmask(mask_source_path, mask_save_path)
    %判断一下目标文件是否有mask
     disp(strcat('正在检查',' "',mask_save_path,'" ','文件夹是否有mask...'));
     if ~exist(fullfile(mask_save_path,"mask.jpg"),'file')
        fprintf("\t文件夹缺少mask图,请在弹窗中绘制...\n\r");
        
        folderinfo = dir(fullfile(mask_source_path,'*.tiff'));
        filename = folderinfo(1).name;
        filepath = fullfile(mask_source_path,filename);
        I = imread(filepath);
        figure,imshow(I,[]);
        roi = drawpolygon('Color','r');
        % 提取多边形定点的x,y坐标
        x = roi.Position(:,1);
        y = roi.Position(:,2);
        % 由坐标生成mask
        [r c] = size(I);
        mask = poly2mask(x,y,r,c);
        figure,imshow(mask),title('mask')
        
        % 对mask做均值处理，去除锯齿
        % 均值滤波
        mask1 = filter2(fspecial('average',11),mask);
        figure,imshow(mask1),title('mask1')
        mask2 = mask1;
        mask2(find(mask2<0.5))=0;
        mask2(find(mask2>=0.5))=1;
        figure,imshow(mask2),title('mask2')
        
        % 保存mask
        mask_path = fullfile(mask_save_path,'mask.jpg');
        imwrite(mask2,mask_path); % 将逻辑值保存成uint8,imwrite为保存成uint8格式。所有读取的时候
                             % 逻辑0,1变成了0,255.需要再转成逻辑值，再转成double,才能运算。                  
        % 将mask保存成mat格式
        save(fullfile(mask_save_path,'mask.mat'),'mask')
        
        getmask = mask2;
        fprintf("\tmask绘制完成.\r\n");
     else
         fprintf("\t文件夹有mask图.\r\n");
         getmask = imread(fullfile(mask_save_path,"mask.jpg"));
         

    end
end





%{
function genmask(imagePath, maskSavePath, imageSuffix)
    % 从指定路径读取图像文件
    imageFiles = dir(fullfile(imagePath, strcat('*', imageSuffix)));

    % 读取第一张图像作为参考图像
    firstImage = imread(fullfile(imagePath, imageFiles(1).name));

    % 显示第一张图像，并绘制多边形 ROI
    figure;
    imshow(firstImage);
    roi = drawpolygon('Color', 'r');
    x = roi.Position(:,1);
    y = roi.Position(:,2);
    
    % 根据 ROI 定点坐标生成对应的二值化 Mask
    [r, c] = size(firstImage);
    mask = poly2mask(x, y, r, c);
    
    % 对生成的 Mask 进行均值滤波和二值化处理
    mask = filter2(fspecial('average', 11), mask);
    mask(mask < 0.5) = 0;
    mask(mask >= 0.5) = 1;
    
    % 将处理后的 Mask 保存为图像文件和.mat格式
    imwrite(mask, maskSavePath);
    save(strcat(maskSavePath, '.mat'), 'mask');
end
%}