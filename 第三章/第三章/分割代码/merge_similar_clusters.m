function merged_idx = merge_similar_clusters(idx, lab_img, k)

    % 初始化聚类中心和样本数量
    cluster_centers = zeros(k, 3);
    cluster_sizes = zeros(k, 1);
    
    % 计算每个聚类的中心和样本数量
    for i = 1:k
        cluster_points = lab_img(idx == i, :);
        if ~isempty(cluster_points)
            cluster_centers(i, :) = mean(cluster_points, 1);
            cluster_sizes(i) = size(cluster_points, 1);
        else
            cluster_centers(i, :) = NaN; % 使用NaN填充空聚类
        end
    end
    
    % 定义相似度阈值
    similarity_threshold = 18; % 根据需要调整阈
    
    % 合并相似聚类簇
    merged_idx = idx;
    merged = false(1, k);
    for i = 1:k
        % 如果簇i已经被合并(merged(i)为true)，或者簇i的中心包含NaN值，则跳过该簇的处理。
        if merged(i) || any(isnan(cluster_centers(i, :)))
            continue;
        end
        for j = i+1:k
            % 如果簇j没有被合并(merged(j)为false)，簇j的中心没有NaN值并且簇i和j的中心距离小于相似性阈值 
            if ~merged(j) && ~any(isnan(cluster_centers(j, :))) && norm(cluster_centers(i, :) - cluster_centers(j, :)) < similarity_threshold
                % 合并相似聚类簇
                fprintf('簇 %d 和 簇 %d 合并\n', i, j);
                merged_idx(idx == j) = i;
                merged(j) = true;
            end
        end
    end
    
    % 重新编号合并后的聚类簇
    merged_idx = renumber_clusters(merged_idx, merged);
end

function new_idx = renumber_clusters(idx, merged)
    new_idx = zeros(size(idx));
    cluster_map = zeros(1, max(idx));
    cluster_count = 0;
    for i = 1:length(merged)
        if ~merged(i)
            cluster_count = cluster_count + 1;
            cluster_map(i) = cluster_count;
        end
    end
    for i = 1:length(idx)
        new_idx(i) = cluster_map(idx(i));
    end
end
