import numpy as np
import pandas as pd
from catboost import CatBoostRegressor
from sklearn.model_selection import GroupKFold
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error

# 读取数据
excel_path = 'C:/Users/Deer/Desktop/平均颜色_输入原颜色.xlsx'
sheet_name = '400'

data = pd.read_excel(excel_path, sheet_name=sheet_name)
data = data.iloc[1:].reset_index(drop=True)  # 去掉第一行空行或表头

# 特征和标签
X = data.iloc[:, [1, 2, 3, 6, 7, 8, 10, 11, 14, 17]].values  # 输入特征
Y = data.iloc[:, 23].values  # Y_std
colors = data.iloc[:, 0].values  # 颜色标签
textures = data['texture'].values  # 纹理类型
koushu = data['筘数'].values
weishu = data['纬数'].values
filenames = data.iloc[:, 5].values  # 文件名

# 原始RGB
R = data.iloc[:, 1].values
G = data.iloc[:, 2].values
B = data.iloc[:, 3].values

# 构造group
structure_id = np.array([f"{t}_{k}_{w}" for t, k, w in zip(textures, koushu, weishu)])

# 五折交叉验证
gkf = GroupKFold(n_splits=5)

Y_val_all = np.zeros_like(Y, dtype=np.float64)  # 保存所有验证集预测
fold_all = np.zeros_like(Y, dtype=int)          # 保存每个样本所属折

print("五折交叉验证训练及验证集评估结果：")
for fold, (train_idx, val_idx) in enumerate(gkf.split(X, Y, groups=structure_id), 1):
    X_train, Y_train = X[train_idx], Y[train_idx]
    X_val, Y_val = X[val_idx], Y[val_idx]

    model = CatBoostRegressor(
        iterations=500,
        learning_rate=0.05,
        depth=9,
        loss_function='RMSE',
        random_seed=42,
        verbose=0,
        task_type="CPU",
        thread_count=1
    )

    model.fit(X_train, Y_train)

    Y_val_pred = model.predict(X_val)
    Y_val_all[val_idx] = Y_val_pred      # 将预测值填回对应位置
    fold_all[val_idx] = fold             # 记录折号

    # 输出当前折的指标
    r2 = r2_score(Y_val, Y_val_pred)
    mse = mean_squared_error(Y_val, Y_val_pred)
    rmse = mean_squared_error(Y_val, Y_val_pred, squared=False)
    mae = mean_absolute_error(Y_val, Y_val_pred)
    print(f"\n第 {fold} 折验证集指标：")
    print(f"  R²   : {r2:.4f}")
    print(f"  MSE  : {mse:.6f}")
    print(f"  RMSE : {rmse:.6f}")
    print(f"  MAE  : {mae:.6f}")

# 总指标
print("\n五折交叉验证总体验证指标：")
print(f"  R²   : {r2_score(Y, Y_val_all):.4f}")
print(f"  MSE  : {mean_squared_error(Y, Y_val_all):.6f}")
print(f"  RMSE : {mean_squared_error(Y, Y_val_all, squared=False):.6f}")
print(f"  MAE  : {mean_absolute_error(Y, Y_val_all):.6f}")

# 保存预测结果
results_df = pd.DataFrame({
    "文件名": filenames,
    "颜色": colors,
    "纹理": textures,
    "筘数": koushu,
    "纬数": weishu,
    "R": R,
    "G": G,
    "B": B,
    "Y_true": Y,
    "Y_pred": Y_val_all,
    "fold": fold_all  # 每个样本所属折
})

save_path = "C:/Users/Deer/Desktop/五折交叉验证预测结果_CatBoost.xlsx"
# results_df.to_excel(save_path, index=False)
print(f"\n五折交叉验证预测结果已保存到: {save_path}")
