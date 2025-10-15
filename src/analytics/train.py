#%%

import pandas as pd
import sqlalchemy
import matplotlib.pyplot as plt

from sklearn import model_selection

from feature_engine import selection
from feature_engine import imputation
from feature_engine import encoding

import mlflow

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment(experiment_id=481979373587284901)

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")
# %%

# SAMPLE - IMPORT DOS DADOS

#import com select para arrumar o tipo de coluna

df = pd.read_sql("SELECT * FROM abt_fiel", con)
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

#se a variável no modelo bivariada for 1 de um pro ooutro, quer dizer que não faz sentido usar essa variável
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

# MODIFY - ONEHOT

# onehot encoding para poucas categorias ( aplicando nas variáveis categóricas)

onehot = encoding.OneHotEncoder(variables=cat_features)


# %%

# MODELs

from sklearn import tree
from sklearn import ensemble

# model = tree.DecisionTreeClassifier(random_state=42, min_samples_leaf=50)
# model = ensemble.AdaBoostClassifier(random_state=42,
#                                     n_estimators=150,
#                                     learning_rate=0.1)
model = ensemble.RandomForestClassifier(random_state=42,
                                       n_jobs=2)

#grid -> Cross Validation
params = {
        "n_estimators": [100,200, 400, 500, 1000],
        "min_samples_leaf": [10, 20, 30, 50, 75, 100]
    }

grid = model_selection.GridSearchCV(model, 
                                    param_grid=params, 
                                    cv=3, 
                                    scoring='roc_auc',
                                    refit=True,
                                    verbose=3,
                                    n_jobs=10)



# %%

# Criando Pipeline

from sklearn import pipeline

with mlflow.start_run() as rn:
    mlflow.sklearn.autolog()

    model_pipeline = pipeline.Pipeline(steps=[
        ('Remocao de Features', drop_features),
        ('Imputacao de Zeros', imput_0),
        ("Imputacao de Nao Usuario", imput_new),
        ('Imputacao de 1000', imput_1000),
        ("OneHote Encoding", onehot),
        ("Algoritmo", grid)
    ])

    model_pipeline.fit(X_train, y_train)




# ASSESS - Métricas

    from sklearn import metrics

    y_pred_train = model_pipeline.predict(X_train)
    y_prob_train = model_pipeline.predict_proba(X_train)

    acc_train = metrics.accuracy_score(y_train, y_pred_train)
    auc_train = metrics.roc_auc_score(y_train,y_prob_train[:,1])

    print("Accurácia Treino:", acc_train)
    print("AUC Treino:", auc_train)

    # só aplicar o transform no teste


    y_pred_test = model_pipeline.predict(X_test)
    y_prob_test = model_pipeline.predict_proba(X_test)

    acc_test = metrics.accuracy_score(y_test, y_pred_test)
    auc_test = metrics.roc_auc_score(y_test,y_prob_test[:,1])

    print("Accurácia Teste:", acc_test)
    print("AUC Teste:", auc_test)

    # verificando oot (out of time)
    X_oot = df_oot[features]
    y_oot = df_oot[target]

    y_pred_oot = model_pipeline.predict(X_oot)
    y_prob_oot = model_pipeline.predict_proba(X_oot)

    acc_oot = metrics.accuracy_score(y_oot, y_pred_oot)
    auc_oot = metrics.roc_auc_score(y_oot,y_prob_oot[:,1])

    print("Accurácia OOT:", acc_oot)
    print("AUC OOT:", auc_oot)

    mlflow.log_metrics({
        'acc_train':acc_train,
        'auc_train':auc_train,
        'acc_test':acc_test,
        'auc_test':auc_test,
        'acc_oot':acc_oot,
        'auc_oot':auc_oot
        })
    
    roc_train = metrics.roc_curve(y_train,y_prob_train[:,1])
    roc_test = metrics.roc_curve(y_test, y_prob_test[:,1])
    roc_oot = metrics.roc_curve(y_oot, y_prob_oot[:,1])

    plt.plot(roc_train[0], roc_train[1])
    plt.plot(roc_test[0], roc_test[1])
    plt.plot(roc_oot[0], roc_oot[1])
    plt.legend([f"Treino:{auc_train:.4f}", 
                f"Teste:{auc_test:.4f}", 
                f"OOT:{auc_oot:.4f}"])
    plt.plot([0,1],[0,1], '--', color= 'black')
    plt.grid(True)
    plt.title("Curva ROC")
    plt.savefig("curva_roc.png")

    mlflow.log_artifact("curva_roc.png")

# %%
# ASSESS - Persistir Modelo

model_series = pd.Series(
        {
            "model": model_pipeline,
            "features":X_train.columns.tolist(),
            "auc_train": auc_train,
            "auc_test": auc_test,
            "auc_oot": auc_oot
        }
    )

model_series.to_pickle("model_fiel.pkl")
# %%

# verificar features importantes pro modelo
features_names = (model_pipeline[:-1].transform(X_train.head(-1)).columns.tolist())
feature_importance = pd.Series(model_pipeline[:-1].feature_importances_, index=features_names)
feature_importance.sort_values(ascending=False)


# testar para outros modelos de ML