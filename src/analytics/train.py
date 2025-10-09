#%%

import pandas as pd
import sqlalchemy

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")
# %%

# SAMPLE - IMPORT DOS DADOS

df = pd.read_sql("abt_fiel", con)
df.head()

# %%

# SAMPLE - OOT

df_oot = df[df['dtRef'] == df['dtRef'].max()].reset_index(drop=True)
df_oot.head()

# %%

# SAMPLE - TEST AND TRAIN

target = 'flFiel'

features = df.columns.tolist()[3:]

df_train_test = df[df['dtRef'] < df['dtRef'].max()].reset_index(drop=True)

X = df_train_test[features] # isso é um pd.DataFrame -> Matriz
y = df_train_test[target]  # isso é um pd.series -> Vetor

# %%

from sklearn import model_selection

X_train, X_test, y_train, y_test = model_selection.train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y,
)

print(f"Base Treino {y_train.shape[0]} Unid. | Tx. Target {100*y_train.mean():.2f}%", )
print(f"Base Treino {y_test.shape[0]} Unid. | Tx. Target {100*y_test.mean():.2f}%", )

# %%

# EXPLORE - MISSING

s_nas = X_train.isna().mean()
s_nas = s_nas[s_nas>0]
print(s_nas)

# %%

# EXPLORE - Bivariada

cat_features = ['descLifeCycleAtual', 'descLifeCycleD28']
num_features = list(set(features) - set(cat_features))


df_train = X_train.copy()
df_train[target] = y_train.copy()

df_train[num_features] = df_train[num_features].astype(float)

bivariada = df_train.groupby(target)[num_features].median().T
bivariada['ratio'] = (bivariada[1] + 0.001) / (bivariada[0] + 0.001)
bivariada.sort_values(by='ratio', ascending=False)


#se a variável no modelo bivariada for 1 de um pro ooutro, quer dizer que não faz sentido usar essa variável

# %%
# removendo colunas com bivariada = 1
to_remove = bivariada[bivariada['ratio']==1].index.tolist()
to_remove


for i in to_remove:
    features.remove(i)
    num_features.remove(i)

# %%

bivariada = df_train.groupby(target)[num_features].median().T
bivariada['ratio'] = (bivariada[1] + 0.001) / (bivariada[0] + 0.001)
bivariada.sort_values(by='ratio', ascending=False)
# %%
