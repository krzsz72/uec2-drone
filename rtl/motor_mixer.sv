`timescale 1ns / 1ps

module motor_mixer #(
    parameter MIN_PULSE = 15'd1000,
    parameter MAX_PULSE = 15'd2000,
    parameter INIT_PULSE = 15'd900
) (
    input  wire        clk,
    input  wire        rst_n,

    // 00: INIT, 01: ARMED, 10: RUN
    input  wire [1:0]  mode,

    input  wire [15:0] throttle,  // expected 1000 - 2000

    input  wire signed [15:0] pid_pitch,
    input  wire signed [15:0] pid_roll,
    input  wire signed [15:0] pid_yaw,

    output reg [14:0] m1_width,
    output reg [14:0] m2_width,
    output reg [14:0] m3_width,
    output reg [14:0] m4_width
);

    // Internal signed signals for calculation
    wire signed [16:0] m1_calc;
    wire signed [16:0] m2_calc;
    wire signed [16:0] m3_calc;
    wire signed [16:0] m4_calc;

    // Signed version of throttle
    wire signed [16:0] throttle_signed = {1'b0, throttle};

    // Calculate mixed values
    // M1 = Throttle - pid_pitch + pid_roll - pid_yaw
    assign m1_calc = throttle_signed - pid_pitch + pid_roll - pid_yaw;
    
    // M2 = Throttle - pid_pitch - pid_roll + pid_yaw
    assign m2_calc = throttle_signed - pid_pitch - pid_roll + pid_yaw;
    
    // M3 = Throttle + pid_pitch + pid_roll + pid_yaw
    assign m3_calc = throttle_signed + pid_pitch + pid_roll + pid_yaw;
    
    // M4 = Throttle + pid_pitch - pid_roll - pid_yaw
    assign m4_calc = throttle_signed + pid_pitch - pid_roll - pid_yaw;

    // Clamping function
    function [14:0] clamp;
        input signed [16:0] val;
        begin
            if (val > signed'({1'b0, MAX_PULSE})) clamp = MAX_PULSE;
            else if (val < signed'({1'b0, MIN_PULSE})) clamp = MIN_PULSE;
            else clamp = val[14:0];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m1_width <= INIT_PULSE;
            m2_width <= INIT_PULSE;
            m3_width <= INIT_PULSE;
            m4_width <= INIT_PULSE;
        end else begin
            case (mode)
                2'b00: begin // INIT
                    m1_width <= INIT_PULSE;
                    m2_width <= INIT_PULSE;
                    m3_width <= INIT_PULSE;
                    m4_width <= INIT_PULSE;
                end
                2'b01: begin // ARMED
                    m1_width <= MIN_PULSE;
                    m2_width <= MIN_PULSE;
                    m3_width <= MIN_PULSE;
                    m4_width <= MIN_PULSE;
                end
                2'b10: begin // RUN
                    m1_width <= clamp(m1_calc);
                    m2_width <= clamp(m2_calc);
                    m3_width <= clamp(m3_calc);
                    m4_width <= clamp(m4_calc);
                end
                default: begin
                    m1_width <= INIT_PULSE;
                    m2_width <= INIT_PULSE;
                    m3_width <= INIT_PULSE;
                    m4_width <= INIT_PULSE;
                end
            endcase
        end
    end

endmodule