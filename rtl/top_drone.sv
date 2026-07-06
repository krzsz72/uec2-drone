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
        input logic btnReset
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
     logic [31:0] odczytwartosc;// = {1'b1,destination,16'b0};
     wire spi_done;
    // wire spi_loopback;
     logic [31:0] spi_odebrane;
    logic [31:0] data_length;
    
    gyro #(.WIDTH(32)
    ) gyro (
        .clk(clk),
        .d_length(data_length),
        .d_out(odczytwartosc),
        .start(spi_start)
    );

     spi_controller #(
       .WIDTH(32)
      )
      spi_controller(
         .clk(clk),
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

always_ff @(posedge clk) begin
    //reset
       if (btnReset)begin
        led[15:0]<=16'b0;
    end else begin
        if(data_length) led[1] <= 1'b1;
        if(spi_start) led[2] <= 1'b1;
         if (spi_done == 1'b1) begin
        // Dla spi_done: zapamiętaj ostatni wynik porównania z 8'h6c
            led[0] <= (spi_odebrane[15:8] == 8'h6c);
            led[15:3]<=spi_odebrane[15:3];
         end
        end
end

    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(1'b0),
        .hex3(spi_odebrane[23:20]), 
        .hex2(spi_odebrane[19:16]), 
        .hex1(spi_odebrane[15:12]), 
        .hex0(spi_odebrane[11:8]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );



endmodule
