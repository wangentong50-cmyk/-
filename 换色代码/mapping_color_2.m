
% target_img = imread('C:\Users\Deer\Desktop\图像换色\result\seg\smoothed_cluster_1.jpg'); % 待换色图像
target_img = imread('D:\MATLAB\Projects\color_transfer\result\0002\seg\smoothed_cluster_2.jpg');
target_img = im2double(target_img);

% 提取掩膜（黑色区域为背景）
gray_target = rgb2gray(target_img);

% 设置阈值
threshold = 0.05;
% 创建二进制掩膜，非黑色区域为有效掩膜
binary_mask = gray_target > threshold;

% 将图像转换为灰度
gray_fabric_img = (0.299 * target_img(:,:,1) + 0.587 * target_img(:,:,2) + 0.114 * target_img(:,:,3)) * 255;

% 获取图像大小
[rows, cols] = size(gray_fabric_img);

% 初始化结果图像的Lab通道
adjusted_gray = zeros(rows, cols);

% 这里要用目标颜色以及预测的标准差
R=0.774665*255;
G=0.571325*255;	
B=0.562186*255;
mean_color_rgb = [R,G,B];
mean_color = 0.299*R + 0.587*G + 0.114*B;
std_color = 0.076330*255;

% 计算待换色图像灰度图的均值和标准差
mean_fabric = mean(gray_fabric_img(binary_mask),"all");
std_fabric = std(gray_fabric_img(binary_mask), 0, 'all');

% 调整灰度图
adjusted_gray(binary_mask) = (gray_fabric_img(binary_mask) - mean_fabric) * (std_color / std_fabric) + mean_color;

% 确保调整后的灰度值在[0,255]范围内
adjusted_gray = max(min(adjusted_gray, 255), 0);

% 保留背景不变
adjusted_gray(~binary_mask) = adjusted_gray(~binary_mask);

% 计算偏差
mean_adjusted_gray = mean(adjusted_gray(binary_mask),"all");
% 创建一个与图像大小相同的偏差矩阵
Y_devition = zeros(size(adjusted_gray));
Y_devition(binary_mask) = adjusted_gray(binary_mask) - mean_adjusted_gray;

% 扩展到三通道
adjusted_rgb = repmat(Y_devition, 1, 1, 3);

% 创建与图像大小相同的矩阵
mean_color_rgb_img = zeros(size(target_img));

% 在掩膜有效区域将均值扩展到对应位置
mean_color_rgb_img(repmat(binary_mask, 1, 1, 3)) = repmat(reshape(mean_color_rgb, 1, 1, 3), sum(binary_mask(:)), 1);

% 将调整后的RGB图像加上参考图像的颜色均值
adjusted_color_img = adjusted_rgb + mean_color_rgb_img;

% 确保结果图像在[0,255]范围内并转换为uint8
adjusted_color_img = uint8(max(min(adjusted_color_img, 255), 0));

% 创建一个与原图像大小相同的初始图像
final_result = uint8(zeros(size(adjusted_color_img)));

% 将掩膜有效区域的RGB值设置为重构后的图像
final_result(repmat(binary_mask, 1, 1, 3)) = adjusted_color_img(repmat(binary_mask, 1, 1, 3));

% 颜色块
color_patch = uint8(ones(200, 200, 3));  % 200×200颜色块
color_patch(:,:,1) = R;
color_patch(:,:,2) = G;
color_patch(:,:,3) = B;

% 显示结果
figure;
subplot(1, 3, 1); imshow(color_patch); title('颜色');
subplot(1, 3, 2); imshow(target_img); title('待换色图像');
subplot(1, 3, 3); imshow(final_result); title('结果图像');

% imwrite(final_result, 'C:\Users\Deer\Desktop\图像换色\result\catboost\smoothed_cluster_2.jpg');


