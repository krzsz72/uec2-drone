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

   // Stała filtru komplementarnego, K = 1 / 2^ALPHA_SHIFT
   // Mniejsza wartość to większe zaufanie do żyroskopu.
   localparam int ALPHA_SHIFT = 8;

   logic signed [39:0] angle_full_reg, angle_full_next;
   logic signed [39:0] angle_from_gyro;

   // Blok sekwencyjny - rejestr przechowujący stan filtru (estymowany kąt)
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         angle_full_reg <= '0;
      end else begin
         angle_full_reg <= angle_full_next;
      end
   end

   // Blok kombinacyjny - obliczenia filtru komplementarnego
   always_comb begin
      // Krok 1: Predykcja kąta na podstawie poprzedniej estymaty i nowego odczytu z żyroskopu
      angle_from_gyro = angle_full_reg + gyro_data;
      // Krok 2: Korekta predykcji na podstawie odczytu z akcelerometru
      // angle_next = angle_from_gyro + K * (accel_angle - angle_from_gyro)
      angle_full_next = angle_from_gyro + ((accel_data - angle_from_gyro) >>> ALPHA_SHIFT);
   end

   // Konwersja z formatu Q15.24 (używanego w obliczeniach) do Q8.7 (oczekiwanego przez PID)
   // Wymaga przesunięcia w prawo o (24 - 7) = 17 bitów.
   assign angle_deg = angle_full_next >>> 17;

endmodule