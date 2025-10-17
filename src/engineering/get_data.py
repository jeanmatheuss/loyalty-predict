#%%

import dotenv
import shutil

dotenv.load_dotenv('../../.env')

from kaggle import api


datasets = [
    'teocalvo/teomewhy-loyalty-system',
    'teocalvo/teomewhy-education-platform'
]

for i in datasets:
    dataset_name = i.split("teomewhy-")[-1]
    path = f'../../data/{dataset_name}/database.db'
    api.dataset_download_file(i, 'database.db')
    shutil.move("database.db", path)
# %%
