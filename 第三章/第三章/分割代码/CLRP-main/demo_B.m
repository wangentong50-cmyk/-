clc
clear
close all
addpath test_images solvers utilits

% I = im2double(imread('barbara.png'));   %gray image
% I = I(1:256,257:end);

I = im2double(imread('C:\Users\Deer\Desktop\color_transfer\pictures\Img0002.jpg'));
% I = im2double(imread('C:\Users\Deer\Desktop\pictures\Img0008(1).jpg'));

% I = im2double(imread('kodim03.png'));   %rgb image
% I = I(1:64*8,129:64*10,:);

[n1,n2,n3] = size(I);
% 最大迭代次数
opts.MaxIt = 200;
% 算法类型
OPTK = 'B';
% 输入图像I
opts.I = I;
% 设置模糊半径
% 使用fspecial创建圆盘形模糊核K,imfilter函数通过K对图像I进行卷积，得到初始估计x0，模糊处理采用了circular边界处理方式
Blur_Radius = 3;

% 创建模糊核k
K = fspecial('disk',Blur_Radius);

% 通过imfilter对输入图像进行模糊处理，得到初始估计x0
x0 = imfilter(I,K,'circular');

% 收敛容差（Tolerance），用于指定优化算法在达到指定的误差范围内停止迭代
opts.Tol = 1e-2;
% 用于控制是否显示详细信息。当设置为0时，不会输出优化过程中的详细信息，只输出最终结果；
% 当设置为1或更高的值时，会输出更多的优化过程信息，如每次迭代的损失值等
opts.verbose = 0;

% 卡通部分的正则化参数（Regularization Parameter），用于控制卡通部分的平滑程度。
% 较大的值会导致更加平滑的卡通部分，但可能会丢失一些细节
opts.tau = 1e-5;  % 原参数
% 纹理部分的正则化参数，用于控制纹理部分的稀疏性。较小的值会导致更加稀疏的纹理部分，但可能会过度消除一些纹理细节。
opts.mu = 1e-4;
% 用于平衡卡通部分和纹理部分的权重系数。较小的值会倾向于更加保留卡通部分，而较大的值会倾向于更加保留纹理部分。
beta = 1e-3;
% 这两个用于指定卡通部分和纹理部分的权重系数，通常设置为相同的值，以达到平衡两者的效果。
opts.beta1 = beta;      
opts.beta2= beta;

% PPSM
alg_opts.gamma = 1.6;
alg_opts.s = 2.01;
alg_opts.r = 1;
[u,v,out] = CLRP_PPSM(x0,K,OPTK,opts,alg_opts);

% 定义保存路径

save_dir_cartoon = 'C:\Users\Deer\Desktop\基于图像分割的织物高保真换色\decomposed_img\cartoon';
save_dir_texture = 'C:\Users\Deer\Desktop\基于图像分割的织物高保真换色\decomposed_img\texture';
save_dir_combined = 'C:\Users\Deer\Desktop\基于图像分割的织物高保真换色\decomposed_img\c_t_combine';

% 检查并创建文件夹（如果不存在）
if ~exist(save_dir_cartoon, 'dir')
    mkdir(save_dir_cartoon);
end

if ~exist(save_dir_texture, 'dir')
    mkdir(save_dir_texture);
end

if ~exist(save_dir_combined, 'dir')
    mkdir(save_dir_combined);
end

% 保存图片
imwrite(u, fullfile(save_dir_cartoon, '0002.jpg'));
% imwrite(v, fullfile(save_dir_texture, '0002.jpg'));
% imwrite(u+v, fullfile(save_dir_combined, '0002.jpg'));

figure;
subplot(2,2,1)
imshow(x0,[])
title('Observed')
subplot(2,2,2)
imshow(u,[])
title('Cartoon')
subplot(2,2,3)
imshow(v,[])
title('Texture')
subplot(2,2,4)
imshow(u+v,[])
title('Cartoon + Texture')
% suptitle('PPSM')
sgtitle('PPSM');

% % EADM
% [u_EADM,v_EADM,out_EADM] = CLRP_EADM(x0,K,OPTK,opts);


