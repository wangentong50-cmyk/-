
% 读取表格，保留原始列名
T = readtable('C:/Users/Deer/Desktop/fabric_features_200/颜色数据归一化_1_sort.xlsx', ...
              'VariableNamingRule','preserve');

% 要计算相关性的特征
featureNames = {'GLCM_Contrast', 'GLCM_Correlation', 'GLCM_Energy', ...
                'GLCM_Homogeneity', 'MeanGradientMag', 'roughness'};

for j = 1:length(featureNames)
    fname = featureNames{j};

    % 计算与MeanY相关系数及p值
    if sum(validIdx_MeanY) >= 3
        [r_meanY, p_meanY] = corr(T.(fname)(validIdx_MeanY), ...
                                  T.MeanY(validIdx_MeanY), 'Type', 'Pearson');
    else
        r_meanY = NaN; p_meanY = NaN;
    end

    % 计算与StdY相关系数及p值
    if sum(validIdx_StdY) >= 3
        [r_stdY, p_stdY] = corr(T.(fname)(validIdx_StdY), ...
                                T.StdY(validIdx_StdY), 'Type', 'Pearson');
    else
        r_stdY = NaN; p_stdY = NaN;
    end

    % 输出
    fprintf('%-16s 与 MeanY 的相关系数: %6.4f, p = %.4f\n', fname, r_meanY, p_meanY);
    fprintf('%-16s 与 StdY  的相关系数: %6.4f, p = %.4f\n', fname, r_stdY, p_stdY);
end




