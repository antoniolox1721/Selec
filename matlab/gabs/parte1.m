clc;
clear;
close all;

%% LAB 3a - Secção 1.1: Filtro Analógico Ta(s)
fo = 1000;          % Frequência central (Hz)
Q = 10;             % Factor de qualidade
ko = 1;             % Ganho linear (0 dB)
wo = 2 * pi * fo;   % Frequência angular central

% Definição do vetor de frequências (0 a 8kHz conforme o guia)
f = 0:10:8000;      % Escala linear é útil para comparar com o digital depois
w = 2 * pi * f;
s = 1j * w;

% Transfer function Ta(s) fornecida no guia 
num_a = ko * (wo/Q) * s;
den_a = s.^2 + (wo/Q)*s + wo^2;
Ta = num_a ./ den_a;

% Magnitude e Fase
Ga = 20 * log10(abs(Ta));
phi_a = angle(Ta) * 180/pi;

%% LAB 3a - Secção 1.2: Transferência do Filtro Digital
fs = 8000;          % Frequência de amostragem (8kHz) 
T = 1/fs;           % Período de amostragem 

% --- CORREÇÃO CRÍTICA ---
% A função bilinear precisa dos coeficientes da função de transferência!
b_analog = [ko*(wo/Q), 0];     % Coeficientes do numerador: s^1, s^0
a_analog = [1, wo/Q, wo^2];    % Coeficientes do denominador: s^2, s^1, s^0

% 1. Obter os coeficientes do filtro digital
[nd, dd] = bilinear(b_analog, a_analog, fs); 

% 2. Calcular a resposta em frequência do filtro digital 
N_pts = 1024; 
[Td, gamma] = freqz(nd, dd, N_pts, 'whole');                                       

% 3. Converter frequência angular digital (gamma) para Hz                            
fd = (gamma / (2 * pi)) * fs; 

% 4. Magnitude em dB e Fase em graus para o filtro digital 
Gd = 20 * log10(abs(Td));
% Usamos 'unwrap' para evitar que a fase dê saltos feios de 360 graus
phi_d = unwrap(angle(Td)) * 180/pi; 

% --- Plotagem APENAS do Digital (sem hold on) ---
figure('Color', 'w', 'Name', 'Filtro Digital Td(z) vs Filtro Analógico');

% Magnitude
subplot(2,1,1);
plot(f, Ga, 'LineWidth', 2, 'Color', [0 0.447 0.741]);
hold on;
plot(fd, Gd, 'LineWidth', 2, 'Color', [0.635 0.078 0.184]); % Vermelho escuro
grid on; 
axis([0 8000 -50 5]); % Eixo até 4000Hz (Nyquist)
ylabel('Magnitude G_d(\omega) [dB]');
title('Resposta em Frequência');

% Fase
subplot(2,1,2);
plot(f, phi_a, 'LineWidth', 2, 'Color', [0.85 0.325 0.098]);
hold on;
plot(fd, phi_d, 'LineWidth', 2, 'Color', [0.466 0.674 0.188]); % Verde
grid on;
ylabel('Fase \phi_d [º]');
xlabel('Frequência [Hz]');

% --- Resposta à Question 1 ---
[~, idx_d] = max(Gd);
[~, idx_a] = max(Ga);
fprintf('Frequência central digital (foa): %.2f Hz\n', f(idx_a));
fprintf('Frequência central digital (fod): %.2f Hz\n', fd(idx_d));


%% LAB 3a - Secção 1.3: Simulação do Filtro Digital (Sinais e Áudio)
fs = 8000;         % Frequência de amostragem
N = 16000;         % Total de amostras
n = 0:(N-1);       % Vetor de índices
t = n / fs;        % Vetor de tempo

% 1. Criar o sinal de entrada x(t) com amostras
x = 0.5 * (1 + sin(2*pi*200*t) + sin(2*pi*1000*t) + sin(2*pi*3000*t));

% 2. Filtrar o sinal usando a equação de diferenças
% A função 'filter' usa os coeficientes do filtro digital que criámos na 1.2
y = filter(nd, dd, x);

% 3. Representação Gráfica no Tempo (mostramos apenas os primeiros 20 ms para se ver bem)
figure('Color', 'w', 'Name', 'Sinais no Domínio do Tempo');
subplot(2,1,1);
plot(t(1:160)*1000, x(1:160), 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
title('Sinal de Entrada: x_n'); xlabel('Tempo [ms]'); ylabel('Amplitude [V]'); grid on;

subplot(2,1,2);
plot(t(1:160)*1000, y(1:160), 'LineWidth', 1.5, 'Color', [0.85 0.325 0.098]);
title('Sinal de Saída (Filtrado): y_n'); xlabel('Tempo [ms]'); ylabel('Amplitude [V]'); grid on;

% 4. Reprodução de Áudio (Descomenta estas linhas para ouvires!)
% disp('A reproduzir o sinal original (x)...');
% sound(x, fs);
% pause(3); % Espera que o som acabe
% disp('A reproduzir o sinal filtrado (y)...');
% sound(y, fs);

% 5. Transformada de Fourier Discreta (DFT)
% Calculamos a FFT e dividimos por N para normalizar a amplitude
Xdft = abs(fft(x)) / N;
Ydft = abs(fft(y)) / N;

% Criar o espetro unilateral (apenas frequências positivas) e dobrar a amplitude (exceto a componente DC)
% Isto segue exatamente a teoria apresentada no LAB3b para obter Xss.
Xss = Xdft(1:N/2+1); Xss(2:end-1) = 2 * Xss(2:end-1);
Yss = Ydft(1:N/2+1); Yss(2:end-1) = 2 * Yss(2:end-1);

f_dft = (0:N/2) * (fs / N); % Cria o eixo de frequências para a DFT

% Gráficos do Espetro de Frequências
figure('Color', 'w', 'Name', 'Transformada de Fourier (Espetro)');
subplot(2,1,1);
plot(f_dft, Xss, 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
title('Espetro do Sinal de Entrada (Xdft)'); xlabel('Frequência [Hz]'); ylabel('Amplitude [V]'); grid on;
xlim([0 4000]);

subplot(2,1,2);
plot(f_dft, Yss, 'LineWidth', 1.5, 'Color', [0.85 0.325 0.098]);
title('Espetro do Sinal de Saída (Ydft)'); xlabel('Frequência [Hz]'); ylabel('Amplitude [V]'); grid on;
xlim([0 4000]);

% Encontrar o valor exato da amplitude em 1000 Hz na saída para responder à Question 2
idx_1kHz = find(f_dft == 1000);
fprintf('Amplitude do sinal de entrada a 1000 Hz: %.4f V\n', Xss(idx_1kHz));
fprintf('Amplitude do sinal de saída a 1000 Hz: %.4f V\n', Yss(idx_1kHz));

%% LAB 3a - Secção 1.3: Simulação do Filtro Digital (Sinais e Áudio)
fs = 8000;         % Frequência de amostragem
N = 16000;         % Total de amostras
n = 0:(N-1);       % Vetor de índices
t = n / fs;        % Vetor de tempo

% 1. Criar o sinal de entrada x(t) com amostras
x = 0.5 * (1 + sin(2*pi*200*t) + sin(2*pi*1000*t) + sin(2*pi*3000*t));

% 2. Filtrar o sinal usando a equação de diferenças
% A função 'filter' usa os coeficientes do filtro digital que criámos na 1.2
y = filter(nd, dd, x);

% 3. Representação Gráfica no Tempo (mostramos apenas os primeiros 20 ms para se ver bem)
figure('Color', 'w', 'Name', 'Sinais no Domínio do Tempo');
subplot(2,1,1);
plot(t(1:160)*1000, x(1:160), 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
title('Sinal de Entrada: x_n'); xlabel('Tempo [ms]'); ylabel('Amplitude [V]'); grid on;

subplot(2,1,2);
plot(t(1:160)*1000, y(1:160), 'LineWidth', 1.5, 'Color', [0.85 0.325 0.098]);
title('Sinal de Saída (Filtrado): y_n'); xlabel('Tempo [ms]'); ylabel('Amplitude [V]'); grid on;

% 4. Reprodução de Áudio (Descomenta estas linhas para ouvires!)
% disp('A reproduzir o sinal original (x)...');
% sound(x, fs);
% pause(3); % Espera que o som acabe
% disp('A reproduzir o sinal filtrado (y)...');
% sound(y, fs);

% 5. Transformada de Fourier Discreta (DFT)
% Calculamos a FFT e dividimos por N para normalizar a amplitude
Xdft = abs(fft(x)) / N;
Ydft = abs(fft(y)) / N;

% Criar o espetro unilateral (apenas frequências positivas) e dobrar a amplitude (exceto a componente DC)
% Isto segue exatamente a teoria apresentada no LAB3b para obter Xss.
Xss = Xdft(1:N/2+1); Xss(2:end-1) = 2 * Xss(2:end-1);
Yss = Ydft(1:N/2+1); Yss(2:end-1) = 2 * Yss(2:end-1);

f_dft = (0:N/2) * (fs / N); % Cria o eixo de frequências para a DFT

% Gráficos do Espetro de Frequências
figure('Color', 'w', 'Name', 'Transformada de Fourier (Espetro)');
subplot(2,1,1);
plot(f_dft, Xss, 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
title('Espetro do Sinal de Entrada (Xdft)'); xlabel('Frequência [Hz]'); ylabel('Amplitude [V]'); grid on;
xlim([0 4000]);

subplot(2,1,2);
plot(f_dft, Yss, 'LineWidth', 1.5, 'Color', [0.85 0.325 0.098]);
title('Espetro do Sinal de Saída (Ydft)'); xlabel('Frequência [Hz]'); ylabel('Amplitude [V]'); grid on;
xlim([0 4000]);

% Encontrar o valor exato da amplitude em 1000 Hz na saída para responder à Question 2
idx_1kHz = find(f_dft == 1000);
fprintf('Amplitude do sinal de entrada a 1000 Hz: %.4f V\n', Xss(idx_1kHz));
fprintf('Amplitude do sinal de saída a 1000 Hz: %.4f V\n', Yss(idx_1kHz));