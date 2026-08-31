//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | gyro communication fsm                       |
//      |______________________________________________|
//
// Author: Krzysztof Piziak
//******************************************************************************


module gyro #(
   parameter int BYTEWIDTH=7,
   parameter logic [BYTEWIDTH-1:0] WIDTH=104 //inout registers width
   )
   (
    input logic clk, ready, rst_n, gyro_data,
    output logic [WIDTH-1:0] d_out,
    output logic [BYTEWIDTH-1:0] d_length,
    output logic [1:0] state_curr, state_prev
   );

   const bit WRITEBIT = 1'b0;
   const bit READBIT = 1'b1;

   typedef enum logic [1:0] {STARTUP, GYRO_POLLING, READ} fsm_state_t;
   fsm_state_t state;
   fsm_state_t state_nxt = STARTUP;

   logic [WIDTH-1:0] data_out = {READBIT,103'b0};
   logic [BYTEWIDTH-1:0] data_length =0;
   logic [WIDTH-1:0] init_cntr, init_cntr_nxt;

   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         state    <= STARTUP;
         init_cntr <= '0;
         d_length <='0;
         d_out    <={READBIT,103'b0};
         state_prev <= '0;
         state_curr <= '0;


      end else begin
         state    <= state_nxt;
         init_cntr <= init_cntr_nxt;
         d_length <= data_length;
         d_out    <= data_out;
         state_prev <= state_curr;
         state_curr <= state;

      end
   end

   // fsm block
   always_comb begin
      state_nxt   = state;
      init_cntr_nxt = init_cntr;
      data_length = d_length;
      data_out = d_out;
      
      case(state)
         STARTUP: begin
            if(ready) begin
               case(init_cntr)    
               'd0: begin
                   data_out={READBIT,7'h0F,96'b0}; //WHOAMI
                   data_length='d16;
                  end
               'd1: begin
                  data_out={WRITEBIT,7'h11,8'b10101100,88'b0};     // CTRL2_G 11h - 0xAC - 0b10101100
                  data_length='d16;  
               end
                'd2: begin
                  data_out={WRITEBIT,7'h12,8'b01000100,88'b0};     // CTRL3_C 12h - 0x44 - 0b01000100
                  data_length='d16;  
               end
                'd3: begin
                  data_out={WRITEBIT,7'h13,8'b00001110,88'b0};     // CTRL4_C 13h - 0x0E - 0b00001110
                  data_length='d16;  
               end
                'd4: begin
                  data_out={WRITEBIT,7'h15,8'b00000001,88'b0};     // CTRL6_C 15h - 0x01 - 0b00000001
                  data_length='d16;  
               end
                'd5: begin
                  data_out={WRITEBIT,7'h16,8'b00000000,88'b0};     // CTRL7_G 16h - 0x00 - 0b00000000
                  data_length='d16;  
               end
                'd6: begin
                  data_out={WRITEBIT,7'h10,8'b10101100,88'b0};     // CTRL1_XL 10h - 0xAC - 0b10101100
                  data_length='d16;  
               end
               default: begin                //when finished
                  state_nxt=GYRO_POLLING;
               end
               endcase
               init_cntr_nxt=init_cntr+1;
         end
      end
         GYRO_POLLING: begin 
            data_out={READBIT,7'h1e,96'b0}; // status_reg 1Eh - 00000-TDA-GDA-XLDA
            data_length='d16;  
            if(gyro_data && ready) state_nxt = READ;
         end
         
         READ: begin 
            data_out={READBIT,7'h22,96'b0}; // OUTX_L_G 22h - OUTX_L_G register D7 D6 D5 D4 D3 D2 D1 D0 \ D15 D14 D13 D12 D11 D10 D9 D8
            data_length='d104; //1bajt na adres + 6 bajtow na XL XH; YL YH; ZL ZH  
            if(ready) state_nxt = GYRO_POLLING;
         end
         default: state_nxt = STARTUP;
      endcase
   end

endmodule