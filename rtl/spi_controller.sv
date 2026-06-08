//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | SPI interface                                |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        WIDTH  = 8  bits                      | 
//      |                                              |
//      |                                              |
//      |                                              |
//  ----| start                                       |
// ==15=| d_in                                 PWM_out |----
//      |                                          cnt |==15=
//  ----| clk                                          |
//      |______________________________________________|
//
//** Description ***************************************************************
//
//  A Pulse Width Modulator (PWM). When enabled, the count advances on the 
//  rising edge of the system clock.
//
//** Sample Instantiation ******************************************************
//
//    PWM #(
//        .MAX_TICK(MAX_TICK),
//        .MAX_PWM(PAX_PWM)
//    )
//    PWM(
//        .clk(clk),
//        .enable(enable),
//        .d_in(d_in),
//        .PWM(PWM),
//        .cnt(cnt)
//    );
//
//** Signal Inputs: ************************************************************
//
//  1) clk: High speed system clock (typically 100 MHz)
//
//  2) enable: Activates the PWM when logic high. PWM idles low when deactivated.
//
//  3) d_in: Is used to determine the duty cycle of the PWM. currently 1us resolution
//
//** Signal Outputs ************************************************************
//
//  1) PWM: Provides a Pulse Width Modulated signal. The frequency is 
//     determined as described in the comments.
//
//  2) cnt: Provides access to the PWM register. 
//

module spi_controller #(
   parameter logic [3:0] WIDTH=8 //inout registers width
   )
   (
    input logic clk, start,
    output logic sclk,
   //controller receive
    output logic [WIDTH-1:0] reg_rx,
    input logic poci,
   //controller transmit
    input logic [WIDTH-1:0] reg_tx,
    output logic copi
   );

   typedef enum logic [1:0] {IDLE, BUSY, DONE} fsm_state_t;
    fsm_state_t state, state_nxt = IDLE;

   logic [WIDTH-1:0] reg_rx_nxt;
   logic copi_nxt, sclk_nxt, busy, busy_nxt, done, done_nxt;
   logic [WIDTH-1:0] bit_ctr, bit_ctr_nxt;

   //seq logic
   always_ff@(posedge clk)begin
      copi<=copi_nxt;
      reg_rx<=reg_rx_nxt;
      sclk<=sclk_nxt;
      done<=done_nxt;
      bit_ctr<=bit_ctr_nxt;
      busy<=busy_nxt;
      state<=state_nxt;
   end

   //fsm logic
   always_comb@(posedge clk)begin
      case(state)
         IDLE: begin
            bit_ctr_nxt='0;
            if(start) state_nxt=BUSY;
         end
         BUSY: begin
            if(bit_ctr==WIDTH) state_nxt=DONE;
            bit_ctr_nxt = bit_ctr+1;
         end
         DONE: begin
            state_nxt=IDLE;
         end
         default: state_nxt=IDLE;
      endcase
   end

   //reg logic
   always_comb@(posedge clk)begin
      case(state)
         IDLE: begin
            sclk_nxt='1;
            busy_nxt='0;
            done_nxt='0;
         end
         BUSY: begin
            sclk_nxt=~sclk;
            busy_nxt='1;
            reg_rx_nxt = {reg_rx[WIDTH-2:0],poci};
            copi_nxt = reg_tx[WIDTH-1-bit_ctr];
         end
         DONE: begin
            done_nxt='1;
         end

      endcase
   end

endmodule