clc;
clear;
close all;

% =========================================================
% LAB3a - Design and simulation of digital filters
% MATLAB
% =========================================================

% -----------------------------
% Pasta de output
% -----------------------------
output_dir = fullfile('output', 'parte_a');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% =========================================================
% PARÂMETROS GERAIS
% =========================================================
fs = 8000;                  % frequência de amostragem [Hz]
Ts = 1 / fs;                % período de amostragem [s]
nfft = 4096;                % nº pontos FFT/freqz

% =========================================================
% 1) IIR - FILTRO PASSA-BANDA
% =========================================================
% Especificações do filtro analógico:
% Tipo: passa-banda
% Ordem: 2
% f0 = 1 kHz
% ganho em f0 = 0 dB
% Q = 10

f0 = 1000;                  % frequência central [Hz]
w0 = 2 * pi * f0;           % frequência angular [rad/s]
Q  = 10;

% Transferência analógica:
%              (w0/Q) s
% T(s) = -------------------------
%        s^2 + (w0/Q)s + w0^2

num_s = [0 (w0 / Q) 0];
den_s = [1 (w0 / Q) (w0^2)];

% Resposta analógica para comparação
f_analog = linspace(0, 8000, nfft);
w_analog = 2 * pi * f_analog;
H_analog = freqs(num_s, den_s, w_analog);

% Transformação bilinear
[b_iir, a_iir] = bilinear(num_s, den_s, fs);

% Resposta digital
[h_iir, f_iir] = freqz(b_iir, a_iir, nfft, fs);

% Frequência central analógica e digital (estimada pelo pico)
[~, idx_analog_peak] = max(abs(H_analog));
f0_analog_estimado = f_analog(idx_analog_peak);

[~, idx_digital_peak] = max(abs(h_iir));
f0_digital_estimado = f_iir(idx_digital_peak);

% -----------------------------
% Gráfico magnitude IIR:
% analógico vs digital
% -----------------------------
figure('Visible', 'off');
plot(f_analog, 20*log10(abs(H_analog) + eps), 'LineWidth', 1.5); hold on;
plot(f_iir,    20*log10(abs(h_iir) + eps),    'LineWidth', 1.3);
grid on;
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');
title('IIR passa-banda: resposta em frequência');
legend('Analógico', 'Digital (bilinear)', 'Location', 'best');
xlim([0 8000]);
saveas(gcf, fullfile(output_dir, 'iir_resposta_frequencia.png'));

% -----------------------------
% Gráfico fase IIR:
% analógico vs digital
% -----------------------------
figure('Visible', 'off');
plot(f_analog, unwrap(angle(H_analog)), 'LineWidth', 1.5); hold on;
plot(f_iir,    unwrap(angle(h_iir)),    'LineWidth', 1.3);
grid on;
xlabel('Frequência (Hz)');
ylabel('Fase (rad)');
title('IIR passa-banda: resposta de fase');
legend('Analógico', 'Digital (bilinear)', 'Location', 'best');
xlim([0 8000]);
saveas(gcf, fullfile(output_dir, 'iir_resposta_fase.png'));

% =========================================================
% 1.3) SIMULAÇÃO DO IIR
% =========================================================
% x(t) = 0.5 [1 + sin(2π200t) + sin(2π1000t) + sin(2π3000t)]
% n = 0 ... 15999

n = 0:15999;
t = n / fs;

x = 0.5 * ( ...
      1 ...
    + sin(2*pi*200*t) ...
    + sin(2*pi*1000*t) ...
    + sin(2*pi*3000*t) );

y_iir = filter(b_iir, a_iir, x);

% -----------------------------
% Som (opcional)
% Descomenta se quiseres ouvir
% -----------------------------
% sound(x, fs);
% pause(length(x)/fs + 1);
% sound(y_iir, fs);

% -----------------------------
% Gráfico temporal IIR
% Mostrar apenas uma janela curta
% -----------------------------
idx_plot = 1:400;

figure('Visible', 'off');
plot(t(idx_plot), x(idx_plot), 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(t(idx_plot), y_iir(idx_plot), 'LineWidth', 1.2);
grid on;
xlabel('Tempo (s)');
ylabel('Amplitude');
title('IIR: simulação temporal');
legend('Entrada x[n]', 'Saída y[n]', 'Location', 'best');
saveas(gcf, fullfile(output_dir, 'iir_simulacao_temporal.png'));

% -----------------------------
% FFT IIR
% -----------------------------
X = fft(x, nfft);
Y_iir = fft(y_iir, nfft);

f_fft = (0:nfft/2-1) * (fs / nfft);

mag_X = abs(X(1:nfft/2)) / length(x);
mag_Y_iir = abs(Y_iir(1:nfft/2)) / length(y_iir);

figure('Visible', 'off');
plot(f_fft, mag_X, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(f_fft, mag_Y_iir, 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('|FFT| normalizada');
title('IIR: análise espectral');
legend('Entrada X[k]', 'Saída Y[k]', 'Location', 'best');
xlim([0 fs/2]);
saveas(gcf, fullfile(output_dir, 'iir_analise_espectral.png'));

% Amplitude na frequência central (aproximada)
[~, idx_1k] = min(abs(f_fft - 1000));
amplitude_saida_1k = mag_Y_iir(idx_1k);

% =========================================================
% 2) FIR - FILTRO PASSA-BAIXO
% =========================================================
% Especificações:
% Tipo: low-pass
% fp = 1 kHz
% fs = 8 kHz
% N = 41 coeficientes
% ordem = 40

fp = 1000;
N = 41;
fir_order = N - 1;

% Janelas
window_rect = ones(1, N);
window_hann = hann(N)';

% Coeficientes
b_fir_rect = fir1(fir_order, fp/(fs/2), 'low', window_rect);
b_fir_hann = fir1(fir_order, fp/(fs/2), 'low', window_hann);
a_fir = 1;

% Respostas em frequência
[h_rect, f_rect] = freqz(b_fir_rect, a_fir, nfft, fs);
[h_hann, f_hann] = freqz(b_fir_hann, a_fir, nfft, fs);

% -----------------------------
% Coeficientes FIR
% -----------------------------
figure('Visible', 'off');
stem(0:fir_order, b_fir_rect, 'filled', 'LineWidth', 1.0); hold on;
stem(0:fir_order, b_fir_hann, 'filled', 'LineWidth', 1.0);
grid on;
xlabel('Índice n');
ylabel('Coeficiente');
title('Coeficientes do FIR');
legend('Janela retangular', 'Janela Hanning', 'Location', 'best');
saveas(gcf, fullfile(output_dir, 'fir_coeficientes.png'));

% -----------------------------
% Magnitude FIR
% -----------------------------
figure('Visible', 'off');
plot(f_rect, 20*log10(abs(h_rect) + eps), 'LineWidth', 1.3); hold on;
plot(f_hann, 20*log10(abs(h_hann) + eps), 'LineWidth', 1.3);
grid on;
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');
title('FIR: resposta em frequência');
legend('Janela retangular', 'Janela Hanning', 'Location', 'best');
xlim([0 4000]);
saveas(gcf, fullfile(output_dir, 'fir_resposta_frequencia.png'));

% -----------------------------
% Fase FIR
% -----------------------------
figure('Visible', 'off');
plot(f_rect, unwrap(angle(h_rect)), 'LineWidth', 1.3); hold on;
plot(f_hann, unwrap(angle(h_hann)), 'LineWidth', 1.3);
grid on;
xlabel('Frequência (Hz)');
ylabel('Fase (rad)');
title('FIR: resposta de fase');
legend('Janela retangular', 'Janela Hanning', 'Location', 'best');
xlim([0 4000]);
saveas(gcf, fullfile(output_dir, 'fir_resposta_fase.png'));

% -----------------------------
% Simulação temporal FIR
% -----------------------------
y_rect = filter(b_fir_rect, a_fir, x);
y_hann = filter(b_fir_hann, a_fir, x);

figure('Visible', 'off');
plot(t(idx_plot), x(idx_plot), 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(t(idx_plot), y_rect(idx_plot), 'LineWidth', 1.2);
plot(t(idx_plot), y_hann(idx_plot), 'LineWidth', 1.2);
grid on;
xlabel('Tempo (s)');
ylabel('Amplitude');
title('FIR: simulação temporal');
legend('Entrada x[n]', 'Saída FIR retangular', 'Saída FIR Hanning', 'Location', 'best');
saveas(gcf, fullfile(output_dir, 'fir_simulacao_temporal.png'));

% -----------------------------
% FFT FIR
% -----------------------------
Y_rect = fft(y_rect, nfft);
Y_hann = fft(y_hann, nfft);

mag_Y_rect = abs(Y_rect(1:nfft/2)) / length(y_rect);
mag_Y_hann = abs(Y_hann(1:nfft/2)) / length(y_hann);

figure('Visible', 'off');
plot(f_fft, mag_X, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(f_fft, mag_Y_rect, 'LineWidth', 1.2);
plot(f_fft, mag_Y_hann, 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('|FFT| normalizada');
title('FIR: análise espectral');
legend('Entrada X[k]', 'FIR retangular', 'FIR Hanning', 'Location', 'best');
xlim([0 fs/2]);
saveas(gcf, fullfile(output_dir, 'fir_analise_espectral.png'));

% =========================================================
% COMPARAÇÃO GLOBAL
% =========================================================
figure('Visible', 'off');
plot(f_iir, 20*log10(abs(h_iir) + eps), 'LineWidth', 1.4); hold on;
plot(f_rect, 20*log10(abs(h_rect) + eps), 'LineWidth', 1.2);
plot(f_hann, 20*log10(abs(h_hann) + eps), 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');
title('Comparação global: resposta em frequência');
legend('IIR bilinear', 'FIR retangular', 'FIR Hanning', 'Location', 'best');
xlim([0 4000]);
saveas(gcf, fullfile(output_dir, 'comparacao_resposta_frequencia.png'));

figure('Visible', 'off');
plot(f_iir, unwrap(angle(h_iir)), 'LineWidth', 1.4); hold on;
plot(f_rect, unwrap(angle(h_rect)), 'LineWidth', 1.2);
plot(f_hann, unwrap(angle(h_hann)), 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('Fase (rad)');
title('Comparação global: resposta de fase');
legend('IIR bilinear', 'FIR retangular', 'FIR Hanning', 'Location', 'best');
xlim([0 4000]);
saveas(gcf, fullfile(output_dir, 'comparacao_resposta_fase.png'));

figure('Visible', 'off');
plot(t(idx_plot), x(idx_plot), 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(t(idx_plot), y_iir(idx_plot), 'LineWidth', 1.2);
plot(t(idx_plot), y_rect(idx_plot), 'LineWidth', 1.2);
plot(t(idx_plot), y_hann(idx_plot), 'LineWidth', 1.2);
grid on;
xlabel('Tempo (s)');
ylabel('Amplitude');
title('Comparação global: simulação temporal');
legend('Entrada', 'IIR', 'FIR retangular', 'FIR Hanning', 'Location', 'best');
saveas(gcf, fullfile(output_dir, 'comparacao_simulacao_temporal.png'));

figure('Visible', 'off');
plot(f_fft, mag_X, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
plot(f_fft, mag_Y_iir, 'LineWidth', 1.2);
plot(f_fft, mag_Y_rect, 'LineWidth', 1.2);
plot(f_fft, mag_Y_hann, 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('|FFT| normalizada');
title('Comparação global: análise espectral');
legend('Entrada', 'IIR', 'FIR retangular', 'FIR Hanning', 'Location', 'best');
xlim([0 fs/2]);
saveas(gcf, fullfile(output_dir, 'comparacao_analise_espectral.png'));

% =========================================================
% ATRASO DO FIR
% =========================================================
delay_teorico_amostras = (N - 1) / 2;
delay_teorico_segundos = delay_teorico_amostras / fs;

% Estimativa do atraso por correlação cruzada
[c_rect, lags_rect] = xcorr(y_rect, x);
[~, idx_rect_max] = max(c_rect);
delay_rect_amostras = lags_rect(idx_rect_max);
delay_rect_segundos = delay_rect_amostras / fs;

[c_hann, lags_hann] = xcorr(y_hann, x);
[~, idx_hann_max] = max(c_hann);
delay_hann_amostras = lags_hann(idx_hann_max);
delay_hann_segundos = delay_hann_amostras / fs;

% =========================================================
% EXPORTAÇÃO CSV
% =========================================================

% IIR
max_len_iir = max(length(b_iir), length(a_iir));
b_iir_pad = nan(max_len_iir, 1);
a_iir_pad = nan(max_len_iir, 1);
b_iir_pad(1:length(b_iir)) = b_iir(:);
a_iir_pad(1:length(a_iir)) = a_iir(:);

coef_iir = [(0:max_len_iir-1)', b_iir_pad, a_iir_pad];

fid = fopen(fullfile(output_dir, 'coeficientes_iir.csv'), 'w');
fprintf(fid, 'indice,b_iir,a_iir\n');
for r = 1:size(coef_iir, 1)
    fprintf(fid, '%d,%.12f,%.12f\n', coef_iir(r,1), coef_iir(r,2), coef_iir(r,3));
end
fclose(fid);

% FIR
coef_fir = [(0:fir_order)', b_fir_rect(:), b_fir_hann(:)];

fid = fopen(fullfile(output_dir, 'coeficientes_fir.csv'), 'w');
fprintf(fid, 'indice,fir_retangular,fir_hanning\n');
for r = 1:size(coef_fir, 1)
    fprintf(fid, '%d,%.12f,%.12f\n', coef_fir(r,1), coef_fir(r,2), coef_fir(r,3));
end
fclose(fid);

% Simulação temporal completa
simulacao = [t(:), x(:), y_iir(:), y_rect(:), y_hann(:)];

fid = fopen(fullfile(output_dir, 'simulacao_temporal.csv'), 'w');
fprintf(fid, 'tempo_s,entrada,saida_iir,saida_fir_ret,saida_fir_hann\n');
for r = 1:size(simulacao, 1)
    fprintf(fid, '%.12f,%.12f,%.12f,%.12f,%.12f\n', ...
        simulacao(r,1), simulacao(r,2), simulacao(r,3), simulacao(r,4), simulacao(r,5));
end
fclose(fid);

% FFT
fft_export = [f_fft(:), mag_X(:), mag_Y_iir(:), mag_Y_rect(:), mag_Y_hann(:)];

fid = fopen(fullfile(output_dir, 'analise_espectral.csv'), 'w');
fprintf(fid, 'frequencia_hz,fft_entrada,fft_iir,fft_fir_ret,fft_fir_hann\n');
for r = 1:size(fft_export, 1)
    fprintf(fid, '%.12f,%.12f,%.12f,%.12f,%.12f\n', ...
        fft_export(r,1), fft_export(r,2), fft_export(r,3), fft_export(r,4), fft_export(r,5));
end
fclose(fid);

% =========================================================
% FICHEIRO DE RESUMO TXT
% =========================================================
fid = fopen(fullfile(output_dir, 'resumo_resultados.txt'), 'w');

fprintf(fid, '==============================\n');
fprintf(fid, 'LAB3a - Resumo de resultados\n');
fprintf(fid, '==============================\n\n');

fprintf(fid, 'Parâmetros gerais:\n');
fprintf(fid, 'fs = %d Hz\n', fs);
fprintf(fid, 'Ts = %.12f s\n', Ts);
fprintf(fid, 'nfft = %d\n\n', nfft);

fprintf(fid, 'IIR passa-banda:\n');
fprintf(fid, 'f0 teórica = %.2f Hz\n', f0);
fprintf(fid, 'Q = %.2f\n', Q);
fprintf(fid, 'f0 analógica estimada = %.4f Hz\n', f0_analog_estimado);
fprintf(fid, 'f0 digital estimada = %.4f Hz\n\n', f0_digital_estimado);

fprintf(fid, 'Amplitude na saída do IIR em 1 kHz (FFT normalizada): %.8f\n\n', amplitude_saida_1k);

fprintf(fid, 'FIR:\n');
fprintf(fid, 'fp = %.2f Hz\n', fp);
fprintf(fid, 'Número de coeficientes N = %d\n', N);
fprintf(fid, 'Ordem = %d\n\n', fir_order);

fprintf(fid, 'Atraso do FIR:\n');
fprintf(fid, 'Atraso teórico = %d amostras = %.8f s\n', ...
    delay_teorico_amostras, delay_teorico_segundos);
fprintf(fid, 'Atraso estimado FIR retangular = %d amostras = %.8f s\n', ...
    delay_rect_amostras, delay_rect_segundos);
fprintf(fid, 'Atraso estimado FIR Hanning = %d amostras = %.8f s\n', ...
    delay_hann_amostras, delay_hann_segundos);

fclose(fid);

% =========================================================
% SAVE .MAT
% =========================================================
save(fullfile(output_dir, 'lab3a_resultados.mat'), ...
    'fs', 'Ts', 'nfft', ...
    'f0', 'w0', 'Q', 'num_s', 'den_s', ...
    'f_analog', 'H_analog', ...
    'b_iir', 'a_iir', 'h_iir', 'f_iir', ...
    'x', 'y_iir', ...
    'fp', 'N', 'fir_order', ...
    'b_fir_rect', 'b_fir_hann', ...
    'h_rect', 'h_hann', 'f_rect', 'f_hann', ...
    'y_rect', 'y_hann', ...
    't', 'f_fft', 'mag_X', 'mag_Y_iir', 'mag_Y_rect', 'mag_Y_hann', ...
    'f0_analog_estimado', 'f0_digital_estimado', ...
    'amplitude_saida_1k', ...
    'delay_teorico_amostras', 'delay_teorico_segundos', ...
    'delay_rect_amostras', 'delay_rect_segundos', ...
    'delay_hann_amostras', 'delay_hann_segundos');

fprintf('Resultados guardados em: %s\n', output_dir);
fprintf('Frequência central analógica estimada: %.4f Hz\n', f0_analog_estimado);
fprintf('Frequência central digital estimada: %.4f Hz\n', f0_digital_estimado);
fprintf('Amplitude da saída do IIR em 1 kHz: %.8f\n', amplitude_saida_1k);
fprintf('Atraso teórico FIR: %d amostras (%.8f s)\n', ...
    delay_teorico_amostras, delay_teorico_segundos);