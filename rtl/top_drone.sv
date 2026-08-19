/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_drone#(
    parameter MAX_TICK = 7'd99 // Changed from 14'd9999 to 7'd99 for 1us tick
) (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        //---PWM---
        output logic [3:0] motor_pwm_out,
        input logic spi_start,
     (*KEEP = "true"*)        output logic sclk,
     (*KEEP = "true"*)        input logic poci,
     (*KEEP = "true"*)        output logic cs_n,
     (*KEEP = "true"*)        output logic copi,
        //---SPI---
        output logic [3:0] an,
        output logic [7:0] sseg,
        output [15:0] led,
        input logic button,
        input logic btnD_pulse,
        input logic btnL_pulse,
        input logic btnR_pulse,
        input logic btnReset,
        input logic [15:0] sw
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    (* DONT_TOUCH = "true" *) logic [15:0] led_reg;

    // --- Sygnały dla PID i miksera silników ---
    // Wzmocnienia PID
    logic signed [15:0] Kp_roll, Ki_roll, Kd_roll;

    // Wyjścia z PID
    logic signed [15:0] pid_roll_out;
    logic signed [15:0] pid_pitch_out = '0; // Na razie bez implementacji
    logic signed [15:0] pid_yaw_out = '0;   // Na razie bez implementacji

    // Sygnały do debugowania PID
    logic signed [15:0] pid_error_roll;
    logic signed [31:0] pid_integral_roll;
    logic signed [15:0] pid_derivative_roll;

    // Sygnały dla miksera
    logic [1:0]  drone_mode;
    logic [15:0] throttle;
    logic        test_mode_active;
    logic [15:0] final_throttle;
    logic signed [15:0] final_pid_roll_out;
    logic [14:0] m1_width, m2_width, m3_width, m4_width;
    logic [14:0] m_width[4];

    /**
     * Signals assignments
     */

    /**
     * Submodules instances
     */

     //logic [6:0] destination = 7'h0F;
     //logic [7:0] data_write;
     //logic [31:0] nadajwartosc = {1'b0,destination,data_write,16'b0};
      (*KEEP = "true"*)
     logic [103:0] odczytwartosc;          // = {1'b1,destination,16'b0};
     wire spi_done;
    // wire spi_loopback;
     (*KEEP = "true"*)
    logic [103:0] spi_odebrane; //max potrzebuje zmiescic 6x2x8bit = 96b +8bit padding z komendy kontrolera
    logic [6:0] data_length;
    logic signed [15:0] roll_raw;
    logic signed [15:0] roll_deg;
    logic signed [15:0] converted_Y;
    logic signed [15:0] angel; //👼
    (* KEEP = "true" *) logic [1:0] gyro_state;

    logic signed [39:0] rollq24;
    logic signed [39:0] gyroYq24;

    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); 
    gyro #( )
     gyro (
        .clk(clk),
        .rst_n(~btnReset),
        .d_length(data_length),
        .d_out(odczytwartosc),
        .ready( (spi_done && sw[15]) | spi_start),
        .gyro_data( (&spi_odebrane[1:0]) ),
        .state_curr(gyro_state)
    );

     spi_controller #( )
      spi_controller(
         .clk(clk),
         .rst_n(~btnReset),
         .d_length(data_length),
         .sclk(sclk),
         .cs_n(cs_n),
         .reg_rx(spi_odebrane),
         .reg_tx(odczytwartosc),
         .poci(poci),
         .copi(copi),
         .busy(),
         .done(spi_done)
      );

      convert_gyro #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_odebrane[79:64]),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(converted_Y),
          .mul_result(gyroYq24)
      );

      convert_accel #(.WIDTH(16) )
       accel_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_raw_data(spi_odebrane[31:16]),
        .data_latch(gyro_read_done),
        .angle_deg(roll_deg),
        .angle_raw(),
        .latched_raw(roll_raw),
        .mul_result(rollq24)
      );

  
    logic signed [15:0] estim_roll;
    angle_estimator #() estimator_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_data(rollq24),
        .gyro_data(gyroYq24),
        .angle_deg(estim_roll)
    );

    // --- Logika trybu testowego silników ---
    // Aktywowany przez menu debugowania (sw[14:12] = 111)
    assign test_mode_active = (sw[14:12] == 3'b111);

    always_comb begin
        // Domyślnie używaj normalnych wartości z PID i przełączników
        final_throttle = throttle;
        final_pid_roll_out = pid_roll_out;

        // Jeśli tryb testowy jest aktywny, nadpisz wartości
        if (test_mode_active) begin
            final_throttle = 16'd1550; // Środek nowego zakresu testowego (1100us, 2000us)
            // Sprawdź przechył i ustaw sztywną korekcję
            if (estim_roll > 16'sd128) begin // Przechył w prawo (> 1 stopień, format Q8.7)
                final_pid_roll_out = -16'sd450; // Generuje korekcję, która w mikserze da 1100us i 2000us
            end else if (estim_roll < -16'sd128) begin // Przechył w lewo (< -1 stopień)
                final_pid_roll_out = 16'sd450;  // Generuje korekcję, która w mikserze da 2000us i 1100us
            end else begin // Wyrównany
                final_pid_roll_out = 16'sd0; // Brak korekcji
            end
        end
    end

    // --- Logika wyboru wzmocnień PID za pomocą przełączników ---
    // Kp, Ki, Kd są w formacie Q4.12
    always_comb begin
        // Wybór Kp (0, 1, 2, 3) za pomocą sw[11:10]
        // Wybór Kp (1.0 do 2.0) za pomocą sw[11:10]
        case (sw[11:10])
            2'b00: Kp_roll = 16'sd0;      // P = 0
            2'b01: Kp_roll = 16'sd4096;   // P = 1.0   (1 * 2^12)
            2'b10: Kp_roll = 16'sd8192;   // P = 2.0   (2 * 2^12)
            2'b11: Kp_roll = 16'sd12288;  // P = 3.0   (3 * 2^12)
            2'b00: Kp_roll = 16'sd4096;   // P = 1.0
            2'b01: Kp_roll = 16'sd5325;   // P = ~1.3
            2'b10: Kp_roll = 16'sd6963;   // P = ~1.7
            2'b11: Kp_roll = 16'sd8192;   // P = 2.0
            default: Kp_roll = 16'sd0;
        endcase

        // Wybór Ki (0.001 do 0.01) za pomocą sw[9:8]
        // Wybór Ki (0.0 do ~0.001) za pomocą sw[9:8]
        case (sw[9:8])
            2'b00: Ki_roll = 16'sd4;      // I = ~0.001 (4 / 2^12)
            2'b01: Ki_roll = 16'sd12;     // I = ~0.003 (12 / 2^12)
            2'b10: Ki_roll = 16'sd29;     // I = ~0.007 (29 / 2^12)
            2'b11: Ki_roll = 16'sd41;     // I = ~0.01  (41 / 2^12)
            2'b00: Ki_roll = 16'sd0;      // I = 0.0
            2'b01: Ki_roll = 16'sd1;      // I = ~0.00025
            2'b10: Ki_roll = 16'sd2;      // I = ~0.0005
            2'b11: Ki_roll = 16'sd4;      // I = ~0.001
            default: Ki_roll = 16'sd0;
        endcase

        // Wybór Kd (0.05 do 0.2) za pomocą sw[7:6]
        // Wybór Kd (0.05 do 0.5) za pomocą sw[7:6]
        case (sw[7:6])
            2'b00: Kd_roll = 16'sd205;    // D = ~0.05 (205 / 2^12)
            2'b01: Kd_roll = 16'sd410;    // D = ~0.1  (410 / 2^12)
            2'b10: Kd_roll = 16'sd614;    // D = ~0.15 (614 / 2^12)
            2'b11: Kd_roll = 16'sd819;    // D = ~0.2  (819 / 2^12)
            2'b00: Kd_roll = 16'sd205;    // D = ~0.05
            2'b01: Kd_roll = 16'sd614;    // D = ~0.15
            2'b10: Kd_roll = 16'sd1229;   // D = ~0.3
            2'b11: Kd_roll = 16'sd2048;   // D = 0.5
            default: Kd_roll = 16'sd0;
        endcase
    end

    // --- Instancja PID dla osi roll ---
    PID #(.WIDTH(16)) pid_roll_inst (
        .clk(clk),
        .rst_n(~btnReset),
        .enable(gyro_read_done), // Obliczenia co nową próbkę z IMU
        .estim_roll(estim_roll),
        .Kp(Kp_roll),
        .Ki(Ki_roll),
        .Kd(Kd_roll),
        .pid_output(pid_roll_out),
        .pid_error_out(pid_error_roll),
        .pid_integral_out(pid_integral_roll),
        .pid_derivative_out(pid_derivative_roll)
    );

    // --- Tryb drona i przepustnica ---
    // sw[0] (enable) - główne zezwolenie, sw[15] - uzbrojenie
    assign drone_mode = ~enable ? 2'b00 : (sw[15] ? 2'b10 : 2'b01); // 00:INIT, 01:ARMED, 10:RUN
    // Przepustnica z sw[5:0], skalowana do 1000-2016us
    assign throttle = 16'(1000 + ({10'b0, sw[5:0]} << 4));

    // --- Mikser silników ---
    motor_mixer motor_mixer_inst (
        .clk(clk), .rst_n(~btnReset), .mode(drone_mode), .throttle(final_throttle),
        .pid_pitch(pid_pitch_out), .pid_roll(final_pid_roll_out), .pid_yaw(pid_yaw_out),
        .m1_width(m1_width), .m2_width(m2_width), .m3_width(m3_width), .m4_width(m4_width)
    );

    assign m_width[0] = m1_width;
    assign m_width[1] = m2_width;
    assign m_width[2] = m3_width;
    assign m_width[3] = m4_width;

    // Instantiate 4 PWM modules
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pwm_inst
            pwm #( .MAX_TICK(MAX_TICK) ) u_pwm (
                .clk(clk),
                .enable(enable),
                .d_in(m_width[i]),
                .pwm(motor_pwm_out[i])
            );
        end
    endgenerate

// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [2:0] page_cnt;       // Do przewijania 104-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

// *******D E B U G**************D E B U G**************D E B U G*******
// sw[14:12] wybór wartości do wyświetlenia:
// 000: Wyjście PID roll (korekcja)
// 001: Kp_roll (część całkowita)
// 010: Kąt roll (estim_roll)
// 011: Błąd PID (pid_error_roll)
// 100: Całka PID (dolne 16 bitów)
// 101: Całka PID (górne 16 bitów)
// 110: Różniczka PID (pid_derivative_roll)
// 111: TRYB TESTOWY - szerokość impulsu dla silnika M1
//
// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : odczytwartosc - nadawanawartosc
// 010 : spi_odebrane - odebrane dane
// 011 : convertedY - 
// 100 : status: converted_Y_H , 00000, led2 - spi_odebrane[1], led1 - ?converted_Y led0 - ?6c
// 101 : angel - Y angle deegrees per second
// 110 : estimated_angle_roll
// 111 : roll_deg
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led_reg <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 3'b0;
        flag_6c_detect <= 1'b0;
    end 
    else begin
        case(sw[14:12])
            3'b000: disp_hex <= pid_roll_out;
            3'b001: disp_hex <= Kp_roll[15:12]; // Wyświetl tylko część całkowitą
            3'b010: disp_hex <= estim_roll;
            3'b011: disp_hex <= pid_error_roll;
            3'b100: disp_hex <= pid_integral_roll[15:0];
            3'b101: disp_hex <= pid_integral_roll[31:16];
            3'b110: disp_hex <= pid_derivative_roll;
            3'b111: disp_hex <= m1_width; // W trybie testowym, pokaż szerokość impulsu M1
            default: disp_hex <= 16'hDEAD;
        endcase
        led_reg <= disp_hex;
    end
end
    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(~btnReset),
        .hex3(disp_hex[15:12]), 
        .hex2(disp_hex[11:8]), 
        .hex1(disp_hex[7:4]), 
        .hex0(disp_hex[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );

    assign led = led_reg;

endmodule
