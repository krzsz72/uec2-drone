//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | unit converter     (WIP)                     |
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


module unit_converter #(
   parameter logic [5:0] WIDTH=16 //inout registers width
   )
   (
    input logic clk, rst_n, //ready    teoretycznie nie potrzebujemy jezeli dzielimy przez stale 6.66kHz?
    input logic [WIDTH-1:0] gyro_raw_data,
    output logic [WIDTH-1:0] angle_raw,
    output logic [WIDTH-1:0] angle_deg
   );

   //uzywamy fixed point arithmetic Q15.24
   logic signed [39:0] mul_result;
   logic signed [WIDTH-1:0] angle_raw_nxt;
   logic signed [WIDTH-1:0] angle_deg_nxt;
   
   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         angle_deg <= '0;
         angle_raw <= '0;

      end else begin
        angle_deg <= angle_deg_nxt;
        angle_raw <= angle_raw_nxt;

      end
   end

   // fsm block
   always_comb begin
      angle_raw_nxt = gyro_raw_data;
   end

endmodule