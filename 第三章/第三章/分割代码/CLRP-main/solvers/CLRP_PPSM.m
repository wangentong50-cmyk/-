function [ u,v,out ] = CLRP_PPSM(x0,K,OPTK,opts,alg_opts)
% PPSM for a customized low-rank prior model for structuredPPSM 用于结构化的自定义低秩先验模型
% cartoon-texture image decomposition model卡通纹理图像分解模型
% with different linear operator K.不同的线性算子K。

% min_{u,v} tau ||u||_TV + mu ||v||_* + 0.5 ||K(u+v)-b||^2.
% where || dot ||_TV is the anisotropic TV norm and 各向异性TV范数
% || dot ||_* is the nuclear norm .核范数

% Input:
% x0: observed image;观测图像
% K: linear operator;线性算子
% OPTK: linear operator K tzpe: 'I', 'S', and 'B'.线性算子类型
% opts: model parameters setting;模型参数设置
% alg_opts: PPSM parameters setting;PPSM参数设置

% Output:
% u: cartoon component;
% v: texture component;
% out: comparative indices.

% Author: Zhizuan Zhang
% Date: 1, December, 2020

% 参数tau和mu分别控制TV范数和核范数的正则化强度。参数beta1和beta2分别用于TV范数和核范数的正则化项。
% MaxIt指定最大迭代次数，Tol是收敛容差。

tau  = opts.tau; % 将变量tau设为参数结构体opts中的tau值，这个值控制了TV正则化项的强度。   
mu  = opts.mu; % 将变量 mu 设为参数结构体 opts 中的 mu 值，这个值控制了核范数正则化项的强度。
beta1 = opts.beta1;  % 变量 beta1 设为参数结构体 opts 中的 beta1 值，这个值用于 TV 正则化项中的参数。  
beta2 = opts.beta2; % 将变量 beta2 设为参数结构体 opts 中的 beta2 值，这个值用于核范数正则化项中的参数。
MaxIt = opts.MaxIt; %  将变量 MaxIt 设为参数结构体 opts 中的 MaxIt 值，表示最大迭代次数。
I     = opts.I; % 将变量 I 设为参数结构体 opts 中的 I，指是输入的观测图像。     
Tol   = opts.Tol; % 将变量 Tol 设为参数结构体 opts 中的 Tol，表示收敛容忍度，用于迭代停止条件的判断。
[n1,n2,n3] = size(x0); %  获取输入图像 x0 的尺寸信息，分别赋值给 n1、n2 和 n3，用于后续计算。

%% the algorithm parameters
alg_gamma = alg_opts.gamma;% 用于控制算法的收敛速度或者步长大小。
alg_s = alg_opts.s;
alg_r = alg_opts.r;
% 确保算法参数的合理性和算法的稳定性
if alg_s*alg_r <= 2
    error('Please check the algorithm parameters!')
end

%%%%%%%%%%%%%%%%% Periodic  boundarz condtion周期性边界条件 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 定义图像在水平和垂直方向的梯度以及它们的转置操作，主要用于计算图像的总变差（TV）
% 创建大小为n1*n2*n3 的零矩阵d1h，将第一个元素的值设为-1，最后一个元素的值设为1。
% 使用二维傅里叶变换 fft2 对 d1h 进行变换。d2h同理
d1h = zeros(n1,n2,n3); d1h(1,1,:) = -1; d1h(n1,1,:) = 1; d1h = fft2(d1h);
d2h = zeros(n1,n2,n3); d2h(1,1,:) = -1; d2h(1,n2,:) = 1; d2h = fft2(d2h);
% 差分算子
% 定义了一个匿名函数 Px，用于计算梯度操作 \nabla_1 x，即在 x 的第一个维度上计算差分。
Px  = @(x) [x(2:n1,:,:)-x(1:n1-1,:,:); x(1,:,:)-x(n1,:,:)]; %%\nabla_1 x
% 在 z 的第二个维度上计算差分
Py  = @(x) [x(:,2:n2,:)-x(:,1:n2-1,:), x(:,1,:)-x(:,n2,:)]; %%\nabla_2 z
% 在 x 的第一个维度上进行转置
PTx = @(x) [x(n1,:,:)-x(1,:,:); x(1:n1-1,:,:)-x(2:n1,:,:)]; %%\nabla_1^T x
% 在 z 的第二个维度上进行转置。
PTy = @(x) [x(:,n2,:)-x(:,1,:), x(:,1:n2-1,:)-x(:,2:n2,:)]; %%\nabla_2^T z
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 初始化u、v以及其他辅助变量和拉格朗日乘数
% 都是大小为 n1 x n2 x n3 的全零矩阵
u  = zeros(n1,n2,n3);
v  = zeros(n1,n2,n3);
v_tilde = zeros(n1,n2,n3);
y1 = zeros(n1,n2,n3); y2 = zeros(n1,n2,n3);
z  = zeros(n1,n2,n3);
lbd11 = zeros(n1,n2,n3); lbd12 = zeros(n1,n2,n3);
lbd2  = zeros(n1,n2,n3);

% 线性算子
%根据输入的OPTK参数选择不同的线性操作符 K，并根据选择的 K 计算相关的中间变量
switch lower(OPTK) % 用于将 OPTK 的值转换为小写，以便进行不区分大小写的比较
    case 'i'  %%%%%%%%%%%%%%%%%%%%%%%%% K = I %%%%%%%%%%%%%%%%当OPTK的值为'i'时，代表选择了恒等操作符K=I，即K是单位矩阵
        MDz   = 1 + alg_r*beta2;  
        ATf = x0;
    case 's'  %%%%%%%%%%%%%%%%%%%%%%%%% K = S %%%%%%%%%%%%%%%%代表选择尺度操作符 K = S，即 K 是尺度矩阵
        MDz   = K + alg_r*beta2;  
        ATf = K.*x0; % 将ATf设置为输入图像x0与尺度矩阵K的逐元素乘积
    case 'b'  %%%%%%%%%%%%%%%%%%%%%%%%% K = B %%%%%%%%%%%%%%%%选择模糊操作符 K = B，即 K 是模糊核
        % 计算模糊核的大小和中心点位置
        siz = size(K); 
        center = [fix(siz(1)/2+1),fix(siz(2)/2+1)];
        % 创建一个与输入图像大小相同的矩阵P，并将模糊核K复制到P的合适位置
        P   = zeros(n1,n2,n3); for i =1:n3; P(1:siz(1),1:siz(2),i) = K; 
        end
        % 首先对矩阵P进行循环移位，移动的距离由1-center决定。center是一个表示移位中心的向量，由两个元素组成，通常用来指定移位的偏移量。
        % 在这里，1-center 的含义是将 P 沿着两个维度分别向右和向下移动，其中向右移动一个单位，向下移动 center(1)-1 个单位。
        % 接着，对经过移位的矩阵进行二维离散傅里叶变换，得到频域表示。
        Bm   = fft2(circshift(P,1-center));
        % 定义HT函数，对输入信号或图像应用特定的频域模糊操作（通过Bm的共轭与频域表示进行乘积运算），然后将其转换回空间域。
        % 因此，这行代码定义了一个模糊操作的逆运算，即模糊操作的转置。
        %  将Bm的共轭矩阵与x的傅里叶变换结果逐元素相乘，得到一个频域表示的结果，并对该频域结果进行逆二维离散傅里叶变换，将其转换回空间域。
        % 取逆傅里叶变换结果的实部，舍弃虚部，得到最终的空间域结果。
        HT  = @(x) real(ifft2(conj(Bm).*fft2(x))); %%% Transpose of blur operator.模糊运算符转置
        MDz = abs(Bm).^2 + alg_r*beta2;  
        ATf   = HT(x0);
end
% 计算矩阵MDu，用于更新变量u。矩阵结合了图像梯度的平方和两个正则化权重，用于控制图像的平滑度和特征保留。
% abs(d1h).^2 abs(d2h).^2分别表示水平和垂直梯度的模平方。
% 模平方反映了梯度的强度（变化率），因此它们的和（abs(d1h).^2 + abs(d2h).^2）代表了图像在空间域内的总变差（Total Variation，TV）。
% 通过beta1加权，beta1是TV正则化项的权重参数。这个项的作用是控制图像在水平和垂直方向上的平滑度，即抑制图像中的噪声和细小纹理，但同时保留较大的结构特征。
% beta2 是另一个正则化项的权重参数，用于平衡不同正则化项对图像的影响。
% MDu是合并图像梯度信息和正则化权重的矩阵，用于PPSM算法的后续迭代中。这一矩阵决定了在更新变量u时，如何平衡图像的平滑度与保留特征之间的关系。
MDu   = beta1*(abs(d1h).^2+abs(d2h).^2) + beta2;
% 初始化，用于存储算法每次迭代的时间和信噪比
Time = zeros(1,MaxIt);
SNR  = zeros(1,MaxIt);

% 迭代优化算法的主要循环
for itr = 1:MaxIt
    
    %%% step 1: un
    % 步骤1：更新cartoon部分(u)。使用PTx和PTy函数计算cartoon部分u的更新，将更新后的u从频域转换回空间域。
    tic;
    % 计算优化变量u（cartoon）的更新。这里使用函数PTx和PTy，它们是对图像进行梯度运算的函数
    Temp= PTx(beta1*y1 + alg_s*lbd11)+PTy(beta1*y2+alg_s*lbd12)+beta2*(z-v)+alg_s*lbd2;
    % 在频域进行的操作，使用逆傅里叶变换将更新后的u（cartoon）转换回空间域。
    un  = real(ifft2(fft2(Temp)./MDu));
    time_u = toc;
    
    %%%% update Lagrangian multipliers
    tic;
    % dun1和dun2计算了un（cartoon）的梯度
    dun1= Px(un);
    dun2= Py(un);
    % 更新了Lagrange乘子
    lbd11_tilde= lbd11 + beta1/alg_s*(y1-dun1);
    lbd12_tilde= lbd12 + beta1/alg_s*(y2-dun2);
    lbd2_tilde = lbd2  + beta2/alg_s*(z-un-v);
    time_l = toc;
    
    %%% step 2: \tilde v
    % 步骤2：更新texture部分(v_tilde)，使用当前的v和Lagrange乘子计算一个中间变量Temp。
    % 对Temp的每个通道进行奇异值分解(SVD)，并应用阈值处理来更新v_tilde。
    tic;
    % 优化算法更新 texture 部分的中间变量
    Temp = v + (2*lbd2_tilde-lbd2)/alg_r/beta2;
  
    for ii = 1:n3
        % % 对Temp的当前通道进行奇异值分解（SVD）,𝑈和𝑉𝑇是 SVD 的左右奇异向量矩阵，D 是奇异值矩阵。
        [U,D,VT] = svd(Temp(:,:,ii),'econ');
        % 提取出奇异值矩阵的对角线元素，得到一个向量。
        D    = diag(D);
        % 找到大于某个阈值的奇异值对应的索引
        ind  = find(D>mu/beta2/alg_r);
        % 根据找到的索引，对奇异值进行阈值处理。大于阈值的奇异值减去阈值，小于等于阈值的保持不变
        D    = diag(D(ind) - mu/beta2/alg_r);
        % 使用处理后的奇异值和奇异向量重构当前通道的 texture 部分，得到更新后的v_tilde
        v_tilde(:,:,ii)   = U(:,ind) * D * VT(:,ind)';
    end
    time_v = toc;
    
    %%% step 3: \tilde y
    % 步骤3：更新cartoon部分(y_tilde),使用当前的y1、y2和Lagrange乘子计算中间变量Temp1和Temp2。应用阈值处理来更新y1_tilde和y2_tilde。
    tic;
    % 根据优化算法更新cartoon部分的中间变量
    Temp1 = y1 - (2*lbd11_tilde-lbd11)/alg_r/beta1;
    % 计算 Temp2，与上一步类似，更新另一个 cartoon 部分的中间变量。
    Temp2 = y2 - (2*lbd12_tilde-lbd12)/alg_r/beta1;
    % 计算nsk，对两个中间变量的平方和进行开方运算，避免了除以零的情况。
    nsk = sqrt(Temp1.^2 + Temp2.^2); nsk(nsk==0)=1;
    % 对nsk进行阈值处理，确保不会出现小于零的值。
    nsk = max(1-(tau/beta1/alg_r)./nsk,0);
    % 根据阈值处理后的nsk，更新y1_tilde和y2_tilde
    y1_tilde = Temp1.*nsk;
    y2_tilde = Temp2.*nsk;
    time_y = toc;
    
    %%% step 4: \tilde z
    % 步骤4：更新texture部分(z_tilde)，使用当前的z和Lagrange乘子计算中间变量Temp。
    % 根据OPTK参数的不同,更新z_tilde的方法也不同,可能涉及傅里叶变换和除法运算。
    tic;
    Temp = ATf + alg_r*beta2*z - 2*lbd2_tilde + lbd2;
    if lower(OPTK) == 'b'
        % 如果线性运算类型是 'B'，则进行傅立叶变换、除法、逆傅立叶变换的运算，得到更新后的 texture 部分 z_tilde
        z_tilde = real(ifft2(fft2(Temp)./MDz));
    else
        % 否则对Temp 进行除法运算，得到更新后的 texture部分z_tilde
        z_tilde = Temp./MDz;
    end
    time_z = toc;
    
    %%% step 5: relaxation
    % 步骤5：松弛操作，使用松弛操作更新cartoon部分v、Lagrange乘子y1、y2、z以及lbd11、lbd12和lbd2。
    tic;
    % 通过松弛操作更新图像的 cartoon 部分v
    vn = v - alg_gamma*(v-v_tilde);
    % 通过松弛操作分别更新了Lagrange 乘子中的两个部分 y1 和 y2
    yn1 = y1 - alg_gamma*(y1 - y1_tilde);
    yn2 = y2 - alg_gamma*(y2 - y2_tilde);
    % 通过松弛操作更新图像的 texture 部分 z
    zn  = z - alg_gamma*(z - z_tilde);
    % 通过松弛操作分别更新Lagrange乘子中的三个部分。
    lbdn11 = lbd11 - alg_gamma*(lbd11 -lbd11_tilde);
    lbdn12 = lbd12 - alg_gamma*(lbd12 -lbd12_tilde);
    lbdn2  = lbd2 - alg_gamma*(lbd2 -lbd2_tilde);
    time_update = toc;
    % 如果参数 alg_gamma等于1，则将更新时间设为0，表示不进行更新。
    if alg_gamma==1
        time_update = 0;
    end
    
    %%% outputs
    % 计算当前迭代的总计算时间和信噪比(SNR)。
    Time(itr)= time_u + max([time_v,time_y,time_z]) + time_l + time_update;
    SNR(itr) = 20*log10(norm(I(:))/norm(un(:)+vn(:)-I(:)));
    %%% stopping rule
    Stopic = compute_tol(u,v,un,vn);
    
    if opts.verbose
        fprintf('the %d th Iter. the Tol. = %.4f \n ',itr,Stopic);
    end
    
    % 检查停止条件,如果满足容差Stopic且不是第一次迭代,则退出循环。
    if Stopic<Tol && itr >1;
        u = un;
        v = vn;
        fprintf('It=%d,cpu=%4.2f,\n',itr,sum(Time));
        Time = Time(1:itr);
        SNR  = SNR(1:itr);
        break;
    end
    
    % 更新下一次迭代的变量u、v、y1、y2、z、lbd11、lbd12和lbd2。
    u = un ; v = vn;
    y1 = yn1; y2 = yn2; z = zn;
    lbd11 = lbdn11; lbd12 = lbdn12; lbd2 = lbdn2;
end
out.It   =itr;
out.Stopic = Stopic;
out.Time = Time;
out.SNR  = SNR;
end