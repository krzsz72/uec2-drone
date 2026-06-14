`timescale 1ns / 1ps

module pid_3axis_tb;

    // Clock and Reset
    logic clk;
    logic rst;
    logic enable;

    // Parameters matches pid_3axis
    localparam W = 16;
    localparam K_W = 16;
    localparam SCALING_FACTOR = 8;

    // PID Coefficients
    logic signed [K_W-1:0] kp_pitch, ki_pitch, kd_pitch;
    logic signed [K_W-1:0] kp_roll,  ki_roll,  kd_roll;
    logic signed [K_W-1:0] kp_yaw,   ki_yaw,   kd_yaw;

    // Inputs
    logic signed [W-1:0] actual_pitch, actual_roll, actual_yaw;
    logic signed [W-1:0] desired_pitch, desired_roll, desired_yaw;

    // Outputs
    logic signed [W-1:0] pid_pitch_out, pid_roll_out, pid_yaw_out;

    // Instantiate Unit Under Test (UUT)
    pid_3axis #(
        .W(W),
        .K_W(K_W),
        .SCALING_FACTOR(SCALING_FACTOR)
    ) uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        
        .kp_pitch(kp_pitch), .ki_pitch(ki_pitch), .kd_pitch(kd_pitch),
        .kp_roll(kp_roll),   .ki_roll(ki_roll),   .kd_roll(kd_roll),
        .kp_yaw(kp_yaw),     .ki_yaw(ki_yaw),     .kd_yaw(kd_yaw),
        
        .actual_pitch(actual_pitch), .actual_roll(actual_roll), .actual_yaw(actual_yaw),
        .desired_pitch(desired_pitch), .desired_roll(desired_roll), .desired_yaw(desired_yaw),
        
        .pid_pitch_out(pid_pitch_out),
        .pid_roll_out(pid_roll_out),
        .pid_yaw_out(pid_yaw_out)
    );

    // Clock generation (100MHz for example)
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        int tests_passed = 1;
        // Initialize Inputs
        clk = 0;
        rst = 1;
        enable = 0;

        // Set PID gains (e.g., Kp = 1.0 -> 256 in Q8.8, Kd = 0.5 -> 128 in Q8.8, Ki = 0.1 -> 25)
        kp_pitch = 16'd256; ki_pitch = 16'd25; kd_pitch = 16'd128;
        kp_roll  = 16'd256; ki_roll  = 16'd25; kd_roll  = 16'd128;
        kp_yaw   = 16'd512; ki_yaw   = 16'd0;  kd_yaw   = 16'd0; // Yaw usually has different gains

        actual_pitch = 0; actual_roll = 0; actual_yaw = 0;
        desired_pitch = 0; desired_roll = 0; desired_yaw = 0;

        // Reset Sequence
        #20;
        rst = 0;
        #20;

        $display("--- Starting 3-Axis PID Tests ---");

        // Test 1: Pitch Error Positive
        desired_pitch = 16'd100;
        enable = 1; #10; enable = 0;
        #20;
        $display("Test 1 - Pitch Error: desired=%0d, actual=%0d => Output=%0d (Expected: 150)", desired_pitch, actual_pitch, pid_pitch_out);
        if (pid_pitch_out !== 16'sd150) begin
            $error("Test 1 FAILED! Expected: 150, Got: %0d", pid_pitch_out);
            tests_passed = 0;
        end

        // Reset state for next test
        rst = 1; #20; rst = 0; #20;
        desired_pitch = 0; // Clear previous input

        // Test 2: Roll Error Negative
        desired_roll = -16'd50;
        enable = 1; #10; enable = 0;
        #20;
        $display("Test 2 - Roll Error: desired=%0d, actual=%0d => Output=%0d (Expected: -75)", desired_roll, actual_roll, pid_roll_out);
        if (pid_roll_out !== -16'sd75) begin
            $error("Test 2 FAILED! Expected: -75, Got: %0d", pid_roll_out);
            tests_passed = 0;
        end

        // Reset state for next test
        rst = 1; #20; rst = 0; #20;
        desired_roll = 0;

        // Test 3: Yaw Error 
        desired_yaw = 16'd200;
        enable = 1; #10; enable = 0;
        #20;
        $display("Test 3 - Yaw Error: desired=%0d, actual=%0d => Output=%0d (Expected: 400)", desired_yaw, actual_yaw, pid_yaw_out);
        if (pid_yaw_out !== 16'sd400) begin
            $error("Test 3 FAILED! Expected: 400, Got: %0d", pid_yaw_out);
            tests_passed = 0;
        end

        // Reset state for next test
        rst = 1; #20; rst = 0; #20;
        desired_yaw = 0;

        // Test 4: Simultaneous execution
        desired_pitch = 16'd10;
        actual_pitch = 16'd20; // error = -10. Out approx -10
        desired_roll = 16'd50;
        actual_roll = 16'd10; // error = +40. Out approx 40
        desired_yaw = -16'd30;
        actual_yaw = 16'd0; // error = -30. Out approx -60
        
        enable = 1; #10; enable = 0;
        #20;
        $display("Test 4 - Simultaneous:");
        $display("  Pitch Out: %0d (Expected: -15)", pid_pitch_out);
        if (pid_pitch_out !== -16'sd15) begin
            $error("Test 4 Pitch FAILED! Expected: -15, Got: %0d", pid_pitch_out);
            tests_passed = 0;
        end
        
        $display("  Roll Out:  %0d (Expected: 60)", pid_roll_out);
        if (pid_roll_out !== 16'sd60) begin
            $error("Test 4 Roll FAILED! Expected: 60, Got: %0d", pid_roll_out);
            tests_passed = 0;
        end
        
        $display("  Yaw Out:   %0d (Expected: -60)", pid_yaw_out);
        if (pid_yaw_out !== -16'sd60) begin
            $error("Test 4 Yaw FAILED! Expected: -60, Got: %0d", pid_yaw_out);
            tests_passed = 0;
        end

        $display("--- 3-Axis PID Tests Complete ---");
        if (tests_passed) begin
            $display("RESULT: ALL TESTS PASSED SUCCESSFULLY");
        end else begin
            $display("RESULT: SOME TESTS FAILED");
        end
        $finish;
    end

endmodule
