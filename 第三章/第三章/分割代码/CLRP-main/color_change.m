% 读取彩色图像
rgbImage = imread('corrected_image_1.jpg');

% 将 RGB 图像转换为 Lab 色彩空间
labImage = rgb2lab(rgbImage);

% 提取 Lab 图像中的 a 和 b 通道
aChannel = labImage(:,:,2);
bChannel = labImage(:,:,3);

% 设定蓝色区域的阈值范围
blueMask = aChannel < 0 & bChannel > 0;

% 创建新的 Lab 图像，将蓝色区域替换为红色
newLabImage = labImage;
newLabImage(blueMask) = 0; % 将蓝色区域设为黑色

% 将修改后的 Lab 图像转换回 RGB 图像
newRgbImage = lab2rgb(newLabImage);

% 显示原始图像和修改后的图像
subplot(1,2,1);
imshow(rgbImage);
title('Original Image');

subplot(1,2,2);
imshow(newRgbImage);
title('Modified Image');

% 保存修改后的图像
imwrite(newRgbImage, 'modified_image.jpg');

