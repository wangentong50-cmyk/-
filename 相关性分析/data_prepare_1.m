function data_prepare()
    image_folder = 'C:\Users\Deer\Desktop\纯色样本数据\samples\';
%     image_folder = 'C:\Users\Deer\Desktop\2\';
    image_files = dir(fullfile(image_folder, '*.jpg'));
    image_files = [image_files; dir(fullfile(image_folder, '*.png'))];
    image_files = [image_files; dir(fullfile(image_folder, '*.jpeg'))];

    % 构建分组
    groups = containers.Map('KeyType','char','ValueType','any');

    for i = 1:length(image_files)
        fname = image_files(i).name;
        parts = split(fname, '_');
        if numel(parts) < 5
            fprintf('跳过命名格式异常文件: %s\n', fname);
            continue;
        end
        texture = parts{1};
        side = parts{2};
        color = parts{3};
        ik = parts{4};
        wk_parts = split(parts{5}, '.');
        wk = wk_parts{1};

        key = sprintf('%s_%s_%s_%s', texture, side, ik, wk);
        entry.color = color;
        entry.filename = fname;

        if isKey(groups, key)
            tmp = groups(key);
            tmp{end+1} = entry;
            groups(key) = tmp;
        else
            groups(key) = {entry};
        end
    end

    records = {};
    keys = groups.keys;
    for k = 1:length(keys)
        key = keys{k};
        imgs = groups(key);
        n = length(imgs);
        for i = 1:n
            for j = 1:n
                if i == j
                    continue;
                end
                fname_in = imgs{i}.filename;
                fname_out = imgs{j}.filename;
                color_out = imgs{j}.color;

                if strcmp(imgs{i}.color, color_out)
                    continue;
                end

                img_in = load_image(fullfile(image_folder, fname_in));
                img_out = load_image(fullfile(image_folder, fname_out));

                avg_in = mean(reshape(img_in, [], 3), 1);
                avg_out = mean(reshape(img_out, [], 3), 1);

                % 输入图像亮度Y及其均值和标准差
                Y_in = 0.299 * img_in(:,:,1) + 0.587 * img_in(:,:,2) + 0.114 * img_in(:,:,3);
                mean_Y_in = mean(Y_in(:));
                std_in = std(Y_in(:));

                % 输入图像梯度幅值均值
                [Gx_in, Gy_in] = imgradientxy(Y_in);
                [Gmag_in, ~] = imgradient(Gx_in, Gy_in);
                mean_grad_in = mean(Gmag_in(:));

                % 输出图像亮度Y及其均值和标准差
                Y_out = 0.299 * img_out(:,:,1) + 0.587 * img_out(:,:,2) + 0.114 * img_out(:,:,3);
                mean_Y_out = mean(Y_out(:));
                std_out = std(Y_out(:));

                % 计算灰度共生矩阵GLCM，输入图像
                gray_in = rgb2gray(im2uint8(img_in)); % 转 uint8 保证灰度矩阵正确
                glcm = graycomatrix(gray_in, 'Offset', [0 1]);
                stats = graycoprops(glcm, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});
                contrast = stats.Contrast;
                correlation = stats.Correlation;
                energy = stats.Energy;
                homogeneity = stats.Homogeneity;

                parts_in = split(fname_in, '_');
                ik = str2double(parts_in{4});
                wk_parts = split(parts_in{5}, '.');
                wk = str2double(wk_parts{1});

                records(end+1, :) = {
                    color_out, fname_in, ...
                    avg_in(1), avg_in(2), avg_in(3), mean_Y_in, std_in, mean_grad_in, ik, wk, ...
                    contrast, correlation, energy, homogeneity, ...
                    fname_out, avg_out(1), avg_out(2), avg_out(3), mean_Y_out, std_out, ik, wk
                };

            end
        end
    end

    headers = {
        '纱线颜色', '输入文件名', ...
        'i_R', 'i_G', 'i_B', 'i_mean', 'i_stdY', 'i_梯度幅值均值', 'i_koushu', 'i_weishu', ...
        'i_contrast', 'i_correlation', 'i_energy', 'i_homogeneity', ...
        '输出文件名', 'o_R', 'o_G', 'o_B', 'o_meanY', 'o_stdY', 'koushu', 'weishu'
    };

    output_file = 'C:\Users\Deer\Desktop\samples_400_new.xlsx';
    T = cell2table(records, 'VariableNames', headers);
    writetable(T, output_file);
    fprintf('Excel 文件已保存为：%s\n', output_file);
end

function img = load_image(path)
    img = imread(path);
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end
    img = im2double(img);
end





