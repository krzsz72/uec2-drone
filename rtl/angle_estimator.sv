//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | angle estimator    (WIP)                     |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        WIDTH  = 32  bits                     | 
//      |                                              |
//      |                 WIP                          |
//      |                                              |
//  ----| ready                                   sclk |----
//  ==8=| reg_tx                                reg_rx |=8==
//  ----| poci                                    copi |----
//      |                                         done |----
//  ----| clk                                     busy |----
//      |                                         cs_n |----
//      |______________________________________________|
//
//** Description ***************************************************************
//
//  An SPI interface controller with inout registers and serial communication copi poci wires.
//
//** Sample Instantiation ******************************************************
//
//    spi_controller #(
//        .WIDTH(16)
//    )
//    spi_controller(
//        .clk(clk),
//        .ready(ready),
//        .sclk(sclk),
//        .cs_n(cs_n),
//        .reg_rx(reg_rx),
//        .reg_tx(reg_tx),
//        .poci(poci),
//        .copi(copi),
//        .busy(busy),
//        .done(done)
//    );
//
//** Signals: ************************************************************
//
//  1) clk: High speed system clock (typically 100 MHz)
//
//  2) ready: Activates the full-duplex transmission when logic high.
//
//  3) sclk: SPI transmission clock. Due to posedge clk logic it is half of clk. 
//
//  4) reg_rx/reg_tx : internal register holding the transceived data.
//
//  5) poci/copi : wires for serial transmission. Containt single bit informaation 
//                 that is being currently transceived
//


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
         if(angle_deg_nxt[39] == 1'b0 && (|angle_deg_nxt[38:32]==1'b1)) begin
            angle_deg <= 16'hFFFF;
         end else if(angle_deg_nxt[39] == 1'b1 && (|angle_deg_nxt[38:32]==1'b1))begin
            angle_deg <= 16'h8000;
         end else begin
            angle_deg      <= angle_deg_nxt[32:17];    //[20+(WIDTH/2)-1:20-(WIDTH/2)];
         end

         eval_error     <= eval_error_nxt;
         eval_gyro      <= eval_gyro_nxt;
      end
   end

   // fsm block
   always_comb begin
      
      eval_gyro_nxt = angle_deg + gyro_data;
      eval_error_nxt = accel_data - eval_gyro;
      angle_deg_nxt = eval_gyro + (eval_error >>> 8);

     end

endmodule