/**
 * Project: uec2-drone
 * Description: Proportional-Integral-Derivative (PID) controller.
 */

module pid #(
    parameter W = 16,            // Width of input data and output data
    parameter K_W = 16,          // Width of Kp, Ki, Kd coefficients
    parameter SCALING_FACTOR = 8 // Number of fractional bits for coefficients
) (
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic signed [K_W-1:0] kp,
    input  logic signed [K_W-1:0] ki,
    input  logic signed [K_W-1:0] kd,

    input  logic signed [W-1:0] actual_val,
    input  logic signed [W-1:0] desired_val,

    output logic signed [W-1:0] pid_out
);

    timeunit 1ns;
    timeprecision 1ps;

    // Extended width for error to avoid overflow on subtraction
    logic signed [W:0] error;
    logic signed [W:0] prev_error;
    
    // Multiplier outputs
    logic signed [W+K_W:0] p_term;
    logic signed [W+K_W:0] i_term_delta;
    logic signed [W+K_W:0] d_term;
    
    // Integrator accumulator
    logic signed [W+K_W+4:0] integrator; // Extra bits for accumulation
    
    // Total sum
    logic signed [W+K_W+5:0] pid_total;

    assign error = signed'({desired_val[W-1], desired_val}) - signed'({actual_val[W-1], actual_val});

    // Combinational products
    assign p_term = kp * error;
    assign i_term_delta = ki * error;
    assign d_term = kd * (error - prev_error);
    
    assign pid_total = p_term + integrator + d_term;

    // Anti-windup and output saturation limits
    localparam logic signed [W-1:0] OUT_MAX = (1 << (W-1)) - 1;
    localparam logic signed [W-1:0] OUT_MIN = -(1 << (W-1));
    
    // To scale back to output width, we shift by SCALING_FACTOR
    logic signed [W+K_W+5:0] scaled_total;
    assign scaled_total = pid_total >>> SCALING_FACTOR;

    logic hit_max, hit_min;
    assign hit_max = (scaled_total > OUT_MAX);
    assign hit_min = (scaled_total < OUT_MIN);

    always_ff @(posedge clk) begin
        if (rst) begin
            prev_error <= '0;
            integrator <= '0;
            pid_out <= '0;
        end else if (enable) begin
            prev_error <= error;
            
            // Conditional integration (anti-windup)
            // Only integrate if we are not saturated, or if the integration direction 
            // is opposite to the saturation.
            if (!hit_max && !hit_min) begin
                integrator <= integrator + i_term_delta;
            end else if (hit_max && (error < 0)) begin
                integrator <= integrator + i_term_delta;
            end else if (hit_min && (error > 0)) begin
                integrator <= integrator + i_term_delta;
            end
            
            // Output Saturation
            if (hit_max)
                pid_out <= OUT_MAX;
            else if (hit_min)
                pid_out <= OUT_MIN;
            else
                pid_out <= scaled_total[W-1:0];
        end
    end

endmodule
