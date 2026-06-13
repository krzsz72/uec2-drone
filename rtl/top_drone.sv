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
        output logic [23:0] spi_odebrane,
        output logic copi,
        //---SPI---
        output logic [3:0] an,
        output logic [7:0] sseg
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

     logic [23:0] nadajwartosc = 24'b10000001100110011001100;
     wire spi_done;
     wire spi_loopback;
     spi_controller #(
       .WIDTH(24)
      )
      spi_controller(
         .clk(clk),
         .start(spi_start | spi_done),
         .sclk(sclk),
         .cs_n(cs_n),
         .reg_rx(spi_odebrane),
         .reg_tx(nadajwartosc),
         .poci(spi_loopback),
         .copi(spi_loopback),
         .busy(busy),
         .done(spi_done)
      );

      disp_hex_mux u_display (
        .clk(clk),
        .reset(),
        .hex3(spi_odebrane[15:12]), 
        .hex2(spi_odebrane[11:8]), 
        .hex1(spi_odebrane[7:4]), 
        .hex0(spi_odebrane[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );



endmodule
