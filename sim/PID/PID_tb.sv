`timescale 1ns/1ps

module PID_tb;

    localparam int WIDTH = 16;
    localparam time CLOCK_PERIOD = 10ns; // 100 MHz

    logic clk;
    logic rst_n;
    logic enable;
    logic signed [WIDTH-1:0] estim_roll;
    logic signed [15:0] Kp;
    logic signed [15:0] Ki;
    logic signed [15:0] Kd;
    logic signed [15:0] pid_output;
    logic signed [WIDTH-1:0] pid_error_out;
    logic signed [31:0] pid_integral_out;
    logic signed [WIDTH-1:0] pid_derivative_out;

    PID #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .estim_roll(estim_roll),
        .Kp(Kp),
        .Ki(Ki),
        .Kd(Kd),
        .pid_output(pid_output),
        .pid_error_out(pid_error_out),
        .pid_integral_out(pid_integral_out),
        .pid_derivative_out(pid_derivative_out)
    );

    initial begin
        clk = 1'b0;
        forever #(CLOCK_PERIOD / 2) clk = ~clk;
    end

    task automatic check_reset_state;
        begin
            @(posedge clk);
            #1;
            assert (dut.pid_integral == 32'sd0)
                else $error("Integral was not reset: %0d", dut.pid_integral);
            assert (dut.pid_last_error == '0)
                else $error("Last error was not reset: %0d", dut.pid_last_error);
            assert (dut.pid_error == '0)
                else $error("Error was not reset: %0d", dut.pid_error);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        enable = 1'b0;
        estim_roll = '0;
        Kp = 16'sd4096; // 1.0 in Q4.12
        Ki = 16'sd0;
        Kd = 16'sd0;

        check_reset_state();

        rst_n = 1'b1;
        estim_roll = 16'sd128; // +1 degree in Q8.7
        repeat (2) @(posedge clk);
        assert (dut.pid_error == 16'sd0)
            else $error("Disabled PID changed error: %0d", dut.pid_error);

        enable = 1'b1;
        @(posedge clk);
        #1;
        assert (dut.pid_error == -16'sd128)
            else $error("Unexpected error: %0d", dut.pid_error);
        assert (dut.pid_integral == -32'sd128)
            else $error("Unexpected integral: %0d", dut.pid_integral);

        repeat (8) @(posedge clk);
        $display("PID smoke test complete at %0t ns: error=%0d integral=%0d output=%0d",
                 $time, pid_error_out, pid_integral_out, pid_output);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "PID testbench timed out");
    end

endmodule
