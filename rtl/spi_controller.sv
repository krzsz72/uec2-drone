//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | SPI controller                               |
//      |______________________________________________|
//
// Author: Krzysztof Piziak
//******************************************************************************


module spi_controller #(
   parameter int BYTEWIDTH=7,
   parameter logic [BYTEWIDTH-1:0] WIDTH=104 //inout registers width
   )
   (
    input logic clk, rst_n, //start,
    input logic [BYTEWIDTH-1:0] d_length,
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
   logic [BYTEWIDTH-1:0] bit_ctr, bit_ctr_nxt; // 6 bitów, żeby policzyć do 103 (..64)

   //prescaler  100MHz na 1MHz =50 (sclk dziala przez flipflop wiec dodatkowe przez pol)
   localparam CLK_DIVIDER = 50;
   logic [5:0] clk_div, clk_div_nxt;
   logic spi_tick;

   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         state    <= IDLE;
         reg_rx   <= '0;
         shift_tx <= '0;
         copi     <= '0;
         sclk     <= '0;
         cs_n     <= '1;
         busy     <= '0;
         done     <= '0;
         bit_ctr  <= '0;
         clk_div  <= '0;
      end else begin
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
            if (d_length && !bit_ctr) state_nxt = BUSY;
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
               if (bit_ctr == d_length) begin
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
            sclk_nxt = 1'b1;
            cs_n_nxt = 1'b1;
            busy_nxt = 1'b0;
            reg_rx_nxt = '0;
            
            if (d_length) begin
               busy_nxt     = 1'b1;
               cs_n_nxt     = 1'b0;          
               shift_tx_nxt = reg_tx;
            end
         end
         
         BUSY: begin
            busy_nxt = 1'b1;
            cs_n_nxt = 1'b0;
            done_nxt = 1'b0;
            
            if (spi_tick) begin
               sclk_nxt = ~sclk;
            
               if (~sclk == 1'b1) begin
                  // ROSNĄCE ZBOCZE: gyro read  
                  reg_rx_nxt = {reg_rx[WIDTH-2:0], poci};
               end else begin
                  // OPADAJĄCE ZBOCZE: gyro send
                  shift_tx_nxt = {shift_tx[WIDTH-2:0], 1'b0};
                  copi_nxt = shift_tx[WIDTH-1]; 
                  if(bit_ctr==d_length)begin
                     cs_n_nxt = 1'b1;
                     busy_nxt = 1'b0;
                     done_nxt = 1'b1;
                  end
               end

            end
         end
         
         DONE: begin
            sclk_nxt = 1'b1;
            cs_n_nxt = 1'b1;
            busy_nxt = 1'b0;
            done_nxt = 1'b0;
         end
      endcase
   end

endmodule