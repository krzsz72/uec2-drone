# System stabilizacji drona

Projekt FPGA realizujący stabilizację drona na bazie IMU, regulatora PID oraz układu PWM. Głównym celem jest utrzymywanie zadanego kąta roll/pitch przy pomocy czterech silników i danych z żyroskopu oraz akcelerometru.

## Co jest w projekcie

- odczyt danych IMU przez SPI,
- estymacja kąta z filtracją komplementarną,
- regulator PID dla osi roll, pitch i yaw,
- mieszanie sygnałów do czterech silników,
- generacja PWM,
- debug z wykorzystaniem przełączników i wyświetlacza 7-segmentowego.

## Najważniejsze moduły

- `rtl/top_drone.sv` – top-level projektu,
- `rtl/gyro.sv` – odczyt danych z IMU,
- `rtl/spi_controller.sv` – magistrala SPI,
- `rtl/convert_gyro.sv` i `rtl/convert_accel.sv` – konwersja danych do formatu Q,
- `rtl/angle_estimator.sv` – estymacja kąta,
- `rtl/PID.sv` – regulator PID,
- `rtl/motor_mixer.sv` – rozdzielenie mocy na silniki,
- `rtl/pwm.v` – generator PWM,
- `fpga/rtl/top_drone_basys3.sv` – warstwa pod płytę Basys 3.

## Uruchomienie

W katalogu głównym:

```bash
. env.sh
```

Dostępne podstawowe skrypty:

```bash
./tools/run_simulation.sh -l
./tools/generate_bitstream.sh
./tools/program_fpga.sh
```

---

## Konfiguracja na płytce

### Przełączniki i przyciski

- `sw[0]` – główne włączenie układu (`enable`)
- `sw[15]` – uzbrojenie / aktywacja pracy regulatora
- `sw[5:0]` – ustawienie throttle
- `btnU` – start odczytu IMU
- `btnC` – reset

### Debug z przełączników

`sw[14:12]` wybiera co jest wyświetlane na 7-segmentach:

| `sw[14:12]` | Wartość |
|---|---|
| `000` | kąt Roll |
| `001` | kąt Pitch |
| `010` | korekcja PID Roll |
| `011` | korekcja PID Pitch |
| `100` | korekcja PID Yaw |
| `101` | błąd PID Roll |
| `110` | całka PID Roll |
| `111` | tryb testowy silnika |

To pozwala bardzo szybko sprawdzić, czy układ mierzy poprawnie kąty, czy PID działa, i czy silniki reagują zgodnie z oczekiwaniem.

---

## Kalibracja PID

Wzmocnienia są ustawiane przełącznikami:

- `Kp_roll` – `sw[11:10]`
- `Ki_roll` – `sw[9:8]`
- `Kd_roll` – `sw[7:6]`

Przykładowe ustawienia:

- `Kp_roll`: `00 -> 1.0`, `01 -> 1.3`, `10 -> 1.7`, `11 -> 2.0`
- `Ki_roll`: `00 -> 0.0`, `01 -> 0.00025`, `10 -> 0.0005`, `11 -> 0.001`
- `Kd_roll`: `00 -> 0.05`, `01 -> 0.15`, `10 -> 0.30`, `11 -> 0.50`

Dla pitch i yaw wartości są stałe i służą do podstawowej stabilizacji oraz delikatnej korekty obrotu.

---

## Podgląd danych IMU

Dane z żyroskopu i akcelerometru są odczytywane przez SPI i przechowywane w rejestrach odczytu.

Najważniejsze sygnały:

- `gyro_state` – stan maszyny stanów odczytu IMU,
- `spi_done` – zakończenie transferu,
- `gyro_read_done` – sygnał gotowości kolejnej próbki,
- `spi_odebrane` – zdekodowane dane z czujnika.

Mapowanie osi w układzie:

- `GYRO_X` → `spi_odebrane[15:0]`
- `GYRO_Y` → `spi_odebrane[31:16]`
- `GYRO_Z` → `spi_odebrane[47:32]`
- `ACCEL_X` → `spi_odebrane[63:48]`
- `ACCEL_Y` → `spi_odebrane[79:64]`

Takie podejście daje szybki podgląd tego, co naprawdę przychodzi z IMU i pozwala wykryć błędy mapowania osi, SPI lub konwersji danych.

---

## Jak to działa

1. IMU dostarcza dane z żyroskopu i akcelerometru.
2. Dane są konwertowane i łączone w estymatorze kąta.
3. PID porównuje aktualny kąt z zerem i generuje korekcję.
4. Korekcja przechodzi przez mikser silników.
5. Każdy silnik dostaje własny sygnał PWM.

---

## Struktura katalogów

```text
.
├── README.md
├── env.sh
├── fpga/
│   ├── constraints/
│   ├── rtl/
│   └── scripts/
├── results/
├── rtl/
│   ├── PID.sv
│   ├── angle_estimator.sv
│   ├── convert_accel.sv
│   ├── convert_gyro.sv
│   ├── gyro.sv
│   ├── motor_mixer.sv
│   ├── pwm.v
│   ├── spi_controller.sv
│   ├── top_drone.sv
│   └── uart_*.sv
├── sim/
├── tools/
│   ├── run_simulation.sh
│   ├── generate_bitstream.sh
│   ├── program_fpga.sh
│   └── clean.sh
└── vivado*.jou
```

---

## Szybki start

```bash
. env.sh
./tools/generate_bitstream.sh
./tools/program_fpga.sh
```

Po wgraniu:

- `sw[0]` – aktywacja,
- `sw[15]` – tryb pracy / uzbrojenie,
- `sw[14:12]` – wybór debugowania,
- `sw[11:10]`, `sw[9:8]`, `sw[7:6]` – kalibracja PID,
- `sw[5:0]` – poziom gazu,
- `btnU` – odczyt IMU,
- `btnC` – reset.

To jest najważniejsza mapa funkcjonalna projektu: pomiar IMU, stabilizacja, debug i kalibracja.
