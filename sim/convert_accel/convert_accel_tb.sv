// ********************************
//
//     TESTBENCH for convert_accel
//
//     Krzysztof Piziak
//
// ********************************
`timescale 1ns/1ps

module convert_accel_tb;

    localparam int WIDTH = 16;

    logic clk;
    logic rst_n;
    logic signed [WIDTH-1:0] accel_raw_data;
    logic data_latch;
    logic signed [WIDTH-1:0] angle_raw;
    logic signed [WIDTH-1:0] angle_deg;
    logic signed [39:0] val_prec;

    // Instancja poprawionego modułu
    convert_accel #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .accel_raw_data(accel_raw_data),
        .data_latch(data_latch),
        .angle_raw(angle_raw),
        .angle_deg(angle_deg),
        .latched_raw(),
        .mul_result(val_prec)
    );

    // Generator zegara systemowego (100 MHz -> okres 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Generator zegara SPI (1 MHz -> okres 1000ns)
    logic sclk;
    initial begin
        sclk = 0;
        forever #500 sclk = ~sclk;
    end

    // Zmienne symulacyjne dla SPI
    logic [15:0] test_data = 16'h0108; // Dane do przesłania 0d2049
    logic [15:0] shift_reg = '0;
    logic copi = 0;
    int   bit_cnt  = 0;
    logic data_ready = 0;

    // =========================================================
    // 1. Symulacja fizycznej linii MOSI (nadawanie od strony układu MPU)
    // =========================================================
    always_ff @(negedge sclk) begin
        if (!rst_n) 
            copi <= 0;
        else 
            copi <= test_data[15 - bit_cnt]; // Przesył MSB First
    end

    // =========================================================
    // 2. Symulacja odbiornika SPI w układzie FPGA
    // =========================================================
    always_ff @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg  <= '0;
            bit_cnt    <= 0;
            data_ready <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[14:0], copi}; // Shiftowanie rejestru
            
            if (bit_cnt == 15) begin
                bit_cnt    <= 0;
                data_ready <= 1'b1; // Ustaw flagę pełnej ramki na 1 takt SCLK
            end else begin
                bit_cnt    <= bit_cnt + 1;
                data_ready <= 1'b0;
            end
        end
    end

    // =========================================================
    // 3. Synchronizacja domen zegarowych i generacja impulsu (Edge Detector)
    // =========================================================
    // Odbieramy powolną flagę data_ready na szybkim zegarze 100MHz
    logic ready_d1, ready_d2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_d1 <= 0;
            ready_d2 <= 0;
            data_latch <= 0;
        end else begin
            ready_d1 <= data_ready;
            ready_d2 <= ready_d1;
            // Detekcja zbocza narastającego
            data_latch <= ready_d1 & ~ready_d2; 
        end
    end

    // Wystawienie zebranych danych na wyjście do konwertera
    assign accel_raw_data = shift_reg;

    // =========================================================
    // Sekwencja testowa
    // =========================================================
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;

        // Symulacja trwa przez odpowiednią ilość czasu.
        // Odczyt 16 bitów przy 1MHz trwa 16us. 
        // Symulujemy 100us, by zaobserwować kilka pełnych transmisji i przyrost akumulatora.
        #100_000; 
        
        $display("Symulacja zakonczona. Aktualny kat: %d deg", angle_deg);
        $finish;
    end

endmodule