`timescale 1ns / 1ps

module uart_display_logic (
    input  logic clk,
    input  logic rst,
    input  logic rx,
    input  logic btnU,        
    output logic tx_out,      
    output logic [3:0] an,
    output logic [7:0] sseg  
);

    // Sygnały dla UART
    logic rd_uart, wr_uart;
    logic rx_empty, tx_full;
    logic [7:0] r_data, w_data;

    // Sygnały dla przycisku
    logic btnu_tick;
    
    // Rejestry przechowujące kody ASCII znaków
    logic [7:0] curr_byte = 8'h00;
    logic [7:0] prev_byte = 8'h00;

    
    uart # (
        .DVSR (22),
        .DVSR_BIT (5),
        .DBIT (8),
        .SB_TICK (16),
        .FIFO_W (2)
    ) u_uart (
        .clk(clk),
        .reset(rst),
        .rd_uart(rd_uart),
        .wr_uart(wr_uart),
        .rx(rx),
        .w_data(w_data),
        .tx_full(tx_full),
        .rx_empty(rx_empty),
        .tx(tx_out),
        .r_data(r_data)
    );

    typedef enum logic [1:0] {IDLE, READ_PULSE, WAIT_FIFO} fsm_state_t;
    fsm_state_t state = IDLE;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_uart   <= 1'b0;
            curr_byte <= 8'h00;
            prev_byte <= 8'h00;
            state     <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (~rx_empty) begin
                        curr_byte <= r_data;
                        prev_byte <= curr_byte;
                        rd_uart   <= 1'b1;      // Wystawienie sygnału czytania
                        state     <= READ_PULSE;
                    end
                end
                READ_PULSE: begin
                    rd_uart <= 1'b0;            // Zakończenie impulsu po 1 takcie
                    state   <= WAIT_FIFO;
                end
                WAIT_FIFO: begin
                    // Pusty takt: dajemy czas FIFO na zaktualizowanie flagi rx_empty
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

   
    debounce u_debounce (
        .clk(clk),
        .reset(rst),
        .sw(btnU),
        .db_level(),
        .db_tick(btnu_tick)         // Generuje 1-taktowy impuls
    );

   
    assign w_data  = curr_byte + 8'd3;
    assign wr_uart = btnu_tick & ~tx_full;

    
    disp_hex_mux u_display (
        .clk(clk),
        .reset(rst),
        .hex3(prev_byte[7:4]), // Lewe cyfry (poprzedni znak)
        .hex2(prev_byte[3:0]), 
        .hex1(curr_byte[7:4]), // Prawe cyfry (aktualny znak)
        .hex0(curr_byte[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );

endmodule