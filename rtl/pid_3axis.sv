/**
 * Project: uec2-drone
 * Description: 3-Axis Proportional-Integral-Derivative (PID) controller.
 * Instantiates three independent single-axis PID controllers for Pitch, Roll, and Yaw.
 */

module pid_3axis #(
    parameter W = 16,
    parameter K_W = 16,
    parameter SCALING_FACTOR = 8
) (
    input  logic clk,
    input  logic rst,
    input  logic enable,

    // Pitch parameters
    input  logic signed [K_W-1:0] kp_pitch,
    input  logic signed [K_W-1:0] ki_pitch,
    input  logic signed [K_W-1:0] kd_pitch,

    // Roll parameters
    input  logic signed [K_W-1:0] kp_roll,
    input  logic signed [K_W-1:0] ki_roll,
    input  logic signed [K_W-1:0] kd_roll,

    // Yaw parameters
    input  logic signed [K_W-1:0] kp_yaw,
    input  logic signed [K_W-1:0] ki_yaw,
    input  logic signed [K_W-1:0] kd_yaw,

    // Actual angles (from Attitude Estimator / Gyro)
    input  logic signed [W-1:0] actual_pitch,
    input  logic signed [W-1:0] actual_roll,
    input  logic signed [W-1:0] actual_yaw,

    // Desired angles (from RC Receiver)
    input  logic signed [W-1:0] desired_pitch,
    input  logic signed [W-1:0] desired_roll,
    input  logic signed [W-1:0] desired_yaw,

    // PID Outputs (to Motor Mixer)
    output logic signed [W-1:0] pid_pitch_out,
    output logic signed [W-1:0] pid_roll_out,
    output logic signed [W-1:0] pid_yaw_out
);

    timeunit 1ns;
    timeprecision 1ps;

    // Pitch PID instance
    pid #(
        .W(W),
        .K_W(K_W),
        .SCALING_FACTOR(SCALING_FACTOR)
    ) pid_inst_pitch (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .kp(kp_pitch),
        .ki(ki_pitch),
        .kd(kd_pitch),
        .actual_val(actual_pitch),
        .desired_val(desired_pitch),
        .pid_out(pid_pitch_out)
    );

    // Roll PID instance
    pid #(
        .W(W),
        .K_W(K_W),
        .SCALING_FACTOR(SCALING_FACTOR)
    ) pid_inst_roll (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .kp(kp_roll),
        .ki(ki_roll),
        .kd(kd_roll),
        .actual_val(actual_roll),
        .desired_val(desired_roll),
        .pid_out(pid_roll_out)
    );

    // Yaw PID instance
    pid #(
        .W(W),
        .K_W(K_W),
        .SCALING_FACTOR(SCALING_FACTOR)
    ) pid_inst_yaw (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .kp(kp_yaw),
        .ki(ki_yaw),
        .kd(kd_yaw),
        .actual_val(actual_yaw),
        .desired_val(desired_yaw),
        .pid_out(pid_yaw_out)
    );

endmodule
