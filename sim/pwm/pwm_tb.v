//*************************************************************
//
// TESTBENCH for PWM
//
//*************************************************************
module pwm_tb();

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

//** INSTANTIATE THE DEVICE UNDER TEST (DUT)*********************


    pwm #(
        .MAX_TICK(4)
    ) test_pwm(
        .clk(clk),
        .enable(enable),
        .d_in(d_in),
        .pwm(PWM),
        .cnt(cnt)
    );


//** CLOCK ****************************************************

    always begin
        clk = 1'b1;
        #(clock_T_ns/2);
        clk = 1'b0;
        #(clock_T_ns/2);
    end

//** DUT Tests ************************************************ 

    initial begin

        initial_conditions();
        
    /* Begin tests */
        clk = 0;
        enable = 0;
        d_in = 0;

        // Wait a bit for global reset/startup
        #100;
        
        enable = 1;
        d_in = 8'd10; 
        
        #12000;
        
        d_in = 8'd50;
        
        #24000;
        
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