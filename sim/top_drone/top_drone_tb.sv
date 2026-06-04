
module top_drone_tb();

    /* Module Inputs */
        reg clk;
        reg enable;
        reg [7:0] d_in;

    /* Module Outputs */
        wire PWM;
        wire [7:0] cnt;

//** CONSTANT DECLARATION ************************************

   /* Local */

    /* Clock simulation */
        localparam clock_T_ns = 10;     // 100 MHz



    /* Testbench Specific */


//** SYMBOLIC STATE DECLARATIONS ******************************

//** SIGNAL DECLARATIONS **************************************

     reg [31:0] i;

//** INSTANTIATE THE UNIT UNDER TEST (UUT)*********************


    top_drone #(
        .MAX_TICK(4)
    ) test_top(
        .clk(clk),
        .enable(enable),
        .d_in(d_in),
        .pwm(PWM)
    );

//** ASSIGN STATEMENTS ****************************************

//** CLOCK ****************************************************

    always begin
        clk = 1'b1;
        #(clock_T_ns/2);
        clk = 1'b0;
        #(clock_T_ns/2);
    end

//** UUT Tests ************************************************ 

    initial begin

        initial_conditions();
        
    /* Begin tests */
        // 1. Initialize Inputs
        clk = 0;
        enable = 0;
        d_in = 0;

        // Wait a bit for global reset/startup
        #100;
        
        // 2. Enable the PWM module and request a "1 ms" pulse
        enable = 1;
        d_in = 8'd10; 
        
        // Let it run for slightly more than one full (scaled) frame.
        // 1 Frame = 200 ticks. 1 Tick = 5 clocks (50ns). 
        // 1 Frame = 10,000ns. Let's wait 12,000ns to see the frame loop.
        #12000;
        
        // 3. Test the Shadow Register (Double Buffering)
        // Change the duty cycle mid-frame to 50 (a "5 ms" pulse)
        d_in = 8'd50;
        
        // Wait another two full frames to watch it finish the current 
        // short pulse, and then output the new longer pulse safely.
        #24000;
        
        // 4. Test Disable behavior
        enable = 0;
        #1000;
        $finish;
    end

//** Tasks **************************************************** 

    task initial_conditions(); begin
        repeat(5) @(posedge clk)
        enable = 1'b0;
        end
    endtask
    
    task delay_N_clocks(input integer N); begin
        repeat(N) @(posedge clk);
        end
    endtask
    
endmodule