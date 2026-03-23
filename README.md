# Selec Lab 3

Este repositório contém a implementação do **Lab 3 de SELEC**, organizada para ser simples de executar em ambiente de laboratório e compatível com os ficheiros auxiliares fornecidos (`T_Display.py` e `T_Simulator.py`).

O projeto está dividido em duas partes:

- **Parte B — Osciloscópio digital** em `main.py`.
- **Parte A — Filtros IIR/FIR** em `lab3a_filtros.m`.

A implementação principal da Parte B foi mantida **centrada num único ficheiro `main.py`**, conforme pedido. Não existe arquitetura multi-módulo para a lógica principal do osciloscópio.

---

## 1. Estrutura do projeto

A estrutura relevante do repositório é a seguinte:

```text
.
├── main.py
├── lab3a_filtros.m
├── README.md
├── scripts/
│   └── install_wsl.sh
├── T_Display.py
├── T_Simulator.py
├── arial_16.py
└── output/
    ├── captures/
    ├── spectra/
    ├── logs/
    └── parte_a/
```

### Descrição de cada elemento principal

- **`main.py`**  
  Ficheiro principal da Parte B. Faz aquisição ADC, conversão para tensão, cálculo estatístico, cálculo manual da DFT, desenho da forma de onda, desenho do espectro e gravação local dos resultados.

- **`lab3a_filtros.m`**  
  Script para MATLAB/Octave relativo à Parte A. Implementa filtros IIR e FIR, plota respostas em frequência e fase, faz simulação temporal e análise espectral, e guarda os resultados automaticamente.

- **`scripts/install_wsl.sh`**  
  Script de instalação para ambiente **WSL Ubuntu já existente**. Instala apenas dependências necessárias dentro do Linux.

- **`T_Display.py` / `T_Simulator.py`**  
  Ficheiros auxiliares fornecidos para integração com o display e com o simulador gráfico.

- **`output/`**  
  Pasta onde ficam guardados os resultados produzidos automaticamente pela Parte A e Parte B.

---

## 2. Requisitos do ambiente

## 2.1 WSL recomendado

Para este projeto, deve ser usada uma distribuição **WSL Ubuntu 22.04**.

> **Importante:** a configuração com **Python 3.13 não funciona corretamente neste contexto de laboratório**, sobretudo por questões de compatibilidade com dependências como **PySide2**. Por isso, a recomendação explícita é usar **Ubuntu 22.04 no WSL**, onde a instalação é muito mais estável para este projeto.

### Recomendação prática

- **Usar:** WSL Ubuntu **22.04**
- **Evitar:** ambientes com **Python 3.13**

---

## 2.2 Dependências necessárias

O projeto precisa das seguintes dependências no WSL Ubuntu:

### Pacotes do sistema

- `python3`
- `python3-pip`
- `git`
- `octave`
- `gnuplot`
- `build-essential`

### Dependências Python

- `PySide2`
- `requests`

Estas dependências são as que estão previstas no script de instalação incluído no projeto.

---

## 3. Instalação no WSL Ubuntu 22.04

### 3.1 O que o script faz

O script `scripts/install_wsl.sh`:

- **não instala o WSL**;
- **não cria a distribuição Ubuntu**;
- instala apenas os pacotes necessários **dentro do Ubuntu já instalado**;
- instala também as dependências Python necessárias para o simulador.

### 3.2 Como instalar

Abrir o terminal do **WSL Ubuntu 22.04**, entrar na pasta do projeto e executar:

```bash
bash scripts/install_wsl.sh
```

### 3.3 Instalação manual alternativa

Se preferir instalar manualmente, pode usar:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip git octave gnuplot build-essential
python3 -m pip install --user --upgrade pip
python3 -m pip install --user PySide2 requests
```

---

## 4. Parte B — Osciloscópio digital (`main.py`)

## 4.1 Objetivo

O ficheiro `main.py` implementa um osciloscópio simples, compatível com o simulador fornecido e orientado para uso em laboratório.

### Funcionalidades incluídas

- aquisição de **240 amostras ADC**;
- conversão dos valores ADC para **tensão em volt**;
- cálculo de:
  - `Vmax`
  - `Vmin`
  - `Vavg`
  - `Vrms`
- cálculo manual da **DFT** sem usar `numpy`;
- desenho da **forma de onda** no display;
- desenho do **espectro** no display;
- suporte para **escala vertical** e **escala horizontal**;
- gravação local de resultados em:
  - CSV de amostras
  - CSV do espectro
  - JSON com metadados da sessão

### Escalas por defeito

Quando o programa arranca, usa por omissão:

- **5 V/div**
- **10 ms/div**

---

## 4.2 Como executar a Parte B

No terminal, dentro da pasta do projeto:

```bash
python3 main.py
```

Ao executar:

1. o simulador é aberto;
2. é mostrada uma mensagem inicial no display;
3. é feita automaticamente uma primeira aquisição;
4. o programa entra num ciclo de leitura de botões;
5. cada nova interação pode desencadear nova aquisição e novo armazenamento local.

---

## 4.3 Funcionamento interno do `main.py`

O fluxo geral do programa é o seguinte:

1. **Inicialização do display/simulador** através de `T_Display.TFT()`.
2. **Criação automática das pastas de saída** dentro de `output/`.
3. **Leitura de 240 amostras ADC** com base na escala temporal atual.
4. **Conversão ADC → tensão**, usando as constantes do simulador/laboratório.
5. **Cálculo estatístico** dos valores adquiridos.
6. **Cálculo manual da DFT** para obter o espectro.
7. **Guardar resultados em disco** com timestamp.
8. **Desenhar no display**:
   - grelha;
   - forma de onda;
   - espectro;
   - informação resumida.
9. **Esperar por eventos dos botões** para nova aquisição ou mudança de escala.

---

## 4.4 Organização visual no display

O display é dividido logicamente em duas zonas principais:

- **Zona superior:** forma de onda no domínio do tempo.
- **Zona inferior:** espectro obtido a partir da DFT.

Além disso, o programa mostra informação textual resumida, como:

- escala vertical atual (`V/div`)
- escala horizontal atual (`ms/div`)
- `Vmax`
- `Vmin`
- `Vavg`
- `Vrms`
- frequência dominante aproximada do espectro

---

## 4.5 Botões do simulador

O comportamento dos botões está definido de forma direta e repetível.

### Botão 1

#### Clique curto

- Faz **nova aquisição**.
- Recalcula estatísticas.
- Recalcula espectro.
- Atualiza o display.
- Guarda novos ficheiros em `output/`.

#### Clique longo

- Avança para a **próxima escala vertical**.
- Depois faz logo uma **nova aquisição**.

#### Duplo clique

- Tem o mesmo efeito funcional do clique longo no estado atual do código.
- Ou seja, **muda a escala vertical** e faz nova aquisição.

### Botão 2

#### Clique curto

- Faz **nova aquisição**.
- Recalcula estatísticas.
- Recalcula espectro.
- Atualiza o display.
- Guarda novos ficheiros em `output/`.

#### Clique longo

- Avança para a **próxima escala horizontal**.
- Depois faz logo uma **nova aquisição**.

#### Duplo clique

- Tem o mesmo efeito funcional do clique longo no estado atual do código.
- Ou seja, **muda a escala horizontal** e faz nova aquisição.

---

## 4.6 Escalas disponíveis

### Escalas verticais (`V/div`)

O programa cicla pelas seguintes escalas verticais:

- `0.5 V/div`
- `1.0 V/div`
- `2.0 V/div`
- `5.0 V/div`
- `10.0 V/div`

### Escalas horizontais (`ms/div`)

O programa cicla pelas seguintes escalas horizontais:

- `5 ms/div`
- `10 ms/div`
- `20 ms/div`
- `50 ms/div`

A escala horizontal escolhida determina o tempo total de aquisição, considerando a grelha horizontal usada pelo programa.

---

## 4.7 Ficheiros gerados pela Parte B

Cada aquisição cria automaticamente ficheiros com **timestamp**.

### 1) Captura temporal

Pasta:

```text
output/captures/
```

Formato típico do nome:

```text
capture_AAAAMMDD_HHMMSS_MMM.csv
```

Conteúdo:

- índice da amostra;
- instante temporal;
- valor ADC;
- tensão correspondente.

### 2) Espectro

Pasta:

```text
output/spectra/
```

Formato típico do nome:

```text
spectrum_AAAAMMDD_HHMMSS_MMM.csv
```

Conteúdo:

- bin da DFT;
- frequência em Hz;
- magnitude.

### 3) Metadados da sessão

Pasta:

```text
output/logs/
```

Formato típico do nome:

```text
session_AAAAMMDD_HHMMSS_MMM.json
```

Conteúdo:

- timestamp;
- número de amostras;
- escala temporal;
- escala vertical;
- duração total da aquisição;
- estatísticas calculadas;
- nome dos ficheiros CSV associados.

---

## 5. Parte A — `lab3a_filtros.m`

## 5.1 Objetivo

Este script implementa a parte de processamento de sinal pedida para o laboratório.

### Funcionalidades incluídas

- filtro **IIR** obtido por **transformação bilinear**;
- filtro **FIR com 41 coeficientes**;
- utilização de janela **retangular**;
- utilização de janela **Hanning**;
- gráficos de **resposta em frequência**;
- gráficos de **fase**;
- **simulação temporal**;
- **análise espectral**;
- gravação automática dos resultados.

---

## 5.2 Como executar no MATLAB

Dentro da pasta do projeto:

```matlab
lab3a_filtros
```

## 5.3 Como executar no Octave

Dentro da pasta do projeto:

```octave
lab3a_filtros
```

> Nota: no WSL, a instalação do `octave` e do `gnuplot` já está prevista no script `scripts/install_wsl.sh`.

---

## 5.4 Ficheiros gerados pela Parte A

Os resultados são guardados em:

```text
output/parte_a/
```

Exemplos de ficheiros produzidos:

- `resposta_frequencia.png`
- `resposta_fase.png`
- `simulacao_temporal.png`
- `analise_espectral.png`
- `coeficientes_iir.csv`
- `coeficientes_fir.csv`
- `simulacao_temporal.csv`
- `lab3a_resultados.mat`

---

## 6. Pasta `output/`

A pasta `output/` centraliza todos os resultados do projeto.

```text
output/
  captures/
  spectra/
  logs/
  parte_a/
```

### Significado de cada subpasta

- **`output/captures/`**  
  Guarda os dados temporais da Parte B.

- **`output/spectra/`**  
  Guarda os dados do espectro calculado pela Parte B.

- **`output/logs/`**  
  Guarda os metadados JSON de cada aquisição da Parte B.

- **`output/parte_a/`**  
  Guarda gráficos e resultados produzidos pelo script `lab3a_filtros.m`.

---

## 7. Resumo rápido de utilização

## 7.1 Instalar dependências

```bash
bash scripts/install_wsl.sh
```

## 7.2 Executar o osciloscópio

```bash
python3 main.py
```

## 7.3 Executar a Parte A

### MATLAB

```matlab
lab3a_filtros
```

### Octave

```octave
lab3a_filtros
```

---

## 8. Notas finais

- Este projeto foi preparado para ser **simples, robusto e compatível com o ambiente de laboratório**.
- Não foi incluída qualquer funcionalidade de email; em vez disso, a solução usa **gravação local em ficheiros**.
- A Parte B foi implementada com foco num **único ficheiro principal (`main.py`)**.
- Para evitar problemas de compatibilidade, a escolha recomendada é **WSL Ubuntu 22.04**.
- Se o simulador não arrancar corretamente num ambiente diferente, a primeira verificação deve ser a versão do Python e a disponibilidade do `PySide2`.
