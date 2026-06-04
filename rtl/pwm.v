//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | PWM  d_in/MAX_PWM fill%                      |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        MAX_TICK  = 14'd9999                  |
//      |        MAX_PWM   = 8'd199                    |
//      |        eg. d_in = 50 ===== 50/200 fill       |
//      |                                              |
//  ----| enable                                       |
//  ==8=| d_in                                 PWM_out |----
//      |                                          cnt |==8=
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
//  3) d_in: Is used to determine the duty cycle of the PWM. This input has a 
//     bit width defined by the B parameter.
//
//** Signal Outputs ************************************************************
//
//  1) PWM: Provides a Pulse Width Modulated signal. The frequency is 
//     determined as described in the comments.
//
//  2) cnt: Provides access to the PWM register. 
//

module pwm #(
   parameter MAX_TICK=14'd9999, //prescaler
   parameter MAX_PWM=8'd199    //counter clamp for 100us pwm 50hz: 20ms / 100us = 200 steps

)
   (
    input wire clk, enable,
    input wire [7:0] d_in,
    output reg pwm,
    output reg [7:0] cnt
   );

   
   // signal declaration
   reg [7:0] D;   //data buffer reg
   reg tick_100us;
   reg [13:0] prescale_cnt;


   always @(posedge clk) begin
      if(!enable)begin
         tick_100us<=1'b0;
         prescale_cnt<=14'd0;
      end else begin
         if(prescale_cnt>=MAX_TICK)begin
            tick_100us<=1'b1;
            prescale_cnt<=14'd0;
         end else begin
            tick_100us<=1'b0;
            prescale_cnt<=prescale_cnt+1'd1;
         end
      end
   end

   always @(posedge clk)begin
       if(!enable)begin
         pwm<=1'b0;
         cnt<=8'd0;
         D<=8'd0;
      end else begin 
         if(tick_100us)begin
            if(cnt>=MAX_PWM)begin
               cnt<=8'd0;
               if(d_in>8'd200) D<=8'd200;
               else D<=d_in;
            end else begin
               cnt<=cnt+1'd1;
            end
         end
      end

      pwm <= (cnt<D)? 1'b1 : 1'b0;
   end





endmodule