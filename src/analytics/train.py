#%%

import pandas as pd
import sqlalchemy

from sklearn import model_selection

from feature_engine import selection
from feature_engine import imputation
from feature_engine import encoding

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")
# %%

# SAMPLE - IMPORT DOS DADOS

df = pd.read_sql("abt_fiel", con)
df.head()

# %%

# SAMPLE - OOT (out of time)

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
# to_remove = bivariada[bivariada['ratio']==1].index.tolist()
# to_remove


# for i in to_remove:
#     features.remove(i)
#     num_features.remove(i)

# %%

bivariada = df_train.groupby(target)[num_features].median().T
bivariada['ratio'] = (bivariada[1] + 0.001) / (bivariada[0] + 0.001)
bivariada = bivariada.sort_values(by='ratio', ascending=False)

bivariada

# %%
df_train.groupby("descLifeCycleAtual")[target].mean()

# %%

df_train.groupby("descLifeCycleD28")[target].mean()

# %%

# MODIFY - DROP

X_train[num_features] = X_train[num_features].astype(float)

# Biblioteca para feature, ele dropa as colunas que não serão usadas no modelo

to_remove = bivariada[bivariada['ratio']==1].index.tolist()
to_remove

drop_features = selection.DropFeatures(to_remove)


# %%

# MODIFY - MISSInG

# biblioteca para preencher 

fill_0 = ['github2025', 'python2025']

imput_0 = imputation.ArbitraryNumberImputer(arbitrary_number=0, variables=fill_0)

imput_new = imputation.CategoricalImputer(
    fill_value='Nao-Usuario', 
    variables=['descLifeCycleD28'])

imput_1000 = imputation.ArbitraryNumberImputer(
    arbitrary_number=1000,
    variables=['avgIntervaloDiasVida',
               'avgIntervaloDiasD28',
               'qtdDiasUltiAtividade'])



# %%

s_na = X_train_transform.isna().mean()
s_na[s_na>0]
# %%

# MODIFY - ONEHOT

# onehot encoding para poucas categorias ( aplicando nas variáveis categóricas)

onehot = encoding.OneHotEncoder(variables=cat_features)

# MODIFY - Aplicando transformações  nas variáveis categóricas do Dataset

X_train_transform = drop_features.fit_transform(X_train)
X_train_transform = imput_0.fit_transform(X_train_transform)
X_train_transform = imput_new.fit_transform(X_train_transform)
X_train_transform = imput_1000.fit_transform(X_train_transform)
X_train_transform = onehot.fit_transform(X_train_transform)

# %%

X_train_transform.head()
# %%
