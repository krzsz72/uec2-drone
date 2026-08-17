module PID #(
    parameter int WIDTH = 16 // Width of angle_deg input (Q8.7)
) (
    input logic clk, rst_n,
    input logic enable,                        // Sygnał zezwalający na obliczenia (np. co nową próbkę)
    input logic signed [WIDTH-1:0] estim_roll, // Kąt w formacie Q8.7
    input logic [2:0] Kp_in,                   // Wzmocnienie proporcjonalne z sw[7:5]
    input logic [2:0] Ki_in,                   // Wzmocnienie całkujące z sw[4:2]
    input logic [1:0] Kd_in,                   // Wzmocnienie różniczkujące z sw[1:0]
    output logic [14:0] pwm_from_pid, // 1000-2000us pulse width
    output logic signed [WIDTH-1:0] pid_error_out,
    output logic signed [31:0] pid_integral_out,
    output logic signed [WIDTH-1:0] pid_derivative_out,
    output logic signed [WIDTH-1:0] pid_output_out // Scaled correction value (Q1.0)
);

    // PID internal signals
    logic signed [WIDTH-1:0] pid_setpoint = '0; // Target angle = 0 (Q8.7)
    logic signed [WIDTH-1:0] pid_error;
    logic signed [31:0] pid_integral; // Q8.7 (24 integer bits, 8 fractional bits)
    logic signed [WIDTH-1:0] pid_derivative;
    logic signed [WIDTH-1:0] pid_last_error;
    logic signed [15:0] pid_output_scaled; // Q1.0, integer correction
    logic signed [15:0] pwm_val;
    logic output_saturated;
    
    localparam [14:0] BASE_THROTTLE = 15'd1500; // 1.5ms pulse
    localparam [14:0] PWM_MIN = 15'd1000;
    localparam [14:0] PWM_MAX = 15'd2000;

    // PID calculation logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin // Reset PID
            pid_integral <= '0;
            pid_last_error <= '0;
            pid_error <= '0;
        end else begin
            if (enable) begin // Wykonuj obliczenia tylko gdy jest nowa próbka
                pid_error <= pid_setpoint - estim_roll;

                // Anti-windup: Całkuj tylko, gdy wyjście nie jest nasycone,
                // lub gdy całkowanie pomaga wyjść z nasycenia.
                if (!output_saturated || (pid_error[WIDTH-1] != pid_integral[31])) begin
                     pid_integral <= pid_integral + pid_error;
                end

                pid_last_error <= pid_error;
            end
        end
    end

    assign pid_derivative = pid_error - pid_last_error;

    // Terms are calculated in Q8.7 format
    logic signed [31:0] p_term, i_term, d_term;
    assign p_term = pid_error * Kp_in;
    assign i_term = pid_integral * Ki_in;
    assign d_term = pid_derivative * Kd_in;

    // Sum terms and scale to Q1.0 (integer)
    // The gains from switches might be too aggressive for the physical system.
    // We add an extra right shift to scale down the overall output gain.
    // '>>> 10' divides the output by 1024 instead of 128, effectively reducing the total gain by a factor of 8.
    assign pid_output_scaled = (p_term + i_term + d_term) >>> 10;

    // Calculate final PWM value and check for saturation
    always_comb begin
        pwm_val = BASE_THROTTLE + pid_output_scaled;
        if (pwm_val > PWM_MAX) begin
            pwm_from_pid = PWM_MAX;
            output_saturated = 1'b1;
        end else if (pwm_val < PWM_MIN) begin
            pwm_from_pid = PWM_MIN;
            output_saturated = 1'b1;
        end else begin
            pwm_from_pid = pwm_val[14:0];
            output_saturated = 1'b0;
        end
    end

    // Outputs for debugging
    assign pid_error_out = pid_error;
    assign pid_integral_out = pid_integral;
    assign pid_derivative_out = pid_derivative;
    assign pid_output_out = pid_output_scaled;

endmodule