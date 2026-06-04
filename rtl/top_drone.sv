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

module top_drone (
        input  logic clk,
        input  logic rst,
        input  logic rx,
        output logic tx,
        input  logic btn,
        output logic rx_monitor, 
        output logic tx_monitor,
        input  logic btnU,    
        output logic [3:0] an,
        output logic [7:0] sseg
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    logic tx_loopback;
    logic tx_out;

    /**
     * Signals assignments
     */

    assign tx = btn ? rx : tx_out;

    /**
     * Submodules instances
     */

    uart_monitor u_uart_monitor (
        .clk             (clk),
        .rx              (rx),
        .tx              (tx_loopback),
        .loopback_enable (btn), // Podłączone do sw[0] z wyższego poziomu
        .rx_monitor      (rx_monitor),
        .tx_monitor      (tx_monitor)
    );

    uart_display_logic u_uart_display_logic (
        .clk (clk),
        .rst (rst),
        .rx (rx),
        .btnU (btnU),        
        .tx_out (tx_out),
        .an (an),
        .sseg (sseg)
    );

endmodule
