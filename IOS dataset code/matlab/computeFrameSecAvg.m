
%%功能：对已经按秒排好序的帧序列FrameSecSeq按秒平均，平均后的图像写入avgframefolderPath文件夹

%FrameSecSeq=
%{f11, f12, f13, ..., f1m_1};   %第1s内的帧-> average_1s
%{f21, f22, f23, ..., f2m_2};   %第2s内的帧-> average_2s
%           ...
%{fn1, fn2, fn3, ..., fnm_n};   %第ns内的帧-> average_ns
                                %注意，m1,m2,...,m_n表示每秒内的帧数不一定相同

%
function  computeFrameSecAvg(FrameSecSeq,avgframefolderPath)
    disp('  开始计算每秒内帧平均...');
    bar = waitbar(0,'处理中...');
    % 对每秒内的所有帧求平均
    %FrameSecAvg = cell(size(FrameSecSeq));
    for i = 1:numel(FrameSecSeq)
        frames = FrameSecSeq{i};
        if ~isempty(frames)
            avgFrame = zeros(size(imread(frames{1}.Path))); % 初始化平均帧
            for j = 1:numel(frames)
                img = imread(frames{j}.Path);
                avgFrame = avgFrame + double(img);
            end
            avgFrame = uint16(double(avgFrame) / numel(frames));
            CurrentFrame_HHMMSS = strcat(num2str(FrameSecSeq{i}{1}.CreateTime.Year,'%04d'), ...
                                         num2str(FrameSecSeq{i}{1}.CreateTime.Month,'%02d'),...
                                         num2str(FrameSecSeq{i}{1}.CreateTime.Day,'%02d'), ...
                                         '_', ...
                                         num2str(FrameSecSeq{i}{1}.CreateTime.Hour,'%02d'), ...
                                         num2str(FrameSecSeq{i}{1}.CreateTime.Minute,'%02d'), ...
                                         num2str(FrameSecSeq{i}{1}.CreateTime.Second,'%02d'));
            imwrite(avgFrame,strcat(avgframefolderPath,'\',CurrentFrame_HHMMSS,'.tiff'));
            %FrameSecAvg{i} = avgFrame;
        end    
    str=['计算第',num2str(i,'%04d'),'张中...',num2str(100*i/numel(FrameSecSeq),'%.2f'),'%'];    % 百分比形式显示处理进程,不需要删掉这行代码就行
    waitbar(i/numel(FrameSecSeq),bar,str)                       % 更新进度条bar，配合bar使用
    end
    close(bar);
    disp('  每秒内帧平均计算完成...');
end
