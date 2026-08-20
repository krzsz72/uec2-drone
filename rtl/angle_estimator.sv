//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | angle estimator                              |
//      |______________________________________________|
//
// Author: Krzysztof Piziak
//******************************************************************************


module angle_estimator #(
   parameter int WIDTH=16 //inout registers width
   )
   (
    input logic clk, rst_n,
    input logic signed [39:0] accel_data,
    input logic signed [39:0] gyro_data,
    output logic signed [WIDTH-1:0] angle_deg  //output for PID
   );


   //uzywamy fixed point arithmetic Q8.7
   logic signed [39:0] angle_deg_nxt;
   logic signed [39:0] eval_error,eval_error_nxt   ;
   logic signed [39:0] eval_gyro,eval_gyro_nxt    ;

   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         angle_deg <= '0;
         eval_error     <='0;
         eval_gyro      <='0;
      end else begin
         angle_deg      <= angle_deg_nxt[32:17];    //[20+(WIDTH/2)-1:20-(WIDTH/2)];
         eval_error     <= eval_error_nxt;
         eval_gyro      <= eval_gyro_nxt;
      end
   end

   // fsm block
   always_comb begin
      
      eval_gyro_nxt = eval_gyro + gyro_data;
      eval_error_nxt = accel_data - eval_gyro;
      angle_deg_nxt = eval_gyro + (eval_error >>> 8);

   end

endmodule