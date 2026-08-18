/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_drone#(
    parameter MAX_TICK = 14'd9999
) (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        input  logic [7:0] d_in,
        //---PWM---
        output logic [3:0] motor_pwm_out,
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
        input logic btnD_pulse,
        input logic btnL_pulse,
        input logic btnR_pulse,
        input logic btnReset,
        input logic [15:0] sw
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    /**
     * Signals assignments
     */

    /**
     * Submodules instances
     */

     //logic [6:0] destination = 7'h0F;
     //logic [7:0] data_write;
     //logic [31:0] nadajwartosc = {1'b0,destination,data_write,16'b0};
      (*KEEP = "true"*)
     logic [103:0] odczytwartosc;          // = {1'b1,destination,16'b0};
     wire spi_done;
    // wire spi_loopback;
     (*KEEP = "true"*)
    logic [103:0] spi_odebrane; //max potrzebuje zmiescic 6x2x8bit = 96b +8bit padding z komendy kontrolera
    logic [6:0] data_length;
    logic signed [15:0] roll_raw;
    logic signed [15:0] roll_deg;
    logic signed [15:0] converted_Y;
    logic signed [15:0] angel; //👼
    logic [1:0] gyro_state;

    logic signed [39:0] rollq24;
    logic signed [39:0] gyroYq24;

    logic gyro_read_done;
    assign gyro_read_done = ((gyro_state==2'b10) & spi_done); 
    gyro #( )
     gyro (
        .clk(clk),
        .rst_n(~btnReset),
        .d_length(data_length),
        .d_out(odczytwartosc),
        .ready( (spi_done && sw[15]) | spi_start),
        .gyro_data( (&spi_odebrane[1:0]) ),
        .state_curr(gyro_state)
    );

     spi_controller #( )
      spi_controller(
         .clk(clk),
         .rst_n(~btnReset),
         .d_length(data_length),
         .sclk(sclk),
         .cs_n(cs_n),
         .reg_rx(spi_odebrane),
         .reg_tx(odczytwartosc),
         .poci(poci),
         .copi(copi),
         .busy(),
         .done(spi_done)
      );

      convert_gyro #(
        .WIDTH(16)
        )
         converter_Y (
          .clk(clk),
          .rst_n(~btnReset),
          .gyro_raw_data(spi_odebrane[79:64]),
          .data_latch(gyro_read_done),
          .angle_deg(angel),
          .angle_raw(),
          .latched_raw(converted_Y),
          .mul_result(gyroYq24)
      );

      convert_accel #(.WIDTH(16) )
       accel_roll (
        .clk(clk),
        .rst_n(~btnReset),
        .accel_raw_data(spi_odebrane[31:16]),
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

    // PID Controller instance
    logic signed [15:0] pid_error_debug;
    logic signed [31:0] pid_integral_debug;
    logic signed [15:0] pid_derivative_debug;
    logic signed [15:0] pid_output_debug;
    logic signed [15:0] pid_input_scaled;

    // Convert integer degrees from `roll_deg` to Q8.7 format for the PID controller
    assign pid_input_scaled = roll_deg <<< 7;

    PID #(.WIDTH(16)) u_pid_controller (
        .clk(clk),
        .rst_n(~btnReset),
        .enable(gyro_read_done),
        .estim_roll(pid_input_scaled),
        .Kp_in(sw[7:5]),
        .Ki_in(sw[4:2]),
        .Kd_in(sw[1:0]),
        .pwm_from_pid(), // Not used directly anymore
        .pid_error_out(pid_error_debug),
        .pid_integral_out(pid_integral_debug),
        .pid_derivative_out(pid_derivative_debug),
        .pid_output_out(pid_output_debug)
    );

    // --- Startup Sequence and Motor Mixer Integration ---
    typedef enum logic [1:0] { FSM_IDLE, FSM_WAIT, FSM_RAMP, FSM_RUN } startup_fsm_state_t;
    startup_fsm_state_t startup_state, startup_state_nxt;

    typedef enum logic [1:0] { MODE_INIT, MODE_ARMED, MODE_RUN } mixer_mode_t;
    mixer_mode_t mixer_mode, mixer_mode_nxt;

    logic [15:0] throttle_out, throttle_out_nxt;

    // Counters
    logic [27:0] wait_counter, wait_counter_nxt;
    logic [27:0] ramp_step_counter, ramp_step_counter_nxt;

    localparam WAIT_TIME = 28'd200_000_000; // 2s @ 100MHz
    localparam RAMP_STEP_TIME = 28'd10_000_000; // 100ms per step
    localparam RAMP_STEPS = 500; // 1500 - 1000

    // Startup FSM - Sequential Part
    always_ff @(posedge clk, posedge btnReset) begin
        if (btnReset) begin
            startup_state <= FSM_IDLE;
            mixer_mode <= MODE_INIT;
            throttle_out <= 0;
            wait_counter <= 0;
            ramp_step_counter <= 0;
        end else begin
            startup_state <= startup_state_nxt;
            mixer_mode <= mixer_mode_nxt;
            throttle_out <= throttle_out_nxt;
            wait_counter <= wait_counter_nxt;
            ramp_step_counter <= ramp_step_counter_nxt;
        end
    end

    // Startup FSM - Combinational Part
    always_comb begin
        startup_state_nxt = startup_state;
        mixer_mode_nxt = mixer_mode;
        throttle_out_nxt = throttle_out;
        wait_counter_nxt = wait_counter;
        ramp_step_counter_nxt = ramp_step_counter;

        case (startup_state)
            FSM_IDLE: begin
                mixer_mode_nxt = MODE_INIT;
                throttle_out_nxt = 0;
                if (btnD_pulse) begin
                    startup_state_nxt = FSM_WAIT;
                    wait_counter_nxt = 0;
                end
            end
            FSM_WAIT: begin
                mixer_mode_nxt = MODE_ARMED;
                throttle_out_nxt = 1000;
                if (wait_counter == WAIT_TIME - 1) begin
                    startup_state_nxt = FSM_RAMP;
                    ramp_step_counter_nxt = 0;
                end else begin
                    wait_counter_nxt = wait_counter + 1;
                end
            end
            FSM_RAMP: begin
                mixer_mode_nxt = MODE_RUN;
                if (throttle_out < 1500) begin
                    if (ramp_step_counter == RAMP_STEP_TIME - 1) begin
                        throttle_out_nxt = throttle_out + 1;
                        ramp_step_counter_nxt = 0;
                    end else begin
                        ramp_step_counter_nxt = ramp_step_counter + 1;
                    end
                end else begin
                    startup_state_nxt = FSM_RUN;
                end
            end
            FSM_RUN: begin
                mixer_mode_nxt = MODE_RUN;
                throttle_out_nxt = 1500;
            end
        endcase
    end

    logic [14:0] m_width[4];
    motor_mixer u_motor_mixer (
        .clk(clk),
        .rst_n(~btnReset),
        .mode(mixer_mode),
        .throttle(throttle_out),
        .pid_pitch(0), // Not implemented yet
        .pid_roll(pid_output_debug),
        .pid_yaw(0),   // Not implemented yet
        .m1_width(m_width[0]),
        .m2_width(m_width[1]),
        .m3_width(m_width[2]),
        .m4_width(m_width[3])
    );

    // Instantiate 4 PWM modules
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pwm_inst
            pwm #( .MAX_TICK(MAX_TICK) ) u_pwm (
                .clk(clk),
                .enable(enable),
                .d_in(m_width[i]),
                .pwm(motor_pwm_out[i])
            );
        end
    endgenerate


// --- DEKLARACJE POMOCNICZE ---
logic [15:0] disp_hex;
logic [2:0] page_cnt;       // Do przewijania 104-bitowych zmiennych
logic       flag_6c_detect; // Zatrzask dla flagi odebrania '6c'

logic [1:0] displayed_motor_idx; // 0:M1, 1:M2, 2:M3, 3:M4
// Zmienna dla wygody - grupuje 3 przełączniki w jeden 3-bitowy wektor (zakres 0-7)
logic [2:0] debug_menu_sel;
assign debug_menu_sel = sw[14:12]; 

// *******D E B U G**************D E B U G**************D E B U G*******
// sw[11]=1: PID debug mode. sw[14:12] select displayed value:
// 000: PWM output (1000-2000)
// 001: PID Gains (Kp, Ki, Kd)
// 010: PID input (estim_roll)
// 011: PID error
// 100: PID integral (lower 16 bits)
// 101: PID integral (upper 16 bits)
// 110: PID derivative
// 111: PWM output (0-100%)
//
// *******D E B U G**************D E B U G**************D E B U G*******
// sw15 - tryb ciagly gyro, sw14,sw13,sw12:
// 001 : odczytwartosc - nadawanawartosc
// 010 : spi_odebrane - odebrane dane
// 011 : convertedY - 
// 100 : status: converted_Y_H , 00000, led2 - spi_odebrane[1], led1 - ?converted_Y led0 - ?6c
// 101 : angel - Y angle deegrees per second
// 110 : estimated_angle_roll
// 111 : roll_deg
// *******D E B U G**************D E B U G**************D E B U G*******


// --- GŁÓWNY BLOK DEBUGGERA ---
always_ff @(posedge clk) begin
    if (btnReset) begin
        led <= 16'b0;
        disp_hex <= '0;
        page_cnt <= 3'b0;
        flag_6c_detect <= 1'b0;
        displayed_motor_idx <= 2'b0; // Reset motor index
    end 
    else begin
        if (sw[11]) begin // PID Test Mode
            // In PID mode, btnL cycles through motors to display
            if (btnL_pulse) begin
                displayed_motor_idx <= displayed_motor_idx + 1;
            end
            
            // This mode uses sw[14:12] to select PID data to display
            case (debug_menu_sel) // sw[14:12]
                3'b000: disp_hex <= m_width[displayed_motor_idx]; // PWM value (1000-2000) for selected motor
                3'b001: disp_hex <= {3'b0, sw[7:5], 3'b0, sw[4:2], 2'b0, sw[1:0]}; // Show gains
                3'b010: disp_hex <= pid_input_scaled; // PID input (scaled roll_deg)
                3'b011: disp_hex <= pid_error_debug;  // PID error (Q8.7)
                3'b100: disp_hex <= pid_integral_debug[15:0]; // Lower part of integral
                3'b101: disp_hex <= pid_integral_debug[31:16]; // Upper part of integral
                3'b110: disp_hex <= pid_derivative_debug; // Derivative term
                3'b111: begin
                    // Calculate PWM percentage for the selected motor
                    logic [15:0] selected_pwm_percent;
                    selected_pwm_percent = (m_width[displayed_motor_idx] > 1000) ? ((m_width[displayed_motor_idx] - 1000) / 10) : 0;
                    disp_hex <= selected_pwm_percent;
                end
                default: disp_hex <= m_width[displayed_motor_idx];
            endcase
            // Display value on hex display and motor index on LEDs 1:0
            led <= {disp_hex[15:2], displayed_motor_idx};

        end else begin // Original Debug Mode
            // 1. PRZEWIJANIE STRON
            if (btnR_pulse) begin 
                page_cnt <= page_cnt + 3'd1;
            end

            // 2. ZATRZASKIWANIE ZDARZEŃ
            if (spi_done == 1'b1 && spi_odebrane[7:0] == 8'h6c) begin // 95:80?
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
                        3'd0: begin led <= odczytwartosc[95:80];           disp_hex <= odczytwartosc[95:80];          end
                        3'd1: begin led <= odczytwartosc[79:64];           disp_hex <= odczytwartosc[79:64];          end
                        3'd2: begin led <= odczytwartosc[63:48];           disp_hex <= odczytwartosc[63:48];          end
                        3'd3: begin led <= odczytwartosc[47:32];           disp_hex <= odczytwartosc[47:32];          end
                        3'd4: begin led <= odczytwartosc[31:16];           disp_hex <= odczytwartosc[31:16];          end
                        3'd5: begin led <= odczytwartosc[15:0];            disp_hex <= odczytwartosc[15:0];           end
                        3'd6: begin led <= {8'b0, odczytwartosc[103:96]};  disp_hex <= {8'b0, odczytwartosc[103:96]}; end
                    endcase
                end

                3'b010: begin // sw[14]=0, sw[13]=1, sw[12]=0 -> SPI_ODEBRANE (56 bit)
                    case (page_cnt)
                        3'd0: begin led <= spi_odebrane[95:80];           disp_hex <= spi_odebrane[95:80];          end // gyro X
                        3'd1: begin led <= spi_odebrane[79:64];           disp_hex <= spi_odebrane[79:64];          end // gyro Y
                        3'd2: begin led <= spi_odebrane[63:48];           disp_hex <= spi_odebrane[63:48];          end // gyro Z
                        3'd3: begin led <= spi_odebrane[47:32];           disp_hex <= spi_odebrane[47:32];          end // xl X
                        3'd4: begin led <= spi_odebrane[31:16];           disp_hex <= spi_odebrane[31:16];          end // xl Y
                        3'd5: begin led <= spi_odebrane[15:0];            disp_hex <= spi_odebrane[15:0];           end // xl Z
                        3'd6: begin led <= {8'b0, spi_odebrane[103:96]};  disp_hex <= {8'b0, spi_odebrane[103:96]}; end
                    endcase
                end

                3'b011: begin // sw[14]=0, sw[13]=1, sw[12]=1 -> CONVERTED_Y
                    led <= converted_Y;                                    disp_hex <= converted_Y[15] ? -converted_Y : converted_Y; //clamp to cut +- (misses lowest value)
                end

                3'b100: begin // sw[14]=1, sw[13]=0, sw[12]=0 -> FLAGI STATUSU
                    led      <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
                    disp_hex <= {converted_Y[15:8], 5'b00000, spi_odebrane[1], (|converted_Y), flag_6c_detect};
                end
                
                3'b101: begin // sw[14]=1, sw[13]=0, sw[12]=1 -> kat Y
                    led <= angel;                                         disp_hex <= angel[15] ? -angel : angel; //clamp angle to cut +-
                end

                3'b110: begin // sw[14]=1, sw[13]=1, sw[12]=0 -> ROLL_RAW
                    led <= estim_roll;                                      disp_hex <= estim_roll[15] ? -estim_roll : estim_roll; //clamp to cut +- (misses lowest value)
                end

                3'b111: begin // sw[14]=1, sw[13]=1, sw[12]=1 -> ROLL_DEG
                    led <= roll_deg;                                      disp_hex <= roll_deg[15] ? -roll_deg : roll_deg; //clamp angle to cut +-
                end

                default: begin
                    led <= 16'b0;
                    disp_hex <= '0;
                end
            endcase
        end
    end
end
    
      disp_hex_mux u_display (
        .clk(clk),
        .reset(1'b0),
        .hex3(disp_hex[15:12]), 
        .hex2(disp_hex[11:8]), 
        .hex1(disp_hex[7:4]), 
        .hex0(disp_hex[3:0]), 
        .dp_in(4'b1111),       // Wygaszone kropki
        .an(an),
        .sseg(sseg)
    );

endmodule
