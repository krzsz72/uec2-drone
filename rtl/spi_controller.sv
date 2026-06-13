//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | SPI interface                                |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        WIDTH  = 16  bits                     | 
//      |                                              |
//      |                                              |
//      |                                              |
//  ----| start                                   sclk |----
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
//        .start(start),
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
   parameter logic [4:0] WIDTH=16 //inout registers width
   )
   (
    input logic clk, start,
    output logic sclk,
    output logic cs_n,
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

   logic [WIDTH-1:0] reg_rx_nxt, shift_tx, shift_tx_nxt;
   logic copi_nxt, sclk_nxt, busy_nxt, done_nxt, cs_n_nxt;
   logic [4:0] bit_ctr, bit_ctr_nxt; // 5 bitów, żeby policzyć do 16

   //prescaler  100MHz na 1MHz =50 (sclk dziala przez flipflop wiec dodatkowe przez pol)
   localparam CLK_DIVIDER = 50;
   logic [5:0] clk_div, clk_div_nxt;
   logic spi_tick;

   // seq block
   always_ff @(posedge clk) begin
         state    <= state_nxt;
         reg_rx   <= reg_rx_nxt;
         shift_tx <= shift_tx_nxt;
         copi     <= copi_nxt;
         sclk     <= sclk_nxt;
         cs_n     <= cs_n_nxt;
         busy     <= busy_nxt;
         done     <= done_nxt;
         bit_ctr  <= bit_ctr_nxt;
         clk_div  <= clk_div_nxt;
   end

   // fsm block
   always_comb begin
      state_nxt   = state;
      bit_ctr_nxt = bit_ctr;
      clk_div_nxt = clk_div;
      spi_tick    = 1'b0;

      case(state)
         IDLE: begin
            bit_ctr_nxt = '0;
            clk_div_nxt = '0;
            if (start) state_nxt = BUSY;
         end
         
         BUSY: begin
            if (clk_div == CLK_DIVIDER-1) begin
               clk_div_nxt = '0;
               spi_tick = 1'b1;
            end else begin
               clk_div_nxt = clk_div + 1;
            end

            if (spi_tick && sclk == 1'b1) begin
               bit_ctr_nxt = bit_ctr + 1;
               if (bit_ctr == WIDTH - 1) begin
                  state_nxt = DONE;
               end
            end
         end
         
         DONE: begin
            state_nxt = IDLE;
         end
         
         default: state_nxt = IDLE;
      endcase
   end

   // reg block
   always_comb begin
      sclk_nxt     = sclk;
      busy_nxt     = busy;
      done_nxt     = 1'b0;
      cs_n_nxt     = cs_n;
      copi_nxt     = copi;
      shift_tx_nxt = shift_tx;
      reg_rx_nxt   = reg_rx;

      case(state)
         IDLE: begin
            sclk_nxt = 1'b0;
            cs_n_nxt = 1'b1;
            busy_nxt = 1'b0;
            
            if (start) begin
               busy_nxt     = 1'b1;
               cs_n_nxt     = 1'b0;          
               shift_tx_nxt = reg_tx;
               copi_nxt     = reg_tx[WIDTH-1];
            end
         end
         
         BUSY: begin
            busy_nxt = 1'b1;
            cs_n_nxt = 1'b0;
            
            if (spi_tick) begin
               sclk_nxt = ~sclk;
               
               if (~sclk == 1'b1) begin
                  // ROSNĄCE ZBOCZE: gyro read
                  reg_rx_nxt = {reg_rx[WIDTH-2:0], poci};
               end else begin
                  // OPADAJĄCE ZBOCZE: gyro send
                  shift_tx_nxt = {shift_tx[WIDTH-2:0], 1'b0};
                  copi_nxt = shift_tx_nxt[WIDTH-1]; 
               end
            end
         end
         
         DONE: begin
            sclk_nxt = 1'b0;
            cs_n_nxt = 1'b1;
            busy_nxt = 1'b0;
            done_nxt = 1'b1;
         end
      endcase
   end

endmodule