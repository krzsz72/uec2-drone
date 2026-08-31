//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | Project top module                           |
//      |______________________________________________|
//
// Author: Krzysztof Piziak, Szymon Rybak
//******************************************************************************


module top_drone_basys3 (
    input  wire clk,
    input  wire btnC,
    input wire btnU,
    input wire [15:0] sw,
    output wire [3:0] motor_pwm,
    output wire JC_csn,
    input wire JC_poci,
    output wire JC_sclk,
    output wire JC_copi,
    output wire [7:0] sseg,
    output wire [3:0] an,
    output wire [15:0] led

    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire clk_in, clk_fb, clk_ss, clk_out;
    wire locked;
    wire pclk;
    wire pclk_mirror;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    logic [7:0] safe_start = 0;
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes



    IBUF clk_ibuf (
        .I(clk),
        .O(clk_in)
    );

    MMCME2_BASE #(
        .CLKIN1_PERIOD(10.000),
        .CLKFBOUT_MULT_F(10.000),
        .CLKOUT0_DIVIDE_F(10.000)
    ) clk_in_mmcme2 (
        .CLKIN1(clk_in),
        .CLKOUT0(clk_out),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(clk_fb),
        .CLKFBOUTB(),
        .CLKFBIN(clk_fb),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(1'b0)
    );

    BUFH clk_out_bufh (
        .I(clk_out),
        .O(clk_ss)
    );

    always_ff @(posedge clk_ss)
        safe_start <= {safe_start[6:0],locked};

    BUFGCE #(
        .SIM_DEVICE("7SERIES")
    ) clk_out_bufgce (
        .I(clk_out),
        .CE(safe_start[7]),
        .O(pclk)
    );

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(pclk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );


    /** #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
     *  Project functional top module
     *  #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
     */

    wire btnU_tick;

      debounce btnU_db (
         .clk(pclk),
         .reset(1'b0),
         .sw(btnU),
         .db_level(),
         .db_tick(btnU_tick)
      );
   
      wire btnC_level;
      debounce btnC_db (
         .clk(pclk),
         .reset(1'b0),
         .sw(btnC),
         .db_level(btnC_level),
         .db_tick()
      );
      wire copi;
      wire sclk;
      wire poci;
      wire cs_n;

      assign JC_copi = copi;

      assign JC_sclk =sclk;

      assign poci = JC_poci;

      assign JC_csn =cs_n;

    top_drone u_top_drone (
        .clk  (pclk),
        .enable(sw[0]), // General PWM enable switch
        .motor_pwm_out(motor_pwm),
        .copi(copi),
        .sclk(sclk),
        .poci(poci),
        .cs_n(cs_n),
        .spi_start(btnU_tick),
        .an,
        .sseg,
        .led(led[15:0]),
        .btnReset(btnC_level),
        .sw(sw)
        );

        
    
endmodule
