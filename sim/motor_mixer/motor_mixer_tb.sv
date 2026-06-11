`timescale 1ns / 1ps

module motor_mixer_tb;

    reg clk;
    reg rst_n;
    reg [1:0] mode;
    reg [15:0] throttle;
    reg signed [15:0] pid_pitch;
    reg signed [15:0] pid_roll;
    reg signed [15:0] pid_yaw;

    wire [14:0] m1_width;
    wire [14:0] m2_width;
    wire [14:0] m3_width;
    wire [14:0] m4_width;

    motor_mixer uut (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .throttle(throttle),
        .pid_pitch(pid_pitch),
        .pid_roll(pid_roll),
        .pid_yaw(pid_yaw),
        .m1_width(m1_width),
        .m2_width(m2_width),
        .m3_width(m3_width),
        .m4_width(m4_width)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        mode = 2'b00; // INIT
        throttle = 16'd1000;
        pid_pitch = 0;
        pid_roll = 0;
        pid_yaw = 0;

        #20;
        rst_n = 1;
        #20;

        $display("Testing INIT state (Expected outputs: 900)");
        #10;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);

        $display("\nTesting ARMED state (Expected outputs: 1000)");
        mode = 2'b01;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);

        $display("\nTesting RUN state with throttle only (Expected outputs: 1500)");
        mode = 2'b10;
        throttle = 16'd1500;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);

        $display("\nTesting Pitch Nose Down: pitch = +100 (Expected: M1/M3 -100 (1400), M2/M4 +100 (1600)... wait, let's look at equations)");
        pid_pitch = 16'd100;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);
        pid_pitch = 0;

        $display("\nTesting Roll Right: roll = +100");
        pid_roll = 16'd100;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);
        pid_roll = 0;

        $display("\nTesting Yaw Right: yaw = +100");
        pid_yaw = 16'd100;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);
        pid_yaw = 0;

        $display("\nTesting Clamping MIN limit: Throttle 1100, Pitch +300");
        throttle = 16'd1100;
        pid_pitch = 16'd300;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);

        $display("\nTesting Clamping MAX limit: Throttle 1900, Pitch +300");
        throttle = 16'd1900;
        pid_pitch = 16'd300;
        #20;
        $display("M1: %0d, M2: %0d, M3: %0d, M4: %0d", m1_width, m2_width, m3_width, m4_width);

        $finish;
    end

endmodule