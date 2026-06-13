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
        output logic led
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
     logic [23:0] nadajwartosc = {1'b0,destination,data_write,8'b0};
     logic [23:0] odczytwartosc = {1'b1,destination,16'b0};
     //wire spi_done;
    // wire spi_loopback;
     logic [23:0] spi_odebrane;

     spi_controller #(
       .WIDTH(24)
      )
      spi_controller(
         .clk(clk),
         .start(spi_start),
         .sclk(sclk),
         .cs_n(cs_n),
         .reg_rx(spi_odebrane),
         .reg_tx(odczytwartosc),
         .poci(poci),
         .copi(copi),
         .busy(),
         .done()
      );

      assign led = (spi_odebrane[15:8] == 8'h6c);


    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(1'b1),
        .hex3(spi_odebrane[15:12]), 
        .hex2(spi_odebrane[11:8]), 
        .hex1(spi_odebrane[7:4]), 
        .hex0(spi_odebrane[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );



endmodule
