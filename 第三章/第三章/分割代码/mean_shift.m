clc;
clear;

% 原始图像
I = imread('C:\Users\Deer\Desktop\图像换色\图片\image_0087.jpg');

% 卡通图像
img = imread('C:\Users\Deer\Desktop\图像换色\图片\cartoon_0087.jpg');

% rgb-lab
lab_img = rgb2lab(img);
% 获取图像的高度和宽度
[height, width, ~] = size(lab_img);
data = reshape(lab_img, [], 3);

% Mean-Shift参数
bandwidth = 10;  % 颜色带宽

% Mean-Shift
[clustCent, point2cluster, clustMembsCell] = MeanShiftCluster(data', bandwidth);

% 获取聚类标签
idx = point2cluster';

% 将聚类结果转换为图像形式
segmented_img = reshape(idx, height, width);

% % 显示原始图像和聚类后的图像
% figure;
% subplot(1, 2, 1);
% imshow(img);
% title('Original Image');
% 
% subplot(1, 2, 2);
% imshow(label2rgb(segmented_img));
% title('Mean-Shift Segmented Image');

% 单独显示每个聚类簇的区域
figure;
unique_labels = unique(idx);
num_clusters = numel(unique_labels);
for k = 1:num_clusters
    subplot(1, num_clusters, k);
    cluster_mask = segmented_img == unique_labels(k);
    cluster_image = img;
    cluster_image(repmat(~cluster_mask, [1, 1, 3])) = 255;
    imshow(cluster_image);
    title(['Cluster ' num2str(k)]);
end

% merge_similar_clusters 函数合并相似簇
merged_idx = merge_similar_clusters(idx, data, num_clusters);

% 将合并后的聚类结果转换回图像形状
segmented_img = reshape(merged_idx, height, width);

% 单独显示每个合并后的聚类簇的区域
figure;
for k = 1:max(merged_idx)
    subplot(1, max(merged_idx), k);
    cluster_mask = segmented_img == k;
    cluster_image = I;
    cluster_image(repmat(~cluster_mask, [1, 1, 3])) = 255;
    imshow(cluster_image);
    title(['Merged Cluster ' num2str(k)]);
end

% 设置形态学操作的结构元素
se = strel('disk', 2);

% 对每个簇进行后处理
merged_image = zeros(size(segmented_img)); % 初始化合并图像
for k = 1:max(merged_idx)
    cluster_mask = merged_idx == k;
    
    % 使用形态学操作平滑边界
    smoothed_mask = imclose(cluster_mask, se);
    smoothed_mask = imopen(smoothed_mask, se);
    % 将平滑后的簇掩码添加到合并图像中
    merged_image(smoothed_mask) = k;
end

output_folder_merged_1 = 'D:\MATLAB\Projects\color_transfer\result\0087\seg';  % 保存图像

% 单独显示每个聚类簇的区域
figure;
for k = 1:max(merged_idx)
    subplot(2, max(merged_idx), k); % 一行显示原图，一行显示掩膜
    cluster_mask = merged_image == k;
    
    % 生成显示掩膜图像（簇区域为白色，其他区域为黑色）
    mask_image = uint8(cluster_mask) * 255;
    
    % 显示原始图像，非簇区域为白色
    cluster_image = I;
    cluster_image(repmat(~cluster_mask, [1, 1, 3])) = 0;
    imshow(cluster_image);
    title(['Cluster ' num2str(k)]);
    
    % 显示掩膜图像
    subplot(2, max(merged_idx), k + max(merged_idx)); % 掩膜图在第二行
    imshow(mask_image);
    title(['Mask ' num2str(k)]);
    cluster_filename = fullfile(output_folder_merged_1, ['smoothed_cluster_' num2str(k) '.jpg']);
%     imwrite(cluster_image, cluster_filename);
end
