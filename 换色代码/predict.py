
import numpy as np
import pandas as pd
from catboost import CatBoostRegressor

# 加载模型
model_path = "C:/Users/Deer/Desktop/图像换色/color_transfer/CatBoost/model.cbm"
model = CatBoostRegressor()
model.load_model(model_path)

# 新样本的新数据
X_new = np.array([
    # 目标RGB、原图RGB、标准差、梯度幅值、对比度、同质性
    [0.799667426,0.707235539,0.23483299,0.162083205,0.301030491,0.361963243,0.047254281,0.207158768,0.122536268,0.946330614], # 恐龙
    [0.774665,0.571325,0.562186,0.688953209,0.349793245,0.21006306,0.063328721,0.264557555,0.03754555,0.989533522], # 鱼
])

# 模型预测
Y_new_pred = model.predict(X_new)

# 预测结果
print("\n预测结果：")
for y_pred in Y_new_pred:
    print(f"{y_pred:.6f}")