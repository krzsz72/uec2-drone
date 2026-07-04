//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | gyroscope driver   (WIP)                     |
//      |______________________________________________|
//      |                                              |
//      |    Parameters and defaults                   |
//      |        WIDTH  = 32  bits                     | 
//      |                                              |
//      |                 WIP                          |
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


module gyro #(
   parameter logic [5:0] WIDTH=32 //inout registers width
   )
   (
    input logic clk, start,
   //what data to sned
    output logic [WIDTH-1:0] d_out,
    output logic [WIDTH-1:0] d_length,
   //status flags
    output logic busy,done
   );


   typedef enum logic [1:0] {IDLE, STARTUP, READ, DONE} fsm_state_t;
   fsm_state_t state, state_nxt = STARTUP;

   logic [WIDTH-1:0] reg_rx_nxt, shift_tx, shift_tx_nxt;
   logic copi_nxt, sclk_nxt, busy_nxt, done_nxt, cs_n_nxt;
   logic [4:0] bit_ctr, bit_ctr_nxt; // 5 bitów, żeby policzyć do 16

   //prescaler  100MHz na 1MHz =50 (sclk dziala przez flipflop wiec dodatkowe przez pol)
   localparam CLK_DIVIDER = 50;
   logic [5:0] clk_div, clk_div_nxt;
   logic spi_tick;

  // logic armed;
   logic [WIDTH-1:0] init_cntr, init_cntr_nxt;
   const bit WRITEBIT = 1'b0;
   const bit READBIT = 1'b1;

   // seq block
   always_ff @(posedge clk) begin
         state    <= state_nxt;
         init_cntr <= init_cntr_nxt;
         shift_tx <= shift_tx_nxt;
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
         STARTUP: begin
          //  if (armed) state_nxt = IDLE;
            if(start) begin
               case(init_cntr)
               //wypisz rejestry po kolei trzba cntr
               0: begin
                   d_out={READBIT,7'h0F,24'b0}; //WHOAMI ... dokoncyzc: pomysl z wysyaniem podniesienia CS_N w ramce od gyro? !
                   d_length='d16;        //                         =====================================================
                  end
               // CTRL2_G 11h - 0xAC - 0b10101100
               // CTRL3_C 12h - 0x44 - 0b01000100
               // CTRL4_C 13h - 0x0E - 0b00001110
               // CTRL6_C 15h - 0x01 - 0b00000001
               // CTRL7_G 16h - 0x00 - 0b00000000
               endcase
               init_cntr_nxt=init_cntr+1;
         end
         
         IDLE: begin
            bit_ctr_nxt = '0;
            clk_div_nxt = '0;
            if (start) state_nxt = READ;
         end
         
         READ: begin
            if (clk_div == CLK_DIVIDER-1) begin
               clk_div_nxt = '0;
               spi_tick = 1'b1;
            end else begin
               clk_div_nxt = clk_div + 1;
            end
         end

            if (spi_tick) begin
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

endmodule