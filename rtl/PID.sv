module PID #(
    parameter int WIDTH = 16 // Width of angle_deg input (Q8.7)
) (
    input logic clk, rst_n,
    input logic enable,                        // Sygnał zezwalający na obliczenia (np. co nową próbkę)
    input logic signed [WIDTH-1:0] estim_roll, // Kąt w formacie Q8.7
    input logic signed [15:0] Kp,              // Wzmocnienie proporcjonalne (Q4.12)
    input logic signed [15:0] Ki,              // Wzmocnienie całkujące (Q4.12)
    input logic signed [15:0] Kd,              // Wzmocnienie różniczkujące (Q4.12)
    output logic signed [15:0] pid_output,     // Wartość korekcji dla miksera silników
    output logic signed [WIDTH-1:0] pid_error_out,
    output logic signed [31:0] pid_integral_out,
    output logic signed [WIDTH-1:0] pid_derivative_out
);

    // PID internal signals
    logic signed [WIDTH-1:0] pid_setpoint = '0; // Target angle = 0 (Q8.7)
    logic signed [WIDTH-1:0] pid_error;
    logic signed [31:0] pid_integral; // Q8.7 (24 integer bits, 8 fractional bits)
    logic signed [WIDTH-1:0] pid_derivative;
    logic signed [WIDTH-1:0] pid_last_error;
    logic [3:0] calc_prescale; // Prescaler for PID calculations

    // Anti-windup: Integral clamping limits
    // Limit the integral term's contribution to the final output to approx. +/- 250us
    // Limit = (250 * 2^17) / Ki_max_approx = (250 * 131072) / 4 = 8192000
    localparam signed [31:0] INTEGRAL_MAX = 32'sd8192000;
    localparam signed [31:0] INTEGRAL_MIN = -32'sd8192000;
    logic signed [47:0] p_term, i_term, d_term;
    
    // PID calculation logic
    always_ff @(posedge clk) begin
        logic signed [31:0] integral_next; // Deklaracja przeniesiona na początek bloku
        if (!rst_n) begin // Reset PID
            pid_integral <= '0;
            integral_next = '0;
            pid_last_error <= '0;
            pid_error <= '0;
            calc_prescale <= '0;
            p_term              <= '0;
            i_term              <= '0;
            d_term              <= '0;
            pid_output          <= '0;
            pid_error_out       <= '0;
            pid_integral_out    <= '0;
            pid_derivative_out  <= '0;

        end else begin
            if (enable) begin // Wykonuj obliczenia tylko gdy jest nowa próbka

                calc_prescale <= 4'b1;

                pid_error <= pid_setpoint - estim_roll;

                integral_next = pid_integral + pid_error;
                if (integral_next > INTEGRAL_MAX) begin
                    pid_integral <= INTEGRAL_MAX;
                end else if (integral_next < INTEGRAL_MIN) begin
                    pid_integral <= INTEGRAL_MIN;
                end else begin
                    pid_integral <= integral_next;
                end

                pid_last_error <= pid_error;
            end

            case (calc_prescale)
            4'd0    : begin
               
            end
            4'd1    : begin
                p_term <= pid_error * Kp;
                calc_prescale <= calc_prescale + 1;
            end
             4'd2    : begin
                 i_term <= pid_integral * Ki;
                 calc_prescale <= calc_prescale + 1;
            end
             4'd3    : begin
                 d_term <= pid_derivative * Kd;
                 calc_prescale <= calc_prescale + 1;
            end
             4'd4    : begin        //nie potrzeba flagi gotowosci PID poniewaz output przypisywany jest dopiero tutaj
                pid_output <= (p_term + i_term + d_term) >>> (19 - 2);
            end
             4'd5    : begin 
                pid_error_out <= pid_error;
                pid_integral_out <= pid_integral;
                pid_derivative_out <= pid_derivative;
                calc_prescale <= calc_prescale + 1;
            end

            default 	:
                calc_prescale <= 4'b0;
             
        endcase

        end
    end

    assign pid_derivative = pid_error - pid_last_error;

    // Obliczenia składowych PID
    // pid_error, pid_derivative są w formacie Q8.7
    // pid_integral jest 32-bitowy, akumuluje wartości Q8.7, więc jest to Q24.7
    // Wzmocnienia Kp, Ki, Kd są w formacie Q4.12
    // p_term, d_term: Q8.7 * Q4.12 -> Q12.19
    // i_term: Q24.7 * Q4.12 -> Q28.19
   
    
        
        
    // assign p_term = pid_error * Kp;
    // assign i_term = pid_integral * Ki;
    // assign d_term = pid_derivative * Kd;

    // Sumowanie składowych i skalowanie do wartości całkowitej.
    // Część ułamkowa sumy ma 7 + 12 = 19 bitów.
    // Przesuwamy o 17 bitów (zamiast 19), aby uzyskać część całkowitą
    // i jednocześnie wzmocnić sygnał 4-krotnie (2^2 = 4).

    // assign pid_output = (p_term + i_term + d_term) >>> (19 - 2);

    // Wyjścia do debugowania
    // assign pid_error_out = pid_error;
    // assign pid_integral_out = pid_integral;
    // assign pid_derivative_out = pid_derivative;

endmodule