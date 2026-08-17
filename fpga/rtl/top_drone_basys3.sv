/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_drone_basys3 (
    input  wire clk,
    input  wire btnC,
    input  wire btnL,
    input  wire btnR,
    input wire [15:0] sw,
    input wire btnU,
    output wire JB10,
    output wire [7:1] JC, //ostatecznie lepiej zrezygnowac z tablicy JC i zrobic ladne nazwy w .xdc
    input wire JC_input,
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

    logic [7:0] pwm_data;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    logic [7:0] safe_start = 0;
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signals assignments
     */

   

    /**
     * FPGA submodules placement
     */

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

    // Mirror pclk on a pin for use by the testbench;
    // not functionally required for this design to work.

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

    assign pwm_data= (sw[1]) ? 8'd10 : 8'd15;
    wire btnU_tick;

      debounce btnU_db (
         .clk(pclk),
         .reset(1'b0),
         .sw(btnU),
         .db_level(),
         .db_tick(btnU_tick)
      );
   wire btnR_pulse;
      debounce btnR_db (
         .clk(pclk),
         .reset(1'b0),
         .sw(btnR),
         .db_level(),
         .db_tick(btnR_pulse)
      );
      wire btnL_pulse;
      debounce btnL_db (
         .clk(pclk),
         .reset(1'b0),
         .sw(btnL),
         .db_level(),
         .db_tick(btnL_pulse)
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

      assign JC[3] = copi;
      assign JC[7] = copi;

      assign JC[2] =sclk;
      assign JC[6] = sclk;

      assign poci = JC_input;
      assign JC[5] = poci; //porty w xdc sa inaczej numerowane ofc smh 🙄

      assign JC[1] =cs_n;
      assign JC[4] = cs_n;

    top_drone u_top_drone (
        .clk  (pclk),
        .rst  (),
        .d_in (pwm_data),
        .enable(sw[0]),
        .pwm(JB10),
        .copi(copi),
        .sclk(sclk),
        .poci(poci),
        .cs_n(cs_n),
        .spi_start(btnU_tick),
        .an,
        .sseg,
        .led(led[15:0]),
        .button(btnU),
        .btnL_pulse(btnL_pulse),
        .btnR_pulse(btnR_pulse),
        .btnReset(btnC_level),
        .sw(sw)
        );

        
    
endmodule
