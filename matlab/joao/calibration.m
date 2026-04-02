% ========================================================
% Calibração do Oscilloscope - Ajuste Linear
% ========================================================
clear; clc; close all;

% 1. Inserir os dados
% Fator2
fator2 = 1/29.3;

% Valores digitais medidos no laboratório (Eixo X)
D = [1234.34, 1652.87, 2079.25, 2501.34, 2927.34];

% Valores teóricos de tensão no pino do ADC (Eixo Y)
Vin = [-9.98, -5, 0, 5, 9.98];
Vadc = ((Vin*fator2) + 1);

% 2. Fazer o ajuste linear (polinómio de grau 1: y = mx + b)
p = polyfit(D, Vadc, 1);

% 3. Extrair os coeficientes
ADC_GAIN = p(1);       % Declive (m)
ADC_OFFSET = p(2);     % Interseção com o eixo Y (b)

% 4. Imprimir os resultados na Command Window
fprintf('--- Resultados da Calibração ---\n');
fprintf('Substituir no ficheiro main.py:\n\n');
fprintf('ADC_GAIN = %.8f\n', ADC_GAIN);
fprintf('ADC_OFFSET = %.6f\n', ADC_OFFSET);
fprintf('--------------------------------\n');

% 5. (Opcional) Gerar o gráfico para o relatório
figure;
plot(D, Vadc, 'o', 'MarkerSize', 8, 'LineWidth', 2.5); % Pontos medidos
hold on;
plot(D, polyval(p, D), '-', 'LineWidth', 2.5);         % Reta de ajuste
set(gca, 'LineWidth', 2, 'FontSize', 12, 'FontWeight', 'bold');
% Formatação do gráfico
title('Calibração do ADC','FontSize', 16);
xlabel('Valor Digital Lido (D)');
ylabel('Tensão no ADC (V_{ADC} em Volts)');
legend('Valores Medidos', 'Reta de Ajuste Linear', 'Location', 'northwest');
grid on;
hold off;