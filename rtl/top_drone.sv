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
     logic [55:0] odczytwartosc;// = {1'b1,destination,16'b0};
     wire spi_done;
    // wire spi_loopback;
     logic [55:0] spi_odebrane; //max potrzebuje zmiescic 6x8bit = 48b +8bit padding z komendy kontrolera
    logic [5:0] data_length;
    logic [15:0] converted_Y;
    gyro #(
        .WIDTH(56)
    ) gyro (
        .clk(clk),
        .rst_n(~btnReset),
        .d_length(data_length),
        .d_out(odczytwartosc),
        .ready( (spi_done && sw[15]) | spi_start),
        .gyro_data(spi_odebrane[1])
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
          .angle_deg(),
          .angle_raw(converted_Y),
          .gyro_raw_data(spi_odebrane[31:16])
      );

logic [15:0] disp_hex;

always_ff @(posedge clk) begin
    //reset
       if (btnReset)begin
        led[15:0]<=16'b0;
        disp_hex <= '0;
    end else begin
        if(sw[14])begin
             disp_hex <= odczytwartosc[55:40]; //sw15 - tryb ciagly, sw14 - nadawana komenda, sw13 - odebrane dane, sw12 - gyroY
            led[15:0] <= odczytwartosc[55:40];
        end
        if(sw[13]) begin
             disp_hex <= spi_odebrane[15:0];
            led[15:0] <= spi_odebrane[15:0];
        end
        if(sw[12])begin
             disp_hex <= converted_Y;
            led[15:0] <= converted_Y;           //sw11 - toggle debug leds full / partial
        end
        if(~sw[11])begin
                if(converted_Y) led[1] <= 1'b1;           //  
                if(spi_odebrane[1]) led[2] <= 1'b1;
                    if (spi_done == 1'b1) begin        // Dla spi_done: zapamiętaj ostatni wynik porównania z 8'h6c
                    if( (spi_odebrane[15:8] == 8'h6c)) led[0] <=1'b1;                      // zapala kolejne ledy co 1 wypelniajac caly bufor. na oscylo nie widac cs_n..?
                    led[15:8]<=converted_Y[15:8];                                // wyswietlmy przyspieszenie w kacie Y: 
                    end                                                                //dorobivc debugger na sw aby pokazywal kolejno data_out, spi_odebrane, przyciski, itp
        end
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
