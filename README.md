# Projeto de Laboratório Universitário

Este repositório contém uma solução simples e compatível com o simulador fornecido para duas partes do laboratório:

- **Parte B:** osciloscópio digital em `main.py`.
- **Parte A:** filtros IIR/FIR em `lab3a_filtros.m`.

A implementação principal do osciloscópio foi mantida num único ficheiro, como pedido.

## Requisitos

### Dentro do WSL Ubuntu

O script `scripts/install_wsl.sh` instala apenas os pacotes necessários dentro de uma instalação já existente do WSL Ubuntu:

- `python3`
- `python3-pip`
- `git`
- `octave`
- `gnuplot`
- `build-essential`
- dependências Python: `PySide2` e `requests`

## Instalação no WSL

1. Abrir o terminal do **WSL Ubuntu**.
2. Entrar na pasta do projeto.
3. Executar:

```bash
bash scripts/install_wsl.sh
```

> Nota: o script **não instala o WSL**, apenas os pacotes dentro do Ubuntu já instalado.

## Como executar o osciloscópio (Parte B)

Executar:

```bash
python3 main.py
```

### Funcionalidades implementadas em `main.py`

- aquisição de **240 amostras ADC**;
- conversão ADC → tensão;
- cálculo de:
  - `Vmax`
  - `Vmin`
  - `Vavg`
  - `Vrms`
- cálculo manual da **DFT** sem `numpy`;
- visualização da forma de onda;
- visualização do espectro;
- suporte para escalas:
  - **vertical** (V/div)
  - **horizontal** (ms/div)
- gravação local automática em CSV e JSON.

### Escalas por omissão

- **5 V/div**
- **10 ms/div**

### Botões no simulador

- **Botão 1 curto:** nova aquisição
- **Botão 1 longo:** muda a escala vertical
- **Botão 2 curto:** nova aquisição
- **Botão 2 longo:** muda a escala horizontal

## Como executar a Parte A

### MATLAB

No MATLAB, dentro da pasta do projeto:

```matlab
lab3a_filtros
```

### Octave

No Octave, dentro da pasta do projeto:

```octave
lab3a_filtros
```

O script gera automaticamente:

- resposta em frequência;
- resposta de fase;
- simulação temporal;
- análise espectral;
- ficheiros com coeficientes e resultados.

## Estrutura de saídas

As saídas são gravadas automaticamente na pasta `output/`:

```text
output/
  captures/
  spectra/
  logs/
  parte_a/
```

### Parte B

Para cada aquisição do osciloscópio são gravados ficheiros com **timestamp**:

- `output/captures/capture_*.csv`
- `output/spectra/spectrum_*.csv`
- `output/logs/session_*.json`

### Parte A

O script MATLAB/Octave grava automaticamente em `output/parte_a/`:

- gráficos `.png`
- tabelas `.csv`
- ficheiro `.mat`

## Observações

- Não foi incluída qualquer funcionalidade de email.
- O projeto está preparado para uso local com o simulador fornecido.
- A solução privilegia simplicidade, robustez e compatibilidade com o ambiente de laboratório.
