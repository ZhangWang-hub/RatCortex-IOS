


% 示例调用
% ResultPath = 'F:\matlab_code\seg\MAIN_PROCEDRES';
% newData1 = {'SignalClip1', 1, 1, 100, 200, 150, 250, 1.5, 0.2, 30, 60, 12};
% newData2 = {'SignalClip1', 1, 2, 110, 210, 160, 260, 1.6, 0.3, 35, 65, 13};
% newData3 = {'SignalClip2', 2, 1, 120, 220, 170, 270, 1.7, 0.4, 40, 70, 14};
% newData4 = {'SignalClip3', 3, 1, 130, 230, 180, 280, 1.8, 0.5, 45, 75, 15};
% newData5 = {'SignalClip3', 3, 2, 140, 240, 190, 290, 1.9, 0.6, 50, 80, 16};
% 
% appendDataWithMerge1(ResultPath, newData1,1);
% appendDataWithMerge1(ResultPath, newData2,0);
% % appendDataWithMerge1(ResultPath, newData3,1);
% % appendDataWithMerge1(ResultPath, newData4,1);
% % appendDataWithMerge1(ResultPath, newData5,1);


function recordData2Excel(ResultPath, newData,overwriteflag)
    pathpart = split(ResultPath,'\');
    filename = fullfile(ResultPath, strcat(pathpart(end),"_result.xlsx"));
    
    % 定义列名
    colNames = {'SignalClipsName', 'Labelindex', 'Brain_region', 'OrigalPoint_x', 'OrigalPoint_y', ...
                'EndPoint_x', 'EndPoint_y', 'SignalAmp', 'AverageSpeed', 'Distance', 'LastTime', 'CoverArea'};
    
    % 检查文件是否存在
    if ~isfile(filename)
        % 如果文件不存在，创建一个空表
        emptyData = cell(0, numel(colNames));
        existingData = cell2table(emptyData, 'VariableNames', colNames);
        writetable(existingData,filename,'WriteMode','overwrite','AutoFitWidth',true);
    end



    % 将新数据追加到表中
    newRow = cell2table(newData, 'VariableNames', colNames);
    %combinedData = [existingData; newRow];

    % 保存到 Excel 文件
    
    if (overwriteflag == 1)
        writetable(newRow, filename, 'WriteMode', 'overwritesheet','AutoFitWidth',true);
    else
        writetable(newRow, filename, 'WriteMode', 'append','AutoFitWidth',true);
    end




end

