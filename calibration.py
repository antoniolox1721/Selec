import T_Display

# ============================================================
# Script de calibração do ADC
# Enunciado:
#  - tensões DC: -10V, -5V, 0V, +5V, +10V
#  - média de 100 aquisições x 100 pontos = 10000 amostras
# ============================================================

CAL_POINTS_V = [-10.0, -5.0, 0.0, 5.0, 10.0]

N_ACQ = 100
PTS_PER_ACQ = 100
ACQ_TIME_MS = 50

DISPLAY_W = 240
DISPLAY_H = 135
TOP_BAR_H = 16


class CalibrationApp:
    def __init__(self):
        self.tft = T_Display.TFT()

        # Índice do ponto de calibração atual
        self.selected_index = 0

        # Resultados guardados para cada ponto
        self.results_adc = [None] * len(CAL_POINTS_V)

        self.draw_screen()

    # ========================================================
    # Aquisição
    # ========================================================
    def average_adc(self):
        total = 0
        count = 0

        for _ in range(N_ACQ):
            points = self.tft.read_adc(PTS_PER_ACQ, ACQ_TIME_MS)
            for adc in points:
                total += adc
                count += 1

        if count == 0:
            return 0.0

        return total / count

    def measure_selected_point(self):
        self.draw_top_bar("A medir")
        adc_avg = self.average_adc()
        self.results_adc[self.selected_index] = adc_avg
        self.draw_screen("Medido")

    # ========================================================
    # Navegação
    # ========================================================
    def next_point(self):
        self.selected_index = (self.selected_index + 1) % len(CAL_POINTS_V)
        self.draw_screen()

    def prev_point(self):
        self.selected_index = (self.selected_index - 1) % len(CAL_POINTS_V)
        self.draw_screen()

    def clear_results(self):
        self.results_adc = [None] * len(CAL_POINTS_V)
        self.draw_screen("Limpo")

    # ========================================================
    # Texto auxiliar
    # ========================================================
    def current_voltage_text(self):
        vin = CAL_POINTS_V[self.selected_index]
        return "%+d V" % int(vin)

    def current_adc_text(self):
        value = self.results_adc[self.selected_index]
        if value is None:
            return "-----"
        return "%.1f" % value

    # ========================================================
    # Desenho
    # ========================================================
    def clear_all(self):
        self.tft.display_set(self.tft.BLACK, 0, 0, DISPLAY_W, DISPLAY_H)

    def draw_top_bar(self, msg="Pronto"):
        self.tft.display_set(
            self.tft.BLACK,
            0, DISPLAY_H - TOP_BAR_H,
            DISPLAY_W, TOP_BAR_H
        )

        text = "CAL  %s" % msg
        self.tft.display_write_str(
            self.tft.Arial16,
            text,
            2,
            DISPLAY_H - 14,
            self.tft.WHITE,
            self.tft.BLACK
        )

        self.tft.set_wifi_icon(DISPLAY_W - 16, DISPLAY_H - 16)

    def draw_body(self):
        # Linha 1: ponto atual
        point_text = "Ponto %d/5" % (self.selected_index + 1)
        self.tft.display_write_str(
            self.tft.Arial16,
            point_text,
            6, 8,
            self.tft.CYAN,
            self.tft.BLACK
        )

        # Informação sobre o número de amostras
        self.tft.display_write_str(
            self.tft.Arial16,
            "100x100",
            150, 8,
            self.tft.GREY2,
            self.tft.BLACK
        )

        # Tensão alvo
        self.tft.display_write_str(
            self.tft.Arial16,
            "Vin alvo",
            6, 28,
            self.tft.WHITE,
            self.tft.BLACK
        )

        self.tft.display_write_str(
            self.tft.Arial16,
            self.current_voltage_text(),
            6, 48,
            self.tft.YELLOW,
            self.tft.BLACK
        )

        # Valor médio do ADC
        self.tft.display_write_str(
            self.tft.Arial16,
            "ADC medio",
            6, 68,
            self.tft.WHITE,
            self.tft.BLACK
        )

        self.tft.display_write_str(
            self.tft.Arial16,
            self.current_adc_text(),
            6, 88,
            self.tft.GREEN,
            self.tft.BLACK
        )

        # Ajuda dos botões: acima da barra inferior
        self.tft.display_write_str(
            self.tft.Arial16,
            "B1 medir",
            6, 104,
            self.tft.WHITE,
            self.tft.BLACK
        )

        self.tft.display_write_str(
            self.tft.Arial16,
            "B2 next",
            125, 104,
            self.tft.WHITE,
            self.tft.BLACK
        )

    def draw_screen(self, msg="Pronto"):
        self.clear_all()
        self.draw_body()
        self.draw_top_bar(msg)

    # ========================================================
    # Ciclo principal
    # ========================================================
    def run(self):
        while self.tft.working():
            but = self.tft.readButton()

            if but == self.tft.NOTHING:
                continue

            print("Botão:", but)

            if but == self.tft.BUTTON1_SHORT:
                # Mede o ponto atual
                self.measure_selected_point()

            elif but == self.tft.BUTTON2_SHORT:
                # Avança para o ponto seguinte
                self.next_point()

            elif but == self.tft.BUTTON2_LONG:
                # Volta ao ponto anterior
                self.prev_point()

            elif but == self.tft.BUTTON1_LONG:
                # Limpa todos os resultados guardados
                self.clear_results()


def main():
    app = CalibrationApp()
    app.run()


if __name__ == "__main__":
    main()