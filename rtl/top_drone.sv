//******************************************************************************
//       ______________________________________________
//      |                                              |
//      | drone top module                             |
//      |______________________________________________|
//
// Author: Krzysztof Piziak, Szymon Rybak
//******************************************************************************


module top_drone#(
    parameter MAX_TICK = 14'd9999
) (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        input  logic [7:0] d_in,
        output logic pwm,
        //---PWM---
        input logic spi_start,
     (*KEEP = "true"*)        output logic sclk,
     (*KEEP = "true"*)        input logic poci,
     (*KEEP = "true"*)        output logic cs_n,
     (*KEEP = "true"*)        output logic copi,
        //---SPI---
        output logic [3:0] an,
        output logic [7:0] sseg,
        output logic [15:0] led,
        input logic button,
        input logic btnR_pulse,
        input logic btnReset,
        input logic [15:0] sw
    );

    timeunit 1ns;
    timeprecision 1ps;

     pwm #(
        .MAX_TICK(MAX_TICK)
     ) u_pwm50Hz(
        .clk,
        .enable,
        .d_in,
        .pwm
     );
   
      (*KEEP = "true"*)
     logic [103:0] spi_transmit;
     wire spi_done;
     (*KEEP = "true"*)
    logic [103:0] spi_received; //max potrzebuje zmiescic 6x2x8bit = 96b +8bit padding z komendy kontrolera
    logic [6:0] data_length;

    logic signed [15:0] roll_raw;
    logic signed [15:0] roll_deg;
    logic signed [15:0] pitch_raw;
    logic signed [15:0] pitch_deg;

    logic signed [15:0] converted_Y;
    logic signed [15:0] converted_X;

    logic signed [15:0] converted_Z;
        logic signed [15:0] angel; //👼 debug
    
    logic [1:0] gyro_state;

    // High precision signed Q15.24 angle data
    logic signed [39:0] rollq24;
    logic signed [39:0] pitchq24;
    logic signed [39:0] gyroXq24;
    logic signed [39:0] gyroYq24;
    logic signed [39:0] gyroZq24;

    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); 
    gyro #( )
     gyro (
        .clk(clk),
        .rst_n(~btnReset),
        .d_length(data_length),
        .d_out(spi_transmit),
        .ready( (spi_done && sw[15]) | spi_start),
        .gyro_data( (&spi_received[1:0]) ),
        .state_curr(gyro_state),
        .state_prev()
    );

     spi_controller #( )
      spi_controller(
         .clk(clk),
         .rst_n(~btnReset),
         .d_length(data_length),
         .sclk(sclk),
         .cs_n(cs_n),
         .reg_rx(spi_received),
         .reg_tx(spi_transmit),
         .poci(poci),
         .copi(copi),
         .busy(),
         .done(spi_done)
      );

      
      convert_gyro #(
        .WIDTH(16)
        )
         converter_X (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_received[95:80]),
          .data_latch(gyro_read_done),
          .angle_deg(converted_X),
          .angle_raw(),
          .latched_raw(),
          .mul_result(gyroXq24)
      );

      convert_gyro #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_received[79:64]),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(converted_Y),
          .mul_result(gyroYq24)
      );

      convert_gyro #(
        .WIDTH(16)
        )
         converter_Z (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_received[63:48]),
          .data_latch(gyro_read_done),
          .angle_deg(),
          .angle_raw(),
          .latched_raw(converted_Z),
          .mul_result(gyroZq24)
      );


      convert_accel #(.WIDTH(16) )
       accel_pitch (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_raw_data(spi_received[31:16]),
        .data_latch(gyro_read_done),
        .angle_deg(pitch_deg),
        .angle_raw(),
        .latched_raw(pitch_raw),
        .mul_result(pitchq24)
      );

      convert_accel #(.WIDTH(16) )
       accel_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_raw_data(spi_received[47:32]),
        .data_latch(gyro_read_done),
        .angle_deg(roll_deg),
        .angle_raw(),
        .latched_raw(roll_raw),
        .mul_result(rollq24)
      );
  
    logic signed [15:0] estim_roll;
    angle_estimator #() estimator_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_data(rollq24),
        .gyro_data(gyroYq24),
        .angle_deg(estim_roll)
    );

    logic signed [15:0] estim_pitch;
    angle_estimator #() estimator_pitch (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_data(pitchq24),
        .gyro_data(gyroXq24),
        .angle_deg(estim_pitch)
    );



// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [2:0] page_cnt;       // Do przewijania 104-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

// Zmienna dla wygody - grupuje 3 przełączniki w jeden 3-bitowy wektor (zakres 0-7)
logic [2:0] debug_menu_sel;
assign debug_menu_sel = sw[14:12]; 

// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : spi_transmit - nadawanawartosc
// 010 : spi_received - odebrane dane
// 011 : convertedY, convertedX, convertedZ
// 100 : status: converted_Y_H , 00000, led2 - spi_received[1], led1 - ?converted_Y led0 - ?6c
// 101 : angel - Y angle deegrees per second
// 110 : estimated_angle_roll, estimated_angle_pitch
// 111 : roll_deg, pitch_deg, yaw_deg
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 3'b0;
        flag_6c_detect <= 1'b0;
    end 
    else begin
        // 1. PRZEWIJANIE STRON
        if (btnR_pulse) begin 
            page_cnt <= page_cnt + 3'd1;
        end

        // 2. ZATRZASKIWANIE ZDARZEŃ
        if (spi_done == 1'b1 && spi_received[7:0] == 8'h6c) begin // 95:80?
            flag_6c_detect <= 1'b1; 
        end

        // 3. MULTIPLEKSER MENU (Kodowanie binarne sw[14:12])
        case (debug_menu_sel)
            3'b000: begin // Zwykły tryb (wszystkie 3 switche w dół)
                led <= 16'b0;
                disp_hex <= '0;
            end
            
            3'b001: begin // sw[14]=0, sw[13]=0, sw[12]=1 -> ODCZYTWARTOSC (104 bit)
                case (page_cnt)
                    3'd0: begin led <= spi_transmit[95:80];           disp_hex <= spi_transmit[95:80];          end
                    3'd1: begin led <= spi_transmit[79:64];           disp_hex <= spi_transmit[79:64];          end
                    3'd2: begin led <= spi_transmit[63:48];           disp_hex <= spi_transmit[63:48];          end
                    3'd3: begin led <= spi_transmit[47:32];           disp_hex <= spi_transmit[47:32];          end
                    3'd4: begin led <= spi_transmit[31:16];           disp_hex <= spi_transmit[31:16];          end
                    3'd5: begin led <= spi_transmit[15:0];            disp_hex <= spi_transmit[15:0];           end
                    3'd6: begin led <= {8'b0, spi_transmit[103:96]};  disp_hex <= {8'b0, spi_transmit[103:96]}; end
                endcase
            end

            3'b010: begin // sw[14]=0, sw[13]=1, sw[12]=0 -> SPI_ODEBRANE (56 bit)
                case (page_cnt)
                    3'd0: begin led <= spi_received[95:80];           disp_hex <= spi_received[95:80];          end // gyro X
                    3'd1: begin led <= spi_received[79:64];           disp_hex <= spi_received[79:64];          end // gyro Y
                    3'd2: begin led <= spi_received[63:48];           disp_hex <= spi_received[63:48];          end // gyro Z
                    3'd3: begin led <= spi_received[47:32];           disp_hex <= spi_received[47:32];          end // xl X
                    3'd4: begin led <= spi_received[31:16];           disp_hex <= spi_received[31:16];          end // xl Y
                    3'd5: begin led <= spi_received[15:0];            disp_hex <= spi_received[15:0];           end // xl Z
                    3'd6: begin led <= {8'b0, spi_received[103:96]};  disp_hex <= {8'b0, spi_received[103:96]}; end
                endcase
            end

            3'b011: begin // sw[14]=0, sw[13]=1, sw[12]=1 -> CONVERTED_Y
                case(page_cnt)
                    3'b00: begin led <= converted_Y;                                    disp_hex <= converted_Y[15] ? -converted_Y : converted_Y; end //clamp to cut +- (misses lowest value)
                    3'b01: begin led <= converted_X;                                    disp_hex <= converted_X[15] ? -converted_X : converted_X; end //clamp to cut +- (misses lowest value)
                    3'b10: begin led <= converted_Z;                                    disp_hex <= converted_Z[15] ? -converted_Z : converted_Z; end //clamp to cut +- (misses lowest value)
                endcase
            end

            3'b100: begin // sw[14]=1, sw[13]=0, sw[12]=0 -> FLAGI STATUSU
                led      <= {converted_Y[15:8], 5'b00000, spi_received[1], (|converted_Y), flag_6c_detect};
                disp_hex <= {converted_Y[15:8], 5'b00000, spi_received[1], (|converted_Y), flag_6c_detect};
            end
            
            3'b101: begin // sw[14]=1, sw[13]=0, sw[12]=1 -> kat Y
                led <= angel;                                         disp_hex <= angel[15] ? -angel : angel; //clamp angle to cut +-
            end

            3'b110: begin // sw[14]=1, sw[13]=1, sw[12]=0 -> ROLL_RAW
                case(page_cnt)
                    3'b00: begin led <= estim_roll;                                      disp_hex <= estim_roll[15] ? -estim_roll : estim_roll; end //clamp to cut +- (misses lowest value)
                    3'b01: begin led <= estim_pitch;                                      disp_hex <= estim_pitch[15] ? -estim_pitch : estim_pitch; end //clamp to cut +- (misses lowest value)
                    
                endcase
            end

            3'b111: begin // sw[14]=1, sw[13]=1, sw[12]=1 -> ROLL_DEG
                case(page_cnt)
                    3'b00: begin led <= roll_deg;                                      disp_hex <= roll_deg[15] ? -roll_deg : roll_deg; end //clamp angle to cut +-
                    3'b01: begin led <= pitch_deg;                                      disp_hex <= pitch_deg[15] ? -pitch_deg : pitch_deg; end //clamp angle to cut +-
                endcase
            end

            default: begin
                led <= 16'b0;
                disp_hex <= '0;
            end
        endcase
    end
end
    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(1'b0),
        .hex3(disp_hex[15:12]), 
        .hex2(disp_hex[11:8]), 
        .hex1(disp_hex[7:4]), 
        .hex0(disp_hex[3:0]), 
        .dp_in({1'b1,page_cnt}),       // kropki jako page_cntr
        .an(an),
        .sseg(sseg)
    );



endmodule
