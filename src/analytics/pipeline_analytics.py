#%%
from exec_query import exec_query

import datetime
import json

# Leitura do arquivo config, para alteração mudar diretamente o arquivo confi.json

with open("config.json", "r") as fp:
    steps = json.load(fp)

now = datetime.datetime.now().strftime("%Y-%m-%d")
start = '2025-01-01'
stop = '2025-10-01'

for s in steps:
    if s["dt_start"] == "now":
        s["dt_start"] = now
    if s["dt_stop"] == "now":
        s["dt_stop"] = now

for i in steps:
    exec_query(**i)
# %%
