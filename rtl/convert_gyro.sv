//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | convert gyro                                 |
//      |______________________________________________|
//
// Author: Krzysztof Piziak
//******************************************************************************


module convert_gyro #(
   parameter int WIDTH=16 //inout registers width
   )
   (
    input logic clk, rst_n,
    input logic signed [WIDTH-1:0] gyro_raw_data,
    input logic data_latch,
    output logic signed [WIDTH-1:0] angle_raw, 
    output logic signed [WIDTH-1:0] angle_deg, //obciety debug
    output logic signed [WIDTH-1:0] latched_raw, //debug
    output logic signed [39:0] mul_result
   );

   //uzywamy fixed point arithmetic Q15.24
   logic signed [39:0] mul_result_nxt;
   logic signed [WIDTH-1:0] angle_raw_nxt;
   logic signed [WIDTH-1:0] angle_deg_nxt;
   logic signed [WIDTH-1:0] latched_raw_nxt;
   
   localparam logic signed [39:0] GYRO_COEF = 40'sd176;  // 176 wynika z (1/6.6khz) * 0.07deg/s

   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         angle_deg <= '0;
         angle_raw <= '0;
         mul_result <= '0;
         latched_raw <= '0;

      end else begin
         angle_deg <= angle_deg_nxt;
         angle_raw <= angle_raw_nxt;
         mul_result <= mul_result_nxt;
         latched_raw <= latched_raw_nxt;
      end
   end

   // fsm block
   always_comb begin
      angle_deg_nxt = angle_deg;
      angle_raw_nxt = angle_raw;
      mul_result_nxt = mul_result;

      if(!data_latch)begin
         angle_raw_nxt = {gyro_raw_data[7:0],gyro_raw_data[15:8]};
      end else begin
         mul_result_nxt = angle_raw * GYRO_COEF;
         latched_raw_nxt = angle_raw ; // debug
         angle_deg_nxt = mul_result_nxt[31:16] ; //obceity debug, czesc calkowita i setna
      end
     end

endmodule