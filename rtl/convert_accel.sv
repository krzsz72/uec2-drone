//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | convert accel      (WIP)                     |
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


module convert_accel #(
   parameter int WIDTH=16 //inout registers width
   )
   (
    input logic clk, rst_n,
    input logic signed [WIDTH-1:0] accel_raw_data,
    input logic data_latch,
    output logic signed [WIDTH-1:0] angle_raw,
    output logic signed [WIDTH-1:0] angle_deg, //tak w zasadzie kosmetyczne bo chcemy pelna rozdzielczosc
    output logic signed [WIDTH-1:0] latched_raw,
    output logic signed [39:0] mul_result
   );

   //uzywamy fixed point arithmetic Q15.24
   logic signed [39:0] mul_result_nxt;
   logic signed [WIDTH-1:0] angle_raw_nxt;
   logic signed [WIDTH-1:0] angle_deg_nxt;
   logic signed [WIDTH-1:0] latched_raw_nxt;
   
   // stała do przemnożenia XL - RAW * (180/(pi * 4098)) * 2^24 = 234569
   localparam logic signed [31:0] XL_COEFF = 32'sd234569;

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
         angle_raw_nxt = {accel_raw_data[7:0],accel_raw_data[15:8]};
      end else begin
         mul_result_nxt = angle_raw * XL_COEFF;
         angle_deg_nxt = mul_result_nxt[39:24] ;
         latched_raw_nxt = angle_raw ;
      end
     end

endmodule