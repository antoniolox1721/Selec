clc;
close all;

output_dir = fullfile('output', 'parte_a');
if ~exist(output_dir, 'dir')
  mkdir(output_dir);
end

if exist('OCTAVE_VERSION', 'builtin')
  pkg load signal;
end

fs = 2000;
fc = 120;
wc = 2 * pi * fc;
nfft = 2048;

% =================================
% IIR por transformação bilinear
% =================================
num_s = [0 0 wc^2];
den_s = [1 sqrt(2) * wc wc^2];
[b_iir, a_iir] = bilinear(num_s, den_s, fs);

% =================================
% FIR com 41 coeficientes
% =================================
fir_order = 40;
window_rect = ones(1, fir_order + 1);
window_hann = hanning(fir_order + 1)';
b_fir_rect = fir1(fir_order, fc / (fs / 2), 'low', window_rect);
b_fir_hann = fir1(fir_order, fc / (fs / 2), 'low', window_hann);
a_fir = 1;

[h_iir, w_iir] = freqz(b_iir, a_iir, nfft, fs);
[h_rect, w_rect] = freqz(b_fir_rect, a_fir, nfft, fs);
[h_hann, w_hann] = freqz(b_fir_hann, a_fir, nfft, fs);

figure('visible', 'off');
plot(w_iir, 20 * log10(abs(h_iir) + eps), 'LineWidth', 1.4); hold on;
plot(w_rect, 20 * log10(abs(h_rect) + eps), 'LineWidth', 1.2);
plot(w_hann, 20 * log10(abs(h_hann) + eps), 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');
title('Resposta em frequência');
legend('IIR bilinear', 'FIR janela retangular', 'FIR janela Hanning', 'Location', 'southwest');
saveas(gcf, fullfile(output_dir, 'resposta_frequencia.png'));

figure('visible', 'off');
plot(w_iir, unwrap(angle(h_iir)), 'LineWidth', 1.4); hold on;
plot(w_rect, unwrap(angle(h_rect)), 'LineWidth', 1.2);
plot(w_hann, unwrap(angle(h_hann)), 'LineWidth', 1.2);
grid on;
xlabel('Frequência (Hz)');
ylabel('Fase (rad)');
title('Resposta de fase');
legend('IIR bilinear', 'FIR janela retangular', 'FIR janela Hanning', 'Location', 'southwest');
saveas(gcf, fullfile(output_dir, 'resposta_fase.png'));

t = 0:1 / fs:0.5;
sinal = sin(2 * pi * 50 * t) + 0.6 * sin(2 * pi * 250 * t) + 0.2 * randn(size(t));
y_iir = filter(b_iir, a_iir, sinal);
y_rect = filter(b_fir_rect, a_fir, sinal);
y_hann = filter(b_fir_hann, a_fir, sinal);

figure('visible', 'off');
plot(t, sinal, 'Color', [0.5 0.5 0.5]); hold on;
plot(t, y_iir, 'LineWidth', 1.2);
plot(t, y_rect, 'LineWidth', 1.1);
plot(t, y_hann, 'LineWidth', 1.1);
xlim([0 0.12]);
grid on;
xlabel('Tempo (s)');
ylabel('Amplitude');
title('Simulação temporal');
legend('Entrada', 'IIR', 'FIR retangular', 'FIR Hanning', 'Location', 'northeast');
saveas(gcf, fullfile(output_dir, 'simulacao_temporal.png'));

spec_freq = (0:nfft / 2 - 1) * (fs / nfft);
fft_in = fft(sinal, nfft);
fft_iir = fft(y_iir, nfft);
fft_rect = fft(y_rect, nfft);
fft_hann = fft(y_hann, nfft);

figure('visible', 'off');
plot(spec_freq, abs(fft_in(1:nfft / 2)), 'Color', [0.5 0.5 0.5]); hold on;
plot(spec_freq, abs(fft_iir(1:nfft / 2)), 'LineWidth', 1.2);
plot(spec_freq, abs(fft_rect(1:nfft / 2)), 'LineWidth', 1.1);
plot(spec_freq, abs(fft_hann(1:nfft / 2)), 'LineWidth', 1.1);
grid on;
xlabel('Frequência (Hz)');
ylabel('|FFT|');
title('Análise espectral');
legend('Entrada', 'IIR', 'FIR retangular', 'FIR Hanning', 'Location', 'northeast');
saveas(gcf, fullfile(output_dir, 'analise_espectral.png'));

pad_a_iir = nan(length(b_iir), 1);
pad_a_iir(1:length(a_iir)) = a_iir(:);
coef_iir = [(0:length(b_iir)-1)', b_iir(:), pad_a_iir];
coef_fir = [(0:length(b_fir_rect)-1)', b_fir_rect(:), b_fir_hann(:)];
simulacao = [t(:), sinal(:), y_iir(:), y_rect(:), y_hann(:)];

fid = fopen(fullfile(output_dir, 'coeficientes_iir.csv'), 'w');
fprintf(fid, 'indice,b_iir,a_iir\n');
for r = 1:size(coef_iir, 1)
  fprintf(fid, '%d,%.10f,%.10f\n', coef_iir(r, 1), coef_iir(r, 2), coef_iir(r, 3));
end
fclose(fid);

fid = fopen(fullfile(output_dir, 'coeficientes_fir.csv'), 'w');
fprintf(fid, 'indice,fir_retangular,fir_hanning\n');
for r = 1:size(coef_fir, 1)
  fprintf(fid, '%d,%.10f,%.10f\n', coef_fir(r, 1), coef_fir(r, 2), coef_fir(r, 3));
end
fclose(fid);

fid = fopen(fullfile(output_dir, 'simulacao_temporal.csv'), 'w');
fprintf(fid, 'tempo_s,entrada,saida_iir,saida_fir_ret,saida_fir_hann\n');
for r = 1:size(simulacao, 1)
  fprintf(fid, '%.10f,%.10f,%.10f,%.10f,%.10f\n', simulacao(r, 1), simulacao(r, 2), simulacao(r, 3), simulacao(r, 4), simulacao(r, 5));
end
fclose(fid);

save(fullfile(output_dir, 'lab3a_resultados.mat'), 'fs', 'fc', 'b_iir', 'a_iir', 'b_fir_rect', 'b_fir_hann', ...
     'w_iir', 'h_iir', 'w_rect', 'h_rect', 'w_hann', 'h_hann', 't', 'sinal', 'y_iir', 'y_rect', 'y_hann');

fprintf('Resultados guardados em %s\n', output_dir);
