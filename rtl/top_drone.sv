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
    logic [1:0] gyro_state;
    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); //nie pojawia sie w trbie ciaglym
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

      unit_converter #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_odebrane[79:65]),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(converted_Y)
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
        .mul_result()
      );


// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [2:0] page_cnt;       // Do przewijania 104-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

// Zmienna dla wygody - grupuje 3 przełączniki w jeden 3-bitowy wektor (zakres 0-7)
logic [2:0] debug_menu_sel;
assign debug_menu_sel = sw[14:12]; 

// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : odczytwartosc - nadawanawartosc
// 010 : spi_odebrane - odebrane dane
// 011 : convertedY - 
// 100 : status: converted_Y_H , 00000, led2 - spi_odebrane[1], led1 - ?converted_Y led0 - ?6c
// 101 : angel - converted Y angle
// 110 : roll_raw
// 111 : roll_deg
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 3'b0;
        flag_6c_detect <= 1'b0;
    end 
    else begin
        // 1. PRZEWIJANIE STRON
        if (btnR_pulse) begin 
            page_cnt <= page_cnt + 3'd1;
        end

        // 2. ZATRZASKIWANIE ZDARZEŃ
        if (spi_done == 1'b1 && spi_odebrane[7:0] == 8'h6c) begin // 95:80?
            flag_6c_detect <= 1'b1; 
        end

        // 3. MULTIPLEKSER MENU (Kodowanie binarne sw[14:12])
        case (debug_menu_sel)
            3'b000: begin // Zwykły tryb (wszystkie 3 switche w dół)
                led <= 16'b0;
                disp_hex <= '0;
            end
            
            3'b001: begin // sw[14]=0, sw[13]=0, sw[12]=1 -> ODCZYTWARTOSC (104 bit)
                case (page_cnt)
                    3'd0: begin led <= odczytwartosc[95:80];           disp_hex <= odczytwartosc[95:80];          end
                    3'd1: begin led <= odczytwartosc[79:64];           disp_hex <= odczytwartosc[79:64];          end
                    3'd2: begin led <= odczytwartosc[63:48];           disp_hex <= odczytwartosc[63:48];          end
                    3'd3: begin led <= odczytwartosc[47:32];           disp_hex <= odczytwartosc[47:32];          end
                    3'd4: begin led <= odczytwartosc[31:16];           disp_hex <= odczytwartosc[31:16];          end
                    3'd5: begin led <= odczytwartosc[15:0];            disp_hex <= odczytwartosc[15:0];           end
                    3'd6: begin led <= {8'b0, odczytwartosc[103:96]};  disp_hex <= {8'b0, odczytwartosc[103:96]}; end
                endcase
            end

            3'b010: begin // sw[14]=0, sw[13]=1, sw[12]=0 -> SPI_ODEBRANE (56 bit)
                case (page_cnt)
                    3'd0: begin led <= spi_odebrane[95:80];           disp_hex <= spi_odebrane[95:80];          end // gyro X
                    3'd1: begin led <= spi_odebrane[79:64];           disp_hex <= spi_odebrane[79:64];          end // gyro Y
                    3'd2: begin led <= spi_odebrane[63:48];           disp_hex <= spi_odebrane[63:48];          end // gyro Z
                    3'd3: begin led <= spi_odebrane[47:32];           disp_hex <= spi_odebrane[47:32];          end // xl X
                    3'd4: begin led <= spi_odebrane[31:16];           disp_hex <= spi_odebrane[31:16];          end // xl Y
                    3'd5: begin led <= spi_odebrane[15:0];            disp_hex <= spi_odebrane[15:0];           end // xl Z
                    3'd6: begin led <= {8'b0, spi_odebrane[103:96]};  disp_hex <= {8'b0, spi_odebrane[103:96]}; end
                endcase
            end

            3'b011: begin // sw[14]=0, sw[13]=1, sw[12]=1 -> CONVERTED_Y
                led <= converted_Y;                                    disp_hex <= converted_Y[15] ? -converted_Y : converted_Y; //clamp to cut +- (misses lowest value)
            end

            3'b100: begin // sw[14]=1, sw[13]=0, sw[12]=0 -> FLAGI STATUSU
                led      <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
                disp_hex <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
            end
            
            3'b101: begin // sw[14]=1, sw[13]=0, sw[12]=1 -> kat Y
                led <= angel;                                         disp_hex <= angel[15] ? -angel : angel; //clamp angle to cut +-
            end

            3'b110: begin // sw[14]=1, sw[13]=1, sw[12]=0 -> ROLL_RAW
                led <= roll_raw;                                      disp_hex <= roll_raw[15] ? -roll_raw : roll_raw; //clamp to cut +- (misses lowest value)
            end

            3'b111: begin // sw[14]=1, sw[13]=1, sw[12]=1 -> ROLL_DEG
                led <= roll_deg;                                      disp_hex <= roll_deg[15] ? -roll_deg : roll_deg; //clamp angle to cut +-
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
