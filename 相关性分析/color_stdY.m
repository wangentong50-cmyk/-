clc;
clear;
close all;

% 读取数据
T = readtable('C:\Users\Deer\Desktop\绘图\features.xlsx');

% 保存路径
saveFolder = 'C:\Users\Deer\Desktop\绘图\折线图';
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end

% 颜色
colors = unique(T.Color, 'stable');

% 筘数纬数组合标签
combLabels = strcat(string(T.Koushu), "-", string(T.Weishu));
[uniqueCombs, ~, combIdx] = unique(combLabels, 'stable');

% 折线颜色
colorMap = containers.Map( ...
    {'blue','gray','green','purple','red','yellow'}, ...
    {[0 0 1], [0.5 0.5 0.5], [0 0.6 0], [0.5 0 0.5], [1 0 0], [1 1 0]} );

% 行：筘数-纬，列：颜色
stdY_matrix = NaN(length(uniqueCombs), length(colors));

for ci = 1:length(colors)
    color = colors{ci};
    colorRows = strcmp(T.Color, color);

    for i = 1:length(uniqueCombs)
        idx = combIdx == i & colorRows;
        if any(idx)
            stdY_matrix(i, ci) = mean(T.StdY(idx));
        end
    end
end

% 绘图
hFig = figure('Name', 'StdY-Color-Line', 'NumberTitle', 'off');
hold on;

for ci = 1:length(colors)
    color = colors{ci};

    if isKey(colorMap, lower(color))
        rgb = colorMap(lower(color));
    else
        rgb = rand(1,3);
        warning('颜色 "%s" 未定义，用随机颜色代替。', color);
    end

    plot(stdY_matrix(:, ci), '-o', ...
        'Color', rgb, ...
        'LineWidth', 1.5, ...
        'DisplayName', color);
end

legend('Location', 'bestoutside');
xticks(1:length(uniqueCombs));
xticklabels(uniqueCombs);
xtickangle(45);
ylabel('StdY（亮度标准差）');
grid on;
hold off;

% 保存
fileName = 'Color_stdY.png';
saveas(hFig, fullfile(saveFolder, fileName));
% close(hFig);

