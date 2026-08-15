// ********************************
//
//     TESTBENCH for angle_estimator
//
//     Krzysztof Piziak
//
// ********************************
`timescale 1ns/1ps

module angle_estimator_tb;

    localparam int WIDTH = 16;

    logic clk;
    logic rst_n;

    logic data_latch;
    logic signed [WIDTH-1:0] angle_deg; //Q8.8
    logic signed [39:0] val_xl;
    logic signed [39:0] val_gyro;

    // Zmienne fizyczne dla wygody (tylko do symulacji!)
    real current_angle_deg = 0.0;
    real rotation_speed_dps = 600.0;
    real sample_rate_hz = 6660.0;
    real delta_deg_per_sample;

    // Nasze wejścia do modułu
    logic signed [39:0] gyro_delta_q24;
    logic signed [39:0] accel_angle_q24;

    // Instancja poprawionego modułu
    convert_accel #(.WIDTH(WIDTH)) accel (
        .clk(clk),
        .rst_n(rst_n),
        .accel_raw_data(accel_angle_q24),
        .data_latch(data_latch),
        .mul_result(val_xl)
    );

    convert_gyro#(.WIDTH(WIDTH)) gyro (
        .clk(clk),
        .rst_n(rst_n),
        .gyro_raw_data(gyro_delta_q24),
        .data_latch(data_latch),
        .mul_result(val_gyro)

    );

    angle_estimator#(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .accel_data(val_xl),
        .gyro_data(val_gyro),
        .angle_deg(angle_deg)

    );

    // Generator zegara systemowego (100 MHz -> okres 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        data_latch =0;
        forever #500 data_latch = ~data_latch;
    end    
    // bez symulacji SPI
    
    // =========================================================
    // Sekwencja testowa
    // =========================================================
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;


    // Obliczenie, ile stopni przybywa w każdym takcie SPI
    delta_deg_per_sample = rotation_speed_dps / sample_rate_hz;
    
    // Podanie stałego przyrostu na żyroskop
    // (Zmieniamy real na Q24 przez mnożenie)
    gyro_delta_q24 = delta_deg_per_sample * (2.0**24);
    
    while (current_angle_deg <= 2.0) begin
        
        // Zwiększamy fizyczny kąt o naszą deltę
        current_angle_deg = current_angle_deg + delta_deg_per_sample;
        
        // Akcelerometr podaje aktualny fizyczny kąt (w Q24)
        accel_angle_q24 = current_angle_deg * (2.0**24);
        
        // Czekamy na kolejny impuls odczytu (np. co 150 us)
        @(posedge data_latch);
        
    end
    
    // Dron osiągnął 10 stopni. Zatrzymujemy obrót.
    gyro_delta_q24 = 0; 
    accel_angle_q24 = 2.0 * (2.0**24); // Równe 10 stopni na stałe
    
    $display("Osiagnięto 10 stopni. Sprawdzam stabilizację filtra.");
    
    // Puszczenie symulacji na kolejne np. 1000 taktow, by zobaczyc czy filtr stabilnie trzyma wartosc
    repeat(100) @(posedge data_latch);
    
    $finish;
    end

endmodule