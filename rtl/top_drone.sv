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
    parameter MAX_TICK = 7'd99 // Changed from 14'd9999 to 7'd99 for 1us tick
) (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        //---PWM---
        output logic [3:0] motor_pwm_out,
        input logic spi_start,
     (*KEEP = "true"*)        output logic sclk,
     (*KEEP = "true"*)        input logic poci,
     (*KEEP = "true"*)        output logic cs_n,
     (*KEEP = "true"*)        output logic copi,
        //---SPI---
        output logic [3:0] an,
        output logic [7:0] sseg,
        output [15:0] led,
        input logic button,
        input logic btnD_pulse,
        input logic btnL_pulse,
        input logic btnR_pulse,
        input logic btnReset,
        input logic [15:0] sw
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    (* DONT_TOUCH = "true" *) logic [15:0] led_reg;

    /**
     * Signals assignments
     */

    /**
     * Submodules instances
     */

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
    (* KEEP = "true" *) logic [1:0] gyro_state;

    logic signed [39:0] rollq24;
    logic signed [39:0] gyroYq24;

    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); 
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

      convert_gyro #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_odebrane[79:64]),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(converted_Y),
          .mul_result(gyroYq24)
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
        .mul_result(rollq24)
      );

  
    logic signed [15:0] estim_roll;
    angle_estimator #() estimator_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_data(rollq24),
        .gyro_data(gyroYq24),
        .angle_deg(estim_roll)
    );

    // --- Simple PWM Test Logic ---
    // Simplified test mode. sw[0] is the main enable switch.
    // Switches sw[10:1] control the pulse width from 900us to 1600us.
    // This allows for manual control and verification of the ESCs and motors.
    logic [14:0] test_pulse_width;
    logic [9:0] pulse_offset;

    assign pulse_offset = sw[10:1]; // Use switches 10 down to 1 for control (10 bits)
    // Base pulse is 900us. Switches add 0-700us.
    // The value from switches is clamped to 700 to stay within the 900-1600us range.
    assign test_pulse_width = 15'd900 + (pulse_offset > 10'd700 ? 10'd700 : pulse_offset);

    logic [14:0] m_width[4];
    assign m_width[0] = enable ? test_pulse_width : 15'd0;
    assign m_width[1] = enable ? test_pulse_width : 15'd0;
    assign m_width[2] = enable ? test_pulse_width : 15'd0;
    assign m_width[3] = enable ? test_pulse_width : 15'd0;

    // Instantiate 4 PWM modules
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pwm_inst
            pwm #( .MAX_TICK(MAX_TICK) ) u_pwm (
                .clk(clk),
                .enable(enable),
                .d_in(m_width[i]),
                .pwm(motor_pwm_out[i])
            );
        end
    endgenerate

// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [2:0] page_cnt;       // Do przewijania 104-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

// Zmienna dla wygody - grupuje 3 przełączniki w jeden 3-bitowy wektor (zakres 0-7)
logic [2:0] debug_menu_sel;
assign debug_menu_sel = sw[14:12]; 

// *******D E B U G**************D E B U G**************D E B U G*******
// sw[11]=1: PID debug mode. sw[14:12] select displayed value:
// 000: PWM output (1000-2000)
// 001: PID Gains (Kp, Ki, Kd)
// 010: PID input (estim_roll)
// 011: PID error
// 100: PID integral (lower 16 bits)
// 101: PID integral (upper 16 bits)
// 110: PID derivative
// 111: PWM output (0-100%)
//
// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : odczytwartosc - nadawanawartosc
// 010 : spi_odebrane - odebrane dane
// 011 : convertedY - 
// 100 : status: converted_Y_H , 00000, led2 - spi_odebrane[1], led1 - ?converted_Y led0 - ?6c
// 101 : angel - Y angle deegrees per second
// 110 : estimated_angle_roll
// 111 : roll_deg
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led_reg <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 3'b0;
        flag_6c_detect <= 1'b0;
    end 
    else begin
        // For this simple test, the complex debug menu is disabled.
        // We can display the PWM value directly on the LEDs and 7-segment display.
        disp_hex <= m_width[0];
        led_reg <= m_width[0];
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

    assign led = led_reg;

endmodule
