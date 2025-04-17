
% 函数名：产生差值图像
% 功能： 从秒内平均的图片（后缀为：_s）按一定间隔产生差值图像，
%        如_s: f1，f2，f3，f4，f5，f6，...，fi....,fn
%
% 例如：framespace =3; 
%        生成结果： diff(f4,f1),  diff(f7,f4)，diff(f10,f7),...，diff(fi+3,fi),...
%        diff表示计算两帧图像差值图的方法，具体看代码。
%
% 作者 ：zhangwang
% 时间 ：
function genDimage(folder_1s,framespace)
    %framespace=5
    %folder_1s = "F:\matlab_code\seg\T20230705 鼠十九 MCAO组_1s";
    %check if mask exist 
    
    if ~exist(fullfile(folder_1s,"mask.jpg"),'file')
        error(strcat(folder_1s,"文件夹缺少mask图,请先用genmask函数文件生成!"));
    end
    savefold = strcat(folder_1s,"_chouyang",num2str(framespace),"_diff");
    if ~exist(savefold,'dir')
        mkdir(savefold);
    end
    
    folder_1s_info = dir(fullfile(folder_1s,'*.tiff'));
    framenums = length(folder_1s_info);
    sortedname = sort_nat({folder_1s_info.name}');
    
    
    maskdata = imbinarize(imread(fullfile(folder_1s,"mask.jpg")));
    FirstFrame = imread(fullfile(folder_1s,sortedname(1))) ;
    FirstFrame = imfilter(FirstFrame,fspecial('average',[31,31])); 
    bar = waitbar(0);
    for i = (1+framespace):framespace:framenums
        %process start here
        SecondFrame = imread(fullfile(folder_1s,sortedname(i)));   
        SecondFrame = imfilter(SecondFrame,fspecial('average',[21,21]));    
        Dimage = double(SecondFrame) ./ double(FirstFrame);
        
        %figure(i),imhist(Dimage);title("Dimage");
       
        %Dimage = imadjust(Dimage);
        %figure(i+framenums),imhist(Dimage1);title("Dimage1");
        %figure(i+2*framenums),imshow(Dimage1);title("Dimage1");%imhist(Dimage2);

        % Dimage2 = imadjust(Dimage1,[0.01,0.5],[],0.1);
        % figure(i+3*framenums),imhist(Dimage2);
        % figure(i+4*framenums),imshow(Dimage2);
        Dimage = imnorm16bit(Dimage) .* uint16(maskdata);
        Dimage = ind2rgb(gray2ind(Dimage,256),jet(256));
        imwrite(Dimage,fullfile(savefold,sortedname(i)));

        FirstFrame = SecondFrame;
    
        str = strcat("Dimages are being generated...",'计算第',num2str(i,'%04d'),'张中...', num2str(100*i/framenums,'%.2f'),'%'); % 百分比形式显示处理进程,不需要删掉这行代码就行
        waitbar(i/framenums,bar,str);% 更新进度条bar，配合bar使用            
    end
    close(bar);


    % image normlization function
    function image_out = imnorm16bit(image_in)
        minvalue = min(min(image_in));
        maxvalue = max(max(image_in));
        image_out = uint16(double(image_in-minvalue)/double(maxvalue-minvalue)*65535);
    end
    
    function image_out = imnorm8bit(image_in)
        minvalue = min(min(image_in));
        maxvalue = max(max(image_in));
        image_out = uint8(double(image_in-minvalue)/double(maxvalue-minvalue)*255);
    end
end