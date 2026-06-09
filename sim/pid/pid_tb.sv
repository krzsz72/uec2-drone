`timescale 1ns / 1ps

module pid_tb;

    logic clk;
    logic rst;
    logic enable;

    logic signed [15:0] kp;
    logic signed [15:0] ki;
    logic signed [15:0] kd;

    logic signed [15:0] actual_val;
    logic signed [15:0] desired_val;

    logic signed [15:0] pid_out;

    pid #(
        .W(16),
        .K_W(16),
        .SCALING_FACTOR(8)
    ) dut (
        .clk,
        .rst,
        .enable,
        .kp,
        .ki,
        .kd,
        .actual_val,
        .desired_val,
        .pid_out
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Enable generation (pulsed)
    initial begin
        enable = 0;
        forever begin
            #190 enable = 1;
            #10 enable = 0;
        end
    end

    // Test sequence
    initial begin
        rst = 1;
        kp = 16'd256; // 1.0 in 8.8 fixed point
        ki = 16'd0;
        kd = 16'd0;
        actual_val = 16'd0;
        desired_val = 16'd0;

        #100;
        rst = 0;

        // Test P term
        desired_val = 16'd100;
        #500;
        
        // Output should be roughly 100
        if (pid_out !== 16'd100) $error("P-term failed. Expected 100, got %d", pid_out);

        // Test I term
        kp = 16'd0;
        ki = 16'd10;
        #500;
        
        if (pid_out == 16'd0) $error("I-term failed to accumulate.");

        // Test D term
        ki = 16'd0;
        kd = 16'd128; // 0.5 in 8.8
        actual_val = 16'd50; // sudden change in error
        #200;

        if (pid_out == 16'd0) $error("D-term failed to react to derivative.");

        $display("Test finished.");
        $finish;
    end

endmodule
