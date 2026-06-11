`timescale 1ns / 1ps

module pid_tb;

    logic clk;
    logic rst;
    logic enable;

    logic signed [15:0] kp;
    logic signed [15:0] ki;
    logic signed [15:0] kd;

    logic signed [15:0] actual_val;
    logic signed [15:0] desired_val;

    logic signed [15:0] pid_out;

    pid #(
        .W(16),
        .K_W(16),
        .SCALING_FACTOR(8)
    ) dut (
        .clk,
        .rst,
        .enable,
        .kp,
        .ki,
        .kd,
        .actual_val,
        .desired_val,
        .pid_out
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Enable generation (pulsed)
    initial begin
        enable = 0;
        forever begin
            #190 enable = 1;
            #10 enable = 0;
        end
    end

    // -------------------------------------------------------------
    // Model obiektu fizycznego (zamknięta pętla sprzężenia zwrotnego)
    // -------------------------------------------------------------
    logic signed [31:0] plant_velocity = 0;
    logic signed [31:0] plant_position = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            plant_velocity <= 0;
            plant_position <= 0;
            actual_val <= 0;
        end else if (enable) begin
            // Wyjście PID traktujemy jako "siłę" napędową. 
            // Odejmujemy przesuniętą prędkość jako proste tarcie (tłumienie obiektu).
            plant_velocity <= plant_velocity + pid_out - (plant_velocity >>> 4);
            
            // Aktualizacja pozycji (całkowanie prędkości)
            plant_position <= plant_position + plant_velocity;
            
            // Mapowanie wewnętrznej (dużej) wartości pozycji na wyjście do modułu PID.
            // Przesunięcie bitowe działa jak dzielenie, zapobiegając przepełnieniu 16 bitów.
            actual_val <= plant_position[23:8]; 
        end
    end

    // Test sequence
    initial begin
        rst = 1;
        // Nastawy PID dla bardzo powolnego dojścia bez oscylacji (silnie przetłumione)
        kp = 16'd100;   // Małe wzmocnienie, aby obiekt powoli i łagodnie ruszał
        ki = 16'd1;    // WYŁĄCZONY człon całkujący! To on powodował przepełnienie (wind-up)
        kd = 16'd1560;  // Silny człon różniczkujący, działa jak bardzo dobry hamulec
        
        desired_val = 16'd0;

        #100;
        rst = 0;

        // KROK 1: Skok wartości zadanej na 2000
        #500;
        desired_val = 16'd2500;
        
        // Czekamy odpowiednio długo (2 ms), aby w podglądzie fal zaobserwować proces 
        // narastania, przeregulowania (oscylacji) i w końcu stabilizacji w okolicach 2000.
        // Przy kroku `enable` co 200 ns daje to 10 000 cykli pracy regulatora.
        #2000000;
        
        // Sprawdzenie, czy układ uregulował się w miarę blisko wartości zadanej (tolerancja +/- 20)
        if (actual_val < 2480 || actual_val > 2520) 
            $error("PID failed to settle properly. Expected ~2500, got %d", actual_val);
            
        // KROK 2: Spadek wartości zadanej do 500, aby zobaczyć reakcję w dół
        desired_val = 16'd2000;
        #2000000;
        
        if (actual_val < 480 || actual_val > 520) 
            $error("PID failed to settle properly. Expected ~500, got %d", actual_val);

        $display("Test finished.");
        $finish;
    end

endmodule
