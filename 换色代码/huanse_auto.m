clc;
clear;

% === 读取Excel文件 ===
excel_path = 'C:\Users\Deer\Desktop\400颜色数据\RGB\织物图像平均颜色\平均颜色_输入原颜色.xlsx'; % Excel文件路径
data = readtable(excel_path);
num_rows = height(data);

% === 图像文件夹路径 ===
image_folder = 'C:\Users\Deer\Desktop\纯色样本数据\samples\';

% === 设置保存结果图像的路径 ===
output_folder = 'C:\Users\Deer\Desktop\预测值换色结果\预测一个值（输入原颜色）\twill_f\yellow\';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('创建保存目录: %s\n', output_folder);
end

for i = 1:num_rows
    % 检查条件
    target_color_name = data{i, 1}{1};  % 第一列：目标颜色名
    
    % 检查颜色
    if ~strcmpi(target_color_name, 'yellow')
        fprintf('跳过行 %d: 颜色不是blue (%s)\n', i, target_color_name);
        continue;
    end
    
    if data{i, 29} ~= 5
        fprintf('跳过行 %d: 第29列值不为1\n', i);
        continue;
    end
    
    % 从Excel行中提取数据
    ref_rgb = [data{i, 2}, data{i, 3}, data{i, 4}] * 255; % 第2-4列：目标RGB（转换为0-255）
    image_name = data{i, 6}{1};                 % 第6列：待处理图像名
%     mean_Y = data{i, 27} * 255;             % 第27列：Y均值（转换为0-255）
    std_Y = data{i, 27} * 255;              % 第28列：Y标准差（转换为0-255）
    
    % 构建完整图像路径
    image_path = fullfile(image_folder, image_name);
    if ~exist(image_path, 'file')
        fprintf('图像不存在: %s\n', image_path);
        continue;
    end
    
    % 读取目标图像
    fabric_img = imread(image_path);
    fabric_img = double(fabric_img);
    
    % 像转换为灰度
    gray_fabric_img = 0.299 * fabric_img(:,:,1) + 0.587 * fabric_img(:,:,2) + 0.114 * fabric_img(:,:,3);
    
    % 计算目标图像的灰度均值和标准差
    mean_fabric = mean(gray_fabric_img(:));
    std_fabric = std(gray_fabric_img(:));
    
    % 换色
    adjusted_gray = (gray_fabric_img - mean_fabric) * (std_Y / std_fabric);
    adjusted_Y = repmat(adjusted_gray, 1, 1, 3);
    
    [rows, cols, ~] = size(fabric_img);
    mean_color_rgb_img = repmat(reshape(ref_rgb, 1, 1, 3), rows, cols, 1);
    adjusted_color_img = adjusted_Y + mean_color_rgb_img;
    adjusted_color_img = uint8(max(min(adjusted_color_img, 255), 0));
    
    % 保存
    [~, name, ext] = fileparts(image_name);
    output_name = sprintf('%s_%s%s', name, target_color_name, ext);
    output_path = fullfile(output_folder, output_name);
    imwrite(adjusted_color_img, output_path);
    fprintf('已处理: %s -> %s\n', image_name, output_path);
end

fprintf('所有处理完成！结果保存在: %s\n', output_folder);