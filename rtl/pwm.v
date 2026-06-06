//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | PWM  d_in/MAX_PWM fill%                      |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        MAX_TICK  = 7'd99                     |
//      |        MAX_PWM   = 15'd19999                 |
//      |        eg. d_in = 1000 ===== 10000/20000 fill|
//      |                                              |
//  ----| enable                                       |
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

module pwm #(
   parameter MAX_TICK=7'd99, //prescaler
   parameter MAX_PWM=15'd19999    //counter clamp for 1us pwm 50hz: 20ms / 1us = 20000 steps

)
   (
    input wire clk, enable,
    input wire [14:0] d_in,
    output reg pwm,
    output reg [14:0] cnt
   );

   
   // signal declaration
   reg [14:0] D;   //data buffer reg
   reg tick_100us;
   reg [6:0] prescale_cnt;


   always @(posedge clk) begin
      if(!enable)begin
         tick_100us<=1'b0;
         prescale_cnt<=7'd0;
      end else begin
         if(prescale_cnt>=MAX_TICK)begin
            tick_100us<=1'b1;
            prescale_cnt<=7'd0;
         end else begin
            tick_100us<=1'b0;
            prescale_cnt<=prescale_cnt+1'd1;
         end
      end
   end

   always @(posedge clk)begin
       if(!enable)begin
         pwm<=1'b0;
         cnt<=15'd0;
         D<=15'd0;
      end else begin 
         if(tick_100us)begin
            if(cnt>=MAX_PWM)begin
               cnt<=15'd0;
               if(d_in>8'd20000) D<=15'd20000;
               else D<=d_in;
            end else begin
               cnt<=cnt+1'd1;
            end
         end
      end

      pwm <= (cnt<D)? 1'b1 : 1'b0;
   end





endmodule