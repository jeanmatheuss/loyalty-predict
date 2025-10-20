# Definindo ambiente conda (python)
CONDA_ENV = loyalty-predict

# Definindo diretório do ambiente virtual
VENV_DIR = .venv

# Definindo diretórios
ENGINEERING_DIR = src/engineering
ANALYTICS_DIR = src/analytics

# Configurando ambiente virtual
.PHONY: setup
setup:
	rm -rf $(VENV_DIR)
	@echo "Criando ambiente virtual..."
	python3 -m venv $(VENV_DIR)
	@echo "Ativando ambiente virtual. Instalando dependências..."
	. $(VENV_DIR)/bin/activate && \
	pip install pipreqs	&& \
	pipreqs src/ --force --savepath requirements.txt && \
	pip install -r requirements.txt

# Executa os scripts
.PHONY: collect
collect:
	@echo "Ativando ambiente virtual..."
	. $(VENV_DIR)/bin/activate
	@echo "Executando scripts de coleta..."
	cd src/engineering && \
	python get_data.py

# ETL das Features

.PHONY: etl
elt:
	@echo "Ativando ambiente virtual..."
	. $(VENV_DIR)/bin/activate
	@echo "Executando scripts de Feature Store..."
	cd src/analytics && \
	python pipeline_analytics.py

# Predição do Modelo

.PHONY: predict
predict:
	@echo "Ativando ambiente virtual..."
	. $(VENV_DIR)/bin/activate
	@echo "Executando scripts de Predição..."
	cd src/analytics && \
	python predict_fiel.py

# Alvo Padrão

# predict colocar após a criação do predict_fiel

.PHONY: all
all: setup collect etl