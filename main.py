import math
import T_Display

# ============================================================
# Configuração pedida no enunciado
# ============================================================
N_POINTS = 240

# Escalas da função do tempo
VOLT_SCALES = [1.0, 2.0, 5.0, 10.0]      # V/div
TIME_SCALES_MS = [5, 10, 20, 50]         # ms/div

DEFAULT_VOLT_INDEX = 2   # 5 V/div
DEFAULT_TIME_INDEX = 1   # 10 ms/div

# Conversão ADC -> tensão
ADC_GAIN = 0.00044028
ADC_OFFSET = 0.091455
REFERENCE_INPUT = 1.0
DIVIDER_FACTOR = 1.0 / 29.3

# Display
DISPLAY_W = 240
DISPLAY_H = 135
TOP_BAR_H = 16
GRID_X = 0
GRID_Y = 0
GRID_W = 240
GRID_H = 135 - 16
GRID_NX = 10
GRID_NY = 6

# Email - altera para o teu
EMAIL_ADDRESS = "antoniopedroalves@tecnico.ulisboa.pt"


class UOscilloscope:
    def __init__(self):
        self.tft = T_Display.TFT()

        self.volt_scale_index = DEFAULT_VOLT_INDEX
        self.time_scale_index = DEFAULT_TIME_INDEX

        self.last_adc = [0] * N_POINTS
        self.last_volt = [0.0] * N_POINTS
        self.last_vmax = 0.0
        self.last_vmin = 0.0
        self.last_vav = 0.0
        self.last_vrms = 0.0
        self.last_spectrum = [0.0] * N_POINTS

        self.show_time()

    # ========================================================
    # Escalas atuais
    # ========================================================
    def current_vdiv(self):
        return VOLT_SCALES[self.volt_scale_index]

    def current_tdiv_ms(self):
        return TIME_SCALES_MS[self.time_scale_index]

    def current_total_time_ms(self):
        return 10 * self.current_tdiv_ms()

    def current_fft_vdiv(self):
        # Enunciado: escala vertical da FFT é o dobro da do tempo
        return self.current_vdiv() / 2.0

    def current_fft_hdiv_hz(self):
        # Nyquist / 10 divisões
        total_time_s = self.current_total_time_ms() / 1000.0
        fs = N_POINTS / total_time_s
        nyquist = fs / 2.0
        return nyquist / 10.0

    # ========================================================
    # Aquisição e cálculo
    # ========================================================
    def adc_to_voltage(self, adc_value):
        v = ADC_GAIN * adc_value + ADC_OFFSET
        v = v - REFERENCE_INPUT
        v = v / DIVIDER_FACTOR
        return v

    def acquire(self):
        total_ms = self.current_total_time_ms()
        points_adc = self.tft.read_adc(N_POINTS, total_ms)

        points_volt = [0.0] * N_POINTS
        vmax = vmin = None
        vsum = 0.0
        sqsum = 0.0

        for n in range(N_POINTS):
            v = self.adc_to_voltage(points_adc[n])
            points_volt[n] = v

            if vmax is None:
                vmax = v
                vmin = v
            else:
                if v > vmax:
                    vmax = v
                if v < vmin:
                    vmin = v

            vsum += v
            sqsum += v * v

        vav = vsum / N_POINTS
        vrms = math.sqrt(sqsum / N_POINTS)

        self.last_adc = points_adc
        self.last_volt = points_volt
        self.last_vmax = vmax
        self.last_vmin = vmin
        self.last_vav = vav
        self.last_vrms = vrms

    def compute_dft_spectrum(self):
        # DFT manual, como pedido no enunciado
        spectrum_half = [0.0] * (N_POINTS // 2 + 1)

        for k in range(N_POINTS // 2 + 1):
            real_part = 0.0
            imag_part = 0.0

            for n in range(N_POINTS):
                angle = 2.0 * math.pi * k * n / N_POINTS
                real_part += self.last_volt[n] * math.cos(angle)
                imag_part -= self.last_volt[n] * math.sin(angle)

            magnitude = math.sqrt(real_part * real_part + imag_part * imag_part)

            if k == 0 or k == N_POINTS // 2:
                spectrum_half[k] = magnitude / N_POINTS
            else:
                spectrum_half[k] = 2.0 * magnitude / N_POINTS

        # Enunciado recomenda preencher os 240 píxeis com pares iguais
        # ignorando o último ponto Nyquist
        pixels = [0.0] * N_POINTS
        for k in range(N_POINTS // 2):
            pixels[2 * k] = spectrum_half[k]
            pixels[2 * k + 1] = spectrum_half[k]

        self.last_spectrum = pixels

    # ========================================================
    # Desenho do display
    # ========================================================
    def clear_all(self):
        self.tft.display_set(self.tft.BLACK, 0, 0, DISPLAY_W, DISPLAY_H)

    def draw_top_bar(self, mode_name):
        self.tft.display_set(self.tft.BLACK, 0, DISPLAY_H - TOP_BAR_H, DISPLAY_W, TOP_BAR_H)

        if mode_name == "TIME":
            text = "%.0fV/div  %dms/div" % (self.current_vdiv(), self.current_tdiv_ms())
        else:
            text = "%.1fV/div  %.0fHz/div" % (self.current_fft_vdiv(), self.current_fft_hdiv_hz())

        self.tft.display_write_str(
            self.tft.Arial16,
            text,
            2,
            DISPLAY_H - 14,
            self.tft.WHITE,
            self.tft.BLACK
        )

        self.tft.set_wifi_icon(DISPLAY_W - 16, DISPLAY_H - 16)

    def draw_time_grid(self):
        self.tft.display_write_grid(
            GRID_X, GRID_Y, GRID_W, GRID_H,
            GRID_NX, GRID_NY, True,
            self.tft.GREY1, self.tft.GREY2
        )

    def draw_fft_grid(self):
        self.tft.display_write_grid(
            GRID_X, GRID_Y, GRID_W, GRID_H,
            GRID_NX, GRID_NY, False,
            self.tft.GREY1, self.tft.GREY2
        )

    def draw_time_waveform(self):
        x = []
        y = []

        vdiv = self.current_vdiv()
        volts_top = 3.0 * vdiv
        volts_bottom = -3.0 * vdiv

        for n in range(N_POINTS):
            xp = n
            v = self.last_volt[n]

            if v > volts_top:
                v = volts_top
            if v < volts_bottom:
                v = volts_bottom

            # 6 divisões verticais => de +3 div a -3 div
            yp = round((GRID_H - 1) * (volts_top - v) / (volts_top - volts_bottom))

            if yp < 0:
                yp = 0
            if yp > GRID_H - 1:
                yp = GRID_H - 1

            x.append(xp)
            y.append(yp)

        self.tft.display_nline(self.tft.YELLOW, x, y)

    def draw_fft_waveform(self):
        x = []
        y = []

        vdiv = self.current_fft_vdiv()
        volts_top = 6.0 * vdiv
        # Defensive guard: vdiv should always be positive due to VOLT_SCALES,
        # so volts_top should never be <= 0. This is just a safeguard.
        if volts_top <= 0:
            volts_top = 1.0
        if volts_top <= 0:
            volts_top = 1.0

        graph_top = GRID_Y
        graph_bottom = GRID_Y + GRID_H - 1

        for n in range(N_POINTS):
            xp = n
            v = self.last_spectrum[n]

            if v < 0:
                v = 0.0
            if v > volts_top:
                v = volts_top

            # 0 -> fundo
            # volts_top -> topo
            yp = round(graph_top + (v / volts_top) * (GRID_H - 1))

            if yp < graph_top:
                yp = graph_top
            if yp > graph_bottom:
                yp = graph_bottom

            x.append(xp)
            y.append(yp)

        self.tft.display_nline(self.tft.CYAN, x, y)

    def show_time(self):
        self.acquire()
        self.clear_all()
        self.draw_time_grid()
        self.draw_time_waveform()
        self.draw_top_bar("TIME")

    def show_fft(self):
        self.compute_dft_spectrum()
        self.clear_all()
        self.draw_fft_grid()
        self.draw_fft_waveform()
        self.draw_top_bar("FFT")

    # ========================================================
    # Botões
    # ========================================================
    def cycle_vertical_scale(self):
        self.volt_scale_index = (self.volt_scale_index + 1) % len(VOLT_SCALES)

    def cycle_horizontal_scale(self):
        self.time_scale_index = (self.time_scale_index + 1) % len(TIME_SCALES_MS)

    def send_last_measurement_email(self):
        delta_t = (self.current_total_time_ms() / 1000.0) / N_POINTS
        body = (
            "uOscilloscope\n"
            "Vmax = %.2f V\n"
            "Vmin = %.2f V\n"
            "Vav  = %.2f V\n"
            "Vrms = %.2f V\n"
            "Escala vertical = %.0f V/div\n"
            "Escala horizontal = %d ms/div\n"
        ) % (
            self.last_vmax,
            self.last_vmin,
            self.last_vav,
            self.last_vrms,
            self.current_vdiv(),
            self.current_tdiv_ms()
        )

        self.tft.send_mail(delta_t, self.last_volt, body, EMAIL_ADDRESS)

    def run(self):
        while self.tft.working():
            but = self.tft.readButton()

            if but != self.tft.NOTHING:
                print("Button pressed:", but)

                if but == self.tft.BUTTON1_SHORT:
                    # 11 - nova leitura e representação no tempo
                    self.show_time()

                elif but == self.tft.BUTTON1_LONG:
                    # 12 - enviar mail com última leitura
                    self.send_last_measurement_email()

                elif but == self.tft.BUTTON2_SHORT:
                    # 21 - mudar escala vertical circularmente
                    self.cycle_vertical_scale()
                    self.show_time()

                elif but == self.tft.BUTTON2_LONG:
                    # 22 - mudar escala horizontal circularmente
                    self.cycle_horizontal_scale()
                    self.show_time()

                elif but == self.tft.BUTTON2_DCLICK:
                    # 23 - calcular DFT da última leitura e mostrar espetro
                    self.show_fft()


def main():
    app = UOscilloscope()
    app.run()


if __name__ == "__main__":
    main()