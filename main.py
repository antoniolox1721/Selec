import math
import os
import sys
import time

import T_Display

if sys.implementation.name == "micropython":
    import ujson as json
else:
    import json

# ============================================================
# Configuração do osciloscópio
# ============================================================
SAMPLE_COUNT = 240
DEFAULT_VOLTS_PER_DIV = 5.0
DEFAULT_MS_PER_DIV = 10
VOLT_SCALES = [0.5, 1.0, 2.0, 5.0, 10.0]
TIME_SCALES_MS = [5, 10, 20, 50]

ADC_GAIN = 0.000440282
ADC_OFFSET = 0.091455441
REFERENCE_VOLTAGE = 1.0
ATTENUATION_FACTOR = 1.0 / 29.3

DISPLAY_WIDTH = 240
DISPLAY_HEIGHT = 135
TOP_GRAPH_HEIGHT = 72
BOTTOM_GRAPH_Y = 72
BOTTOM_GRAPH_HEIGHT = DISPLAY_HEIGHT - BOTTOM_GRAPH_Y
H_DIVS = 10
V_DIVS = 8

OUTPUT_ROOT = "output"
CAPTURE_DIR = OUTPUT_ROOT + "/captures"
SPECTRA_DIR = OUTPUT_ROOT + "/spectra"
LOG_DIR = OUTPUT_ROOT + "/logs"

BUTTON_NOTHING = 0


class OscilloscopeApp:
    def __init__(self):
        self.tft = T_Display.TFT()
        self.font = self.tft.Arial16
        self.volt_scale_index = self._find_scale_index(VOLT_SCALES, DEFAULT_VOLTS_PER_DIV)
        self.time_scale_index = self._find_scale_index(TIME_SCALES_MS, DEFAULT_MS_PER_DIV)
        self.capture_counter = 0
        self.latest_metadata = None
        self._ensure_output_tree()

    def _find_scale_index(self, options, value):
        for index, option in enumerate(options):
            if option == value:
                return index
        return 0

    def _ensure_output_tree(self):
        for path in (OUTPUT_ROOT, CAPTURE_DIR, SPECTRA_DIR, LOG_DIR):
            self._ensure_dir(path)

    def _ensure_dir(self, path):
        partial = ""
        for part in path.split("/"):
            if not part:
                continue
            partial = part if not partial else partial + "/" + part
            try:
                os.mkdir(partial)
            except OSError:
                pass

    def current_volts_per_div(self):
        return VOLT_SCALES[self.volt_scale_index]

    def current_ms_per_div(self):
        return TIME_SCALES_MS[self.time_scale_index]

    def acquisition_time_ms(self):
        return H_DIVS * self.current_ms_per_div()

    def adc_to_voltage(self, adc_value):
        probe_voltage = ADC_GAIN * adc_value + ADC_OFFSET
        return (probe_voltage - REFERENCE_VOLTAGE) / ATTENUATION_FACTOR

    def acquire_samples(self):
        total_ms = self.acquisition_time_ms()
        raw_samples = self.tft.read_adc(SAMPLE_COUNT, total_ms)
        voltages = [0.0] * SAMPLE_COUNT
        for index in range(SAMPLE_COUNT):
            voltages[index] = self.adc_to_voltage(raw_samples[index])
        return raw_samples, voltages

    def compute_statistics(self, voltages):
        v_max = voltages[0]
        v_min = voltages[0]
        v_sum = 0.0
        square_sum = 0.0
        for value in voltages:
            if value > v_max:
                v_max = value
            if value < v_min:
                v_min = value
            v_sum += value
            square_sum += value * value
        count = len(voltages)
        v_avg = v_sum / count
        v_rms = math.sqrt(square_sum / count)
        return {
            "vmax": v_max,
            "vmin": v_min,
            "vavg": v_avg,
            "vrms": v_rms,
        }

    def compute_dft(self, voltages, total_time_ms):
        sample_count = len(voltages)
        total_time_s = total_time_ms / 1000.0
        sample_rate = sample_count / total_time_s
        half_count = sample_count // 2
        spectrum = []
        for k in range(half_count):
            real_part = 0.0
            imag_part = 0.0
            for n in range(sample_count):
                angle = (2.0 * math.pi * k * n) / sample_count
                real_part += voltages[n] * math.cos(angle)
                imag_part -= voltages[n] * math.sin(angle)
            magnitude = math.sqrt(real_part * real_part + imag_part * imag_part) / sample_count
            if k != 0:
                magnitude *= 2.0
            spectrum.append({
                "bin": k,
                "frequency_hz": (k * sample_rate) / sample_count,
                "magnitude": magnitude,
            })
        return spectrum, sample_rate

    def _timestamp(self):
        now = time.localtime()
        year = now[0]
        month = now[1]
        day = now[2]
        hour = now[3]
        minute = now[4]
        second = now[5]
        milliseconds = self._millisecond_fragment()
        return "%04d%02d%02d_%02d%02d%02d_%03d" % (
            year,
            month,
            day,
            hour,
            minute,
            second,
            milliseconds,
        )

    def _millisecond_fragment(self):
        if hasattr(time, "ticks_ms"):
            return time.ticks_ms() % 1000
        return int((time.time() * 1000.0) % 1000)

    def save_outputs(self, raw_samples, voltages, spectrum, statistics):
        timestamp = self._timestamp()
        capture_filename = CAPTURE_DIR + "/capture_" + timestamp + ".csv"
        spectrum_filename = SPECTRA_DIR + "/spectrum_" + timestamp + ".csv"
        metadata_filename = LOG_DIR + "/session_" + timestamp + ".json"

        dt_s = (self.acquisition_time_ms() / 1000.0) / SAMPLE_COUNT
        with open(capture_filename, "w") as capture_file:
            capture_file.write("index,time_s,adc,voltage_v\n")
            for index in range(SAMPLE_COUNT):
                capture_file.write(
                    "%d,%.9f,%d,%.9f\n" % (
                        index,
                        index * dt_s,
                        raw_samples[index],
                        voltages[index],
                    )
                )

        with open(spectrum_filename, "w") as spectrum_file:
            spectrum_file.write("bin,frequency_hz,magnitude_v\n")
            for entry in spectrum:
                spectrum_file.write(
                    "%d,%.9f,%.9f\n" % (
                        entry["bin"],
                        entry["frequency_hz"],
                        entry["magnitude"],
                    )
                )

        metadata = {
            "timestamp": timestamp,
            "sample_count": SAMPLE_COUNT,
            "time_per_div_ms": self.current_ms_per_div(),
            "volts_per_div": self.current_volts_per_div(),
            "acquisition_time_ms": self.acquisition_time_ms(),
            "statistics": statistics,
            "capture_csv": capture_filename,
            "spectrum_csv": spectrum_filename,
        }
        with open(metadata_filename, "w") as metadata_file:
            json.dump(metadata, metadata_file)

        self.latest_metadata = metadata
        return metadata_filename

    def draw_grid(self, y_origin, height):
        self.tft.display_write_grid(0, y_origin, DISPLAY_WIDTH, height, H_DIVS, V_DIVS, True)

    def draw_waveform(self, voltages):
        x_points = []
        y_points = []
        volts_per_div = self.current_volts_per_div()
        pixels_per_div = (TOP_GRAPH_HEIGHT - 1) / float(V_DIVS)
        y_center = (TOP_GRAPH_HEIGHT - 1) / 2.0
        for index in range(SAMPLE_COUNT):
            x_pixel = int(index * (DISPLAY_WIDTH - 1) / (SAMPLE_COUNT - 1))
            y_pixel = int(y_center - (voltages[index] / volts_per_div) * pixels_per_div)
            if y_pixel < 0:
                y_pixel = 0
            if y_pixel >= TOP_GRAPH_HEIGHT:
                y_pixel = TOP_GRAPH_HEIGHT - 1
            x_points.append(x_pixel)
            y_points.append(y_pixel)
        self.tft.display_nline(self.tft.YELLOW, x_points, y_points)

    def draw_spectrum(self, spectrum):
        x_points = []
        y_points = []
        usable_bins = len(spectrum)
        peak = 0.0
        for entry in spectrum:
            if entry["magnitude"] > peak:
                peak = entry["magnitude"]
        if peak <= 0.0:
            peak = 1.0

        graph_top = BOTTOM_GRAPH_Y
        graph_bottom = DISPLAY_HEIGHT - 1
        graph_height = BOTTOM_GRAPH_HEIGHT - 1
        for index in range(usable_bins):
            x_pixel = int(index * (DISPLAY_WIDTH - 1) / (usable_bins - 1)) if usable_bins > 1 else 0
            normalized = spectrum[index]["magnitude"] / peak
            y_pixel = int(graph_bottom - normalized * graph_height)
            if y_pixel < graph_top:
                y_pixel = graph_top
            if y_pixel > graph_bottom:
                y_pixel = graph_bottom
            x_points.append(x_pixel)
            y_points.append(y_pixel)
        self.tft.display_nline(self.tft.CYAN, x_points, y_points)

    def draw_labels(self, statistics, spectrum):
        labels = [
            "V/div %.1f" % self.current_volts_per_div(),
            "T/div %dms" % self.current_ms_per_div(),
            "Vmax %.2f" % statistics["vmax"],
            "Vmin %.2f" % statistics["vmin"],
            "Vavg %.2f" % statistics["vavg"],
            "Vrms %.2f" % statistics["vrms"],
        ]
        peak_frequency = 0.0
        peak_magnitude = 0.0
        for entry in spectrum[1:]:
            if entry["magnitude"] > peak_magnitude:
                peak_magnitude = entry["magnitude"]
                peak_frequency = entry["frequency_hz"]
        labels.append("Fp %.1fHz" % peak_frequency)

        start_y = 2
        for text in labels:
            self.tft.display_write_str(self.font, text, start_y, 2, self.tft.WHITE, self.tft.BLACK)
            start_y += 16
            if start_y > DISPLAY_WIDTH - 20:
                break

    def render(self, voltages, statistics, spectrum):
        self.tft.display_set(self.tft.BLACK, 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT)
        self.draw_grid(0, TOP_GRAPH_HEIGHT)
        self.draw_grid(BOTTOM_GRAPH_Y, BOTTOM_GRAPH_HEIGHT)
        self.draw_waveform(voltages)
        self.draw_spectrum(spectrum)
        self.draw_labels(statistics, spectrum)
        self.tft.set_wifi_icon(DISPLAY_WIDTH - 16, DISPLAY_HEIGHT - 16)

    def acquire_process_display_and_save(self):
        raw_samples, voltages = self.acquire_samples()
        statistics = self.compute_statistics(voltages)
        spectrum, _sample_rate = self.compute_dft(voltages, self.acquisition_time_ms())
        metadata_path = self.save_outputs(raw_samples, voltages, spectrum, statistics)
        self.render(voltages, statistics, spectrum)
        self.capture_counter += 1
        print("Aquisição %d guardada em %s" % (self.capture_counter, metadata_path))

    def cycle_vertical_scale(self):
        self.volt_scale_index = (self.volt_scale_index + 1) % len(VOLT_SCALES)
        print("Nova escala vertical: %.1f V/div" % self.current_volts_per_div())

    def cycle_horizontal_scale(self):
        self.time_scale_index = (self.time_scale_index + 1) % len(TIME_SCALES_MS)
        print("Nova escala horizontal: %d ms/div" % self.current_ms_per_div())

    def show_startup_message(self):
        self.tft.display_set(self.tft.BLACK, 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT)
        self.tft.display_write_str(self.font, "Osciloscopio", 4, 4, self.tft.GREEN, self.tft.BLACK)
        self.tft.display_write_str(self.font, "B1 curto: adquirir", 24, 4, self.tft.WHITE, self.tft.BLACK)
        self.tft.display_write_str(self.font, "B1 longo: V/div", 44, 4, self.tft.WHITE, self.tft.BLACK)
        self.tft.display_write_str(self.font, "B2 longo: T/div", 64, 4, self.tft.WHITE, self.tft.BLACK)
        self.tft.display_write_str(self.font, "CSV + JSON local", 84, 4, self.tft.CYAN, self.tft.BLACK)
        self.tft.set_wifi_icon(DISPLAY_WIDTH - 16, DISPLAY_HEIGHT - 16)

    def run(self):
        self.show_startup_message()
        self.acquire_process_display_and_save()
        while self.tft.working():
            button = self.tft.readButton()
            if button == BUTTON_NOTHING:
                continue
            if button == self.tft.BUTTON1_SHORT or button == self.tft.BUTTON2_SHORT:
                self.acquire_process_display_and_save()
            elif button == self.tft.BUTTON1_LONG:
                self.cycle_vertical_scale()
                self.acquire_process_display_and_save()
            elif button == self.tft.BUTTON2_LONG:
                self.cycle_horizontal_scale()
                self.acquire_process_display_and_save()
            elif button == self.tft.BUTTON1_DCLICK:
                self.cycle_vertical_scale()
                self.acquire_process_display_and_save()
            elif button == self.tft.BUTTON2_DCLICK:
                self.cycle_horizontal_scale()
                self.acquire_process_display_and_save()


def main():
    app = OscilloscopeApp()
    app.run()


if __name__ == "__main__":
    main()
