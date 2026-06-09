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
//  ----| start                                   sclk |----
//  ==8=| reg_tx                                reg_rx |=8==
//  ----| poci                                    copi |----
//      |                                              |
//  ----| clk                                          |
//      |______________________________________________|
//
//** Description ***************************************************************
//
//  An SPI interface controller with inout registers and serial communication copi poci wires.
//
//** Sample Instantiation ******************************************************
//
//    spi_controller #(
//        .WIDTH(8)
//    )
//    spi_controller(
//        .clk(clk),
//        .start(start),
//        .sclk(sclk),
//        .reg_rx(reg_rx),
//        .reg_tx(reg_tx),
//        .poci(poci),
//        .copi(copi)
//    );
//
//** Signals: ************************************************************
//
//  1) clk: High speed system clock (typically 100 MHz)
//
//  2) start: Activates the full-duplex transmission when logic high.
//
//  3) sclk: SPI transmission clock. Due to posedge clk logic it is half of clk. 
//
//  4) reg_rx/reg_tx : internal register holding the transceived data.
//
//  5) poci/copi : wires for serial transmission. Containt single bit informaation 
//                 that is being currently transceived
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
    output logic copi,
   //status flags
    output logic busy,done
   );

   typedef enum logic [1:0] {IDLE, BUSY, DONE} fsm_state_t;
    fsm_state_t state, state_nxt = IDLE;

   logic [WIDTH-1:0] reg_rx_nxt;
   logic copi_reg_nxt, copi_reg, sclk_nxt, busy_nxt, done_nxt;
   logic [WIDTH-1:0] bit_ctr, bit_ctr_nxt;

   //seq logic
   always_ff @(posedge clk)begin
      copi_reg<=copi_reg_nxt;
      reg_rx<=reg_rx_nxt;
      sclk<=sclk_nxt;
      done<=done_nxt;
      bit_ctr<=bit_ctr_nxt;
      busy<=busy_nxt;
      state<=state_nxt;
   end

   //fsm logic
   always_comb begin
      case(state)
         IDLE: begin
            bit_ctr_nxt='0;
            if(start) state_nxt=BUSY;
         end
         BUSY: begin
            if(bit_ctr==WIDTH) state_nxt=DONE;
            if(sclk) bit_ctr_nxt = bit_ctr+1;
         end
         DONE: begin
            state_nxt=IDLE;
         end
         default: state_nxt=IDLE;
      endcase
   end

   //reg logic
   always_comb begin
      assign copi = (state == BUSY) ? copi_reg : 1'bz;

      case(state)
         IDLE: begin
            sclk_nxt='1;
            busy_nxt='0;
            done_nxt='0;
         end
         BUSY: begin
            sclk_nxt=~sclk;
            busy_nxt='1;
            if(sclk) begin
               reg_rx_nxt = {reg_rx[WIDTH-2:0],poci};
               copi_reg_nxt = reg_tx[WIDTH-1-bit_ctr];
            end
         end
         DONE: begin
            done_nxt='1;
         end

      endcase
   end

endmodule