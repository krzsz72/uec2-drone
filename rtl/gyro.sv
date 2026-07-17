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


module gyro #(
   parameter int BYTEWIDTH=6,
   parameter logic [BYTEWIDTH-1:0] WIDTH=56 //inout registers width
   )
   (
    input logic clk, ready, rst_n, gyro_data, //start de facto ready - done od spi   gyro_data sprawdzana gotowosc danych na zewn i tutaj tylko flaga wysylana zeby nastepna ramke wyslalo
    output logic [WIDTH-1:0] d_out,
    output logic [BYTEWIDTH-1:0] d_length
   );

   const bit WRITEBIT = 1'b0;
   const bit READBIT = 1'b1;

   typedef enum logic [1:0] {STARTUP, GYRO_POLLING, READ} fsm_state_t;
   fsm_state_t state;
   fsm_state_t state_nxt = STARTUP;

   logic [WIDTH-1:0] data_out = {READBIT,55'b0};
   logic [BYTEWIDTH-1:0] data_length =0;
   logic [WIDTH-1:0] init_cntr, init_cntr_nxt;

   // seq block
   always_ff @(posedge clk) begin
      if(!rst_n) begin
         state    <= STARTUP;
         init_cntr <= '0;
         d_length <='0;
         d_out    <={READBIT,55'b0};

      end else begin
         state    <= state_nxt;
         init_cntr <= init_cntr_nxt;
         d_length <= data_length;
         d_out    <= data_out;

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
          //  if (armed) state_nxt = GYRO_POLLING;
            if(ready) begin
               case(init_cntr)    //wypisz rejestry po kolei
               'd0: begin
                   data_out={READBIT,7'h0F,48'b0}; //WHOAMI ... dokoncyzc: pomysl z wysyaniem podniesienia CS_N w ramce od gyro? !
                   data_length='d16;
                  end
               'd1: begin
                  data_out={WRITEBIT,7'h11,8'b10101100,40'b0};     // CTRL2_G 11h - 0xAC - 0b10101100
                  data_length='d16;  
               end
                'd2: begin
                  data_out={WRITEBIT,7'h12,8'b01000100,40'b0};     // CTRL3_C 12h - 0x44 - 0b01000100
                  data_length='d16;  
               end
                'd3: begin
                  data_out={WRITEBIT,7'h13,8'b00001110,40'b0};     // CTRL4_C 13h - 0x0E - 0b00001110
                  data_length='d16;  
               end
                'd4: begin
                  data_out={WRITEBIT,7'h15,8'b00000001,40'b0};     // CTRL6_C 15h - 0x01 - 0b00000001
                  data_length='d16;  
               end
                'd5: begin
                  data_out={WRITEBIT,7'h16,8'b00000000,40'b0};     // CTRL7_G 16h - 0x00 - 0b00000000
                  data_length='d16;  
                  state_nxt=GYRO_POLLING;
               end
               default: begin                //when finished
                  state_nxt=GYRO_POLLING;
               end
               endcase
               init_cntr_nxt=init_cntr+1;
         end
      end
         GYRO_POLLING: begin //polling czy dane sa gotowe
            if(ready) begin
               data_out={READBIT,7'h1e,48'b0}; // status_reg 1Eh - 00000-TDA-GDA-XLDA    --- to idzie do spi_odebrane. jezeli bit[1] bedzie 1 to dane sa gotowe
               data_length='d16;  
            end
            if(gyro_data) state_nxt = READ;
         end
         
         READ: begin //wysyla ramke o dlugosci 3 bajtow by sczytac xyz rejestry.  PAMIETAJ O ZEROWANIU spi_odebrane PO KAZDYM ODCZYCIE
            if(ready) begin
               data_out={READBIT,7'h22,48'b0}; // OUTX_L_G 22h - OUTX_L_G register D7 D6 D5 D4 D3 D2 D1 D0 \ D15 D14 D13 D12 D11 D10 D9 D8
               data_length='d56; //1bajt na adres + 6 bajtow na XL XH; YL YH; ZL ZH  
            end
            state_nxt = GYRO_POLLING;
         end
         default: state_nxt = STARTUP;
      endcase
   end

endmodule