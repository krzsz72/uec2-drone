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
    parameter MAX_TICK = 14'd9999
) (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        input  logic [7:0] d_in,
        output logic pwm,
        //---PWM---
        input logic spi_start,
        output logic sclk,
        input logic poci,
        output logic cs_n,
        output logic copi,
        //---SPI---
        output logic [3:0] an,
        output logic [7:0] sseg,
        output logic [15:0] led,
        input logic button,
        input logic btnR_pulse,
        input logic btnReset,
        input logic [15:0] sw
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    /**
     * Signals assignments
     */

    /**
     * Submodules instances
     */

     pwm #(
        .MAX_TICK(MAX_TICK)
     ) u_pwm50Hz(
        .clk,
        .enable,
        .d_in,
        .pwm
     );
   
     logic [6:0] destination = 7'h0F;
     logic [7:0] data_write;
     logic [31:0] nadajwartosc = {1'b0,destination,data_write,16'b0};
      (*KEEP = "true"*)
     logic [55:0] odczytwartosc;// = {1'b1,destination,16'b0};
     wire spi_done;
    // wire spi_loopback;
     (*KEEP = "true"*)
    logic [55:0] spi_odebrane; //max potrzebuje zmiescic 6x8bit = 48b +8bit padding z komendy kontrolera
    logic [5:0] data_length;
    logic signed [15:0] converted_Y;
    logic signed [15:0] angel; //👼
    logic [1:0] gyro_state;
    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); //nie pojawia sie w trbie ciaglym
    gyro #(
        .WIDTH(56)
    ) gyro (
        .clk(clk),
        .rst_n(~btnReset),
        .d_length(data_length),
        .d_out(odczytwartosc),
        .ready( (spi_done && sw[15]) | spi_start),
        .gyro_data(spi_odebrane[1]),
        .state_curr(gyro_state)
    );

     spi_controller #(
       .WIDTH(56)
      )
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

      unit_converter #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(convertedY),
          .gyro_raw_data(spi_odebrane[31:16])
      );

// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [1:0] page_cnt;       // Do przewijania 56-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

// Zmienna dla wygody - grupuje 3 przełączniki w jeden 3-bitowy wektor (zakres 0-7)
logic [2:0] debug_menu_sel;
assign debug_menu_sel = sw[14:12]; 

// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : odczytwartosc - nadawanawartosc
// 010 : spi_odebrane - odebrane dane
// 011 : convertedY - 
// 100 : status: convertedY_H , 00000, led2 - spi_odebrane[1], led1 - ?convertedY led0 - ?6c
// 101 : angel - converted Y angle
// 110 : 
// 111 : 
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 2'b0;
        flag_6c_detect <= 1'b0;
    end 
    else begin
        // 1. PRZEWIJANIE STRON (Użyj swojej flagi zbocza zamiast btnR_pulse!)
        if (btnR_pulse) begin 
            page_cnt <= page_cnt + 2'd1;
        end

        // 2. ZATRZASKIWANIE ZDARZEŃ (Zachowane z poprzedniej wersji)
        if (spi_done == 1'b1 && spi_odebrane[15:8] == 8'h6c) begin
            flag_6c_detect <= 1'b1; 
        end

        // 3. MULTIPLEKSER MENU (Kodowanie binarne sw[14:12])
        case (debug_menu_sel)
            3'b000: begin // Zwykły tryb (wszystkie 3 switche w dół)
                led <= 16'b0;
                disp_hex <= '0;
            end
            
            3'b001: begin // sw[14]=0, sw[13]=0, sw[12]=1 -> ODCZYTWARTOSC (56 bit)
                case (page_cnt)
                    2'd0: begin led <= odczytwartosc[15:0];          disp_hex <= odczytwartosc[15:0];          end
                    2'd1: begin led <= odczytwartosc[31:16];         disp_hex <= odczytwartosc[31:16];         end
                    2'd2: begin led <= odczytwartosc[47:32];         disp_hex <= odczytwartosc[47:32];         end
                    2'd3: begin led <= {8'b0, odczytwartosc[55:48]}; disp_hex <= {8'b0, odczytwartosc[55:48]}; end
                endcase
            end

            3'b010: begin // sw[14]=0, sw[13]=1, sw[12]=0 -> SPI_ODEBRANE (56 bit)
                case (page_cnt)
                    2'd0: begin led <= spi_odebrane[15:0];           disp_hex <= spi_odebrane[15:0];           end //gyro Z
                    2'd1: begin led <= spi_odebrane[31:16];          disp_hex <= spi_odebrane[31:16];          end //gyro Y
                    2'd2: begin led <= spi_odebrane[47:32];          disp_hex <= spi_odebrane[47:32];          end //gyro X
                    2'd3: begin led <= {8'b0, spi_odebrane[55:48]};  disp_hex <= {8'b0, spi_odebrane[55:48]};  end
                endcase
            end

            3'b011: begin // sw[14]=0, sw[13]=1, sw[12]=1 -> CONVERTED_Y
                led <= converted_Y;
                disp_hex <= converted_Y;
            end

            3'b100: begin // sw[14]=1, sw[13]=0, sw[12]=0 -> FLAGI STATUSU
                led      <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
                disp_hex <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
            end
            
            3'b101: begin // sw[14]=1, sw[13]=0, sw[12]=1 -> kat Y
                led <= angel;                                        disp_hex <= angel;
            end

            3'b110: begin // sw[14]=1, sw[13]=1, sw[12]=0 -> MIEJSCE NA NOWĄ ZMIENNĄ
                // led <= ...
            end

            3'b111: begin // sw[14]=1, sw[13]=1, sw[12]=1 -> MIEJSCE NA NOWĄ ZMIENNĄ
                // led <= ...
            end

            default: begin
                led <= 16'b0;
                disp_hex <= '0;
            end
        endcase
    end
end
    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(1'b0),
        .hex3(disp_hex[15:12]), 
        .hex2(disp_hex[11:8]), 
        .hex1(disp_hex[7:4]), 
        .hex0(disp_hex[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );



endmodule
